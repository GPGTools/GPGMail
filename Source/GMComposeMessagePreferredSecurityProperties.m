//
//  GMComposeMessagePreferredSecurityProperties.m
//  GPGMail
//
//  Created by Lukas Pitschl on 22.11.16.
//
//

#import "GMComposeMessagePreferredSecurityProperties.h"

#import "CCLog.h"
#import "NSString+GPGMail.h"

//#import "GPGKey.h"

#import "GPGMailBundle.h"

#import "MCKeychainManager.h"
#import "MCMessage.h"
#import "ComposeBackEnd.h"

#import "ComposeBackEnd+GPGMail.h"
#import "GMSecurityHistory.h"

#import "Message+GPGMail.h"
#import "GMMessageSecurityFeatures.h"


@implementation GMComposeMessageReplyToDummyKey

- (instancetype)init {
    self = [super initWithFingerprint:@"0x0000000000000000"];
    return self;
}

@end

// The GMComposeMessageSecurityKeyStatus class is responsible for
// keeping track of the key availability for either S/MIME or OpenPGP.
//
// Whenever the sender or recipients for a message change, a new lookup
// occurs in order to determine if the necessary signing and encryption keys
// are available.
//
// Since fetching S/MIME certificates involves macOS Keychain and might
// be an expensive operation, the certificates are cached internally
// and subsequent lookups check the internal cache first and only
// if no query has been previously run for the sender or recipient
// the Mail's MCKeychainManager class is used.
//
// The GMComposeMessageSecurityKeyStatus class provides the following information:
//
// - canSign: is a valid signing key available for the sender
// - canEncrypt: are valid encryption keys available for the recipients
// - senderKey: the signing key associated with the sender address
// - recipientKeys: the encryption keys associated with the recipients' addresses
// - invalidSigningIdentityError: an error that might have occurred while querying S/MIME certificates
// - recipientsThatHaveNoEncryptionKeys: a list of recipients for which no encryption keys are available.
@interface GMComposeMessageSecurityKeyStatus : NSObject

- (instancetype)initWithSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod;

- (id)encryptionKeyForAddress:(NSString *)address;
- (id)signingKeyForAddress:(NSString *)address;
- (NSArray *)recipientsThatHaveNoEncryptionKeys;

- (void)updateSender:(NSString *)sender;
- (void)updateRecipients:(NSArray *)recipients replyToAddresses:(NSArray *)replyToAddresses;

- (void)clearKeyCache;

// Security method the the key status represents. Either OpenPGP or S/MIME
@property (nonatomic, assign) GPGMAIL_SECURITY_METHOD securityMethod;

// A local cache of key lookups for any selected sender addresses.
@property (nonatomic, copy) NSMutableDictionary *signingKeys;

// A local cache of key lookups for any entered recipients.
@property (nonatomic, copy) NSMutableDictionary *encryptionKeys;

// A map that contains manual mappings between a sender address
// and a specific key. This is used in case that multiple signing keys
// exist for the same address.
//
// The map is always queried before the local cache.
@property (nonatomic, copy) NSMutableDictionary *signingKeySenderMap;

// The key associated with the current sender address.
@property (nonatomic, copy) NSMutableDictionary *senderKey;

// The keys associated with the current recipients.
@property (nonatomic, copy) NSMutableDictionary *recipientKeys;

@property (nonatomic, copy) NSError *invalidSigningIdentityError;

@property (nonatomic, assign) BOOL canEncrypt;
@property (nonatomic, assign) BOOL canSign;

@end

@implementation GMComposeMessageSecurityKeyStatus

- (instancetype)initWithSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod {
    if(self = [super init]) {
        _securityMethod = securityMethod;

        _signingKeys = [NSMutableDictionary new];
        _encryptionKeys = [NSMutableDictionary new];
        _signingKeySenderMap = [NSMutableDictionary new];

        _senderKey = [NSMutableDictionary new];
        _recipientKeys = [NSMutableDictionary new];

        _canSign = NO;
        _canEncrypt = NO;
    }
    return self;
}

// Manually map a signing key to a sender address.
- (void)setSigningKey:(GPGKey *)key forSender:(NSString *)sender {
    [self.signingKeySenderMap setObject:key forKey:[sender gpgNormalizedEmail]];
}

// Returns a manually mapped signing key for the given sender address.
- (GPGKey *)signingKeyForSender:(NSString *)sender {
    return [self.signingKeySenderMap objectForKey:[sender gpgNormalizedEmail]];
}

// Returns the current sender address.
- (NSString *)sender {
    if(![[self.senderKey allKeys] count]) {
        return nil;
    }
    return [self.senderKey allKeys][0];
}

// This method needs to be called whenever the sender address changes.
//
// The current `senderKey` map is cleared, the key associated
// with the sender address retrieved and the result cached to prevent
// unnecessary lookups.
//
// If a valid key is found `canSign` is set to true.
- (void)updateSender:(NSString *)sender {
    [self.senderKey removeAllObjects];
    id key = [self signingKeyForAddress:sender];
    [self cacheSigningKey:key forAddress:sender];
    self.canSign = key == nil ? NO : YES;
}

// This method needs to be called whenever the recipients change.
//
// The current `recipientKeys` map is cleared, a lookup for each recipient
// started and the result cached to prevent unnecessary lookups.
//
// If valid keys for all recipients are available, `canEncrypt` is set to true.
- (void)updateRecipients:(NSArray *)recipients replyToAddresses:(NSArray *)replyToAddresses {
    [self.recipientKeys removeAllObjects];

    // While it might seem counter intuitive, the default for encrypt is set to yes if recipients are available.
    // This makes sense, since the first recipient with no certificate available will set the status to NO.
    // Other cases don't change the default value.
    BOOL canEncrypt = [recipients count] ? YES : NO;
    for(NSString *address in recipients) {
        id key = [self encryptionKeyForAddress:address];
        // In order to support gnupg groups, it's possible that a list of keys is returned, even if only
        // one recipient is passed in. If more than one key is found, the list of keys is stored for that recipient,
        // instead of only the first key. (#903)
        [self cacheEncryptionKey:key forAddress:address];

        if(key == nil) {
            canEncrypt = NO;
        }
    }

    // For reply-to addresses a dummy key is created and cached
    // in order to satisfy Mail's requirement, treating reply-to
    // addresses the same as recipients. See #970 for details.
    for(NSString *address in replyToAddresses) {
        // Make sure not to use a dummy key for a reply to address which is
        // as real recipient as well.
        if([recipients containsObject:address] || [recipients containsObject:[address gpgNormalizedEmail]]) {
            continue;
        }
        [self cacheEncryptionKey:[GMComposeMessageReplyToDummyKey new] forAddress:address];
    }

    self.canEncrypt = canEncrypt;
}

// Retrieve the signing key for a given address.
//
// First the local `signingKeySenderMap` and `signingKeys` caches are
// checked for signing key mappings and only if they don't contain a valid
// key the actual key stores for OpenPGP and S/MIME are checked.
//
// Returns nil if no key is found.
- (id)signingKeyForAddress:(NSString *)address {
    id signingKey = [self.signingKeySenderMap objectForKey:[address gpgNormalizedEmail]];
    if(signingKey) {
        return signingKey;
    }

    // Check the internal cache.
    signingKey = [self.signingKeys objectForKey:address];
    if(signingKey != nil) {
        return signingKey != [NSNull null] ? signingKey : nil;
    }

    if(self.securityMethod == GPGMAIL_SECURITY_METHOD_SMIME) {
        NSError __autoreleasing *invalidSigningIdentityError = nil;
        id signingIdentity = nil;
        // Bug #957: Adapt GPGMail to the S/MIME changes introduced in Mail for 10.13.2b3
        //
        // Apple Mail team has added a possibility to display errors, if macOS fails to read
        // a signing identity.
        if([MCKeychainManager respondsToSelector:@selector(copySigningIdentityForAddress:error:)]) {
        signingIdentity = [MCKeychainManager copySigningIdentityForAddress:address error:&invalidSigningIdentityError];
        }
        else {
            signingIdentity = (__bridge id)[MCKeychainManager copySigningIdentityForAddress:address error:&invalidSigningIdentityError];
        }
        self.invalidSigningIdentityError = invalidSigningIdentityError;
        return signingIdentity;
    }
    else {
        NSString *senderAddress = [address gpgNormalizedEmail];
        // TODO: Consider pereferring the default key if one is configured.
        NSArray *signingKeyList = [[[GPGMailBundle sharedInstance] signingKeyListForAddress:senderAddress] allObjects];
        if([signingKeyList count] > 0) {
            signingKey = signingKeyList[0];
            return signingKey;
        }
    }
    
    return nil;
}

// Retrieve the encryption key for given recipient.
//
// First the local `encryptionKey` cache is checked for encryption
// key mappings and only if it doesn't contain a valid key the actual
// key stores for OpenPGP and S/MIME are checked.
//
// Returns nil if no key is found. Might return a list of keys for OpenPGP in
// order to support GnuPG groups.
- (id)encryptionKeyForAddress:(NSString *)address {
    // Check the internal cache.
    id encryptionKey = [self.encryptionKeys objectForKey:address];
    if(encryptionKey != nil) {
        return encryptionKey != [NSNull null] ? encryptionKey : nil;
    }

    if(self.securityMethod == GPGMAIL_SECURITY_METHOD_SMIME) {
        id certificate = [MCKeychainManager copyEncryptionCertificateForAddress:address];
        if(certificate) {
            return certificate;
        }
    }
    else {
        NSString *normalizedAddress = [address gpgNormalizedEmail];
        NSArray *keyList = [[[GPGMailBundle sharedInstance] publicKeyListForAddresses:@[normalizedAddress]] allObjects];
        if([keyList count] > 0) {
            return keyList;
        }
    }

    return nil;
}

// Cache the result for a signing key lookup under the given address.
//
// Each lookup caches the result under the full address
// (e.g Lukas Pitschl <lukele@gpgtools.org>) **and** the email
// only, since Mail tends to pass the address in either format at times.
- (void)cacheSigningKey:(id)key forAddress:(NSString *)address {
    key = key == nil ? [NSNull null] : key;
    [self.signingKeys setObject:key forKey:address];
    [self.signingKeys setObject:key forKey:[address gpgNormalizedEmail]];
    [self.senderKey setObject:key forKey:address];
}

// Cache the result for an encryption key lookup under the given address.
//
// Each lookup caches the result under the full address
// (e.g Lukas Pitschl <lukele@gpgtools.org>) **and** the email
// only, since Mail tends to pass the address in either format at times.
- (void)cacheEncryptionKey:(id)key forAddress:(NSString *)address {
    key = key == nil ? [NSNull null] : key;
    // Never cache dummy keys for addresses entered into reply-to.
    // Otherwise the dummy key might be returned instead of a real
    // key, if the same address as entered in the `reply-to` field is
    // *later* entered in the `to` or `cc` field.
    if(![key isKindOfClass:[GMComposeMessageReplyToDummyKey class]]) {
        [self.encryptionKeys setObject:key forKey:address];
        [self.encryptionKeys setObject:key forKey:[address gpgNormalizedEmail]];
    }
    [self.recipientKeys setObject:key forKey:address];
}

// Returns a list of all recipients for which no encryption key is available.
- (NSArray *)recipientsThatHaveNoEncryptionKeys {
    // Bug #961: Deadlock when using S/MIME and trying to toggle encryption state of a message on macOS 10.13
    //
    // -[ComposeBackEnd recipientsThatHaveNoKeyForEncryption] uses the smimeLock internally.
    // Since the calling method of _GMRecipientsThatHaveNoKeyForEncryption already uses the smimeLock,
    // a deadlock is triggered when calling the original mail method.
    //
    // Since the code for checking for missing S/MIME certificates is by now almost identical to the
    // check performed for OpenPGP keys, there's no need to call into the original mail method anymore.
    NSMutableArray *recipients = [NSMutableArray new];

    [self.recipientKeys enumerateKeysAndObjectsUsingBlock:^(id address, id key, BOOL * __unused stop) {
        if(key == nil || key == [NSNull null]) {
            [recipients addObject:address];
        }
    }];

    return [recipients copy];
}

- (void)clearKeyCache {
    // In case the keyring is updated it is necessary to clear the key caches.
    [self.encryptionKeys removeAllObjects];
    [self.signingKeys removeAllObjects];
    [self.senderKey removeAllObjects];
    [self.recipientKeys removeAllObjects];
    [self.signingKeySenderMap removeAllObjects];
}

@end

NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderKeySecurityMethod = @"x-gm-security-method";
NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldSign = @"x-gm-should-sign";
NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldEncrypt = @"x-gm-should-encrypt";
NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderKeySender = @"x-gm-sender";
NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderKeySenderFingerprint = @"x-gm-sender-fingerprint";
NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderKeyReferenceMessageEncrypted = @"x-gm-reference-encrypted";
NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderValueOpenPGP = @"openpgp";
NSString * const kGMComposeMessagePreferredSecurityPropertiesHeaderValueSMIME = @"smime";

@interface GMComposeMessagePreferredSecurityProperties ()

@property (nonatomic, readwrite, assign) BOOL userDidChooseSecurityMethod;

@property (nonatomic, readwrite, assign) BOOL shouldSignMessage;
@property (nonatomic, readwrite, assign) BOOL shouldEncryptMessage;

@property (nonatomic, retain) GMComposeMessageSecurityKeyStatus *PGPKeyStatus;
@property (nonatomic, retain) GMComposeMessageSecurityKeyStatus *SMIMEKeyStatus;

@property (nonatomic, readwrite, retain) MCMessage *message;

@end

@implementation GMComposeMessagePreferredSecurityProperties

- (instancetype)init {
    if((self = [super init])) {
        _PGPKeyStatus = [[GMComposeMessageSecurityKeyStatus alloc] initWithSecurityMethod:GPGMAIL_SECURITY_METHOD_OPENPGP];
        _SMIMEKeyStatus = [[GMComposeMessageSecurityKeyStatus alloc] initWithSecurityMethod:GPGMAIL_SECURITY_METHOD_SMIME];

        _messageIsDraft = NO;
        _messageIsReply = NO;
        _messageIsFowarded = NO;
        _userDidChooseSecurityMethod = NO;

        _userShouldSignMessage = ThreeStateBooleanUndetermined;
        _userShouldEncryptMessage = ThreeStateBooleanUndetermined;

        // Should sign and should encrypt message will be set to the user
        // preferences and later updated from
        // `-[GMComposeMessagePreferredSecurityProperties updateWithHintsFromComposeBackEnd:]`
        // once additional information is available. For example draft headers if a draft
        // is continued, or sign and encrypt status of an original message if a
        // reply is created.
        GMSecurityOptions *defaultSecurityOptions = [[GMSecurityHistory new] securityOptionsFromDefaults];
        _shouldSignMessage = defaultSecurityOptions.shouldSign;
        _shouldEncryptMessage = defaultSecurityOptions.shouldEncrypt;

        _referenceMessageIsEncrypted = ThreeStateBooleanUndetermined;
    }
    
    return self;
}

+ (GPGMAIL_SECURITY_METHOD)defaultSecurityMethod {
    return [GMSecurityHistory defaultSecurityMethod];
}

- (void)setUserShouldSignMessage:(ThreeStateBoolean)userShouldSignMessage {
    // Since our three state boolean enum defines False as 0 and True as 1, it should be save
    // to use the bool as is. No need to convert it to ThreeStateBooleanTrue or ThreeStateBooleanFalse
    @synchronized (self) {
        if(_userShouldSignMessage != userShouldSignMessage) {
            _userShouldSignMessage = userShouldSignMessage;
        }
    }
}

- (ThreeStateBoolean)userShouldSignMessage {
    @synchronized (self) {
        return _userShouldSignMessage;
    }
}

- (void)setUserShouldEncryptMessage:(ThreeStateBoolean)userShouldEncryptMessage {
    @synchronized (self) {
        if(_userShouldEncryptMessage != userShouldEncryptMessage) {
            _userShouldEncryptMessage = userShouldEncryptMessage;
        }
    }
}

- (ThreeStateBoolean)userShouldEncryptMessage {
    @synchronized (self) {
        return _userShouldEncryptMessage;
    }
}

- (BOOL)shouldSignMessage {
    @synchronized (self) {
        if(!self.canSign)
            return NO;

        if(_userShouldSignMessage != ThreeStateBooleanUndetermined)
            return _userShouldSignMessage;

        return _shouldSignMessage;
    }
}

- (BOOL)shouldEncryptMessage {
    @synchronized (self) {
        if(!self.canEncrypt)
            return NO;

        if(_userShouldEncryptMessage != ThreeStateBooleanUndetermined)
            return _userShouldEncryptMessage;

        return _shouldEncryptMessage;
    }
}

- (void)setSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod {
    @synchronized (self) {
        if(_securityMethod != securityMethod) {
            _securityMethod = securityMethod;
        }
        _userDidChooseSecurityMethod = YES;
    }
}

- (GPGMAIL_SECURITY_METHOD)securityMethod {
    @synchronized (self) {
        return _securityMethod;
    }
}

- (BOOL)userDidChooseSecurityMethod {
    @synchronized (self) {
        return _userDidChooseSecurityMethod;
    }
}

- (BOOL)canSign {
    @synchronized (self) {
        return self.keyStatus.canSign;
    }
}

- (BOOL)canEncrypt {
    @synchronized (self) {
        return self.keyStatus.canEncrypt;
    }
}

- (NSDictionary *)signingIdentities {
    @synchronized (self) {
        return self.keyStatus.senderKey;
    }
}

- (NSDictionary *)encryptionCertificates {
    @synchronized (self) {
        return self.keyStatus.recipientKeys;
    }
}

- (void)updateWithHintsFromComposeBackEnd:(ComposeBackEnd *)backEnd {
    @synchronized (self) {
        self.message = [backEnd originalMessage];

        _messageIsReply = [(ComposeBackEnd_GPGMail *)backEnd messageIsBeingReplied];
        _messageIsDraft = [self.message primitiveMessageType] == 5;
        _messageIsFowarded = [(ComposeBackEnd_GPGMail *)backEnd messageIsBeingForwarded];

        // Bug #1041: If the `originalMessage` is a draft, it no longer refers
        // to the message that is being replied, but instead to the message that
        // is being written.
        // In that case the security features of the `originalMessage` can't be used
        // but instead the security features information is stored in special header
        // keys on the draft.
        if(_messageIsDraft) {
            MCMessageHeaders *headers = [backEnd originalMessageHeaders];
            [self configureFromDraftHeaders:headers];
        }
        else {
            if((_messageIsReply || _messageIsFowarded) && ([(Message_GPGMail *)self.message securityFeatures].PGPEncrypted || [(Message_GPGMail *)self.message isSMIMEEncrypted])) {
                _referenceMessageIsEncrypted = ThreeStateBooleanTrue;
            }

            GMSecurityOptions *securityOptions = nil;
            // Bug #1045: Status of security buttons should be updated properly when draft is continued.
            //
            // Determine the default values for `shouldSign` and `shouldEncrypt`.
            // N.B.: Once determined these values don't change. The button state
            // is then defined by the values of `shouldSign|Encrypt` and `canSign|canEncrypt`
            //
            // There's no need to pass in encrypt or sign flags, since those are only
            // necessary to determine the best security method and that's not needed here.
            if(_messageIsReply || _messageIsDraft) {
                securityOptions = [[GMSecurityHistory new] bestSecurityOptionsForReplyToMessage:self.message signFlags:0 encryptFlags:0];
            }
            else {
                securityOptions = [[GMSecurityHistory new] bestSecurityOptionsForSignFlags:0 encryptFlags:0];
            }
            _shouldSignMessage = securityOptions.shouldSign;
            _shouldEncryptMessage = securityOptions.shouldEncrypt;
        }
    }
}

- (GPGKey *)signingKey {
    @synchronized (self) {
        NSString *sender = [self.PGPKeyStatus sender];
        return [self.PGPKeyStatus signingKeyForSender:sender];
    }
}

- (GPGKey *)encryptionKeyForDraft {
    @synchronized (self) {
        // Check if a key for encrypting the draft is available matching the sender.
        // Otherwise, return any key pair with encryption capabilities.
        // The best match is of course a signing key which is set when selecting a sender address.
        GPGKey *signingKey = [self signingKey];
        if(signingKey != nil && signingKey.canAnyEncrypt) {
            return signingKey;
        }
        // Otherwise check for a secret key matching the sender address.
        NSString *senderAddress = [[self.PGPKeyStatus sender] gpgNormalizedEmail];
        GPGKey *key = (GPGKey *)[self.PGPKeyStatus signingKeyForAddress:senderAddress];
        if(key != nil && key.canAnyEncrypt) {
            return key;
        }
        // Last but not least, accept any public key associated with an available secret key.
        return [[GPGMailBundle sharedInstance] anyPersonalPublicKeyWithPreferenceAddress:senderAddress];
    }
}

- (void)updateSigningKey:(GPGKey *)signingKey forSender:(NSString *)sender {
    @synchronized (self) {
        // Once a signing key is set, the keyring is no longer queried for a key matching
        // the signer address, but the set signing key is always used. (#895)
        [self.PGPKeyStatus setSigningKey:signingKey forSender:sender];
        [self.PGPKeyStatus updateSender:sender];
        // Also make sure to update the encrypt-to-self key.
        [self.PGPKeyStatus cacheEncryptionKey:signingKey forAddress:sender];
    }
}

- (void)updateSender:(NSString *)sender recipients:(NSArray *)recipients replyToAddresses:(NSArray *)replyToAddresses {
    @synchronized (self) {
        [self _updateSender:sender recipients:recipients replyToAddresses:replyToAddresses];
    }
}

- (void)_updateSender:(NSString *)sender recipients:(NSArray *)recipients replyToAddresses:(NSArray *)replyToAddresses {
    BOOL allowEncryptEvenIfNoSigningKeyIsAvailable = [[GPGOptions sharedOptions] boolForKey:@"AllowEncryptEvenIfNoSigningKeyIsAvailable"];

    // Bug #976: Mail complains that it has not "finished finding public keys"
    //           when the user presses send.
    //
    // This error can be reliably triggered, if pressing the encrypt button
    // is the last action performed before sending the message, since pressing
    // the send button right after will trigger a call to `-[ComposeBackEnd updateSMIMEStatus:]`
    // which uses `-[ComposeBackEnd _smimeLock]` internally.
    // At the same time `-[ComposeViewController sendMailAfterChecking:]` – which is
    // invoked when pressing the send button – performs a check if -[ComposeBackEnd _smimeLock]`
    // is still locked. If `-[ComposeBackEnd updateSMIMEStatus:]` takes too long to complete,
    // the lock will still be in use and a result Mail will warn the user that it has not
    // "finished finding public keys."
    //
    // In previous versions S/MIME certificates were not properly cached,
    // which lead to the problem that a lookup for an S/MIME certificate
    // might take just long enough to lead to the bug.
    //
    // In order to make sure that updateSMIMEStatus returns almost immediately,
    // all S/MIME certificates and OpenPGP keys which are queried whenever
    // the user changes the sender or recipients of the message, are cached separately
    // in their own `GMComposeMessageSecurityKeyStatus` instances instead of as
    // before in the same dictionary, always evicting all entries not matching the
    // necessary type (S/MIME lookups would evict any GPGKey entries, GPG lookups
    // would evict any S/MIME certificate entries).
    [self.PGPKeyStatus updateSender:sender];
    // Bug #1060: Display error tooltip if no signing key is available
    //
    // Always refresh recipient key status as well, in order to show
    // proper tooltips when hovering over the encryption security button.
    // Previously, if no signing key was available the tooltip would show
    // that no recipients where entered yet.
    [self.PGPKeyStatus updateRecipients:recipients replyToAddresses:replyToAddresses];

    // SMIME only allows encryption if a signing certificate exists.
    [self.SMIMEKeyStatus updateSender:sender];
    if(self.SMIMEKeyStatus.canSign) {
        [self.SMIMEKeyStatus updateRecipients:recipients replyToAddresses:replyToAddresses];
    }
    else {
        [self.SMIMEKeyStatus updateRecipients:@[] replyToAddresses:replyToAddresses];
    }

    // Now we know, if signing and encryption is available. Now on to determine, what security properties should be enabled.
    GPGMAIL_SIGN_FLAG signFlags = 0;
    if(self.PGPKeyStatus.canSign)
        signFlags |= GPGMAIL_SIGN_FLAG_OPENPGP;
    if(self.SMIMEKeyStatus.canSign)
        signFlags |= GPGMAIL_SIGN_FLAG_SMIME;
    
    GPGMAIL_ENCRYPT_FLAG encryptFlags = 0;
    if(self.PGPKeyStatus.canEncrypt && (self.PGPKeyStatus.canSign || allowEncryptEvenIfNoSigningKeyIsAvailable))
        encryptFlags |= GPGMAIL_ENCRYPT_FLAG_OPENPGP;
    if(self.SMIMEKeyStatus.canEncrypt)
        encryptFlags |= GPGMAIL_ENCRYPT_FLAG_SMIME;
    
    GMSecurityHistory *securityHistory = [[GMSecurityHistory alloc] init];
    GMSecurityOptions *securityOptions = [securityHistory securityOptionsFromDefaults];
    
    GPGMAIL_SECURITY_METHOD securityMethod = self.securityMethod;

    // In past versions the security properties were also refreshed
    // continously in case a draft was being continued. There's however
    // no need to do this, since security method and security button
    // statuses are already stored in the drafts header. See
    // `[ComposeBackEnd_GPGMail configureFromDraftHeaders:]` for details.
    if(_messageIsDraft) {
        // If this is a draft which was created before install GPG Mail,
        // the security method might be undetermined. In that case, set
        // it to the default.
        // Bug #1061: Restore the security method configured on the draft
        //
        // Due to a missing check if the security method is undetermined or
        // if the user actively selected a security method, the security method
        // was set to the default security method when a draft was continued.
        //
        // Now the default security is only set if not enough information
        // is available from the draft itself.
        if(_securityMethod == GPGMAIL_SECURITY_METHOD_UNDETERMINDED && !_userDidChooseSecurityMethod) {
            _securityMethod = securityOptions.securityMethod;
        }

        return;
    }
    // In case of a reply or a forward, the reference message will determine
    // what security method to use.
    if(_messageIsReply || _messageIsFowarded) {
        securityOptions = [securityHistory bestSecurityOptionsForReplyToMessage:self.message signFlags:signFlags encryptFlags:encryptFlags];
    }
    else {
        securityOptions = [securityHistory bestSecurityOptionsForSignFlags:signFlags encryptFlags:encryptFlags];
    }

    // In case the security method to be used is undetermined, the security options
    // will define what method to best use.
    if(securityMethod == GPGMAIL_SECURITY_METHOD_UNDETERMINDED) {
        securityMethod = securityOptions.securityMethod;
    }

    // DON'T use self.securityMethod. The property is only supposed to be used from outside, since
    // it also sets the userDidChooseSecurityMethod value.
    _securityMethod = securityMethod;
}

- (void)resetKeyStatus {
    @synchronized (self) {
        [self.PGPKeyStatus clearKeyCache];
    }
}

- (GMComposeMessageSecurityKeyStatus *)keyStatus {
    @synchronized (self) {
        GMComposeMessageSecurityKeyStatus *keyStatus = self.securityMethod == GPGMAIL_SECURITY_METHOD_SMIME ? self.SMIMEKeyStatus : self.PGPKeyStatus;
        return keyStatus;
    }
}

- (NSArray *)recipientsThatHaveNoEncryptionKey {
    @synchronized (self) {
        return [self.keyStatus recipientsThatHaveNoEncryptionKeys];
    }
}

- (NSError *)invalidSigningIdentityError {
    return self.keyStatus.invalidSigningIdentityError;
}

#pragma mark Bug #1045

- (NSDictionary *)messageProtectionStatusDraftHeaders {
    @synchronized (self) {
        // Bug #1045: Status of security buttons should be updated properly when draft is continued.
        //
        // When saving the current `shouldSign` and `shouldEncrypt` status of the
        // message in the draft headers, `self.shouldSignMessage` and `self.shouldEncryptMessage`
        // can't be used, since they have the side effect to return NO if not all keys
        // are available to either sign or encrypt, instead of the real current status.
        // While this comes in handy for properly updating the UI, it falsifies the status
        // stored in the draft headers.
        BOOL shouldSign = _userShouldSignMessage != ThreeStateBooleanUndetermined ? _userShouldSignMessage : _shouldSignMessage;
        BOOL shouldEncrypt = _userShouldEncryptMessage != ThreeStateBooleanUndetermined ? _userShouldEncryptMessage : _shouldEncryptMessage;

        return @{
                 kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldEncrypt: shouldEncrypt ? @"YES" : @"NO",
                 kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldSign: shouldSign ? @"YES" : @"NO"
                 };
    }
}

#pragma mark

- (NSDictionary *)secureDraftHeaders {
    @synchronized (self) {
        NSMutableDictionary *secureDraftHeaders = [[NSMutableDictionary alloc] initWithDictionary:
                                                   @{kGMComposeMessagePreferredSecurityPropertiesHeaderKeySecurityMethod: self.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? kGMComposeMessagePreferredSecurityPropertiesHeaderValueOpenPGP : kGMComposeMessagePreferredSecurityPropertiesHeaderValueSMIME
                                                     }];
        [secureDraftHeaders addEntriesFromDictionary:[self messageProtectionStatusDraftHeaders]];
        // Once set, the reference-encrypted header must not be altered.
        // So if the header doesn't exist and thus `_referenceMessageIsEncrypted`'s
        // value is `ThreeStateBooleanUndetermined`, it is not returned.
        if(!_messageIsDraft || (_messageIsDraft && _referenceMessageIsEncrypted != ThreeStateBooleanUndetermined)) {
            [secureDraftHeaders setValue:_referenceMessageIsEncrypted == ThreeStateBooleanTrue ? @"YES": @"NO" forKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeyReferenceMessageEncrypted];
        }

        if(![[self.PGPKeyStatus sender] isEqualToString:@""] && self.signingKey != nil) {
            [secureDraftHeaders setValue:[self.signingKey fingerprint] forKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeySenderFingerprint];
            [secureDraftHeaders setValue:[self.PGPKeyStatus sender] forKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeySender];
        }

        return [secureDraftHeaders copy];
    }
}

- (NSArray *)secureDraftHeadersKeys {
    return @[
             kGMComposeMessagePreferredSecurityPropertiesHeaderKeySecurityMethod,
             kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldSign,
             kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldEncrypt,
             kGMComposeMessagePreferredSecurityPropertiesHeaderKeyReferenceMessageEncrypted,
             kGMComposeMessagePreferredSecurityPropertiesHeaderKeySender,
             kGMComposeMessagePreferredSecurityPropertiesHeaderKeySenderFingerprint
    ];
}

- (void)configureFromDraftHeaders:(MCMessageHeaders *)draftHeaders {
    @synchronized (self) {
        // x-should-pgp-encrypt is the old obsolete name, but has to be supported
        // for old drafts. If both header keys are set, prefer the new one.
        GMSecurityOptions *defaultSecurityOptions = [[GMSecurityHistory new] securityOptionsFromDefaults];

        BOOL headerIsAvailable = NO;
        for(NSString *headerKey in @[kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldEncrypt, @"x-should-pgp-encrypt"]) {
            if([draftHeaders firstHeaderForKey:headerKey] != nil) {
                _shouldEncryptMessage = [[[draftHeaders firstHeaderForKey:headerKey] uppercaseString] isEqualToString:@"YES"] ? YES : NO;
                headerIsAvailable = YES;
                break;
            }
        }
        if(!headerIsAvailable) {
            _shouldEncryptMessage = defaultSecurityOptions.shouldEncrypt;
        }

        headerIsAvailable = NO;
        for(NSString *headerKey in @[kGMComposeMessagePreferredSecurityPropertiesHeaderKeyShouldSign, @"x-should-pgp-sign"]) {
            if([draftHeaders firstHeaderForKey:headerKey] != nil) {
                _shouldSignMessage = [[[draftHeaders firstHeaderForKey:headerKey] uppercaseString] isEqualToString:@"YES"] ? YES : NO;
                headerIsAvailable = YES;
                break;
            }
        }
        if(!headerIsAvailable) {
            _shouldSignMessage = defaultSecurityOptions.shouldSign;
        }

        NSString *securityMethod = [draftHeaders firstHeaderForKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeySecurityMethod];
        if([@[kGMComposeMessagePreferredSecurityPropertiesHeaderValueOpenPGP, kGMComposeMessagePreferredSecurityPropertiesHeaderValueSMIME] containsObject:securityMethod]) {
            _securityMethod = [[securityMethod lowercaseString] isEqualToString:kGMComposeMessagePreferredSecurityPropertiesHeaderValueOpenPGP] ? GPGMAIL_SECURITY_METHOD_OPENPGP : GPGMAIL_SECURITY_METHOD_SMIME;
        }
        else {
            Message_GPGMail *message = (Message_GPGMail *)self.message;
            if([message isSMIMESigned] || [message isSMIMEEncrypted] || [message securityFeatures].PGPSigned || [message securityFeatures].PGPEncrypted) {
                _securityMethod = [message isSMIMEEncrypted] || [message isSMIMESigned] ? GPGMAIL_SECURITY_METHOD_SMIME : GPGMAIL_SECURITY_METHOD_OPENPGP;
            }
        }

        if([draftHeaders firstHeaderForKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeyReferenceMessageEncrypted] != nil) {
            _referenceMessageIsEncrypted = [[[draftHeaders firstHeaderForKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeyReferenceMessageEncrypted] uppercaseString] isEqualToString:@"YES"] ? YES : NO;
        }

        NSString *senderAddress = [draftHeaders firstHeaderForKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeySender];
        NSString *senderFingerprint = [draftHeaders firstHeaderForKey:kGMComposeMessagePreferredSecurityPropertiesHeaderKeySenderFingerprint];
        if(![senderAddress isEqualToString:@""] && ![senderFingerprint isEqualToString:@""]) {
            GPGKey *signingKey = [[GPGMailBundle sharedInstance] keyForFingerprint:senderFingerprint];
            if(signingKey) {
                [self updateSigningKey:signingKey forSender:senderAddress];
            }
        }
    }
}

- (BOOL)referenceMessageIsEncrypted {
    @synchronized (self) {
        return _referenceMessageIsEncrypted == ThreeStateBooleanTrue;
    }
}

- (NSString *)description {
    @synchronized (self) {
        NSMutableString *description = [[NSMutableString alloc] initWithString:@"{\n"];
        [description appendString:[NSString stringWithFormat:@"\tSecurity method: %@,\n", _securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? @"OpenPGP" : @"S/MIME"]];
        [description appendString:[NSString stringWithFormat:@"\tCan encrypt: %@,\n", self.keyStatus.canEncrypt ? @"YES" : @"NO"]];
        [description appendString:[NSString stringWithFormat:@"\tCan sign: %@,\n", self.keyStatus.canSign ? @"YES" : @"NO"]];
        [description appendString:[NSString stringWithFormat:@"\tShould encrypt: %@,\n", self.shouldEncryptMessage ? @"YES" : @"NO"]];
        [description appendString:[NSString stringWithFormat:@"\tShould sign: %@,\n", self.shouldSignMessage ? @"YES" : @"NO"]];
        [description appendString:[NSString stringWithFormat:@"\tReference message is encrypted: %@,\n", _referenceMessageIsEncrypted == ThreeStateBooleanTrue ? @"YES" : (_referenceMessageIsEncrypted == ThreeStateBooleanFalse ? @"NO" : @"N/A")]];
        [description appendString:[NSString stringWithFormat:@"\tSender: %@,\n", self.keyStatus.senderKey]];
        [description appendString:[NSString stringWithFormat:@"\tRecipients: %@,\n", self.keyStatus.recipientKeys]];

        [description appendString:@"\n}"];
        return description;
    }
}

@end

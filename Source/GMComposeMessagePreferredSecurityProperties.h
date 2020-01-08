//
//  GMComposeMessagePreferredSecurityProperties.h
//  GPGMail
//
//  Created by Lukas Pitschl on 22.11.16.
//
//

#import <Foundation/Foundation.h>
#import <Libmacgpg/Libmacgpg.h>

#import "GPGConstants.h"

#import "MCMessage.h"
#import "ComposeBackEnd.h"

@class GPGKey;

typedef enum {
    ThreeStateBooleanFalse,
    ThreeStateBooleanTrue,
    ThreeStateBooleanUndetermined
} ThreeStateBoolean;

@interface GMComposeMessagePreferredSecurityProperties : NSObject {
    BOOL _messageIsDraft;
    BOOL _messageIsReply;
    BOOL _messageIsFowarded;
    
    ThreeStateBoolean _userShouldSignMessage;
    ThreeStateBoolean _userShouldEncryptMessage;

    GPGMAIL_SECURITY_METHOD _securityMethod;

    ThreeStateBoolean _referenceMessageIsEncrypted;
}

- (instancetype)init;

+ (GPGMAIL_SECURITY_METHOD)defaultSecurityMethod;

- (void)updateWithHintsFromComposeBackEnd:(ComposeBackEnd *)backEnd;
- (void)updateSender:(NSString *)sender recipients:(NSArray *)recipients replyToAddresses:(NSArray *)replyToAddresses;

- (void)updateSigningKey:(GPGKey *)signingKey forSender:(NSString *)sender;

- (GPGKey *)encryptionKeyForDraft;
- (GPGKey *)signingKey;

- (NSArray *)recipientsThatHaveNoEncryptionKey;

- (NSDictionary *)secureDraftHeaders;
- (NSArray *)secureDraftHeadersKeys;

- (void)resetKeyStatus;

@property (nonatomic, readonly, assign) BOOL canSign;
@property (nonatomic, readonly, assign) BOOL canEncrypt;

// Computed properties which will either return the user decision (userShouldSignMessage, userShouldEncryptMessage)
// if available, or otherwise the best default based on GPG Mail settings.
@property (nonatomic, readonly, assign) BOOL shouldSignMessage;
@property (nonatomic, readonly, assign) BOOL shouldEncryptMessage;

// These two properties store the status that the user chose, by clicking on the
// sign or encrypt button. Internally these bools use a three state boolean.
//
// In order to determine whether a message should be encrypted or not however,
// use `shouldSign|EncryptMessage` instead, since that also takes into consideration
// the configured defaults.
//
// These variables can however also be used to determine whether or not the user
// has manually toggled one of the security buttons.
@property (nonatomic, assign) ThreeStateBoolean userShouldSignMessage;
@property (nonatomic, assign) ThreeStateBoolean userShouldEncryptMessage;

@property (nonatomic, readonly, copy) NSDictionary *signingIdentities;
@property (nonatomic, readonly, copy) NSDictionary *encryptionCertificates;

@property (nonatomic, readwrite, assign) GPGMAIL_SECURITY_METHOD securityMethod;

@property (nonatomic, readonly, assign) BOOL userDidChooseSecurityMethod;

@property (nonatomic, readonly, copy) NSError *invalidSigningIdentityError;

// Bug #1041: GMComposeMessagePreferredSecurityProperties also records
// the security status of the reference message in case the composed
// message is a reply or forward.
@property (nonatomic, readonly, assign) BOOL referenceMessageIsEncrypted;

@end

// The GMComposeMessageReplyToDummyKey class is representing
// a GPG Key which is only used as a placeholder for reply-to
// addresses.
//
// See -[HeadersEditor_GPGMail MA_changeHeaderField:] for further
// details.
@interface GMComposeMessageReplyToDummyKey : GPGKey

- (instancetype)init;

@end

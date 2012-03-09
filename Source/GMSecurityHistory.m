/*
 * Copyright (c) 2000-2012, GPGTools Project Team <gpgtools-devel@lists.gpgtools.org>
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of GPGTools Project Team nor the names of GPGMail
 *       contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY GPGTools Project Team AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL GPGTools Project Team AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Libmacgpg/Libmacgpg.h>
#import "CCLog.h"
#import "NSString+GPGMail.h"
#import "Message+GPGMail.h"
#import "GMSecurityHistory.h"

@implementation GMSecurityHistory

+ (GPGMAIL_SECURITY_METHOD)defaultSecurityMethod {
    GPGMAIL_SECURITY_METHOD securityMethod = GPGMAIL_SECURITY_METHOD_OPENPGP;
    if([[GPGOptions sharedOptions] integerForKey:@"DefaultSecurityMethod"]) {
        securityMethod = [[GPGOptions sharedOptions] integerForKey:@"DefaultSecurityMethod"];
        DebugLog(@"Default Security Method is: %@", securityMethod != 0 && securityMethod == GPGMAIL_SECURITY_METHOD_SMIME ? @"S/MIME" : @"OpenPGP");
    }
    return securityMethod;
}

- (GMSecurityOptions *)bestSecurityOptionsForSender:(NSString *)sender recipients:(NSArray *)recipients signFlags:(GPGMAIL_SIGN_FLAG)signFlags 
                                          encryptFlags:(GPGMAIL_ENCRYPT_FLAG)encryptFlags {
    GPGMAIL_SECURITY_METHOD securityMethod = 0;
    NSDictionary *usedSecurityMethods = [GMSecurityHistoryStore sharedInstance].securityOptionsHistory;
    NSSet *uniqueRecipients = [[self class] _uniqueRecipients:recipients];
    sender = [sender gpgNormalizedEmail];
    // Now we're good to go.
    BOOL canPGPSign = (signFlags & GPGMAIL_SIGN_FLAG_OPENPGP);
    BOOL canPGPEncrypt = (encryptFlags & GPGMAIL_ENCRYPT_FLAG_OPENPGP);
    BOOL canSMIMESign = (signFlags & GPGMAIL_SIGN_FLAG_SMIME);
    BOOL canSMIMEEncrypt = (encryptFlags & GPGMAIL_ENCRYPT_FLAG_SMIME);
    BOOL SMIMEKeyAvailable = canSMIMESign || canSMIMEEncrypt;
    BOOL PGPKeyAvailable = canPGPSign || canPGPEncrypt;
    
    
    // First, let's check if the user can do any of the things.
    // If not, no security method is set.
    if(!signFlags && !encryptFlags) {
        // No security method is not an option. Set to OpenPGP by default.
        return [GMSecurityOptions securityOptionsWithSecurityMethod:[[self class] defaultSecurityMethod] shouldSign:NO shouldEncrypt:NO];
    }
    
    // We have both, PGP key and S/MIME key. This is a bit tough. 
    if(SMIMEKeyAvailable && PGPKeyAvailable) {
        NSDictionary *signHistory = [usedSecurityMethods objectForKey:@"sign"];
        NSDictionary *signSMIMEHistory = [(NSDictionary *)[signHistory objectForKey:sender] objectForKey:@"SMIME"];
        NSDictionary *signPGPHistory = [(NSDictionary *)[signHistory objectForKey:sender] objectForKey:@"PGP"];
        NSDictionary *encryptHistory = [usedSecurityMethods objectForKey:@"encrypt"];
        NSDictionary *encryptSMIMEHistory = [(NSDictionary *)[encryptHistory objectForKey:uniqueRecipients] objectForKey:@"SMIME"];
        NSDictionary *encryptPGPHistory = [(NSDictionary *)[encryptHistory objectForKey:uniqueRecipients] objectForKey:@"PGP"];
        NSUInteger didSignSMIMECount = [[(NSDictionary *)[signSMIMEHistory objectForKey:uniqueRecipients] objectForKey:@"DidSignCount"] unsignedIntegerValue];
        NSUInteger didEncryptSMIMECount = [[encryptSMIMEHistory objectForKey:@"DidEncryptCount"] unsignedIntegerValue];
        NSUInteger didSignPGPCount = [[(NSDictionary *)[signPGPHistory objectForKey:uniqueRecipients] objectForKey:@"DidSignCount"] unsignedIntegerValue];
        NSUInteger didEncryptPGPCount = [[encryptPGPHistory objectForKey:@"DidEncryptCount"] unsignedIntegerValue];
        
        // If there's a encrypt history, there has to be a sign history,
        // because for any account that has either an S/MIME or PGP key we record
        // the status of any email.
        if(!encryptPGPHistory && !encryptSMIMEHistory)
            securityMethod = [[self class] defaultSecurityMethod];
        else if(encryptPGPHistory && !encryptSMIMEHistory)
            securityMethod = GPGMAIL_SECURITY_METHOD_OPENPGP;
        else if(encryptSMIMEHistory && !encryptPGPHistory)
            securityMethod = GPGMAIL_SECURITY_METHOD_SMIME;
        else {
            // There is an encrypt smime history and an encrypt pgp history,
            // now it's again tough.
            // Let's check first which was used to encrypt to the addresses more often.
            // Count is equal, check sign history.
            if(didEncryptPGPCount > didEncryptSMIMECount)
                securityMethod = GPGMAIL_SECURITY_METHOD_OPENPGP;
            else if(didEncryptSMIMECount > didEncryptPGPCount)
                securityMethod = GPGMAIL_SECURITY_METHOD_SMIME;
            else {
                if(didSignPGPCount >= didSignSMIMECount)
                    securityMethod = GPGMAIL_SECURITY_METHOD_OPENPGP;
                else {
                    securityMethod = GPGMAIL_SECURITY_METHOD_SMIME;
                }
            }
        }
        BOOL canSign = NO;
        BOOL canEncrypt = NO;
        if(securityMethod == GPGMAIL_SECURITY_METHOD_SMIME) {
            canSign = canSMIMESign;
            canEncrypt = canSMIMEEncrypt;
        }
        else if(securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
            canSign = canPGPSign;
            canEncrypt = canPGPEncrypt;
        }
        
        if(!securityMethod)
            securityMethod = [[self class] defaultSecurityMethod];
        
        // Now we've got the security method, and it's up to find out whether to
        // enable signing and encrypting for the key.
        return [self _getSignAndEncryptOptionsForSender:sender recipients:uniqueRecipients securityMethod:securityMethod canSign:canSign canEncrypt:canEncrypt];
    }
    // Next, check if signing from S/MIME is not possible. That automatically means
    // S/MIME can't encrypt either, due to implementation details of Apple's S/MIME.
    else {
        BOOL canEncrypt = NO;
        BOOL canSign = NO;
        if(!canSMIMESign && PGPKeyAvailable) {
            securityMethod = GPGMAIL_SECURITY_METHOD_OPENPGP;
            canEncrypt = canPGPEncrypt;
            canSign = canPGPSign;
        }
        else {
            securityMethod = GPGMAIL_SECURITY_METHOD_SMIME;
            canEncrypt = canSMIMEEncrypt;
            canSign = canSMIMESign;
        }
        return [self _getSignAndEncryptOptionsForSender:sender recipients:uniqueRecipients securityMethod:securityMethod canSign:canSign canEncrypt:canEncrypt];
    }
    
    return [GMSecurityOptions securityOptionsWithSecurityMethod:[[self class] defaultSecurityMethod] shouldSign:NO shouldEncrypt:NO];
}

- (GMSecurityOptions *)bestSecurityOptionsForSender:(NSString *)sender recipients:(NSArray *)recipients securityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod 
                                            canSign:(BOOL)canSign canEncrypt:(BOOL)canEncrypt {
    NSSet *uniqueRecipients = [[self class] _uniqueRecipients:recipients];
    return [self _getSignAndEncryptOptionsForSender:sender recipients:uniqueRecipients securityMethod:securityMethod canSign:canSign canEncrypt:canEncrypt];
}

- (GMSecurityOptions *)_getSignAndEncryptOptionsForSender:(NSString *)sender recipients:(NSSet *)recipients securityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod 
                                                                             canSign:(BOOL)canSign canEncrypt:(BOOL)canEncrypt {
    NSDictionary *usedSecurityMethods = [GMSecurityHistoryStore sharedInstance].securityOptionsHistory;
    NSString *securityMethodName = (securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) ? @"PGP" : @"SMIME"; 
    // First check if the method was already used to encrypt to these recipients. EncryptCount should be > 0 if
    // so. If the DidEncryptCount is equal to the DidNotEncrypt count check which was last used.
    // If only the last one would always be considered, this could make a wrong assumption if
    // it was only a one time thing.
    BOOL encrypt = canEncrypt;
    if(canEncrypt) {
        NSDictionary *encryptHistory = [(NSDictionary *)[(NSDictionary *)[usedSecurityMethods objectForKey:@"encrypt"] objectForKey:recipients] objectForKey:securityMethodName];
        NSUInteger didEncryptCount =  [[encryptHistory objectForKey:@"DidEncryptCount"] unsignedIntValue];
        NSUInteger didNotEncryptCount = [[encryptHistory objectForKey:@"DidNotEncryptCount"] unsignedIntValue];
        BOOL didLastEncrypt = [[encryptHistory objectForKey:@"DidLastEncrypt"] boolValue];
        if(didEncryptCount == didNotEncryptCount)
            encrypt = didLastEncrypt;
        else if(didEncryptCount > didNotEncryptCount)
            encrypt = YES;
        else {
            encrypt = NO;
        }
    }
    
    BOOL sign = canSign;
    if(canSign) {
        // Let's play the same game now for signing.
        // Signing is a little bit different though, since it might matter who you're sending to.
        // You might sign to some people but not to others, so if any addresses are given check
        // again how often you signed for those addresses or didn't.
        // If no addresses are given, simply check how often the key was used for signing, not signing
        // and what was last used.
        NSDictionary *signHistoryForRecipients = nil;
        NSDictionary *signHistory = nil;
        NSDictionary *signHistoryToUse = nil;
        
        signHistory = [(NSDictionary *)[(NSDictionary *)[usedSecurityMethods objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodName];
        if([recipients count])
            signHistoryForRecipients = [signHistory objectForKey:recipients];
        
        if(signHistoryForRecipients && signHistory)
            signHistoryToUse = signHistoryForRecipients;
        else
            signHistoryToUse = signHistory;
        
        NSUInteger didSignCount = [[signHistoryToUse objectForKey:@"DidSignCount"] unsignedIntValue]; 
        NSUInteger didNotSignCount = [[signHistoryToUse objectForKey:@"DidNotSignCount"] unsignedIntValue];
        BOOL didLastSign = [[signHistoryToUse objectForKey:@"DidLastSign"] boolValue];
        
        if(didSignCount == didNotSignCount)
            sign = didLastSign;
        else if(didSignCount > didNotSignCount)
            sign = YES;
        else {
            sign = NO;
        }
    }
    
    return [GMSecurityOptions securityOptionsWithSecurityMethod:securityMethod shouldSign:sign shouldEncrypt:encrypt];
}

- (GMSecurityOptions *)bestSecurityOptionsForReplyToMessage:(Message *)message signFlags:(GPGMAIL_SIGN_FLAG)signFlags 
                                               encryptFlags:(GPGMAIL_ENCRYPT_FLAG)encryptFlags {
    GPGMAIL_SECURITY_METHOD securityMethod = 0;
    BOOL canPGPSign = (signFlags & GPGMAIL_SIGN_FLAG_OPENPGP);
    BOOL canPGPEncrypt = (encryptFlags & GPGMAIL_ENCRYPT_FLAG_OPENPGP);
    BOOL canSMIMESign = (signFlags & GPGMAIL_SIGN_FLAG_SMIME);
    BOOL canSMIMEEncrypt = (encryptFlags & GPGMAIL_ENCRYPT_FLAG_SMIME);
    BOOL canSign = NO;
    BOOL canEncrypt = NO;
    
    if(message.isSMIMESigned) {
        securityMethod = GPGMAIL_SECURITY_METHOD_SMIME;
        canSign = canSMIMESign;
    }
    else if(message.PGPSigned) {
        securityMethod = GPGMAIL_SECURITY_METHOD_OPENPGP;
        canSign = canPGPSign;
    }
    
    if(message.isSMIMEEncrypted) {
        securityMethod = GPGMAIL_SECURITY_METHOD_SMIME;
        canEncrypt = canSMIMEEncrypt;
    }
    else if(message.PGPEncrypted) {
        securityMethod = GPGMAIL_SECURITY_METHOD_OPENPGP;
        canEncrypt = canPGPEncrypt;
    }
    if(!securityMethod)
        securityMethod = [[self class] defaultSecurityMethod];
    
    return [GMSecurityOptions securityOptionsWithSecurityMethod:securityMethod shouldSign:canSign shouldEncrypt:canEncrypt];
}

+ (NSSet *)_uniqueRecipients:(NSArray *)recipients {
    // Apparently mutable sets are not a good choice for NSDictionary lookups,
    // so let's make a non mutable first.
    NSMutableSet *uniqueRecipientsMutable = [[NSMutableSet alloc] init];
    for(NSString *address in recipients)
        [uniqueRecipientsMutable addObject:[address gpgNormalizedEmail]];
    NSSet *uniqueRecipients = [NSSet setWithSet:uniqueRecipientsMutable];
    [uniqueRecipientsMutable release];
    return uniqueRecipients;
}

+ (void)addEntryForSender:(NSString *)sender recipients:(NSArray *)recipients securityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod
                  didSign:(BOOL)didSign didEncrypt:(BOOL)didEncrypt {
    NSDictionary *securityMethodHistory = [[GMSecurityHistoryStore sharedInstance].securityOptionsHistory mutableCopy];
    NSString *securityMethodKey = securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? @"PGP" : @"SMIME";
    NSSet *uniqueRecipients = [[self class] _uniqueRecipients:recipients];
    sender = [sender gpgNormalizedEmail];
    if(!securityMethodHistory) {
        securityMethodHistory = [[NSMutableDictionary alloc] init];
    }
    // Building the dictionary for non existing keys.
    if(![securityMethodHistory objectForKey:@"sign"])
        [securityMethodHistory setValue:[NSMutableDictionary dictionary] forKey:@"sign"];
    if(![(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender])
        // No entry exists, initialize one.
        [[securityMethodHistory objectForKey:@"sign"] setValue:[NSMutableDictionary dictionary] forKey:sender];
    if(![(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey]) {
        [[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] setValue:[NSMutableDictionary dictionary] forKey:securityMethodKey];
        [[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"DidSignCount"];
        [[(NSMutableDictionary *)[(NSMutableDictionary *)(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"DidNotSignCount"];
    }
    // Now increase the existing one.
    // Out of frustration I gotta say this. I FUCKING HATE DICTIONARY SYNTAX IN OBJECTIVE-C! FUCKING! HATE! IT!
    NSString *countKey = didSign ? @"DidSignCount" : @"DidNotSignCount";
    NSUInteger count = [[[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] valueForKey:countKey] unsignedIntegerValue];
    count++;
    [[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] setValue:[NSNumber numberWithUnsignedInteger:count] forKey:countKey];
    [[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] setValue:[NSNumber numberWithBool:didSign] forKey:@"DidLastSign"];
    
    if(![(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] objectForKey:uniqueRecipients]) {
        // If there's not entry for sign from address to recipients, add it.
        [(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] setObject:[NSMutableDictionary dictionary] forKey:uniqueRecipients];
        [(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] objectForKey:uniqueRecipients] setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"DidSignCount"];
        [(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] objectForKey:uniqueRecipients] setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"DidNotSignCount"];
    }
    count = [[(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] objectForKey:uniqueRecipients] objectForKey:countKey] unsignedIntegerValue];
    count++;
    [(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] objectForKey:uniqueRecipients] setObject:[NSNumber numberWithUnsignedInteger:count] forKey:countKey];
    [(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"sign"] objectForKey:sender] objectForKey:securityMethodKey] objectForKey:uniqueRecipients] setObject:[NSNumber numberWithBool:didSign] forKey:@"DidLastSign"];
    
    if(![securityMethodHistory objectForKey:@"encrypt"])
        [securityMethodHistory setValue:[NSMutableDictionary dictionary] forKey:@"encrypt"];
    if(![(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients])
        [(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] setObject:[NSMutableDictionary dictionary] forKey:uniqueRecipients];
    if(![(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients] objectForKey:securityMethodKey]) {
        [(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients] setObject:[NSMutableDictionary dictionary] forKey:securityMethodKey]; 
        [[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients] objectForKey:securityMethodKey] setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"DidEncryptCount"];
        [[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients] objectForKey:securityMethodKey] setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"DidNotEncryptCount"];
    }
    
    countKey = didEncrypt ? @"DidEncryptCount" : @"DidNotEncryptCount";
    count = [[(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients] objectForKey:securityMethodKey] objectForKey:countKey] unsignedIntegerValue];
    count++;
    [(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients] objectForKey:securityMethodKey] setObject:[NSNumber numberWithUnsignedInteger:count] forKey:countKey];
    [(NSMutableDictionary *)[(NSMutableDictionary *)[(NSMutableDictionary *)[securityMethodHistory objectForKey:@"encrypt"] objectForKey:uniqueRecipients] objectForKey:securityMethodKey] setObject:[NSNumber numberWithBool:didEncrypt] forKey:@"DidLastEncrypt"];
    
    // Dang, this is some seriously fucking code. But if anyone knows how to do this
    // nice, please clean it up!
    DebugLog(@"Security Options History: %@", securityMethodHistory);
    
    [[GMSecurityHistoryStore sharedInstance] saveHistory:securityMethodHistory];
    
    [securityMethodHistory release];
}

@end

@implementation GMSecurityOptions

@synthesize securityMethod = _securityMethod, shouldSign = _shouldSign, shouldEncrypt = _shouldEncrypt;

- (id)initWithSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod shouldSign:(BOOL)shouldSign shouldEncrypt:(BOOL)shouldEncrypt {
    if(self = [super init]) {
        _securityMethod = securityMethod;
        _shouldSign = shouldSign;
        _shouldEncrypt = shouldEncrypt;
    }
    return self;
}

+ (GMSecurityOptions *)securityOptionsWithSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod shouldSign:(BOOL)shouldSign shouldEncrypt:(BOOL)shouldEncrypt {
    GMSecurityOptions *securityOptions = [[GMSecurityOptions alloc] initWithSecurityMethod:securityMethod shouldSign:shouldSign shouldEncrypt:shouldEncrypt];
    return [securityOptions autorelease];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Best Security options: {\n\tSecurity Method: %@\n\tShould Sign: %@\n\tShould Encrypt: %@\n}", 
            self.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? @"OpenPGP" : @"S/MIME",
            self.shouldSign ? @"YES" : @"NO", self.shouldEncrypt ? @"YES" : @"NO"];
}

@end

@interface GMSecurityHistoryStore ()

@property (nonatomic, retain) NSDictionary *securityOptionsHistory;

@end

@implementation GMSecurityHistoryStore

@synthesize securityOptionsHistory = _securityOptionsHistory;

+ (GMSecurityHistoryStore *)sharedInstance {
    static dispatch_once_t gmshs_once;
    static GMSecurityHistoryStore *_sharedInstance;
    dispatch_once(&gmshs_once, ^{
        _sharedInstance = [[GMSecurityHistoryStore alloc] initWithHistoryFile:GPGMAIL_SECURITY_OPTIONS_HISTORY_FILE];
    });
    return _sharedInstance;
}

- (id)initWithHistoryFile:(NSString *)historyFile {
    if(self = [super init]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *historyStoreDirectory = [[NSString stringWithString:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]] 
                                           stringByAppendingPathComponent:GPGMAIL_SECURITY_OPTIONS_HISTORY_DOMAIN];
        if(![fileManager fileExistsAtPath:historyStoreDirectory])
            [fileManager createDirectoryAtPath:historyStoreDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        
        NSString *historyStorePath = [historyStoreDirectory stringByAppendingPathComponent:historyFile];
        _storePath = [historyStorePath retain];
        [self openHistoryStoreAtPath:historyStorePath];
    }
    return self;
}

- (void)openHistoryStoreAtPath:(NSString *)historyFile {
    NSDictionary *root = [NSKeyedUnarchiver unarchiveObjectWithFile:historyFile];
    self.securityOptionsHistory = root;
}

- (void)saveHistory:(NSDictionary *)history {
    self.securityOptionsHistory = history;
    [NSKeyedArchiver archiveRootObject:self.securityOptionsHistory toFile:_storePath];
}

- (void)dealloc {
    [super dealloc];
    
    [_storePath release];
    [_securityOptionsHistory release];
}

@end

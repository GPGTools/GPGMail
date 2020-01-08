//
//  GMMessageSecurityParseResult.m
//  GPGMail
//
//  Created by Lukas Pitschl on 01.10.16.
//
//

#import "CCLog.h"

#import "NSObject+LPDynamicIvars.h"
#import "NSString+GPGMail.m"

#import "MCMessage.h"
#import "MimePart+GPGMail.h"
#import "Message+GPGMail.h"
#import "MCActivityMonitor.h"
#import "MimeBody+GPGMail.h"

#import "GMMessageSecurityFeatures.h"
#import "GMMessageProtectionStatus.h"

@interface GMMessageSecurityFeatures (MimePartNotImplemented)

- (id)decryptedMimeBody;
    
@end

@interface GMMessageSecurityFeatures ()

- (void)collectSecurityFeaturesStartingWithMimePart:(GM_CAST_CLASS(MimePart *, id))topPart;

@end


@implementation GMMessageSecurityFeatures

- (id)init {
    return [super init];
}

+ (GMMessageSecurityFeatures *)securityFeaturesFromMessageProtectionStatus:(GMMessageProtectionStatus *)messageProtectionStatus topLevelMimePart:(MCMimePart *)topLevelMimePart {
    GMMessageSecurityFeatures *securityFeatures = [self new];
    [securityFeatures collectSecurityFeaturesFromMessageProtectionStatus:messageProtectionStatus topLevelMimePart:topLevelMimePart];
    return securityFeatures;
}

+ (GMMessageSecurityFeatures *)securityFeaturesFromTopLevelMimePart:(MCMimePart *)topLevelMimePart {
    return [[self class] securityFeaturesFromMessageProtectionStatus:[(MimePart_GPGMail *)topLevelMimePart GMMessageProtectionStatus] topLevelMimePart:topLevelMimePart];
}

+ (GMMessageSecurityFeatures *)securityFeaturesFromMimeBody:(id)mimeBody {
    return [[self class] securityFeaturesFromTopLevelMimePart:[mimeBody topLevelPart]];
}

- (void)setPGPEncrypted:(BOOL)isPGPEncrypted {
    [self setIvar:@"PGPEncrypted" value:@(isPGPEncrypted)];
}

- (BOOL)PGPEncrypted {
    NSNumber *isPGPEncrypted = [self getIvar:@"PGPEncrypted"];
    
    return [isPGPEncrypted boolValue];
}

- (BOOL)PGPSigned {
    NSNumber *isPGPSigned = [self getIvar:@"PGPSigned"];
    
    return [isPGPSigned boolValue];
}

- (void)setPGPSigned:(BOOL)isPGPSigned {
    [self setIvar:@"PGPSigned" value:@(isPGPSigned)];
}

- (BOOL)PGPPartlyEncrypted {
    NSNumber *isPGPEncrypted = [self getIvar:@"PGPPartlyEncrypted"];
    return [isPGPEncrypted boolValue];
}


- (void)setPGPPartlyEncrypted:(BOOL)isPGPEncrypted {
    [self setIvar:@"PGPPartlyEncrypted" value:@(isPGPEncrypted)];
}

- (BOOL)PGPPartlySigned {
    NSNumber *isPGPSigned = [self getIvar:@"PGPPartlySigned"];
    return [isPGPSigned boolValue];
}

- (void)setPGPPartlySigned:(BOOL)isPGPSigned {
    [self setIvar:@"PGPPartlySigned" value:@(isPGPSigned)];
}

- (NSUInteger)numberOfPGPAttachments {
    return [[self getIvar:@"PGPNumberOfPGPAttachments"] integerValue];
}

- (void)setNumberOfPGPAttachments:(NSUInteger)nr {
    [self setIvar:@"PGPNumberOfPGPAttachments" value:@((NSUInteger)nr)];
}

- (void)setPGPSignatures:(NSArray *)signatures {
    [self setIvar:@"PGPSignatures" value:signatures];
}

- (NSArray *)PGPSignatures {
    return [self getIvar:@"PGPSignatures"];
}

- (void)setPGPErrors:(NSArray *)errors {
    [self setIvar:@"PGPErrors" value:errors];
}

- (NSArray *)PGPErrors {
    return [self getIvar:@"PGPErrors"];
}

- (void)setPGPAttachments:(NSArray *)attachments {
    [self setIvar:@"PGPAttachments" value:attachments];
}

- (NSArray *)PGPAttachments {
    return [self getIvar:@"PGPAttachments"];
}

- (NSArray *)PGPSignatureLabels {
    // TODO: Re-implement this properly. might not even have to be on securityfeatures.
    NSString *senderEmail = @"";//[[self valueForKey:@"_sender"] gpgNormalizedEmail];
    
    // Check if the signature in the message signers is a GPGSignature, if
    // so, copy the email addresses and return them.
    NSMutableArray *signerLabels = [NSMutableArray array];
    NSArray *messageSigners = [self PGPSignatures];
    for(GPGSignature *signature in messageSigners) {
        // Check with the key manager if an updated key is available for
        // this signature, since auto-key-retrieve might have changed it.
        GPGKey *newKey = [[GPGMailBundle sharedInstance] keyForFingerprint:signature.fingerprint];
		// Do not set the primary key of newKey as the signatures key!
        signature.key = newKey;
        NSString *email = signature.email;
        if(email) {
            // If the sender E-Mail != signature E-Mail, we display the sender E-Mail if possible.
            if (![[email gpgNormalizedEmail] isEqualToString:senderEmail]) {
                GPGKey *key = signature.key;
                for (GPGUserID *userID in key.userIDs) {
                    if ([[userID.email gpgNormalizedEmail] isEqualToString:senderEmail]) {
                        email = userID.email;
                        break;
                    }
                }
            }
        } else {
            // Check if name is available and use that.
            if([signature.name length])
                email = signature.name;
            else
                // For some reason a signature might not have an email set.
                // This happens if the public key is not available (not downloaded or imported
                // from the signature server yet). In that case, display the fingerprint.
                // Also, add an appropriate warning.
                email = [NSString stringWithFormat:@"0x%@", signature.fingerprint];
        }
        [signerLabels addObject:email];
    }
    
    return signerLabels;
}

- (BOOL)PGPInfoCollected {
    return [[self getIvar:@"PGPInfoCollected"] boolValue];
}

- (void)setPGPInfoCollected:(BOOL)infoCollected {
    [self setIvar:@"PGPInfoCollected" value:@(infoCollected)];
    // If infoCollected is set to NO, clear all associated info.
    if(!infoCollected)
        [self clearPGPInformation];
}

- (BOOL)PGPDecrypted {
    return [[self getIvar:@"PGPDecrypted"] boolValue];
}

- (void)setPGPDecrypted:(BOOL)isDecrypted {
    [self setIvar:@"PGPDecrypted" value:@(isDecrypted)];
}

- (BOOL)PGPVerified {
    return [[self getIvar:@"PGPVerified"] boolValue];
}

- (void)setPGPVerified:(BOOL)isVerified {
    [self setIvar:@"PGPVerified" value:@(isVerified)];
}

- (void)collectSecurityFeaturesFromMessageProtectionStatus:(GMMessageProtectionStatus *)messageProtectionStatus topLevelMimePart:(MCMimePart *)topLevelMimePart {
    BOOL isEncrypted = NO;
    BOOL isSigned = NO;
    BOOL isPartlyEncrypted = NO;
    BOOL isPartlySigned = NO;
    NSMutableArray *errors = [NSMutableArray array];
    NSMutableArray *signatures = [NSMutableArray array];
    NSMutableArray *pgpAttachments = [NSMutableArray array];
    
    //MCMimeBody *mimeBody = [topPart mimeBody];
    MCMimePart *decryptedMimePart = [(MimePart_GPGMail *)topLevelMimePart decryptedTopLevelMimePart];
    GMMessageProtectionStatus *decryptedMessageProtectionStatus = [(MimePart_GPGMail *)decryptedMimePart GMMessageProtectionStatus];

    isPartlySigned = messageProtectionStatus.partsOfMessageAreSigned;
    isPartlyEncrypted = messageProtectionStatus.partsOfMessageAreEncrypted;
    isEncrypted = messageProtectionStatus.completeMessageIsEncrypted || isPartlyEncrypted;
    isSigned = messageProtectionStatus.completeMessageIsSigned || isPartlySigned;

    // Bug #987: PGP/MIME encrypted and signed message are recognized as partially encrypted
    //           - signature not shown
    //
    // Even if a decrypted mime part is available (in case of a PGP/MIME message) it is
    // still possible that the encrypted message itself is signed. In which case
    // the signed status of the encrypted part and the decrypted part have to be taken
    // into consideration.
    if(decryptedMimePart) {
        isSigned = isSigned || decryptedMessageProtectionStatus.completeMessageIsSigned;
        // The encrypted part is fully signed, but it's still just a part of the entire
        // message.
        if(isPartlyEncrypted) {
            isPartlySigned = YES;
        }
    }

    NSArray *protectedParts = [messageProtectionStatus.encryptedParts arrayByAddingObjectsFromArray:messageProtectionStatus.signedParts];
    for(MimePart_GPGMail *protectedPart in protectedParts) {
        if(protectedPart.PGPError) {
            [errors addObject:protectedPart.PGPError];
        }
        if(protectedPart.PGPSigned) {
            if([protectedPart.PGPSignatures count]) {
                BOOL inSignatures = NO;
                for(GPGSignature *signature in signatures) {
                    if([[protectedPart.PGPSignatures[0] fingerprint] isEqualToString:[signature fingerprint]]) {
                        inSignatures = YES;
                    }
                }
                if(!inSignatures) {
                    [signatures addObject:protectedPart.PGPSignatures[0]];
                }
            }
        }
    }

    if(decryptedMimePart) {
        NSArray *decryptedProtectedParts = decryptedMessageProtectionStatus.signedParts;
        for(MimePart_GPGMail *protectedPart in decryptedProtectedParts) {
            if(protectedPart.PGPError) {
                [errors addObject:protectedPart.PGPError];
            }
            if(protectedPart.PGPSigned) {
                if([protectedPart.PGPSignatures count]) {
                    BOOL inSignatures = NO;
                    for(GPGSignature *signature in signatures) {
                        if([[protectedPart.PGPSignatures[0] fingerprint] isEqualToString:[signature fingerprint]]) {
                            inSignatures = YES;
                        }
                    }
                    if(!inSignatures) {
                        [signatures addObject:protectedPart.PGPSignatures[0]];
                    }
                }
            }
        }
    }

    [(MimePart_GPGMail *)topLevelMimePart enumerateSubpartsWithBlock:^(MCMimePart *currentPart) {
        MimePart_GPGMail *protectedPart = (MimePart_GPGMail *)currentPart;
        if(protectedPart.PGPAttachment) {
            [pgpAttachments addObject:protectedPart];
        }
    }];

    // This is a normal message, out of here, otherwise
    // this might break a lot of stuff.
    if(!isSigned && !isEncrypted && ![pgpAttachments count] && ![errors count])
        return;
    
    if([pgpAttachments count]) {
        self.numberOfPGPAttachments = [pgpAttachments count];
        self.PGPAttachments = pgpAttachments;
    }
    // Set the flags based on the parsed message.
    // Happened before in decrypt bla bla bla, now happens before decodig is finished.
    // Should work better.
    GMMessageSecurityFeatures *decryptedMimeBodySecurityFeatures = [(MimePart_GPGMail *)decryptedMimePart securityFeatures];
    
    self.PGPEncrypted = isEncrypted;
    self.PGPSigned = isSigned;
    self.PGPPartlyEncrypted = isPartlyEncrypted;
    self.PGPPartlySigned = isPartlySigned;
    self.PGPSignatures = signatures;
    self.PGPErrors = errors;

    // Only for test purpose, after the correct error to be displayed should be constructed.
    GM_CAST_CLASS(MFError *, id) error = nil;
    if([errors count])
        error = errors[0];
    else if([self.PGPAttachments count])
        error = [self errorSummaryForPGPAttachments:self.PGPAttachments];
    
    // Set the error on the activity monitor so the error banner is displayed
    // on above the message content.
    if(error) {
        [(MCActivityMonitor *)[GM_MAIL_CLASS(@"ActivityMonitor") currentMonitor] setError:error];
        // On Mavericks the ActivityMonitor trick doesn't seem to work, since the currentMonitor
        // doesn't necessarily have to belong to the current message.
        // So we store the mainError on the message and it's later used by the CertificateBannerController thingy.
        self.PGPMainError = error;
    }
    else {
        self.PGPMainError = nil;
    }
}

- (NSError *)errorSummaryForPGPAttachments:(NSArray *)attachments {
    NSUInteger verificationErrors = 0;
    NSUInteger decryptionErrors = 0;
    
    for(GM_CAST_CLASS(MimePart *, id) part in attachments) {
        if(![part PGPError])
            continue;
        
        if([[(NSError *)[part PGPError] userInfo] valueForKey:@"VerificationError"])
            verificationErrors++;
        else if([[(NSError *)[part PGPError] userInfo] valueForKey:@"DecryptionError"])
            decryptionErrors++;
    }
    
    if(!verificationErrors && !decryptionErrors)
        return nil;
    
    NSUInteger totalErrors = verificationErrors + decryptionErrors;
    
    NSString *title = nil;
    NSString *message = nil;
    // 1035 says decryption error, 1036 says verification error.
    // If both, use 1035.
    NSUInteger errorCode = 0;
    
    if(verificationErrors && decryptionErrors) {
        // @"%d Anhänge konnten nicht entschlüsselt oder verifiziert werden."
        title = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_DECRYPT_VERIFY_ERROR_TITLE");
        message = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_DECRYPT_VERIFY_ERROR_MESSAGE");
        errorCode = 1035;
    }
    else if(verificationErrors) {
        if(verificationErrors == 1) {
            title = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENT_VERIFY_ERROR_TITLE");
            message = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENT_VERIFY_ERROR_MESSAGE");
        }
        else {
            title = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_VERIFY_ERROR_TITLE");
            message = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_VERIFY_ERROR_MESSAGE");
        }
        errorCode = 1036;
    }
    else if(decryptionErrors) {
        if(decryptionErrors == 1) {
            title = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENT_DECRYPT_ERROR_TITLE");
            message = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENT_DECRYPT_ERROR_MESSAGE");
        }
        else {
            title = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_DECRYPT_ERROR_TITLE");
            message = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_DECRYPT_ERROR_MESSAGE");
        }
        errorCode = 1035;
    }
    
    title = [NSString stringWithFormat:title, totalErrors];
    
    // TODO: This works differently
    GM_CAST_CLASS(MFError *, id) error = nil;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    [userInfo setValue:title forKey:@"_MFShortDescription"];
    [userInfo setValue:message forKey:@"NSLocalizedDescription"];
    [userInfo setValue:@YES forKey:@"DecryptionError"];
    
    error = [GPGMailBundle errorWithCode:errorCode userInfo:userInfo];
    
    return error;
}

- (void)clearPGPInformation {
    self.PGPSignatures = nil;
    self.PGPEncrypted = NO;
    self.PGPPartlyEncrypted = NO;
    self.PGPSigned = NO;
    self.PGPPartlySigned = NO;
    self.PGPDecrypted = NO;
    self.PGPVerified = NO;
    self.PGPErrors = nil;
    self.PGPAttachments = nil;
    self.numberOfPGPAttachments = 0;
}


@end

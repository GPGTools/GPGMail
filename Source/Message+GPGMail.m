/* Message+GPGMail.m created by Lukas Pitschl (@lukele) on Thu 18-Aug-2011 */

/*
 * Copyright (c) 2000-2011, GPGTools Project Team <gpgtools-devel@lists.gpgtools.org>
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
 * THIS SOFTWARE IS PROVIDED BY THE GPGTools Project Team ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE GPGTools Project Team BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <objc/objc-runtime.h>
#import <Libmacgpg/Libmacgpg.h>
#import "NSObject+LPDynamicIvars.h"
#import "CCLog.h"
#import <MimePart.h>
#import <MimeBody.h>
#import "LibraryMessage.h"
#import <MessageStore.h>
#import <ActivityMonitor.h>
#import "MFError.h"
#import "MessageRouter.h"
#import "MimePart+GPGMail.h"
#import "Message+GPGMail.h"
#import "GPGMailBundle.h"
#import "NSString+GPGMail.h"
#import "GPGFlaggedString.h"

@implementation Message_GPGMail

- (void)fakeMessageFlagsIsEncrypted:(BOOL)isEncrypted isSigned:(BOOL)isSigned {
    unsigned int currentMessageFlags = [[self valueForKey:@"_messageFlags"] unsignedIntValue];
    
	if(isEncrypted)
        currentMessageFlags |= 0x00000008;
    if(isSigned)
        currentMessageFlags |= 0x00800000;
    
    [self setValue:[NSNumber numberWithUnsignedInt:currentMessageFlags] forKey:@"_messageFlags"];
}

- (BOOL)isSigned {
    return ([[self valueForKey:@"_messageFlags"] unsignedIntValue] & 0x00800000) || self.PGPSigned;
}

- (BOOL)isEncrypted {
    return ([[self valueForKey:@"_messageFlags"] unsignedIntValue] & 0x00000008) || self.PGPEncrypted;
}

- (BOOL)isSMIMESigned {
	return ([[self valueForKey:@"_messageFlags"] unsignedIntValue] & 0x00800000) && !self.PGPSigned;
}

- (BOOL)isSMIMEEncrypted {
	return ([[self valueForKey:@"_messageFlags"] unsignedIntValue] & 0x00000008) && !self.PGPEncrypted;
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
	NSString *senderEmail = [[self valueForKey:@"_sender"] gpgNormalizedEmail];
	
    // Check if the signature in the message signers is a GPGSignature, if
    // so, copy the email addresses and return them.
    NSMutableArray *signerLabels = [NSMutableArray array];
    NSArray *messageSigners = [self PGPSignatures];
    for(GPGSignature *signature in messageSigners) {
		// Check with the key manager if an updated key is available for
		// this signature, since auto-key-retrieve might have changed it.
		GPGKey *newKey = [[GPGMailBundle sharedInstance] keyForFingerprint:signature.fingerprint];
        signature.key = newKey.primaryKey;
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
                // from the signature server yet). In that case, display the user id.
                // Also, add an appropriate warning.
                email = [NSString stringWithFormat:@"0x%@", [signature.fingerprint shortKeyID]];
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

- (void)collectPGPInformationStartingWithMimePart:(GM_CAST_CLASS(MimePart *, id))topPart decryptedBody:(MimeBody *)decryptedBody {
    __block BOOL isEncrypted = NO;
    __block BOOL isSigned = NO;
    __block BOOL isPartlyEncrypted = NO;
    __block BOOL isPartlySigned = NO;
    NSMutableArray *errors = [NSMutableArray array];
    NSMutableArray *signatures = [NSMutableArray array];
    NSMutableArray *pgpAttachments = [NSMutableArray array];
    __block BOOL isDecrypted = NO;
    __block BOOL isVerified = NO;
    __block NSUInteger numberOfAttachments = 0;
    // If there's a decrypted message body, its top level part possibly holds information
    // about signatures and errors.
    // Theoretically it could contain encrypted inline data, signed inline data
    // and attachments, but for the time, that's out of scope.
    // This information is added to the message.
    //
    // If there's no decrypted message body, either the message contained
    // PGP inline data or failed to decrypt. In either case, the top part
    // passed in contains all the information.
    //MimePart *informationPart = decryptedBody == nil ? topPart : [decryptedBody topLevelPart];
    [topPart enumerateSubpartsWithBlock:^(GM_CAST_CLASS(MimePart *, id) currentPart) {
        // Only set the flags for non attachment parts to support
        // plain messages with encrypted/signed attachments.
        // Otherwise those would display as signed/encrypted as well.
		// application/pgp is a special case since Mail.app identifies it as an attachment, while its
		// truly a text/plain part (legacy pgp format)
        if([currentPart isAttachment] && ![currentPart isType:@"application" subtype:@"pgp"]) {
            if([currentPart PGPAttachment])
                [pgpAttachments addObject:currentPart];
        }
        else {
            isEncrypted |= [currentPart PGPEncrypted];
            isSigned |= [currentPart PGPSigned];
            isPartlySigned |= [currentPart PGPPartlySigned];
            isPartlyEncrypted |= [currentPart PGPPartlyEncrypted];
            if([currentPart PGPError])
                [errors addObject:[currentPart PGPError]];
            if([[currentPart PGPSignatures] count])
                [signatures addObjectsFromArray:[currentPart PGPSignatures]];
            isDecrypted |= [currentPart PGPDecrypted];
            // encrypted & signed & no error = verified.
            // not encrypted & signed & no error = verified.
            isVerified |= [currentPart PGPSigned];
        }
        
        // Count the number of attachments, but ignore signature.asc
        // and encrypted.asc files, since those are only PGP/MIME attachments
        // and not actual attachments.
        // We'll only see those attachments if the 
        if([currentPart isAttachment]) {
            if([currentPart isPGPMimeEncryptedAttachment] || [currentPart isPGPMimeSignatureAttachment])
                return;
            else {
                numberOfAttachments++;
            }
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
    Message *decryptedMessage = nil;
    if(decryptedBody)
        decryptedMessage = [decryptedBody message];
    self.PGPEncrypted = isEncrypted || [(Message_GPGMail *)decryptedMessage PGPEncrypted];
    self.PGPSigned = isSigned || [(Message_GPGMail *)decryptedMessage PGPSigned];
    self.PGPPartlyEncrypted = isPartlyEncrypted || [(Message_GPGMail *)decryptedMessage PGPPartlyEncrypted];
    self.PGPPartlySigned = isPartlySigned || [(Message_GPGMail *)decryptedMessage PGPPartlySigned];
    [signatures addObjectsFromArray:[(Message_GPGMail *)decryptedMessage PGPSignatures]];
    self.PGPSignatures = signatures;
    [errors addObjectsFromArray:[(Message_GPGMail *)decryptedMessage PGPErrors]];
    self.PGPErrors = errors;
    [pgpAttachments addObjectsFromArray:[(Message_GPGMail *)decryptedMessage PGPAttachments]];
    self.PGPDecrypted = isDecrypted;
    self.PGPVerified = isVerified;
    
    [self fakeMessageFlagsIsEncrypted:self.PGPEncrypted isSigned:self.PGPSigned];
    
	if(decryptedMessage) {
		[(Message_GPGMail *)decryptedMessage fakeMessageFlagsIsEncrypted:self.PGPEncrypted isSigned:self.PGPSigned];
	}
    
	// The problem is, Mail.app would correctly apply the rules, if we didn't
	// deactivate the snippet generation. But since we do, because it's kind of
	// a pain in the ass, it doesn't.
	// So we re-evaluate the message rules here and then they should be applied correctly.
	// ATTENTION: We have to make sure that the user actively selected this message,
	//			  otherwise, the body data is not yet available, and will 'cause the evaluation rules
	//			  to wreak havoc.
	if(!self.isSMIMEEncrypted && !self.isSMIMESigned)
		[self applyMatchingRulesIfNecessary];
		
    // Only for test purpose, after the correct error to be displayed should be constructed.
    GM_CAST_CLASS(MFError *, id) error = nil;
    if([errors count])
        error = errors[0];
    else if([self.PGPAttachments count])
        error = [self errorSummaryForPGPAttachments:self.PGPAttachments];
    
	// Set the error on the activity monitor so the error banner is displayed
	// on above the message content.
    if(error) {
        [(ActivityMonitor *)[GM_MAIL_CLASS(@"ActivityMonitor") currentMonitor] setError:error];
		// On Mavericks the ActivityMonitor trick doesn't seem to work, since the currentMonitor
		// doesn't necessarily have to belong to the current message.
		// So we store the mainError on the message and it's later used by the CertificateBannerController thingy.
		[self setIvar:@"PGPMainError" value:error];
	}

    DebugLog(@"%@ Decrypted Message [%@]:\n\tisEncrypted: %@, isSigned: %@,\n\tisPartlyEncrypted: %@, isPartlySigned: %@\n\tsignatures: %@\n\terrors: %@",
          decryptedMessage, [decryptedMessage subject], [(Message_GPGMail *)decryptedMessage PGPEncrypted] ? @"YES" : @"NO", [(Message_GPGMail *)decryptedMessage PGPSigned] ? @"YES" : @"NO",
          [(Message_GPGMail *)decryptedMessage PGPPartlyEncrypted] ? @"YES" : @"NO", [(Message_GPGMail *)decryptedMessage PGPPartlySigned] ? @"YES" : @"NO", [(Message_GPGMail *)decryptedMessage PGPSignatures], [(Message_GPGMail *)decryptedMessage PGPErrors]);
    
    DebugLog(@"%@ Message [%@]:\n\tisEncrypted: %@, isSigned: %@,\n\tisPartlyEncrypted: %@, isPartlySigned: %@\n\tsignatures: %@\n\terrors: %@\n\tattachments: %@",
          self, [self subject], self.PGPEncrypted ? @"YES" : @"NO", self.PGPSigned ? @"YES" : @"NO",
          self.PGPPartlyEncrypted ? @"YES" : @"NO", self.PGPPartlySigned ? @"YES" : @"NO", self.PGPSignatures, self.PGPErrors, self.PGPAttachments);
    
    // Fix the number of attachments, this time for real!
    // Uncomment once completely implemented.
    [[self dataSourceProxy] setNumberOfAttachments:(unsigned int)numberOfAttachments isSigned:self.isSigned isEncrypted:self.isEncrypted forMessage:self];
    if(decryptedMessage)
        [[(Message_GPGMail *)decryptedMessage dataSourceProxy] setNumberOfAttachments:(unsigned int)numberOfAttachments isSigned:self.isSigned isEncrypted:self.isEncrypted forMessage:decryptedMessage];
    // Set PGP Info collected so this information is not overwritten.
    self.PGPInfoCollected = YES;
}

- (void)applyMatchingRulesIfNecessary {
    // Disable this feature for the time being.
    // We have to find a better and more reliable way to implement this.
    return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
	if(![[self dataSourceProxy] respondsToSelector:@selector(routeMessages:isUserAction:)])
		return;
#pragma clang diagnostic pop

	if(!self.isEncrypted && !self.isSigned)
		return;
	
	// isEncrypted has to be re-evaluated again, since it might contain a signed message
	// but didn't have the key in cache, to correctly apply rules the first time around.
	[[GPGMailBundle sharedInstance] scheduleApplyingRulesForMessage:(Message *)self isEncrypted:self.PGPEncrypted];
}

- (MFError *)errorSummaryForPGPAttachments:(NSArray *)attachments {
    NSUInteger verificationErrors = 0;
    NSUInteger decryptionErrors = 0;
    
    for(GM_CAST_CLASS(MimePart *, id) part in attachments) {
        if(![part PGPError])
            continue;
        
        if([[(MFError *)[part PGPError] userInfo] valueForKey:@"VerificationError"])
            verificationErrors++;
        else if([[(MFError *)[part PGPError] userInfo] valueForKey:@"DecryptionError"])
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
            title = title = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENT_DECRYPT_ERROR_TITLE");
            message = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENT_DECRYPT_ERROR_MESSAGE");
        }
        else {
            title = title = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_DECRYPT_ERROR_TITLE");
            message = GMLocalizedString(@"MESSAGE_BANNER_PGP_ATTACHMENTS_DECRYPT_ERROR_MESSAGE");
        }
        errorCode = 1035;
    }
    
    title = [NSString stringWithFormat:title, totalErrors];
    
    GM_CAST_CLASS(MFError *, id) error = nil;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    [userInfo setValue:title forKey:@"_MFShortDescription"];
    [userInfo setValue:message forKey:@"NSLocalizedDescription"];
    [userInfo setValue:@YES forKey:@"DecryptionError"];
    // The error domain is checked in certain occasion, so let's use the system
    // dependent one.
    NSString *errorDomain = [GPGMailBundle isMavericks] ? @"MCMailErrorDomain" : @"MFMessageErrorDomain";
    
    error = [GM_MAIL_CLASS(@"MFError") errorWithDomain:errorDomain code:errorCode localizedDescription:nil title:title helpTag:nil
                            userInfo:userInfo];
    
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

- (BOOL)shouldBePGPProcessed {
    // Components are missing? What to do...
//    if([[GPGMailBundle sharedInstance] componentsMissing])
//        return NO;
    
    // OpenPGP is disabled for reading? Return false.
    if(![[GPGOptions sharedOptions] boolForKey:@"UseOpenPGPForReading"])
        return NO;
    
    // Message was actively selected by the user? PGP process message.
    if([self userDidActivelySelectMessageCheckingMessageOnly:YES])
        return YES;
    
    // If NeverCreatePreviewSnippets is set, return NO.
    if([[GPGOptions sharedOptions] boolForKey:@"NeverCreatePreviewSnippets"])
        return NO;
    
    // Message was not actively select and snippets should not be created?
    // Don't process the message and let's get on with it.
    return YES;
}

- (BOOL)userDidActivelySelectMessageCheckingMessageOnly:(BOOL)messageOnly {
	BOOL userDidSelectMessage = NO;
	// In some occasions this variable is not set, even though the user actively selected the message.
	// This issue has been seen with drafts. The reason seems to be, that the message object does
	// where the flag has been set, is not necessarily the same we're seeing in here.
	// As it turns out, while the message object is re-created, the messageBody object remains the same.
	// So let's check on the messageBody object as well.
	// Lesson learned: using messageBody forces the message body to be loaded.
	// Since we're only interested in the messageBody if it's already available, we use
	// messageBodyIfAvailable instead.
	// Another lesson learned: this leads to terrible problems, since the some body
	// methods, call shouldBePGPProcessed, which in turn calls this message again.
	// So in order to avoid a recursion, we don't check the body in all circumstances.
	// Update. Don't check the body, it still causes recursions sometimes.
	if([self getIvar:@"UserSelectedMessage"])
		userDidSelectMessage = [[self getIvar:@"UserSelectedMessage"] boolValue];
	
	return userDidSelectMessage;
}

- (BOOL)shouldCreateSnippetWithData:(NSData *)data {
    // CreatePreviewSnippets is set? Always return true.
    DebugLog(@"Create Preview snippets: %@", [[GPGOptions sharedOptions] boolForKey:@"CreatePreviewSnippets"] ? @"YES" : @"NO");
    DebugLog(@"User Selected Message: %@", [[self getIvar:@"UserSelectedMessage"] boolValue] ? @"YES" : @"NO");
	
	// Always *create snippet* (decrypt data) if the user actively selected the message.
	if([self userDidActivelySelectMessageCheckingMessageOnly:NO])
		return YES;
	
	// Since rule applying and snippet creation are connected, snippets are
	// created in classic view as well, but always only if the passphrase is in cache.
	// * none of the above and CreatePreviewSnippets preference is set -> create the snippet
	// * none of the above but passphrase for key is available (gpg-agent or keychain) -> create the snippet
	
	if([[GPGOptions sharedOptions] boolForKey:@"CreatePreviewSnippets"])
		return YES;
    
    // Otherwise check if the passphrase is already cached. If it is
    // return true, 'cause the user want be asked for the passphrase again.
    
    // The message could be encrypted to multiple subkeys.
    // All of the keys have to be in the cache.
    NSMutableSet *keyIDs = [[NSMutableSet alloc] initWithCapacity:0];
    
    NSArray *packets = nil;
    @try {
        packets = [GPGPacket packetsWithData:data];
    }
    @catch (NSException *exception) {
        return NO;
    }
    
	for (GPGPacket *packet in packets) {
		if (packet.tag == GPGPublicKeyEncryptedSessionKeyPacketTag) {
			GPGPublicKeyEncryptedSessionKeyPacket *keyPacket = (GPGPublicKeyEncryptedSessionKeyPacket *)packet;
			[keyIDs addObject:keyPacket.keyID];
		}
    }
    
	NSUInteger nrOfMatchingSecretKeys = 0;
	NSUInteger nrOfKeysWithPassphraseInCache = 0;
    GPGController *gpgc = [[GPGController alloc] init];
    
    for(NSString *keyID in keyIDs) {
        GPGKey *key = [[GPGMailBundle sharedInstance] secretGPGKeyForKeyID:keyID includeDisabled:YES];
        if(!key)
            continue;
		nrOfMatchingSecretKeys += 1;
		if([gpgc isPassphraseForKeyInCache:key]) {
			nrOfKeysWithPassphraseInCache += 1;
			DebugLog(@"Passphrase found in cache!");
        }
    }
    
	BOOL passphraseInCache = nrOfMatchingSecretKeys + nrOfKeysWithPassphraseInCache	!= 0 && nrOfMatchingSecretKeys == nrOfKeysWithPassphraseInCache ? YES : NO;
	
	DebugLog(@"Passphrase in cache? %@", passphraseInCache ? @"YES" : @"NO");
    
	return passphraseInCache;
}

#pragma mark - Proxies for OS X version differences.

- (id)dataSourceProxy {
    // 10.8 uses dataSource, 10.7 uses messageStore.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
    if([self respondsToSelector:@selector(dataSource)])
        return [self dataSource];
    if([self respondsToSelector:@selector(messageStore)])
       return [self messageStore];
#pragma clang diagnostic pop
    return nil;
}

- (void)MASetMessageInfo:(id)info subjectPrefixLength:(unsigned char)subjectPrefixLength to:(id)to sender:(id)sender type:(BOOL)type dateReceivedTimeIntervalSince1970:(double)receivedDate dateSentTimeIntervalSince1970:(double)sentDate messageIDHeaderDigest:(id)messageIDHeaderDigest inReplyToHeaderDigest:(id)headerDigest dateLastViewedTimeIntervalSince1970:(double)lastViewedDate {
	// Replace the GPGFlaggedString with an actual NSString, otherwise Drafts cannot be properly displayed
	// in some cases, since plist decoding doesn't work.
	NSString *newSender = sender;
	if([sender isKindOfClass:[GPGFlaggedString class]])
		newSender = [sender string];
	
	[self MASetMessageInfo:info subjectPrefixLength:subjectPrefixLength to:to sender:newSender type:type dateReceivedTimeIntervalSince1970:receivedDate dateSentTimeIntervalSince1970:sentDate messageIDHeaderDigest:messageIDHeaderDigest inReplyToHeaderDigest:headerDigest dateLastViewedTimeIntervalSince1970:lastViewedDate];
}

- (NSString *)gmDescription {
    
    return [NSString stringWithFormat:@"<%@: %p, library id:%lld conversationID:%lld mailbox:%@\n\t"
                                       "MIME encrypted: %@\n\t"
                                       "MIME signed: %@\n\t"
                                       "was decrypted successfully: %@\n\t"
                                       "was verified successfully: %@\n\t"
                                       "number of pgp attachments: %d\n\t"
                                       "number of signatures: %d\n\t"
                                       "pgp info collected: %@>",
                                        NSStringFromClass([self class]), self, (long long)[(id)self libraryID], (long long)[(id)self conversationID],
                                            [[(id)self mailbox] displayName],
            self.PGPEncrypted ? @"YES" : @"NO", self.PGPSigned ? @"YES" : @"NO",
            self.PGPDecrypted ? @"YES" : @"NO", self.PGPVerified ? @"YES" : @"NO",
            (unsigned int)[self.PGPAttachments count], (unsigned int)[self.PGPSignatures count],
            self.PGPInfoCollected ? @"YES" : @"NO"];
}

@end

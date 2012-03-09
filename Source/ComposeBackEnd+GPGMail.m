//
//  ComposeBackEnd+GPGMail.m
//  GPGMail
//
//  Created by Lukas Pitschl on 31.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <OutgoingMessage.h>
#import <_OutgoingMessageBody.h>
#import <MessageBody.h>
#import <MimeBody.h>
#import <MimePart.h>
#import <MessageWriter.h>
#import <NSString-EmailAddressString.h>
#import <NSString-NSStringUtils.h>
#import <MutableMessageHeaders.h>
#import <MailNotificationCenter.h>
#import <ComposeBackEnd.h>
#import "CCLog.h"
#import "NSObject+LPDynamicIvars.h"
#import "NSString+GPGMail.h"
#import "NSData+GPGMail.h"
#import "MimePart+GPGMail.h"
#import "Message+GPGMail.h"
#import "GPGFlaggedString.h"
#import "GMSecurityHistory.h"
#import "GPGMailBundle.h"
#import "HeadersEditor+GPGMail.h"
#import "MailDocumentEditor.h"
#import "MailDocumentEditor+GPGMail.h"
#import "ComposeBackEnd+GPGMail.h"
#import "ActivityMonitor.h"
#import <MFError.h>

@implementation ComposeBackEnd_GPGMail

- (void)MASetEncryptIfPossible:(BOOL)encryptIfPossible {
    if([self ivarExists:@"SetEncrypt"]) {
        encryptIfPossible = [[self getIvar:@"SetEncrypt"] boolValue];
    }
    
    // Force Encrypt contains the user choice.
    // It overrides SetEncrypt, which is checked when
    // displaying the correct image, so it has to
    // be reset, if ForceSign is set, otherwise the wrong
    // image could be shown.
    if([self ivarExists:@"ForceEncrypt"]) {
        encryptIfPossible = [[self getIvar:@"ForceEncrypt"] boolValue];
        [self setIvar:@"SetEncrypt" value:[NSNumber numberWithBool:encryptIfPossible]];
    }
    // If SetEncrypt and CanEncrypt don't match, use CanEncrypt,
    // since that's more important.
    if(![[self getIvar:@"EncryptIsPossible"] boolValue])
        encryptIfPossible = NO;
    
    [self setIvar:@"shouldEncrypt" value:[NSNumber numberWithBool:encryptIfPossible]];
    [self MASetEncryptIfPossible:encryptIfPossible];
    [(MailDocumentEditor_GPGMail *)[((ComposeBackEnd *)self) delegate] updateSecurityMethodHighlight];
}

- (void)MASetSignIfPossible:(BOOL)signIfPossible {
    if([self ivarExists:@"SetSign"]) {
        signIfPossible = [[self getIvar:@"SetSign"] boolValue];
    }

    // Force Sign contains the user choice.
    // It overrides SetSign, which is checked when
    // displaying the correct image, so it has to
    // be reset, if ForceSign is set, otherwise the wrong
    // image could be shown.
    if([self ivarExists:@"ForceSign"]) {
        signIfPossible = [[self getIvar:@"ForceSign"] boolValue];
        [self setIvar:@"SetSign" value:[NSNumber numberWithBool:signIfPossible]];
    }
    
    // If SetSign and CanSign don't match, use CanSign,
    // since that's more important.
    if(![[self getIvar:@"SignIsPossible"] boolValue])
        signIfPossible = NO;
    
    [self setIvar:@"shouldSign" value:[NSNumber numberWithBool:signIfPossible]];
    [self MASetSignIfPossible:signIfPossible];
    [(MailDocumentEditor_GPGMail *)[((ComposeBackEnd *)self) delegate] updateSecurityMethodHighlight];
}

- (id)MA_makeMessageWithContents:(WebComposeMessageContents *)contents isDraft:(BOOL)isDraft shouldSign:(BOOL)shouldSign shouldEncrypt:(BOOL)shouldEncrypt shouldSkipSignature:(BOOL)shouldSkipSignature shouldBePlainText:(BOOL)shouldBePlainText {
    GPGMAIL_SECURITY_METHOD securityMethod = self.guessedSecurityMethod;
    if(self.securityMethod)
        securityMethod = self.securityMethod;
    if(securityMethod == GPGMAIL_SECURITY_METHOD_SMIME) {
        id ret = [self MA_makeMessageWithContents:contents isDraft:isDraft shouldSign:shouldSign shouldEncrypt:shouldEncrypt shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];
        // If a message has been successfully created, add an entry to the security options history.
        if(ret && !isDraft) {
            [GMSecurityHistory addEntryForSender:((ComposeBackEnd *)self).sender recipients:[((ComposeBackEnd *)self) allRecipients] securityMethod:GPGMAIL_SECURITY_METHOD_SMIME didSign:shouldSign didEncrypt:shouldEncrypt];
        }
        return ret;
    }

    // The encryption part is a little tricky that's why
    // Mail.app is gonna do the heavy lifting with our GPG encryption method
    // instead of the S/MIME one.
    // After that's done, we only have to extract the encrypted part.
    BOOL shouldPGPEncrypt = NO;
    BOOL shouldPGPSign = NO;
    BOOL shouldPGPInlineSign = NO;
    BOOL shouldPGPInlineEncrypt = NO;
    // It might not be possible to inline encrypt drafts, since contents.text is nil.
    // Maybe it's not problem, and simply html should be used. (TODO: Figure that out.)
    BOOL shouldCreatePGPInlineMessage = [[GPGOptions sharedOptions] boolForKey:@"UseOpenPGPInlineToSend"] && !isDraft;
    if(securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
        shouldPGPEncrypt = shouldEncrypt;
        shouldPGPSign = shouldSign;
    }
    // If this message is to be saved as draft, shouldEncrypt and shouldSign is always false.
    // That's why GPGMail takes the values store by clicking on the signed and encrypt icons.
    if(isDraft && [[GPGOptions sharedOptions] boolForKey:@"OptionallyEncryptDrafts"]) {
        shouldPGPSign = [[self getIvar:@"shouldSign"] boolValue];
        shouldPGPEncrypt = [[self getIvar:@"shouldEncrypt"] boolValue];
    }
    // At the moment for drafts signing and encrypting is disabled.
    // GPG not enabled, or neither encrypt nor sign are checked, let's get the shit out of here.
    if(!shouldPGPEncrypt && !shouldPGPSign) {
        OutgoingMessage *outMessage = [self MA_makeMessageWithContents:contents isDraft:isDraft shouldSign:shouldSign shouldEncrypt:shouldEncrypt shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];
        return outMessage;
    }

    // Save the original headers.
    // If isDraft is set cleanHeaders are an NSDictionary they need to be a NSMutableDictionary
    // though, since Mail.app otherwise complains.
    // The isDraft flag is removed before calling the makeMessageWithContents method, otherwise
    // the encrypting and signing methods wouldn't be invoked.
    // Mail.app only wants NSMutableDictionary cleanHeaders if it's not a draft.
    // Since the isDraft flag is removed, Mail.app assumes it creates a normal message
    // to send out and therefore wants NSMutableDictionary clean headers.
    id copiedCleanHeaders = nil;
    copiedCleanHeaders = [[(ComposeBackEnd *)self cleanHeaders] mutableCopy];

    [self setIvar:@"originalCleanHeaders" value:copiedCleanHeaders];
    [copiedCleanHeaders release];
    // If isDraft is set the cleanHeaders are an NSDictionary instead of an NSMutableDictionary.
    // Using mutableCopy they are converted into an NSMutableDictionary.
    copiedCleanHeaders = [[(ComposeBackEnd *)self cleanHeaders] mutableCopy];
    [self setValue:copiedCleanHeaders forKey:@"_cleanHeaders"];
    [copiedCleanHeaders release];
    
    // Inject the headers needed in newEncryptedPart and newSignedPart.
    [self _addGPGFlaggedStringsToHeaders:[(ComposeBackEnd *)self cleanHeaders] forEncrypting:shouldPGPEncrypt forSigning:shouldPGPSign];

    // If the message is supposed to be encrypted or signed inline,
    // GPGMail does that directly in the Compose back end, and not use
    // the message write to create it, yet, to get an OutgoingMessage to work with.
    // Mail.app is instructed to create the Outgoing message with no encrypting and no
    // signing. 
    // After that the body is replaced by the pgp inline data.
    if(shouldCreatePGPInlineMessage) {
        shouldPGPInlineSign = shouldPGPSign;
        shouldPGPInlineEncrypt = shouldPGPEncrypt;
        shouldPGPSign = NO;
        shouldPGPEncrypt = NO;
    }
    
    // Drafts store the messages with a very minor set of headers and mime types
    // not suitable for encrypted/signed messages. But fortunately, Mail.app doesn't
    // have a problem if a normal message is stored as draft, so GPGMail just needs
    // to disable the isDraft parameter, Mail.app will take care of the rest.
    OutgoingMessage *outgoingMessage = [self MA_makeMessageWithContents:contents isDraft:NO shouldSign:shouldPGPSign shouldEncrypt:shouldPGPEncrypt shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];

	
    // If there was an error creating the outgoing message it's gonna be nil
    // and the error is stored away for later display.
    if(!outgoingMessage) {
		if (isDraft) {
			// Cancel saving to prevent the default error message.
			[self setIvar:@"cancelSaving" value:(id)kCFBooleanTrue];
			[(MailDocumentEditor *)[(ComposeBackEnd *)self delegate] setUserSavedMessage:NO];
			
			
			// Display "our" error message.
			NSBundle *messagesFramework = [NSBundle bundleWithIdentifier:@"com.apple.MessageFramework"];
			NSString *localizedDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"SMIME_CANT_SIGN_MESSAGE", @"Delayed", messagesFramework, @""), [((ComposeBackEnd *)self).sender gpgNormalizedEmail]];
			NSString *titleDescription = NSLocalizedStringFromTableInBundle(@"SMIME_CANT_SIGN_TITLE", @"Delayed", messagesFramework, @"");
			MFError *error = [MFError errorWithDomain:@"MFMessageErrorDomain" code:1036 localizedDescription:nil title:titleDescription
											  helpTag:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:localizedDescription,
																	@"NSLocalizedDescription", titleDescription, @"_MFShortDescription", nil]];

			[self performSelectorOnMainThread:@selector(didCancelMessageDeliveryForError:) withObject:error waitUntilDone:NO];
		}
        return nil;
	}

    // Fetch the encrypted data from the body data.
    NSData *encryptedData = [((_OutgoingMessageBody *)[outgoingMessage messageBody]) rawData];
	

	// Search for an errorCode in encryptedData:
	NSRange range = [encryptedData rangeOfData:[gpgErrorIdentifier dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [encryptedData length])];
	if (range.length > 0) {
		GPGErrorCode errorCode = 0;
		char *readPos = (char *)[encryptedData bytes];
		char *endPos = readPos + [encryptedData length];
		
		// Extract the errorCode.
		readPos += range.location + range.length;
		for (; readPos < endPos && *readPos <= '9' && *readPos >= '0'; readPos++) {
			errorCode = errorCode * 10 + *readPos - '0';
		}
		
		if (errorCode == GPGErrorCancelled) {
			if (isDraft) {
				// If the user cancel the signing, we cancel the saving and mark the message as unsaved.
				[self setIvar:@"cancelSaving" value:(id)kCFBooleanTrue];
				[(MailDocumentEditor *)[(ComposeBackEnd *)self delegate] setUserSavedMessage:NO];
			}
		}
		return nil;
	}

	
    // And restore the original headers.
    [(ComposeBackEnd *)self setValue:[self getIvar:@"originalCleanHeaders"] forKey:@"_cleanHeaders"];

    // Signing only results in an outgoing message which can be sent
    // out exactly as created by Mail.app. No need to further modify.
    // Only encrypted messages have to be adjusted.
    if(shouldPGPSign && !shouldPGPEncrypt && !shouldCreatePGPInlineMessage) {
        if(!isDraft)
            [GMSecurityHistory addEntryForSender:((ComposeBackEnd *)self).sender recipients:[((ComposeBackEnd *)self) allRecipients] securityMethod:GPGMAIL_SECURITY_METHOD_OPENPGP didSign:shouldPGPSign didEncrypt:shouldPGPEncrypt];
        return outgoingMessage;
    }


    Subdata *newBodyData = nil;
    
    if(!shouldCreatePGPInlineMessage) {
        // Check for preferences here, and set mime or plain version.
        newBodyData = [self _newPGPBodyDataWithEncryptedData:encryptedData headers:[outgoingMessage headers] shouldBeMIME:YES];
    }
    else {
        newBodyData = [self _newPGPInlineBodyDataWithData:[[contents.plainText string] dataUsingEncoding:NSUTF8StringEncoding] headers:[outgoingMessage headers] shouldSign:shouldPGPInlineSign shouldEncrypt:shouldPGPInlineEncrypt];
    }

    // AND NOW replace the current message body with the new gpg message body.
    // The subdata contains the range of the actual body excluding the headers
    // but references the entrie message (NSMutableData).
    [(_OutgoingMessageBody *)[outgoingMessage messageBody] setValue:newBodyData forKey:@"_rawData"];
    // _rawData instance variable has to hold the NSMutableData which
    // contains the data of the entire message including the header data.
    // Not sure why it's done this way, but HECK it works!
    [outgoingMessage setValue:[newBodyData valueForKey:@"_parentData"] forKey:@"_rawData"];
    [newBodyData release];
    
    if(!isDraft)
        [GMSecurityHistory addEntryForSender:((ComposeBackEnd *)self).sender recipients:[((ComposeBackEnd *)self) allRecipients] securityMethod:GPGMAIL_SECURITY_METHOD_OPENPGP didSign:shouldPGPSign didEncrypt:shouldPGPEncrypt];
    
    return outgoingMessage;
}


- (void)didCancelMessageDeliveryForError:(NSError *)error {
    [(MailDocumentEditor *)[(ComposeBackEnd *)self delegate] backEnd:self didCancelMessageDeliveryForEncryptionError:error];
}

- (void)_addGPGFlaggedStringsToHeaders:(NSMutableDictionary *)headers forEncrypting:(BOOL)forEncrypting forSigning:(BOOL)forSigning {
    // To decide whether S/MIME or PGP operations should be performed on
    // the message, different headers have to be flagged.
    //
    // For signing:
    // * flag the "from" value and set the GPGKey to use.
    //
    // For encrypting:
    // * temporarily add the flagged sender ("from") to the bcc recipients list,
    //   to encrypt for self, so each message can also be decrypted by the sender.
    //   (the "from" value is not inlucded in the recipients list passed to the encryption
    //    method)
    if(forSigning) {
		GPGFlaggedString *flaggedString = [[headers valueForKey:@"from"] flaggedStringWithFlag:@"recipientType" value:@"from"];
		GPGKey *key = [self getIvar:@"gpgKeyForSigning"];
		if (key) {
			[flaggedString setValue:key forFlag:@"gpgKey"];
		}
        [headers setObject:flaggedString forKey:@"from"];
    }
    if(forEncrypting) {
        // Save the original bcc recipients, to restore later.
        [self setIvar:@"originalBCCRecipients" value:[headers valueForKey:@"bcc"]];
        NSMutableArray *newBCCList = [NSMutableArray array];
        // Flag BCCs as bcc, so we can use hidden-recipient.
        NSArray *bccRecipients = [headers valueForKey:@"bcc"];
        for(NSString *bcc in bccRecipients)
            [newBCCList addObject:[bcc flaggedStringWithFlag:@"recipientType" value:@"bcc"]];

        [newBCCList addObject:[[headers valueForKey:@"from"] flaggedStringWithFlag:@"recipientType" value:@"from"]];
        [headers setValue:newBCCList forKey:@"bcc"];
    }
}

- (Subdata *)_newPGPBodyDataWithEncryptedData:(NSData *)encryptedData headers:(MutableMessageHeaders *)headers shouldBeMIME:(BOOL)shouldBeMIME {
    // Now on to creating a new body and replacing the old one.
    NSString *boundary = (NSString *)[MimeBody newMimeBoundary];
    NSData *topData;
    NSData *versionData;
    MimePart *topPart;
    MimePart *versionPart;
    MimePart *dataPart;
    if(!shouldBeMIME) {
        topPart = [[MimePart alloc] init];
        [topPart setType:@"text"];
        [topPart setSubtype:@"plain"];
        topPart.contentTransferEncoding = @"8bit";
        [topPart setBodyParameter:@"utf8" forKey:@"charset"];
        topData = encryptedData;
    }
    else {
        // 1. Create the top level part.
        topPart = [[MimePart alloc] init];
        [topPart setType:@"multipart"];
        [topPart setSubtype:@"encrypted"];
        [topPart setBodyParameter:@"application/pgp-encrypted" forKey:@"protocol"];
        // It's extremely important to set the boundaries for the parts
        // that need them, otherwise the body data will not be properly generated
        // by appendDataForMimePart.
        [topPart setBodyParameter:boundary forKey:@"boundary"];
        topPart.contentTransferEncoding = @"7bit";
        // 2. Create the first subpart - the version.
        versionPart = [[MimePart alloc] init];
        [versionPart setType:@"application"];
        [versionPart setSubtype:@"pgp-encrypted"];
        [versionPart setContentDescription:@"PGP/MIME Versions Identification"];
        versionPart.contentTransferEncoding = @"7bit";
        // 3. Create the pgp data subpart.
        dataPart = [[MimePart alloc] init];
        [dataPart setType:@"application"];
        [dataPart setSubtype:@"octet-stream"];
        [dataPart setBodyParameter:@"encrypted.asc" forKey:@"name"];
        dataPart.contentTransferEncoding = @"7bit";
        [dataPart setDisposition:@"inline"];
        [dataPart setDispositionParameter:@"encrypted.asc" forKey:@"filename"];
        [dataPart setContentDescription:@"OpenPGP encrypted message"];
        // 4. Append both parts to the top level part.
        [topPart addSubpart:versionPart];
        [topPart addSubpart:dataPart];

        // Again Mail.app will do the heavy lifting for us, only thing we need to do
        // is create a map of mime parts and body data.
        // The problem with that is, mime part can't be used a as a key with
        // a normal NSDictionary, since that wants to copy all keys.
        // So instad we use a CFDictionary which only retains keys.
        versionData = [@"Version: 1\r\n" dataUsingEncoding:NSASCIIStringEncoding];
        topData = [@"This is an OpenPGP/MIME encrypted message (RFC 2440 and 3156)" dataUsingEncoding:NSASCIIStringEncoding];
    }

    CFMutableDictionaryRef partBodyMapRef = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    CFDictionaryAddValue(partBodyMapRef, topPart, topData);
    if(shouldBeMIME) {
        CFDictionaryAddValue(partBodyMapRef, versionPart, versionData);
        CFDictionaryAddValue(partBodyMapRef, dataPart, encryptedData);
    }

    NSMutableDictionary *partBodyMap = (NSMutableDictionary *)partBodyMapRef;
    // The body is done, now on to updating the headers since we'll use the original headers
    // but have to change the top part headers.
    // And also add our own special GPGMail header.
    // Create the new top part headers.
    NSMutableData *contentTypeData = [[NSMutableData alloc] initWithLength:0];
    [contentTypeData appendData:[[NSString stringWithFormat:@"%@/%@;", [topPart type], [topPart subtype]] dataUsingEncoding:NSASCIIStringEncoding]];
    for(id key in [topPart bodyParameterKeys])
        [contentTypeData appendData:[[NSString stringWithFormat:@"\n\t%@=\"%@\";", key, [topPart bodyParameterForKey:key]] dataUsingEncoding:NSASCIIStringEncoding]];
    [headers setHeader:contentTypeData forKey:@"content-type"];
    [contentTypeData release];
    [headers setHeader:[GPGMailBundle agentHeader] forKey:@"x-pgp-agent"];
    [headers setHeader:@"7bit" forKey:@"content-transfer-encoding"];
    [headers removeHeaderForKey:@"content-disposition"];
    [headers removeHeaderForKey:@"from "];

	// Set the original bcc recipients.
    NSArray *originalBCCRecipients = (NSArray *)[self getIvar:@"originalBCCRecipients"];
    if([originalBCCRecipients count])
        [headers setHeader:originalBCCRecipients forKey:@"bcc"];
	else
        [headers removeHeaderForKey:@"bcc"];
    // Create the actualy body data.
    NSData *headerData = [headers encodedHeadersIncludingFromSpace:NO];
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    // First add the header data.
    [bodyData appendData:headerData];
    // Now the mime parts.
    MessageWriter *messageWriter = [[MessageWriter alloc] init];
    [messageWriter appendDataForMimePart:topPart toData:bodyData withPartData:partBodyMap];
    [messageWriter release];
    if(shouldBeMIME) {
        [versionPart release];
        [dataPart release];
    }
    [topPart release];
    CFRelease(partBodyMapRef);
    [boundary release];
    // Contains the range, which separates the mail headers
    // from the actual mime content.
    // JUST FOR INFO: messageDataIncludingFromSpace: returns an instance of NSMutableData, so basically
    // it might be the same as _rawData. But we don't need that, so, that's alright.
    NSRange contentRange = NSMakeRange([headerData length],
                                       ([bodyData length] - [headerData length]));
    Subdata *contentSubdata = [[Subdata alloc] initWithParent:bodyData range:contentRange];
    [bodyData release];
    return contentSubdata;
}

- (Subdata *)_newPGPInlineBodyDataWithData:(NSData *)data headers:(MutableMessageHeaders *)headers shouldSign:(BOOL)shouldSign shouldEncrypt:(BOOL)shouldEncrypt {
    if (!data)
        return nil;
    // Now on to creating a new body and replacing the old one. 
    NSString *boundary = (NSString *)[MimeBody newMimeBoundary];
    NSData *topData = nil;
    MimePart *topPart;
    
    NSData *signedData = data;
    NSData *encryptedData = nil;
    
    topPart = [[MimePart alloc] init];
    topPart.type = @"text";
    topPart.subtype = @"plain";
    topPart.contentTransferEncoding = @"8bit";
    [topPart setBodyParameter:@"utf8" forKey:@"charset"];
    
    if(shouldSign) {
        signedData = [topPart inlineSignedDataForData:data sender:[headers firstHeaderForKey:@"from"]];
        if (!signedData) {
            [boundary release];
            [topPart release];
            return nil;
        }
        topData = signedData;
    }

    id newlyEncryptedPart = nil;
    if(shouldEncrypt) {
        NSMutableArray *recipients = [[NSMutableArray alloc] init];
        [recipients addObjectsFromArray:[headers headersForKey:@"to"]];
        [recipients addObjectsFromArray:[headers headersForKey:@"cc"]];
        [recipients addObjectsFromArray:[headers headersForKey:@"bcc"]];
        newlyEncryptedPart = [topPart newEncryptedPartWithData:signedData recipients:recipients encryptedData:&encryptedData];
        [recipients release];
        topData = encryptedData;
    }

    if(!topData) {
        [boundary release];
        [topPart release];
        [newlyEncryptedPart release];
        return nil;
    }
    
    // The body is done, now on to updating the headers since we'll use the original headers
    // but have to change the top part headers.
    // And also add our own special GPGMail header.
    // Create the new top part headers.
    NSMutableData *contentTypeData = [[NSMutableData alloc] initWithLength:0];
    [contentTypeData appendData:[[NSString stringWithFormat:@"%@/%@;", [topPart type], [topPart subtype]] dataUsingEncoding:NSASCIIStringEncoding]];
    for(id key in [topPart bodyParameterKeys])
        [contentTypeData appendData:[[NSString stringWithFormat:@"\n\t%@=\"%@\";", key, [topPart bodyParameterForKey:key]] dataUsingEncoding:NSASCIIStringEncoding]];
    [headers setHeader:contentTypeData forKey:@"content-type"];
    [contentTypeData release];
    [headers setHeader:[GPGMailBundle agentHeader] forKey:@"x-pgp-agent"];
    [headers setHeader:topPart.contentTransferEncoding forKey:@"content-transfer-encoding"];
    [headers removeHeaderForKey:@"content-disposition"];
    [headers removeHeaderForKey:@"from "];	
	
	// Set the original bcc recipients.
    NSArray *originalBCCRecipients = (NSArray *)[self getIvar:@"originalBCCRecipients"];
    if([originalBCCRecipients count])
        [headers setHeader:originalBCCRecipients forKey:@"bcc"];
	else
        [headers removeHeaderForKey:@"bcc"];
    // Create the actualy body data.
    NSData *headerData = [headers encodedHeadersIncludingFromSpace:NO];
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    // First add the header data.
    [bodyData appendData:headerData];
    [bodyData appendData:topData];
    [topPart release];
    [boundary release];
    // Contains the range, which separates the mail headers
    // from the actual mime content.
    // JUST FOR INFO: messageDataIncludingFromSpace: returns an instance of NSMutableData, so basically
    // it might be the same as _rawData. But we don't need that, so, that's alright.
    NSRange contentRange = NSMakeRange([headerData length], 
                                       ([bodyData length] - [headerData length]));
    Subdata *contentSubdata = [[Subdata alloc] initWithParent:bodyData range:contentRange];
    [bodyData release];
    [newlyEncryptedPart release];
    return contentSubdata;
}

- (BOOL)MACanEncryptForRecipients:(NSArray *)recipients sender:(NSString *)sender {
    // Otherwise check the gpg keys.
    // Loop through all the addresses and check if we can encrypt for them.
    // If no recipients are set, encrypt is false.
    // For some reason, we're running into zombies if we don't do
    // this.
    [self retain];
    DebugLog(@"Recipients: %@", recipients);
    
    sender = [sender gpgNormalizedEmail];
    BOOL canSMIMEEncrypt = [self MACanEncryptForRecipients:recipients sender:sender];
    
    DebugLog(@"Can S/MIME encrypt to recipients: %@? %@", recipients, canSMIMEEncrypt ? @"YES" : @"NO");
    
    NSMutableArray *mutableRecipients = [[NSMutableArray alloc] initWithArray:recipients];
    NSMutableArray *nonEligibleRecipients = [NSMutableArray array];
    [mutableRecipients addObject:[sender gpgNormalizedEmail]];

    for(NSString *address in mutableRecipients) {
        if(![[GPGMailBundle sharedInstance] canEncryptMessagesToAddress:[address gpgNormalizedEmail]])
            [nonEligibleRecipients addObject:address];
    }
    BOOL canPGPEncrypt = [nonEligibleRecipients count] == 0 && [recipients count];
    
    DebugLog(@"Can PGP encrypt to recipients: %@? %@", mutableRecipients, canPGPEncrypt ? @"YES" : @"NO");
    
    BOOL canSMIMESign = [[self getIvar:@"CanSMIMESign"] boolValue];
    BOOL canPGPSign = [[self getIvar:@"CanPGPSign"] boolValue];
    
    GPGMAIL_SIGN_FLAG signFlags = 0;
    if(canPGPSign)
        signFlags |= GPGMAIL_SIGN_FLAG_OPENPGP;
    if(canSMIMESign)
        signFlags |= GPGMAIL_SIGN_FLAG_SMIME;
    
    GPGMAIL_ENCRYPT_FLAG encryptFlags = 0;
    if(canPGPEncrypt)
        encryptFlags |= GPGMAIL_ENCRYPT_FLAG_OPENPGP;
    if(canSMIMEEncrypt)
        encryptFlags |= GPGMAIL_ENCRYPT_FLAG_SMIME;
    
    // If a message is replied to which is S/MIME or PGP/MIME signed,
    // automatically set the appropriate security method.
    BOOL canEncrypt = NO;
    BOOL canSign = NO;
    
    GMSecurityHistory *securityHistory = [[GMSecurityHistory alloc] init];
    GMSecurityOptions *securityOptions = nil;
    
    if(!self.securityMethod) {
        if(self.messageIsBeingReplied) {
            Message *originalMessage = [((ComposeBackEnd *)self) originalMessage];
            securityOptions = [securityHistory bestSecurityOptionsForReplyToMessage:originalMessage signFlags:signFlags encryptFlags:encryptFlags];
        }
        else {
            securityOptions = [securityHistory bestSecurityOptionsForSender:sender recipients:recipients signFlags:signFlags encryptFlags:encryptFlags];
        }
        self.guessedSecurityMethod = securityOptions.securityMethod;
        
        if(self.guessedSecurityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
            canEncrypt = canPGPEncrypt;
            canSign = canPGPSign;
        }
        else {
            canEncrypt = canSMIMEEncrypt;
            canSign = canSMIMESign;
        }
        if(self.guessedSecurityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
            DebugLog(@"Security Method is OpenPGP");
            DebugLog(@"Can OpenPGP Encrypt: %@", canPGPEncrypt ? @"YES" : @"NO");
            DebugLog(@"Can OpenPGP Sign: %@", canPGPSign ? @"YES" : @"NO");
        }
        else if(self.guessedSecurityMethod == GPGMAIL_SECURITY_METHOD_SMIME) {
            DebugLog(@"Security Method is S/MIME");
            DebugLog(@"Can S/MIME Encrypt: %@", canSMIMEEncrypt ? @"YES" : @"NO");
            DebugLog(@"Can S/MIME Sign: %@", canSMIMESign ? @"YES" : @"NO");
        }
    }
    else {
        canEncrypt = self.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? canPGPEncrypt : canSMIMEEncrypt;
        canSign = self.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? canPGPSign : canSMIMESign;
        if(self.messageIsBeingReplied) {
            Message *originalMessage = [((ComposeBackEnd *)self) originalMessage];
            securityOptions = [securityHistory bestSecurityOptionsForReplyToMessage:originalMessage signFlags:signFlags encryptFlags:encryptFlags];
        }
        else {
            securityOptions = [securityHistory bestSecurityOptionsForSender:sender recipients:recipients securityMethod:self.securityMethod canSign:canSign canEncrypt:canEncrypt];
        }
    }
    
    [self setIvar:@"SetEncrypt" value:[NSNumber numberWithBool:securityOptions.shouldEncrypt]];
    [self setIvar:@"SetSign" value:[NSNumber numberWithBool:securityOptions.shouldSign]];
    [self setIvar:@"EncryptIsPossible" value:[NSNumber numberWithBool:canEncrypt]];
    [self setIvar:@"SignIsPossible" value:[NSNumber numberWithBool:canSign]];
    
    [securityHistory release];
    [mutableRecipients release];
    
    [self release];
    
    return canEncrypt;
}

- (BOOL)MACanSignFromAddress:(NSString *)address {
    // If the security method is not yet set and the back end was not yet initialized,
    // check S/MIME and PGP keychains to see if either method has a key
    // for signing.
    // For some reason, we're running into zombies if we don't do
    // this.
    [self retain];
    BOOL canSMIMESign = [self MACanSignFromAddress:address];
    
    DebugLog(@"Can sign S/MIME from address: %@? %@", address, canSMIMESign ? @"YES" : @"NO");
    
    BOOL canPGPSign = [[GPGMailBundle sharedInstance] canSignMessagesFromAddress:[address uncommentedAddress]];
    
    DebugLog(@"Can sign PGP from address: %@? %@", address, canPGPSign ? @"YES" : @"NO");
    
    // Now, here's a problem. If canSign returns NO, canEncrypt is no longer
    // checked, since for some reason S/MIME works like that, or maybe it's
    // only Apple's implementation.
    // So to avoid this, always return YES here if the security method is not already set.
    // The correct status is stored for later lookup in canEncrypt.
    [self setIvar:@"CanPGPSign" value:[NSNumber numberWithBool:canPGPSign]];
    [self setIvar:@"CanSMIMESign" value:[NSNumber numberWithBool:canSMIMESign]];
    [self release];
    return YES;
}

- (id)MARecipientsThatHaveNoKeyForEncryption {
    GPGMAIL_SECURITY_METHOD securityMethod = self.guessedSecurityMethod;
    if(self.securityMethod)
        securityMethod = self.securityMethod;
    
    if(securityMethod == GPGMAIL_SECURITY_METHOD_SMIME)
        return [self MARecipientsThatHaveNoKeyForEncryption];

    NSMutableArray *nonEligibleRecipients = [NSMutableArray array];
    for(NSString *recipient in [((ComposeBackEnd *)self) allRecipients]) {
        if(![[GPGMailBundle sharedInstance] canEncryptMessagesToAddress:[recipient uncommentedAddress]])
            [nonEligibleRecipients addObject:[recipient uncommentedAddress]];
    }

    return nonEligibleRecipients;
}

- (BOOL)wasInitialized {
    return [[self getIvar:@"WasInitialized"] boolValue];
}

- (void)setWasInitialized:(BOOL)wasInitialized {
    [self setIvar:@"WasInitialized" value:[NSNumber numberWithBool:wasInitialized]];
}

- (GPGMAIL_SECURITY_METHOD)securityMethod {
    return [[self getIvar:@"SecurityMethod"] unsignedIntValue];
}

- (void)setSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod {
    [self setIvar:@"SecurityMethod" value:[NSNumber numberWithUnsignedInt:securityMethod]];
    // Reset SetSign, SetEncrypt, SignIsPossible, EncryptIsPossible, shouldSign, shouldEncrypt.
    [self removeIvar:@"SetSign"];
    [self removeIvar:@"SetEncrypt"];
    [self removeIvar:@"SignIsPossible"];
    [self removeIvar:@"EncryptIsPossible"];
    [self removeIvar:@"shouldSign"];
    [self removeIvar:@"shouldEncrypt"];
    [self removeIvar:@"ForceEncrypt"];
    [self removeIvar:@"ForceSign"];
    
    // NEVER! automatically change the security method once the user selected it.
    // Only send the notification if security method is not reset to 0.
    // otherwise some serious shit happens.
    // Also only begin posting if the back end was initialized.
    if(securityMethod && self.wasInitialized/* && !self.userDidChooseSecurityMethod*/) {
        [(ComposeBackEnd *)self setHasChanges:YES];
        [self postSecurityMethodDidChangeNotification:(GPGMAIL_SECURITY_METHOD)securityMethod];
    }
}

- (void)setGuessedSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod {
    [self setIvar:@"GuessedSecurityMethod" value:[NSNumber numberWithUnsignedInteger:securityMethod]];
    [self removeIvar:@"SetSign"];
    [self removeIvar:@"SetEncrypt"];
    [self removeIvar:@"SignIsPossible"];
    [self removeIvar:@"EncryptIsPossible"];
    [self removeIvar:@"shouldSign"];
    [self removeIvar:@"shouldEncrypt"];
    [self removeIvar:@"ForceEncrypt"];
    [self removeIvar:@"ForceSign"];
}

- (GPGMAIL_SECURITY_METHOD)guessedSecurityMethod {
    return [[self getIvar:@"GuessedSecurityMethod"] unsignedIntegerValue];
}

- (BOOL)userDidChooseSecurityMethod {
    return [[self getIvar:@"UserDidChooseSecurityMethod"] boolValue];
}

- (void)setUserDidChooseSecurityMethod:(BOOL)userDidChoose {
    [self setIvar:@"UserDidChooseSecurityMethod" value:[NSNumber numberWithBool:userDidChoose]];
}

- (BOOL)messageIsBeingReplied {
    // 1 = Reply
    // 2 = Reply to all.
    // 4 = Restored Reply window.
    NSInteger type = [(ComposeBackEnd *)self type];
    return type == 1 || type == 2 || type == 4;
}

- (void)postSecurityMethodDidChangeNotification:(GPGMAIL_SECURITY_METHOD)securityMethod {
    if(!securityMethod)
        return;
    /* Post notification that the security method has changed. */
    NSNotification *notification = [NSNotification notificationWithName:@"SecurityMethodDidChangeNotification" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:securityMethod] forKey:@"SecurityMethod"]];
    [(MailNotificationCenter *)[NSClassFromString(@"MailNotificationCenter") defaultCenter] postNotification:notification];
}

- (BOOL)MA_saveThreadShouldCancel {
	if ([[self getIvar:@"cancelSaving"] boolValue]) {
		[self setIvar:@"cancelSaving" value:(id)kCFBooleanFalse];
		return YES;
	}
	return [self MA_saveThreadShouldCancel];
}

@end

/*
 Flags abfragen
 struct ComposeBackEndFlags flags;
 object_getInstanceVariable(self, "_flags", (void **)&flags);
*/

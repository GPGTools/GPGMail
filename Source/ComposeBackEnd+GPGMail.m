//
//  ComposeBackEnd+GPGMail.m
//  GPGMail
//
//  Created by Lukas Pitschl on 31.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "objc/runtime.h"
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
#import "MailAccount.h"
#import "MessageAttachment.h"
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
#import "NSData-MessageAdditions.h"
#define restrict
#import <RegexKit/RegexKit.h>

@implementation ComposeBackEnd_GPGMail

- (BOOL)setupSecurityPropertiesQueue {
	if(![self getIvar:@"GMSecurityPropertiesQueue"]) {
		GMDispatchQueueObject *securityPropertiesQueue = [[GMDispatchQueueObject alloc] initWithName:"org.gpgtools.GPGMail.securityPropertiesQueue" queueAttributes:DISPATCH_QUEUE_CONCURRENT];
		[self setIvar:@"GMSecurityPropertiesQueue" value:securityPropertiesQueue];
	}
	return YES;
}

- (dispatch_queue_t)securityPropertiesQueue {
	GMDispatchQueueObject *securityPropertiesQueue = [self getIvar:@"GMSecurityPropertiesQueue"];
	return securityPropertiesQueue.dispatchQueue;
}

- (id)MAInitCreatingDocumentEditor:(BOOL)createDocumentEditor {
    
    id ret = [self MAInitCreatingDocumentEditor:createDocumentEditor];
    
    /** On Yosemite, if Mail was invoked via AppleScript, this queue might already have been setup.
     */
    [ret setupSecurityPropertiesQueue];
    
    return ret;
}

- (void)MASetKnowsCanSign:(BOOL)knowsCanSign {
    // In Yosemite, this is reset if the sender changes,
    // so let's also reset GMKnowsCanSign.
    if(knowsCanSign == NO) {
        [self updateSecurityProperties:@{@"GMKnowsCanSign": @NO}];
    }
    
    [self MASetKnowsCanSign:knowsCanSign];
}

- (void)MASetEncryptIfPossible:(BOOL)encryptIfPossible {
    DebugLog(@"[Main thread: %@] - Set Encrypt: %@", [NSThread isMainThread] ? @"YES" : @"NO", encryptIfPossible ? @"YES" : @"NO");
    NSDictionary *securityProperties = self.securityProperties;
    if(securityProperties[@"SetEncrypt"]) {
        encryptIfPossible = [securityProperties[@"SetEncrypt"] boolValue];
    }
    
    // Force Encrypt contains the user choice.
    // It overrides SetEncrypt, which is checked when
    // displaying the correct image, so it has to
    // be reset, if ForceSign is set, otherwise the wrong
    // image could be shown.
    if(securityProperties[@"ForceEncrypt"]) {
        encryptIfPossible = [securityProperties[@"ForceEncrypt"] boolValue];
        [self updateSecurityProperties:@{@"SetEncrypt": @(encryptIfPossible)}];
    }
    // If SetEncrypt and CanEncrypt don't match, use CanEncrypt,
    // since that's more important.
    if(![securityProperties[@"EncryptIsPossible"] boolValue])
        encryptIfPossible = NO;
    
    [self updateSecurityProperties:@{@"shouldEncrypt": @(encryptIfPossible)}];
    
    [self MASetEncryptIfPossible:encryptIfPossible];
    [(MailDocumentEditor_GPGMail *)[((ComposeBackEnd *)self) delegate] updateSecurityMethodHighlight];
	
	HeadersEditor_GPGMail *headersEditor = ((MailDocumentEditor *)[((ComposeBackEnd *)self) delegate]).headersEditor;
	[headersEditor updateSymmetricButton];
}

- (BOOL)GMEncryptIfPossible {
	// On Yosemite or higher there's a property to read the encryptIfPossible flag.
	// otherwise, we have to access the _flags struct.
	BOOL encryptIfPossible = NO;
	if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
		encryptIfPossible = [[self valueForKey:@"_encryptIfPossible"] boolValue];
	}
	else {
		mailFlags backEndFlags;
		Ivar flags = class_getInstanceVariable([self class], "_flags");

		CFTypeRef cfSelf = CFBridgingRetain(self);
		backEndFlags = *(mailFlags *)((uint8_t *)cfSelf + ivar_getOffset(flags));
		encryptIfPossible = backEndFlags.encryptIfPossible;
		CFBridgingRelease(cfSelf);
	}

	return encryptIfPossible;
}

- (BOOL)GMSignIfPossible {
	// On Yosemite or higher there's a property to read the signIfPossible flag.
	// otherwise, we have to access the _flags struct.
	BOOL signIfPossible = NO;
	if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
		signIfPossible = [[self valueForKey:@"_signIfPossible"] boolValue];
	}
	else {
		mailFlags backEndFlags;
		Ivar flags = class_getInstanceVariable([self class], "_flags");

		CFTypeRef cfSelf = CFBridgingRetain(self);
		backEndFlags = *(mailFlags *)((uint8_t *)cfSelf + ivar_getOffset(flags));
		signIfPossible = backEndFlags.signIfPossible;
		CFBridgingRelease(cfSelf);
	}

	return signIfPossible;
}

- (void)MASetSignIfPossible:(BOOL)signIfPossible {
    NSDictionary *securityProperties = self.securityProperties;
    NSMutableDictionary *updatedSecurityProperties = [@{} mutableCopy];
    if(securityProperties[@"SetSign"]) {
        signIfPossible = [securityProperties[@"SetSign"] boolValue];
    }

    // Force Sign contains the user choice.
    // It overrides SetSign, which is checked when
    // displaying the correct image, so it has to
    // be reset, if ForceSign is set, otherwise the wrong
    // image could be shown.
    if(securityProperties[@"ForceSign"]) {
        signIfPossible = [securityProperties[@"ForceSign"] boolValue];
        updatedSecurityProperties[@"SetSign"] = @(signIfPossible);
    }
    
    // If SetSign and CanSign don't match, use CanSign,
    // since that's more important.
    if(![securityProperties[@"SignIsPossible"] boolValue])
        signIfPossible = NO;
    
    updatedSecurityProperties[@"shouldSign"] = @(signIfPossible);
    [self updateSecurityProperties:updatedSecurityProperties];
    [self MASetSignIfPossible:signIfPossible];
    [(MailDocumentEditor_GPGMail *)[((ComposeBackEnd *)self) delegate] updateSecurityMethodHighlight];
}

- (id)MASender {
	// If a message is to be redirected, the flagged from string,
	// which might have been set in -[ComposeBackEnd _makeMessageWithContents:isDraft:shouldSign:shouldEncrypt:shouldSkipSignature:shouldBePlainText:]
	// is replaced with this value, which of course is a simple string and
	// not a flagged value.
	// So in that case, they from header is checked and if it is
	// a flagged string it is returned instead of invoking the MASender
	// method.
	// This way the flagged from string makes it through to the newSignedPart method.
	
	// Not a resend? Out of here!
	if([(ComposeBackEnd *)self type] != 7)
		return [self MASender];
	
	// Fetch the from header from the clean headers to check
	// if this message should be pgp signed.
	NSDictionary *cleanHeaders = [(ComposeBackEnd *)self cleanHeaders];
	id sender = cleanHeaders[@"from"];
	// Not a GPGFlaggedString. Out of here!
	if(![sender respondsToSelector:@selector(setValue:forFlag:)])
		return [self MASender];
	
	// Now emulate what -[ComposeBackEnd sender] does internally.
	// At least part of it.
	MailAccount *account = [GM_MAIL_CLASS(@"MailAccount") accountContainingEmailAddress:sender];
	// Not sure what to do in this case, so let's fall back.
	if(!account)
		return [self MASender];
	// IF we're still in here, return the flagged sender.
	return sender;
}

- (id)MA_makeMessageWithContents:(WebComposeMessageContents *)contents isDraft:(BOOL)isDraft shouldSign:(BOOL)shouldSign shouldEncrypt:(BOOL)shouldEncrypt shouldSkipSignature:(BOOL)shouldSkipSignature shouldBePlainText:(BOOL)shouldBePlainText {
	GPGMAIL_SECURITY_METHOD securityMethod = self.guessedSecurityMethod;
    if(self.securityMethod)
        securityMethod = self.securityMethod;
    if(securityMethod != GPGMAIL_SECURITY_METHOD_OPENPGP) {
        id ret = [self MA_makeMessageWithContents:contents isDraft:isDraft shouldSign:shouldSign shouldEncrypt:shouldEncrypt shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];
        // If a message has been successfully created, add an entry to the security options history.
        if(ret && !isDraft) {
            [GMSecurityHistory addEntryForSender:((ComposeBackEnd *)self).sender recipients:[((ComposeBackEnd *)self) allRecipients] securityMethod:GPGMAIL_SECURITY_METHOD_SMIME didSign:shouldSign didEncrypt:shouldEncrypt];
        }
        return ret;
    }

    NSDictionary *securityProperties = self.securityProperties;
    // The encryption part is a little tricky that's why
    // Mail.app is gonna do the heavy lifting with our GPG encryption method
    // instead of the S/MIME one.
    // After that's done, we only have to extract the encrypted part.
    BOOL shouldPGPEncrypt = shouldEncrypt;
    BOOL shouldPGPSign = shouldSign;
	BOOL shouldPGPSymmetric = [securityProperties[@"shouldSymmetric"] boolValue];
    BOOL shouldPGPInlineSign = NO;
    BOOL shouldPGPInlineEncrypt = NO;
    BOOL shouldPGPInlineSymmetric = NO;
	
	// If this message is to be saved as draft, force encryption.
    if (isDraft && !shouldPGPEncrypt && [[GPGOptions sharedOptions] boolForKey:@"OptionallyEncryptDrafts"])
		shouldPGPEncrypt = YES;
	
    // It might not be possible to inline encrypt drafts, since contents.text is nil.
    // Maybe it's not problem, and simply html should be used. (TODO: Figure that out.)
    BOOL shouldCreatePGPInlineMessage = [[GPGOptions sharedOptions] boolForKey:@"UseOpenPGPInlineToSend"] && !isDraft;

    
	// If this message is a calendar event which is being sent from iCal without user interaction (ForceSign and ForceEncrypt are NOT set),
	// it should never be encrypted nor signed.
	if(!securityProperties[@"ForceSign"] && !securityProperties[@"ForceEncrypt"] &&
	   [self sentActionInvokedFromiCalWithContents:contents]) {
		shouldPGPEncrypt = NO;
		shouldPGPSign = NO;
		shouldSign = NO;
		shouldEncrypt = NO;
		shouldPGPSymmetric = NO;
	}
	
    // At the moment for drafts signing and encrypting is disabled.
    // GPG not enabled, or neither encrypt nor sign are checked, let's get the shit out of here.
    if(!shouldPGPEncrypt && !shouldPGPSign && !shouldPGPSymmetric) {
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
    // If isDraft is set the cleanHeaders are an NSDictionary instead of an NSMutableDictionary.
    // Using mutableCopy they are converted into an NSMutableDictionary.
    copiedCleanHeaders = [[(ComposeBackEnd *)self cleanHeaders] mutableCopy];
    [self setValue:copiedCleanHeaders forKey:@"_cleanHeaders"];
    
	// Inject the headers needed in newEncryptedPart and newSignedPart.
	[self _addGPGFlaggedStringsToHeaders:[(ComposeBackEnd *)self cleanHeaders] forEncrypting:shouldPGPEncrypt forSigning:shouldPGPSign forSymmetric:shouldPGPSymmetric isDraft:isDraft];

    // If the message is supposed to be encrypted or signed inline,
    // GPGMail does that directly in the Compose back end, and not use
    // the message write to create it, yet, to get an OutgoingMessage to work with.
    // Mail.app is instructed to create the Outgoing message with no encrypting and no
    // signing. 
    // After that the body is replaced by the pgp inline data.
    if(shouldCreatePGPInlineMessage) {
        shouldPGPInlineSign = shouldPGPSign;
        shouldPGPInlineEncrypt = shouldPGPEncrypt;
		shouldPGPInlineSymmetric = shouldPGPSymmetric;
        shouldPGPSign = NO;
        shouldPGPEncrypt = NO;
		shouldPGPSymmetric = NO;
    }
	
	NSMutableAttributedString *plainText = (NSMutableAttributedString *)contents.plainText;
	NSMutableString *plainString = [plainText mutableString];
	
	// If we are only signing and there isn't a newline at the end of the plaintext, append it.
	// We need this to prevent servers from doing this.
	if (shouldPGPSign && !shouldPGPEncrypt && !shouldPGPSymmetric) {
		if ([plainString characterAtIndex:plainString.length - 1] != '\n') {
			[plainString appendString:@"\n"];
		}
	}
	if (shouldPGPSign) {
		// Remove all whitespaces at the end of lines. But don't kill attachments.
		RKRegex *regex = [RKRegex regexWithRegexString:@"[\\t\\f\\r\\p{Z}]+$" options:RKCompileMultiline];
		RKEnumerator *rkEnum = [plainString matchEnumeratorWithRegex:regex];
		
		NSMutableArray *ranges = [NSMutableArray array];
		
		// Get all matches and reverse the order.
		for (NSArray *match in rkEnum) {
			[ranges insertObject:match[0] atIndex:0];
		}
		// Removed matched characters.
		for (NSValue *range in ranges) {
			[plainString replaceCharactersInRange:range.rangeValue withString:@""];
		}
	}
    
	// This is later checked, to determine the real isDraft value.
	[contents setIvar:@"IsDraft" value:@(isDraft)];
	[contents setIvar:@"ShouldEncrypt" value:@(shouldPGPEncrypt || shouldPGPInlineEncrypt)];
	[contents setIvar:@"ShouldSign" value:@(shouldPGPSign || shouldPGPInlineSign)];
	
    if(isDraft) {
        // If there's a public key available to encrypt the draft,
        // it's encrypted, otherwise we disable encryption.
        GPGKey *encryptDraftPublicKey = [[[(ComposeBackEnd *)self cleanHeaders] valueForKey:@"from"] valueForFlag:@"DraftPublicKey"];
        if(encryptDraftPublicKey) {
            // Drafts mustn't be signed, otherwise Mail creates duplicate zombie drafts again.
            shouldPGPSign = NO;
            shouldPGPSymmetric = NO;
            shouldPGPEncrypt = YES;
        }
        else {
            shouldPGPEncrypt = NO;
            shouldPGPSign = NO;
            shouldPGPSymmetric = NO;
        }
    }
	
	// Drafts store the messages with a very minor set of headers and mime types
    // not suitable for encrypted/signed messages. But fortunately, Mail.app doesn't
    // have a problem if a normal message is stored as draft, so GPGMail just needs
    // to disable the isDraft parameter, Mail.app will take care of the rest.
    OutgoingMessage *outgoingMessage = [self MA_makeMessageWithContents:contents isDraft:NO shouldSign:shouldPGPSign shouldEncrypt:shouldPGPEncrypt || shouldPGPSymmetric shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];
	
	// If there was an error creating the outgoing message it's gonna be nil
    // and the error is stored away for later display.
    if(!outgoingMessage) {
		if (isDraft) {
			// Cancel saving to prevent the default error message.
			[self setIvar:@"cancelSaving" value:(id)kCFBooleanTrue];
			[(MailDocumentEditor *)[(ComposeBackEnd *)self delegate] setUserSavedMessage:NO];
			
			// The error message should be set on the current activity monitor, so we
			// simply have to fetch it.
			GM_CAST_CLASS(MFError *, id) error = (MFError *)[(ActivityMonitor *)[GM_MAIL_CLASS(@"ActivityMonitor") currentMonitor] error];
			[self performSelectorOnMainThread:@selector(didCancelMessageDeliveryForError:) withObject:error waitUntilDone:NO];
		}
		// Restore the clean headers so BCC is removed as well.
		[(ComposeBackEnd *)self setValue:[self getIvar:@"originalCleanHeaders"] forKey:@"_cleanHeaders"];
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
		[(ComposeBackEnd *)self setValue:[self getIvar:@"originalCleanHeaders"] forKey:@"_cleanHeaders"];
		return nil;
	}
	
    // And restore the original headers.
    [(ComposeBackEnd *)self setValue:[self getIvar:@"originalCleanHeaders"] forKey:@"_cleanHeaders"];

	
	
	BOOL attachKeys = shouldPGPSign && [[GPGOptions sharedOptions] boolForKey:@"AttachKeyToOutgoingMessages"];
	NSData *keysToAttach = nil;

	if (!shouldCreatePGPInlineMessage && attachKeys) {
		// Get the signer key and export it, so we can attach it to the message.
		GPGKey *key = [self getIvar:@"gpgKeyForSigning"];
		if (key) {
			GPGController *gpgc = [[GPGController alloc] init];
			@try {
				gpgc.useArmor = YES;
				keysToAttach = [gpgc exportKeys:@[key] options:GPGExportMinimal];
			}
			@catch (NSException *exception) {
				GPGDebugLog(@"Exception during exporting keys: %@", exception);
			}
		}

	}
		
	
    // Signing only results in an outgoing message which can be sent
    // out exactly as created by Mail.app. No need to further modify.
    // Only encrypted messages have to be adjusted.
    if(shouldPGPSign && !shouldPGPEncrypt && !shouldPGPSymmetric && !shouldCreatePGPInlineMessage && keysToAttach.length == 0) {
        if(!isDraft)
            [GMSecurityHistory addEntryForSender:((ComposeBackEnd *)self).sender recipients:[((ComposeBackEnd *)self) allRecipients] securityMethod:GPGMAIL_SECURITY_METHOD_OPENPGP didSign:shouldPGPSign didEncrypt:shouldPGPEncrypt];
        return outgoingMessage;
    }

	
	
    Subdata *newBodyData = nil;
    
	// Check for preferences here, and set mime or plain version
    if(!shouldCreatePGPInlineMessage) {
		
		if (shouldPGPEncrypt || shouldPGPSymmetric) {
			newBodyData = [self _newPGPBodyDataWithEncryptedData:encryptedData headers:[outgoingMessage headers] shouldBeMIME:YES keysToAttach:keysToAttach];
		} else {
			newBodyData = [self _newPGPBodyDataWithOriginalData:encryptedData headers:[outgoingMessage headers] keysToAttach:keysToAttach];
		}
    } else {
        newBodyData = [self _newPGPInlineBodyDataWithData:[[contents.plainText string] dataUsingEncoding:NSUTF8StringEncoding] headers:[outgoingMessage headers] shouldSign:shouldPGPInlineSign shouldEncrypt:shouldPGPInlineEncrypt];
    }

	if (newBodyData) {
		// AND NOW replace the current message body with the new gpg message body.
		// The subdata contains the range of the actual body excluding the headers
		// but references the entrie message (NSMutableData).
		[(_OutgoingMessageBody *)[outgoingMessage messageBody] setValue:newBodyData forKey:@"_rawData"];
		// _rawData instance variable has to hold the NSMutableData which
		// contains the data of the entire message including the header data.
		// Not sure why it's done this way, but HECK it works!
		[outgoingMessage setValue:[newBodyData valueForKey:@"_parentData"] forKey:@"_rawData"];
	}
    
    if(!isDraft)
        [GMSecurityHistory addEntryForSender:((ComposeBackEnd *)self).sender recipients:[((ComposeBackEnd *)self) allRecipients] securityMethod:GPGMAIL_SECURITY_METHOD_OPENPGP didSign:shouldPGPSign didEncrypt:shouldPGPEncrypt];
    
    return outgoingMessage;
}

- (BOOL)sentActionInvokedFromiCalWithContents:(WebComposeMessageContents *)contents {
	if([contents.attachmentsAndHtmlStrings count] == 0)
		return NO;
	
	
	BOOL fromiCal = NO;
	for(id item in contents.attachmentsAndHtmlStrings) {
		if([item isKindOfClass:GM_MAIL_CLASS(@"MessageAttachment")]) {
			MessageAttachment *attachment = (MessageAttachment *)item;
			// For some non apparent reason, iCal invitations are not recognized by isCalendarInvitation anymore...
			// so let's check for text/calendar AND isCalendarInvitation.
			if(([[[attachment mimeType] lowercaseString] isEqualToString:@"text/calendar"] || attachment.isCalendarInvitation) &&
			   [[attachment filename] rangeOfString:@"iCal"].location != NSNotFound &&
			   [[attachment filename] rangeOfString:@".ics"].location != NSNotFound) {
				fromiCal = YES;
				break;
			}
		}
	}
	
	return fromiCal;
}


/**
 makeMessageWithContents:isDraft:shouldSign:shouldEncrypt:shouldSkipSignature:shouldBePlainText: sets the encrpyt and sign flags
 internal on the message write. For drafts however, these flags are not set, which leads to unencrypted, unsigned drafts.
 Our workaround forces drafts to be encrypted and/or signed by disabling the draft setting.
 The problem is, while that works for normal IMAP accounts, it doesn't for GMail, which creates a new message for each
 draft if "Store drafts on server" is activated.
 We hook into this message, to force the draft setting to be on for drafts, AFTER the encrypt and sign flags are set.
 This way, the messages remain actual drafts, and GMail is satisfied as well and behaves as it should.
 
 On Mavericks the method is called: newOutgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:
 On (Mountain)Lion the method is called: outgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:
 
 GMCodeInjector makes sure, that the correct method is overridden by our own.
 */
- (id)MAOutgoingMessageUsingWriter:(id)writer contents:(id)contents headers:(id)headers isDraft:(BOOL)isDraft shouldBePlainText:(BOOL)shouldBePlainText {
	if([contents ivarExists:@"IsDraft"])
		isDraft = [[contents getIvar:@"IsDraft"] boolValue];
	if([[contents getIvar:@"ShouldEncrypt"] boolValue] || [[contents getIvar:@"ShouldSign"] boolValue])
		[headers setHeader:[GPGMailBundle agentHeader] forKey:@"X-PGP-Agent"];
	if([contents ivarExists:@"IsDraft"] && isDraft) {
		[headers setHeader:@"com.apple.mail-draft" forKey:@"x-uniform-type-identifier"];
		// Mail doesn't pass in the sign status, when saving a draft, so we have to get it ourselves.
		// For encrypt we also use the state of the button, shouldEncrypt is overriden by our own
		// logic to always encrypt drafts if possible.
		BOOL shouldSign = NO;
		BOOL shouldEncrypt = NO;
		
        NSDictionary *securityProperties = self.securityProperties;
        
		if(securityProperties[@"ForceSign"])
			shouldSign = [securityProperties[@"ForceSign"] boolValue];
		else
			shouldSign = [securityProperties[@"shouldSign"] boolValue];
		
		if(securityProperties[@"ForceEncrypt"])
			shouldEncrypt = [securityProperties[@"ForceEncrypt"] boolValue];
		else
			shouldEncrypt = [securityProperties[@"shouldEncrypt"] boolValue];
		
		
		[headers setHeader:shouldEncrypt ? @"YES" : @"NO" forKey:@"x-should-pgp-encrypt"];
		[headers setHeader:shouldSign ? @"YES" : @"NO" forKey:@"x-should-pgp-sign"];
		
		// MailTags seems to duplicate our mail headers, if the message is to be encrypted.
		// This behaviour is worked around in [MCMessageGenerator _newDataForMimePart:withPartData:]
		// by removing the duplicate mail headers.
		// We should however only interfere, if a draft is being created, since this workaround might not be suitable
		// for every type of message.
		// In order for the MCMessageGenerator instance to know if a draft is being created,
		// we add a flag to it.
		[writer setIvar:@"IsDraft" value:@(YES)];
	}
	else {
		[headers removeHeaderForKey:@"x-should-pgp-encrypt"];
		[headers removeHeaderForKey:@"x-should-pgp-sign"];
		[headers removeHeaderForKey:@"x-uniform-type-identifier"];
		[headers removeHeaderForKey:@"x-apple-mail-plain-text-draft"];
	}
	return [self MAOutgoingMessageUsingWriter:writer contents:contents headers:headers isDraft:isDraft shouldBePlainText:shouldBePlainText];
}

- (void)didCancelMessageDeliveryForError:(NSError *)error {
    [(MailDocumentEditor *)[(ComposeBackEnd *)self delegate] backEnd:self didCancelMessageDeliveryForEncryptionError:error];
}

- (void)_addGPGFlaggedStringsToHeaders:(NSMutableDictionary *)headers forEncrypting:(BOOL)forEncrypting forSigning:(BOOL)forSigning forSymmetric:(BOOL)forSymmetric isDraft:(BOOL)isDraft {
	// To decide whether S/MIME or PGP operations should be performed on
	// the message, different headers have to be flagged.
	//
	// F̶o̶r̶ ̶s̶i̶g̶n̶i̶n̶g̶ Always:
	// * flag the "from" value with "gpgKey" = GPGKey.
	//
	// For encrypting:
	// * temporarily add the flagged sender ("recipientType" = "from") to the bcc recipients list,
	//   to encrypt for self, so each message can also be decrypted by the sender.
	//   (the "from" value is not inlucded in the recipients list passed to the encryption
	//    method)
	//   Also flag all bcc recipients with "recipientType" = "bcc".
	//
	// For symmetric:
	// * flag the "from" value with "symmetricEncrypt" = YES,
	//   if forEncrypting isn't set flag additionally with "doNotPublicEncrypt" = YES.
	//
	// Is draft:
	// * flag the "from" value with "isDraft" = YES.
	//

	
	GPGFlaggedString *flaggedString = [headers[@"from"] flaggedStringWithFlag:@"recipientType" value:@"from"];
	if (forSymmetric) {
		[flaggedString setValue:@YES forFlag:@"symmetricEncrypt"];
		if (!forEncrypting) {
			[flaggedString setValue:@YES forFlag:@"doNotPublicEncrypt"];
		}
	}
	GPGKey *key = [self getIvar:@"gpgKeyForSigning"];
	if (key) {
		[flaggedString setValue:key forFlag:@"gpgKey"];
	}

    if (isDraft) {
        [flaggedString setValue:@YES forFlag:@"isDraft"];
        // If this message is saved as draft, check if we have a gpg key which belongs to the
        // specified sender. If it's not available, try to find any secret key available.
        GPGKey *encryptDraftPublicKey = key.primaryKey;
        if(!encryptDraftPublicKey)
            encryptDraftPublicKey = [[GPGMailBundle sharedInstance] anyPersonalPublicKeyWithPreferenceAddress:[headers[@"from"] gpgNormalizedEmail]];
        // Store the appropriate public key to encrypt.
        if(encryptDraftPublicKey)
            [flaggedString setValue:encryptDraftPublicKey forFlag:@"DraftPublicKey"];
    }
	headers[@"from"] = flaggedString;
	
    if (forEncrypting) {
        // Save the original bcc recipients, to restore later.
        [self setIvar:@"originalBCCRecipients" value:[headers valueForKey:@"bcc"]];
        NSMutableArray *newBCCList = [NSMutableArray array];
        // Flag BCCs as bcc, so we can use hidden-recipient.
        NSArray *bccRecipients = [headers valueForKey:@"bcc"];
        for(NSString *bcc in bccRecipients)
            [newBCCList addObject:[bcc flaggedStringWithFlag:@"recipientType" value:@"bcc"]];

        [newBCCList addObject:flaggedString];
        [headers setValue:newBCCList forKey:@"bcc"];
    }
}

- (Subdata *)_newPGPBodyDataWithOriginalData:(NSData *)originalData headers:(MutableMessageHeaders *)headers keysToAttach:(NSData *)keysToAttach {
	
	if (keysToAttach.length == 0 || originalData.length < 100) {
		// If originalData's length < 100: No boundarys! (Should never happen)
		return nil;
	}
	

	// Find the MIME boundary.
	NSData *start = [NSData dataWithBytes:"\n--" length:3];
	NSData *end = [NSData dataWithBytes:"--\n" length:3];
	
	NSRange searchRange = NSMakeRange(originalData.length - 30, 30);
	NSRange endRange = [originalData rangeOfData:end options:NSDataSearchBackwards range:searchRange];
	if (endRange.length == 0) {
		return nil;
	}
	
	searchRange = NSMakeRange(endRange.location - 70, 70);
	NSRange startRange = [originalData rangeOfData:start options:NSDataSearchBackwards range:searchRange];
	if (startRange.length == 0) {
		return nil;
	}
	
	searchRange.location = startRange.location;
	searchRange.length = endRange.location + 3 - searchRange.location;
	
	NSData *bounddary = [originalData subdataWithRange:searchRange];
	
	
	// Build the message.
	NSData *headerData = [headers encodedHeadersIncludingFromSpace:NO];
	
	NSMutableData *mutableBodyData = [NSMutableData data];
	[mutableBodyData appendData:headerData];
	[mutableBodyData appendData:[originalData subdataWithRange:NSMakeRange(0, endRange.location)]];
	[mutableBodyData appendBytes:"\nContent-Transfer-Encoding: 7bit\nContent-Type: application/pgp-keys\n\n" length:69];
	[mutableBodyData appendData:keysToAttach];
	[mutableBodyData appendData:bounddary];
	
	
	NSRange contentRange = NSMakeRange(headerData.length, mutableBodyData.length - headerData.length);
	Subdata *contentSubdata = [[GM_MAIL_CLASS(@"Subdata") alloc] initWithParent:mutableBodyData range:contentRange];
	
	return contentSubdata;
	
}

- (Subdata *)_newPGPBodyDataWithEncryptedData:(NSData *)encryptedData headers:(MutableMessageHeaders *)headers shouldBeMIME:(BOOL)shouldBeMIME keysToAttach:(NSData *)keysToAttach {
    // Now on to creating a new body and replacing the old one.
    NSString *boundary = (NSString *)[GM_MAIL_CLASS(@"MimeBody") newMimeBoundary];
    NSData *topData;
    NSData *versionData;
    MimePart *topPart;
    MimePart *versionPart;
    MimePart *dataPart;
    MimePart *keysPart;
	
    Class MimePart = GM_MAIL_CLASS(@"MimePart");
    
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
        // 5. Append both parts to the top level part.
        [topPart addSubpart:versionPart];
        [topPart addSubpart:dataPart];
		
		
		// 6. Optionally attch the OpenPGP key(s).
		if (keysToAttach.length > 0) {
			keysPart = [[MimePart alloc] init];
			[keysPart setType:@"application"];
			[keysPart setSubtype:@"pgp-keys"];

			[topPart addSubpart:keysPart];
		}
		
		

        // Again Mail.app will do the heavy lifting for us, only thing we need to do
        // is create a map of mime parts and body data.
        // The problem with that is, mime part can't be used a as a key with
        // a normal NSDictionary, since that wants to copy all keys.
        // So instad we use a CFDictionary which only retains keys.
        versionData = [@"Version: 1\r\n" dataUsingEncoding:NSASCIIStringEncoding];
        topData = [@"This is an OpenPGP/MIME encrypted message (RFC 2440 and 3156)" dataUsingEncoding:NSASCIIStringEncoding];
    }

    CFMutableDictionaryRef partBodyMapRef = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
    CFDictionaryAddValue(partBodyMapRef, (__bridge const void *)(topPart), (__bridge const void *)(topData));
    if(shouldBeMIME) {
        CFDictionaryAddValue(partBodyMapRef, (__bridge const void *)(versionPart), (__bridge const void *)(versionData));
        CFDictionaryAddValue(partBodyMapRef, (__bridge const void *)(dataPart), (__bridge const void *)(encryptedData));
		if (keysToAttach.length > 0) CFDictionaryAddValue(partBodyMapRef, (__bridge const void *)(keysPart), (__bridge const void *)(keysToAttach));
    }

    NSMutableDictionary *partBodyMap = (__bridge NSMutableDictionary *)partBodyMapRef;
    // The body is done, now on to updating the headers since we'll use the original headers
    // but have to change the top part headers.
    // And also add our own special GPGMail header.
    // Create the new top part headers.
    NSMutableData *contentTypeData = [[NSMutableData alloc] initWithLength:0];
    [contentTypeData appendData:[[NSString stringWithFormat:@"%@/%@;", [topPart type], [topPart subtype]] dataUsingEncoding:NSASCIIStringEncoding]];
    for(id key in [topPart bodyParameterKeys])
        [contentTypeData appendData:[[NSString stringWithFormat:@"\n\t%@=\"%@\";", key, [topPart bodyParameterForKey:key]] dataUsingEncoding:NSASCIIStringEncoding]];
    [headers setHeader:contentTypeData forKey:@"content-type"];
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
    MessageWriter *messageWriter = [[GM_MAIL_CLASS(@"MessageWriter") alloc] init];
    [messageWriter appendDataForMimePart:topPart toData:bodyData withPartData:partBodyMap];
    CFRelease(partBodyMapRef);
    // Contains the range, which separates the mail headers
    // from the actual mime content.
    // JUST FOR INFO: messageDataIncludingFromSpace: returns an instance of NSMutableData, so basically
    // it might be the same as _rawData. But we don't need that, so, that's alright.
    NSRange contentRange = NSMakeRange([headerData length],
                                       ([bodyData length] - [headerData length]));
    Subdata *contentSubdata = [[GM_MAIL_CLASS(@"Subdata") alloc] initWithParent:bodyData range:contentRange];
    return contentSubdata;
}

- (Subdata *)_newPGPInlineBodyDataWithData:(NSData *)data headers:(MutableMessageHeaders *)headers shouldSign:(BOOL)shouldSign shouldEncrypt:(BOOL)shouldEncrypt {
    if (!data)
        return nil;
    // Now on to creating a new body and replacing the old one. 
    NSData *topData = nil;
    MimePart *topPart;
    
    NSData *signedData = data;
    NSData *encryptedData = nil;
    
	Class MimePart = [GPGMailBundle resolveMailClassFromName:@"MimePart"];
	
    topPart = [[MimePart alloc] init];
    [topPart setValue:@"text" forKey:@"type"];
    [topPart setSubtype:@"plain"];
    [topPart setContentTransferEncoding:@"8bit"];
    [topPart setBodyParameter:@"utf8" forKey:@"charset"];
    
    if(shouldSign) {
        signedData = [(MimePart_GPGMail *)topPart inlineSignedDataForData:data sender:[headers firstAddressForKey:@"from"]];
        if (!signedData) {
            return nil;
        }
        topData = signedData;
    }

    id newlyEncryptedPart = nil;
    if(shouldEncrypt) {
        NSMutableArray *recipients = [[NSMutableArray alloc] init];
        [recipients addObjectsFromArray:[headers addressListForKey:@"to"]];
        [recipients addObjectsFromArray:[headers addressListForKey:@"cc"]];
        [recipients addObjectsFromArray:[headers addressListForKey:@"bcc"]];
        newlyEncryptedPart = [topPart newEncryptedPartWithData:signedData recipients:recipients encryptedData:&encryptedData];
        topData = encryptedData;
    }

    if(!topData) {
        return nil;
    }
    
    // The body is done, now on to updating the headers since we'll use the original headers
    // but have to change the top part headers.
    // And also add our own special GPGMail header.
    // Create the new top part headers.
    NSMutableData *contentTypeData = [[NSMutableData alloc] initWithLength:0];
    NSString *topType = [topPart valueForKey:@"type"];
	NSString *topSubtype = [topPart valueForKey:@"subtype"];
	
	[contentTypeData appendData:[[NSString stringWithFormat:@"%@/%@;", topType, topSubtype] dataUsingEncoding:NSASCIIStringEncoding]];
    for(id key in [topPart bodyParameterKeys])
        [contentTypeData appendData:[[NSString stringWithFormat:@"\n\t%@=\"%@\";", key, [topPart bodyParameterForKey:key]] dataUsingEncoding:NSASCIIStringEncoding]];
    [headers setHeader:contentTypeData forKey:@"content-type"];
    [headers setHeader:[GPGMailBundle agentHeader] forKey:@"x-pgp-agent"];
    [headers setHeader:[topPart contentTransferEncoding] forKey:@"content-transfer-encoding"];
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
    // Contains the range, which separates the mail headers
    // from the actual mime content.
    // JUST FOR INFO: messageDataIncludingFromSpace: returns an instance of NSMutableData, so basically
    // it might be the same as _rawData. But we don't need that, so, that's alright.
    NSRange contentRange = NSMakeRange([headerData length], 
                                       ([bodyData length] - [headerData length]));
    Subdata *contentSubdata = [[GM_MAIL_CLASS(@"Subdata") alloc] initWithParent:bodyData range:contentRange];
    return contentSubdata;
}

- (BOOL)MACanEncryptForRecipients:(NSArray *)recipients sender:(NSString *)sender {
    // This method is never supposed to be called on the main thread,
	// so let's check for that.
    if([NSThread isMainThread])
		return NO;
	
    // To really fix #624 make sure the backEnd is alive till the end of this method.
	ComposeBackEnd_GPGMail *bself __attribute__((objc_precise_lifetime)) = self;
	
	if(![((ComposeBackEnd *)bself) delegate])
		return NO;
	
	DebugLog(@"Recipients: %@", recipients);
    
    BOOL canSMIMEEncrypt = [(ComposeBackEnd_GPGMail *)bself MACanEncryptForRecipients:recipients sender:sender];
    
	// S/MIME addresses are treated in a case sensitive manner, so the normalizing (uncommenting and lowercasing)
	// is only supposed to be done, AFTER the S/MIME canEncrypt check (#673)
	sender = [sender gpgNormalizedEmail];
    
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
    
    NSDictionary *securityProperties = self.securityProperties;
    BOOL canSMIMESign = [securityProperties[@"CanSMIMESign"] boolValue];
    BOOL canPGPSign = [securityProperties[@"CanPGPSign"] boolValue];
    
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
    
    if(!bself.securityMethod) {
        if(bself.messageIsBeingReplied) {
            Message *originalMessage = [((ComposeBackEnd *)bself) originalMessage];
            securityOptions = [securityHistory bestSecurityOptionsForReplyToMessage:originalMessage signFlags:signFlags encryptFlags:encryptFlags];
        }
		else if([bself draftIsContinued]) {
			Message *originalMessage = [((ComposeBackEnd *)bself) originalMessage];
			securityOptions = [securityHistory bestSecurityOptionsForMessageDraft:originalMessage signFlags:signFlags encryptFlags:encryptFlags];
		}
        else {
            securityOptions = [securityHistory bestSecurityOptionsForSender:sender recipients:recipients signFlags:signFlags encryptFlags:encryptFlags];
        }
        bself.guessedSecurityMethod = securityOptions.securityMethod;
        
        if(bself.guessedSecurityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
            canEncrypt = canPGPEncrypt;
            canSign = canPGPSign;
        }
        else {
            canEncrypt = canSMIMEEncrypt;
            canSign = canSMIMESign;
        }
        if(bself.guessedSecurityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
            DebugLog(@"Security Method is OpenPGP");
            DebugLog(@"Can OpenPGP Encrypt: %@", canPGPEncrypt ? @"YES" : @"NO");
            DebugLog(@"Can OpenPGP Sign: %@", canPGPSign ? @"YES" : @"NO");
        }
        else if(bself.guessedSecurityMethod == GPGMAIL_SECURITY_METHOD_SMIME) {
            DebugLog(@"Security Method is S/MIME");
            DebugLog(@"Can S/MIME Encrypt: %@", canSMIMEEncrypt ? @"YES" : @"NO");
            DebugLog(@"Can S/MIME Sign: %@", canSMIMESign ? @"YES" : @"NO");
        }
    }
    else {
        canEncrypt = bself.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? canPGPEncrypt : canSMIMEEncrypt;
        canSign = bself.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? canPGPSign : canSMIMESign;
        if(bself.messageIsBeingReplied) {
            Message *originalMessage = [((ComposeBackEnd *)bself) originalMessage];
            securityOptions = [securityHistory bestSecurityOptionsForReplyToMessage:originalMessage signFlags:signFlags encryptFlags:encryptFlags];
        }
        else {
            securityOptions = [securityHistory bestSecurityOptionsForSender:sender recipients:recipients securityMethod:bself.securityMethod canSign:canSign canEncrypt:canEncrypt];
        }
    }
    
    NSMutableDictionary *updatedSecurityProperties = [@{} mutableCopy];
    
    updatedSecurityProperties[@"SecurityOptions"] = securityOptions;
    // On Yosemite, there's a new method which is responsible for handling the correct
    // button state -[HeadersEditor setMessageIsToBeEncrypted:].
    // This method is called, after the check for canEncrypt is run.
    // Since canEncrypt checks the preferences the user has set, SetEncrypt
    // is set to Yes, if EncryptNewMessagesByDefault is enabled.
    // The problem is, in that case messageIsToBeEncrypted is also set
    // to true, even though the message can't be encrypted yet if no recipients
    // are set. Due to that wrong state, the buttons are later not properly
    // updated, when recipients are actually added and the test can be properly run.
    // So if no recipients are available, we simply don't set SetEncrypt and everything
    // should be fine. We might consider doing that on other OS X versions as well.
    if([recipients count] > 0 || (![recipients count] && ![GPGMailBundle isYosemite]))
        updatedSecurityProperties[@"SetEncrypt"] = @(securityOptions.shouldEncrypt);
    
    updatedSecurityProperties[@"SetSign"] = @(securityOptions.shouldSign);
    updatedSecurityProperties[@"EncryptIsPossible"] = @(canEncrypt);
    updatedSecurityProperties[@"SignIsPossible"] = @(canSign);
    
    if ([[GPGOptions sharedOptions] boolForKey:@"AllowSymmetricEncryption"]) {
        updatedSecurityProperties[@"SymmetricIsPossible"] = @([GPGMailBundle gpgMailWorks]);
    }

    [self updateSecurityProperties:updatedSecurityProperties];
    
    return canEncrypt;
}

- (BOOL)MACanSignFromAddress:(NSString *)address {
    // To really fix #624 make sure the backEnd is alive till the end of this method.
	ComposeBackEnd_GPGMail *bself __attribute__((objc_precise_lifetime)) = self;
	
	if(![((ComposeBackEnd *)bself) delegate])
		return NO;

	// If the security method is not yet set and the back end was not yet initialized,
    // check S/MIME and PGP keychains to see if either method has a key
    // for signing.
    // For some reason, we're running into zombies if we don't do
    // this.
    BOOL canSMIMESign = [bself MACanSignFromAddress:address];
    NSMutableDictionary *updatedSecurityProperties = [@{} mutableCopy];
    updatedSecurityProperties[@"CanSMIMESign"] = @(canSMIMESign);
    
    DebugLog(@"Can sign S/MIME from address: %@? %@", address, canSMIMESign ? @"YES" : @"NO");
    
    NSDictionary *securityProperties = self.securityProperties;
    BOOL canPGPSign = [[GPGMailBundle sharedInstance] canSignMessagesFromAddress:[address gpgNormalizedEmail]];
    updatedSecurityProperties[@"CanPGPSign"] = @(canPGPSign);
    updatedSecurityProperties[@"GMKnowsCanSign"] = @(YES);
    
    [self updateSecurityProperties:updatedSecurityProperties];
    
    DebugLog(@"Can sign PGP from address: %@? %@", address, canPGPSign ? @"YES" : @"NO");
    
    // Now, here's a problem. If canSign returns NO, canEncrypt is no longer
    // checked, since for some reason S/MIME works like that, or maybe it's
    // only Apple's implementation.
    // So to avoid this, always return YES here if the security method is not already set.
    // The correct status is stored for later lookup in canEncrypt.
    return YES;
}

- (id)MARecipientsThatHaveNoKeyForEncryption {
    if(![((ComposeBackEnd *)self) delegate])
		return [NSArray array];
	
	GPGMAIL_SECURITY_METHOD securityMethod = self.guessedSecurityMethod;
    if(self.securityMethod)
        securityMethod = self.securityMethod;
    
    if(securityMethod == GPGMAIL_SECURITY_METHOD_SMIME)
        return [self MARecipientsThatHaveNoKeyForEncryption];

    NSMutableArray *nonEligibleRecipients = [NSMutableArray array];
    for(NSString *recipient in [((ComposeBackEnd *)self) allRecipients]) {
        if(![[GPGMailBundle sharedInstance] canEncryptMessagesToAddress:[recipient gpgNormalizedEmail]])
            [nonEligibleRecipients addObject:[recipient gpgNormalizedEmail]];
    }

    return nonEligibleRecipients;
}

- (NSDictionary *)securityProperties {
    __block NSDictionary *_securityProperties = nil;
    dispatch_queue_t securityPropertiesQueue = [self securityPropertiesQueue];

    ComposeBackEnd_GPGMail __weak *weakSelf = self;
    dispatch_sync(securityPropertiesQueue, ^{
        ComposeBackEnd_GPGMail __strong *strongSelf = weakSelf;
        if(![strongSelf ivarExists:@"GMSecurityProperties"])
            [strongSelf setIvar:@"GMSecurityProperties" value:[NSMutableDictionary new]];
        
        _securityProperties = [strongSelf getIvar:@"GMSecurityProperties"];
    });
    return _securityProperties;
}

- (void)updateSecurityProperties:(NSDictionary *)updates {
	// We create our own copy of the securityProperties,
	// since it's very much possible that they'll be overwritten with new
	// ones,
    NSMutableDictionary *securityProperties = [self.securityProperties mutableCopy];
	
    NSMutableDictionary *propertiesToUpdate = [@{} mutableCopy];
    
    for(id key in updates) {
        if([updates[key] isKindOfClass:[NSNull class]])
            [securityProperties removeObjectForKey:key];
        else
            propertiesToUpdate[key] = updates[key];
    }
    
    [securityProperties addEntriesFromDictionary:propertiesToUpdate];
    self.securityProperties = securityProperties;
}

- (void)setSecurityProperties:(NSDictionary *)securityProperties {
    dispatch_queue_t securityPropertiesQueue = [self securityPropertiesQueue];

	ComposeBackEnd_GPGMail __weak *weakSelf = self;
    dispatch_barrier_async(securityPropertiesQueue, ^{
        ComposeBackEnd_GPGMail __strong *strongSelf = weakSelf;
        [strongSelf setIvar:@"GMSecurityProperties" value:securityProperties];
    });
}

- (BOOL)wasInitialized {
    return [[self getIvar:@"WasInitialized"] boolValue];
}

- (void)setWasInitialized:(BOOL)wasInitialized {
    [self setIvar:@"WasInitialized" value:@(wasInitialized)];
}

- (GPGMAIL_SECURITY_METHOD)securityMethod {
    return [self.securityProperties[@"SecurityMethod"] unsignedIntValue];
}

- (void)setSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod {
    // Reset SetSign, SetEncrypt, SignIsPossible, EncryptIsPossible, shouldSign, shouldEncrypt.
    [self updateSecurityProperties:@{@"SecurityMethod": @((unsigned int)securityMethod),
                                     @"SetSign": [NSNull null],
                                     @"SetEncrypt": [NSNull null],
                                     @"SignIsPossible": [NSNull null],
                                     @"EncryptIsPossible": [NSNull null],
                                     @"shouldSign": [NSNull null],
                                     @"shouldEncrypt": [NSNull null],
                                     @"shouldSymmetric": [NSNull null]}];

    // Don't reset ForceEncrypt and ForceSign. User preference has to stick. ALWAYS!
    
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
    [self updateSecurityProperties:@{@"GuessedSecurityMethod": @((unsigned int)securityMethod),
                                     @"SetSign": [NSNull null],
                                     @"SetEncrypt": [NSNull null],
                                     @"SignIsPossible": [NSNull null],
                                     @"EncryptIsPossible": [NSNull null],
                                     @"shouldSign": [NSNull null],
                                     @"shouldEncrypt": [NSNull null],
                                     @"shouldSymmetric": [NSNull null]}];
	
	// Don't reset ForceEncrypt and ForceSign. User preference has to stick. ALWAYS!
}

- (GPGMAIL_SECURITY_METHOD)guessedSecurityMethod {
    return (GPGMAIL_SECURITY_METHOD)[self.securityProperties[@"GuessedSecurityMethod"] unsignedIntegerValue];
}

- (BOOL)userDidChooseSecurityMethod {
    return [[self getIvar:@"UserDidChooseSecurityMethod"] boolValue];
}

- (void)setUserDidChooseSecurityMethod:(BOOL)userDidChoose {
    [self setIvar:@"UserDidChooseSecurityMethod" value:@(userDidChoose)];
}

- (void)MA_configureLastDraftInformationFromHeaders:(id)headers overwrite:(BOOL)overwrite {
	BOOL draftIsContinued = [headers firstHeaderForKey:@"x-should-pgp-sign"] != nil || [headers firstHeaderForKey:@"x-should-pgp-encrypt"] != nil;
	[self setIvar:@"DraftIsContinued" value:@(draftIsContinued)];
	// If the "Send again" method is used, this method is called as well, even though it's not a draft.
	// To really figure out if this is a draft or not, we're going to check for our own,
	// is draft headers.
	
	[self MA_configureLastDraftInformationFromHeaders:headers overwrite:overwrite];
}

- (BOOL)messageIsBeingReplied {
    // 1 = Reply
    // 2 = Reply to all.
    // 4 = Restored Reply window.
    NSInteger type = [(ComposeBackEnd *)self type];
    return (type == 1 || type == 2 || type == 4) && ![self draftIsContinued];
}

- (BOOL)draftIsContinued {
	return [[self getIvar:@"DraftIsContinued"] boolValue];
}

- (void)postSecurityMethodDidChangeNotification:(GPGMAIL_SECURITY_METHOD)securityMethod {
    if(!securityMethod)
        return;
    /* Post notification that the security method has changed. */
    NSNotification *notification = [NSNotification notificationWithName:@"SecurityMethodDidChangeNotification" object:nil userInfo:@{@"SecurityMethod": @((unsigned int)securityMethod)}];
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

@implementation GMDispatchQueueObject

@synthesize dispatchQueue=_dispatchQueue;

- (id)initWithName:(const char *)name queueAttributes:(dispatch_queue_attr_t)attributes {
	if(self = [super init]) {
		_name = [[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
		_dispatchQueue = dispatch_queue_create(name, attributes);
	}
	return self;
}

- (dispatch_queue_t)dispatchQueue {
	return _dispatchQueue;
}

- (void)dealloc {
	dispatch_release(_dispatchQueue);
}

@end

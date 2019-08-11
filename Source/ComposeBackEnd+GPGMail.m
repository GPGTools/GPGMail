//
//  ComposeBackEnd+GPGMail.m
//  GPGMail
//
//  Created by Lukas Pitschl on 31.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "objc/runtime.h"
#import <AppKit/AppKit.h>
#import <MCOutgoingMessage.h>
#import <_MCOutgoingMimeBody.h>
//#import <MessageBody.h>
#import <MCMimeBody.h>
#import <MCMimePart.h>
#import <MCMessageGenerator.h>
//#import <NSString-EmailAddressString.h>
//#import <NSString-NSStringUtils.h>
#import <MCMutableMessageHeaders.h>
//#import <MailNotificationCenter.h>
#import <ComposeBackEnd.h>
#import "MFMailAccount.h"
#import "MCAttachment.h"
#import "CCLog.h"
#import "NSObject+LPDynamicIvars.h"
#import "NSString+GPGMail.h"
#import "NSData+GPGMail.h"
#import "MimePart+GPGMail.h"
#import "Message+GPGMail.h"
#import "GPGFlaggedString.h"
#import "GMSecurityHistory.h"
#import "GPGMailBundle.h"
//#import "HeadersEditor+GPGMail.h"
//#import "MailDocumentEditor.h"
#import "MailDocumentEditor+GPGMail.h"
#import "ComposeBackEnd+GPGMail.h"
//#import "ActivityMonitor.h"
//#import <MFError.h>
//#import "NSData-MessageAdditions.h"
#define restrict
#import <RegexKit/RegexKit.h>

#import "ComposeViewController.h"
#import "HeadersEditor.h"
#import "MCActivityMonitor.h"

#import "MCKeychainManager.h"

#import "NSArray+Functional.h"
#import "GPGConstants.h"

#import "GMComposeMessagePreferredSecurityProperties.h"

#define MAIL_SELF ((ComposeBackEnd *)self)

extern NSString * const kComposeViewControllerPreventAutoSave;

const NSString *kComposeBackEndPreferredSecurityPropertiesKey = @"PreferredSecurityPropertiesKey";
NSString * const kLibraryMimeBodyReturnCompleteBodyDataForComposeBackendKey = @"ReturnCompleteBodyDataForComposeBackEnd";

@implementation ComposeBackEnd_GPGMail


- (id)MA_makeMessageWithContents:(WebComposeMessageContents *)contents isDraft:(BOOL)isDraft shouldSign:(BOOL)shouldSign shouldEncrypt:(BOOL)shouldEncrypt shouldSkipSignature:(BOOL)shouldSkipSignature shouldBePlainText:(BOOL)shouldBePlainText {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return [self MA_makeMessageWithContents:contents isDraft:isDraft shouldSign:shouldSign shouldEncrypt:shouldEncrypt shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];
    }
    GMComposeMessagePreferredSecurityProperties *securityProperties = self.preferredSecurityProperties;
    
	GPGMAIL_SECURITY_METHOD securityMethod = securityProperties.securityMethod;
    
    BOOL bailOut = NO;
    
    // Currently there are three cases where it's time to bail out early.
    // 1.) securityMethod is SMIME
    // 2.) The message is a calendar event which is sent from iCal without user interaction.
    //     In this case, `userShouldSignMessage` and `userShouldEncryptMessage` will be set to `ThreeStateBooleanUndetermined`
    // 3.) The message is neither a draft nor should it be encrypted or signed.
    bailOut = securityMethod != GPGMAIL_SECURITY_METHOD_OPENPGP;
    if(!bailOut) {
        bailOut = [self sentActionInvokedFromiCalWithContents:contents] && securityProperties.userShouldSignMessage == ThreeStateBooleanUndetermined && securityProperties.userShouldEncryptMessage == ThreeStateBooleanUndetermined;
    }
    if(!bailOut) {
        bailOut = !isDraft && !shouldSign && !shouldEncrypt;
    }
    
    if(bailOut) {
        return [self MA_makeMessageWithContents:contents isDraft:isDraft shouldSign:shouldSign shouldEncrypt:shouldEncrypt shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];
    }
    
    // OpenPGP Drafts are encrypted by default (unless the user disabled that feature. In that case
    // shouldEncrypt is set to YES regardless of its current value.
    // It's important however to store the original values for shouldEncrypt and shouldSign in case of a draft,
    // since these values are automatically restored once the draft is continued by the user.
    BOOL userWantsDraftsEncrypted = [[GPGOptions sharedOptions] boolForKey:@"OptionallyEncryptDrafts"];
    BOOL userWantsInlinePGP = [[GPGOptions sharedOptions] boolForKey:@"UseOpenPGPInlineToSend"];
    
    // TODO: Find out how to port the flagging of keys to the new method based on certificates and no longer on NSStrings.
    
    // First handle PGP/MIME, since that requires less manual changes (at the moment).
    
    
    // Fix up text to be signed.
    if(shouldSign) {
        contents.plainText = [self plainTextFixedForSigning:[contents.plainText mutableCopy] shouldAddNewLine:shouldSign && !shouldEncrypt];
    }
    
    // TODO: Remove before release.
    // FOR STEVE ONLY.
    //  NSAssert(!shouldSign, @"Yeah, I can't allow you to sign this message. Also, we want to test the crash reporter.");
    
    // Before the message is created in -[ComposeBackEnd outgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:]
    // additional headers have to be added. If they're added here, they might disappear.
    // In order for the headers not to be removed, they have to be added in -[ComposeBackEnd outgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:].
    // Since the following values are not all available in that method, they are attached to the contents object, and later add to the headers.
    // This is later checked, to determine the real isDraft value.
    [contents setIvar:@"IsDraft" value:@(isDraft)];
    // For drafts, Mail doesn't pass in the real states of the encrypt and sign buttons, so they are fetched from the
    // security properties.
    [contents setIvar:@"ShouldEncrypt" value:@(securityProperties.shouldEncryptMessage)];
    [contents setIvar:@"ShouldSign" value:@(securityProperties.shouldSignMessage)];
    
    // TODO: Find out how to properly handle encryption of drafts in regards to available keys and stuff.
    BOOL encryptDraft = userWantsDraftsEncrypted;
    
    // On to creating the actual message.
    // Drafts and "normal" outgoing messages are handled a bit differently.
    // Drafts are *never* signed, otherwise the user would have to enter their passphrase everytime a draft is created,
    // depending on the cache time set.
    // Also by default Mail doesn't encrypt or sign drafts. In addition, Mail only creates a very basic MIME tree for drafts,
    // which would be unsuitable for PGP/MIME processed messages.
    // In order to force Mail to encrypt messages even if a draft is created, isDraft is always passed as NO to the native
    // method.
    BOOL signMessage = isDraft ? NO : securityProperties.shouldSignMessage;
    BOOL encryptMessage = isDraft ? encryptDraft : securityProperties.shouldEncryptMessage;
    
    MCOutgoingMessage *outgoingMessage = [self MA_makeMessageWithContents:contents isDraft:NO shouldSign:signMessage shouldEncrypt:encryptMessage shouldSkipSignature:shouldSkipSignature shouldBePlainText:shouldBePlainText];
    
    // NOTE: The monitor is set on the threadDictionary of the current thread. So as long as any error which
    //       might occur during message creation is set on the same thread, it's reliably matching this message.
    NSError *creationError = [(MCActivityMonitor *)[MCActivityMonitor currentMonitor] error];
    // When message creation failed, `outgoingMessage` will be `nil`.
    // It's however also possible that the user cancelled the pinentry dialog, in which case
    // `outgoingMessage` contains a valid message but an error is set on the current activity monitor.
    
    // Bug #999: GPG Mail randomly displays an error alert during message creation
    //
    // In case `creationError` was not nil, GPG Mail falsely assumed that an error
    // in relation to encrypting or signing the message had occurred and would return nil
    // instead of a valid outgoing message. As a result the user would be presented with an error dialog.
    //
    // In most reported cases, the error was related to Mail temporarily being unable to contact a mail server.
    //
    // In order to properly handle these cases, GPG Mail must compare the error code
    // of errors set on the current monitor against the error codes for
    // signing or encryption errors.
    // Only if the error is either a signing or encryption error, nil is returned
    // instead of an outgoing message object to have Mail present an error alert to
    // the user if necessary.
    if([creationError code] != 1035 && [creationError code] != 1036) {
        // The error is not relevant for GPG Mail. Mail will deal with it when checking
        // [[MCActivityMonitor currentMonitor] error]
        creationError = nil;
    }
    BOOL messageCreationSucceeded = outgoingMessage != nil && !creationError;
    if(!messageCreationSucceeded) {
        // If a draft should have been created, the user is presented with an error message and
        // is allowed to continue editing the message, after reacting to the error message.
        BOOL signingCancelled = [creationError.userInfo[@"GPGErrorCode"] integerValue] == GPGErrorCancelled;
        
        if(isDraft) {
            // It should also be possible to simply cancel the activity monitor.
            // TODO: Properly test this!.
            [[MCActivityMonitor currentMonitor] cancel];
            // Cancel saving to prevent the default error message.
            //[self setIvar:@"cancelSaving" value:(id)kCFBooleanTrue];
            
            // In case an error occured due to the user cancelling out the pinentry request, no error is displayed.
            if(!signingCancelled) {
                // The error message should be set on the current activity monitor, so we
                // simply have to fetch it.
                GM_CAST_CLASS(NSError *, id) error = (NSError *)[(MCActivityMonitor *)[MCActivityMonitor currentMonitor] error];
                [self performSelectorOnMainThread:@selector(didCancelMessageDeliveryForError:) withObject:error waitUntilDone:NO];
            }
        }
        return nil;
    }
    
    return outgoingMessage;
}

- (NSAttributedString *)plainTextFixedForSigning:(NSMutableAttributedString *)plainText shouldAddNewLine:(BOOL)shouldAddNewLine {
    NSMutableString *plainString = [plainText mutableString];
    
    // If we are only signing and there isn't a newline at the end of the plaintext, append it.
    // We need this to prevent servers from doing this.
    if (shouldAddNewLine) {
        if ([plainString characterAtIndex:plainString.length - 1] != '\n') {
            [plainString appendString:@"\n"];
        }
    }
    
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
    
    // TODO: Fix and verify that the data is really transformed.
    return plainText;
}



- (BOOL)sentActionInvokedFromiCalWithContents:(WebComposeMessageContents *)contents {
	if([contents.attachmentsAndHtmlStrings count] == 0)
		return NO;
	
	
	BOOL fromiCal = NO;
	for(id item in contents.attachmentsAndHtmlStrings) {
		if([item isKindOfClass:GM_MAIL_CLASS(@"MCAttachment")]) {
			MCAttachment *attachment = (MCAttachment *)item;
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

- (BOOL)GMShouldDownloadRemoteAttachments {
	// On Yosemite or higher there's a property to read the shouldDownloadRemoteAttachments flag.
	// otherwise, we have to access the _flags struct.
	BOOL shouldDownloadRemoteAttachments = NO;
	if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
		shouldDownloadRemoteAttachments = [[self valueForKey:@"_shouldDownloadRemoteAttachments"] boolValue];
	}
	else {
		mailFlags backEndFlags;
		Ivar flags = class_getInstanceVariable([self class], "_flags");
		
		CFTypeRef cfSelf = CFBridgingRetain(self);
		backEndFlags = *(mailFlags *)((uint8_t *)cfSelf + ivar_getOffset(flags));
		shouldDownloadRemoteAttachments = backEndFlags.shouldDownloadRemoteAttachments;
		CFBridgingRelease(cfSelf);
	}
	
	return shouldDownloadRemoteAttachments;
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
- (id)MAOutgoingMessageUsingWriter:(id)writer contents:(id)contents headers:(id)headers isDraft:(BOOL)isDraft shouldBePlainText:(BOOL)shouldBePlainText NS_RETURNS_RETAINED {
	if([contents ivarExists:@"IsDraft"])
		isDraft = [[contents getIvar:@"IsDraft"] boolValue];
	if([contents ivarExists:@"IsDraft"] && isDraft) {
		// Prevent hang on 10.10 when restoring drafts.
		// Mail on 10.10 needs the "x-apple-mail-remote-attachments" header in every draft mail.
		// See: https://gpgtools.lighthouseapp.com/projects/65764-gpgmail/tickets/871
		[headers setHeader:self.GMShouldDownloadRemoteAttachments ? @"YES" : @"NO" forKey:@"x-apple-mail-remote-attachments"];


		// Mail doesn't pass in the sign status, when saving a draft, so we have to get it ourselves.
		// For encrypt we also use the state of the button, shouldEncrypt is overriden by our own
		// logic to always encrypt drafts if possible.
        GMComposeMessagePreferredSecurityProperties *securityProperties = [self preferredSecurityProperties];
        BOOL shouldSign = securityProperties.shouldSignMessage;
		BOOL shouldEncrypt = securityProperties.shouldEncryptMessage;
		
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

        // If a draft is being created which should be encrypted, but not encryptionCertificates are setup
        // on the writer, a fitting certificate is added at this point.
        BOOL userWantsDraftsEncrypted = [[GPGOptions sharedOptions] boolForKey:@"OptionallyEncryptDrafts"];
        id smimeLock = [self valueForKey:@"_smimeLock"];
        // Bug #957: Adapt GPGMail to the S/MIME changes introduced in Mail for 10.13.2b3
        //
        // _smimeLock is no longer a simple object to be used with @synchronized but instead
        // a real NSLock.
        if([smimeLock isKindOfClass:[NSLock class]]) {
            @try {
                [smimeLock lock];
                [self GMConfigureEncryptionCertificatesForMessageGenerator:writer shouldEncryptDraft:userWantsDraftsEncrypted];
            }
            @catch(NSException *e) {}
            @finally {
                [smimeLock unlock];
            }
        }
        else {
            @synchronized (smimeLock) {
                [self GMConfigureEncryptionCertificatesForMessageGenerator:writer shouldEncryptDraft:userWantsDraftsEncrypted];
            }
        }
	}
	else {
		[headers removeHeaderForKey:@"x-should-pgp-encrypt"];
		[headers removeHeaderForKey:@"x-should-pgp-sign"];
	}
	return [self MAOutgoingMessageUsingWriter:writer contents:contents headers:headers isDraft:isDraft shouldBePlainText:shouldBePlainText];
}

- (void)GMConfigureEncryptionCertificatesForMessageGenerator:(MCMessageGenerator *)messageGenerator shouldEncryptDraft:(BOOL)shouldEncryptDraft {
    // In case the user doesn't want drafts encrypted, -[MCMessageGenerator encryptionCertificates] has
    // to be nil instead of an empty array.
    GMComposeMessagePreferredSecurityProperties *securityProperties = [self preferredSecurityProperties];
    NSMutableArray *keys = nil;
    GPGKey *encryptionKeyForDraft = nil;
    if(shouldEncryptDraft) {
        // Bug #951: GPGMail tries to encrypt draft even though no PGP key is available
        //
        // In case no PGP key is returned by -[GMComposeMessagePreferredSecurityProperties encryptionKeyForDraft],
        // the Mail's writer object is currently passed an empty array, which errorneously causes Mail to try to
        // encrypt the message even thogh no key is available.
        // In order to fix that, the array has to be niled
        encryptionKeyForDraft = [securityProperties encryptionKeyForDraft];
        if(encryptionKeyForDraft) {
            keys = [NSMutableArray arrayWithObject:encryptionKeyForDraft];
        }
    }
    // TODO: If userWantsDraftsEncrypted is enabled, but no appropriate key could be found
    // warn the user that draft is not going to be encrypted.
    [messageGenerator setEncryptionCertificates:[keys copy]];
}

- (void)didCancelMessageDeliveryForError:(NSError *)error {
    [(ComposeViewController *)[(ComposeBackEnd *)self delegate] backEnd:self didCancelMessageDeliveryForEncryptionError:error];
}

- (id)MARecipientsThatHaveNoKeyForEncryption {
    if(![((ComposeBackEnd *)self) delegate])
		return [NSArray array];
	
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return [self MARecipientsThatHaveNoKeyForEncryption];
    }
    
    // Bug #957: Adapt GPGMail to the S/MIME changes introduced in Mail for 10.13.2b3
    //
    // _smimeLock is no longer a simple object to be used with @synchronized but instead
    // a real NSLock.
    id smimeLock = [self valueForKey:@"_smimeLock"];
    NSMutableArray *nonEligibleRecipients = [NSMutableArray array];
    if([smimeLock isKindOfClass:[NSLock class]]) {
        @try {
            [smimeLock lock];
            nonEligibleRecipients = [self _GMRecipientsThatHaveNoKeyForEncryption];
        }
        @catch(NSException *e) {}
        @finally {
            [smimeLock unlock];
        }
    }
    else {
        @synchronized(smimeLock) {
            nonEligibleRecipients = [self _GMRecipientsThatHaveNoKeyForEncryption];
        }
    }

    return nonEligibleRecipients;
}

- (id)_GMRecipientsThatHaveNoKeyForEncryption {
    NSMutableArray *nonEligibleRecipients = [NSMutableArray array];

    GPGMAIL_SECURITY_METHOD securityMethod = self.preferredSecurityProperties.securityMethod;
    BOOL isSMIME = securityMethod == GPGMAIL_SECURITY_METHOD_SMIME;
    // Bug #961: Deadlock when using S/MIME and trying to toggle encryption state of a message on macOS 10.13
    //
    // -[ComposeBackEnd recipientsThatHaveNoKeyForEncryption] uses the smimeLock internally.
    // Since the calling method of _GMRecipientsThatHaveNoKeyForEncryption already uses the smimeLock,
    // a deadlock is triggered when calling the original mail method.
    //
    // Since the code for checking for missing S/MIME certificates is by now almost identical to the
    // check performed for OpenPGP keys, there's no need to call into the original mail method anymore.
    for(NSString *recipient in [((ComposeBackEnd *)self) allRecipients]) {
        // For Apple's S/MIME implementation it's important that the full recipient matches the certificate.
        // For OpenPGP the email address of the recipient suffices.
        NSString *recipientAddress = isSMIME ? recipient : [recipient gpgNormalizedEmail];
        NSDictionary *encryptionCertificates = [self valueForKey:@"_encryptionCertificates"];
        if(!encryptionCertificates[recipientAddress] || encryptionCertificates[recipientAddress] == [NSNull null]) {
            [nonEligibleRecipients addObject:recipient];
        }
    }

    return nonEligibleRecipients;
}

- (BOOL)messageIsBeingReplied {
    // 1 = Reply
    // 2 = Reply to all.
    // 3 = Forward.
    // 4 = Restored Reply window.
    NSInteger type = [(ComposeBackEnd *)self type];
    return (type == 1 || type == 2 || type == 4) && ![self draftIsContinued];
}

- (BOOL)messageIsBeingForwarded {
    NSInteger type = [MAIL_SELF type];
    return type == 3 && ![self draftIsContinued];
}


- (BOOL)draftIsContinued {
    MCMessageHeaders *headers = [MAIL_SELF originalMessageHeaders];
    BOOL draftIsContinued = [headers firstHeaderForKey:@"x-should-pgp-sign"] != nil || [headers firstHeaderForKey:@"x-should-pgp-encrypt"] != nil;
    return draftIsContinued;
}


- (GMComposeMessagePreferredSecurityProperties *)preferredSecurityProperties {
    GMComposeMessagePreferredSecurityProperties *securityProperties = nil;
    // Bug #957: Adapt GPGMail to the S/MIME changes introduced in Mail for 10.13.2b3
    //
    // _smimeLock is no longer a simple object to be used with @synchronized but instead
    // a real NSLock.
    securityProperties = [self getIvar:kComposeBackEndPreferredSecurityPropertiesKey];

    return securityProperties;
}

- (void)setPreferredSecurityProperties:(GMComposeMessagePreferredSecurityProperties *)preferredSecurityProperties {
    // Bug #957: Adapt GPGMail to the S/MIME changes introduced in Mail for 10.13.2b3
    //
    // _smimeLock is no longer a simple object to be used with @synchronized but instead
    // a real NSLock.
    [self setIvar:kComposeBackEndPreferredSecurityPropertiesKey value:preferredSecurityProperties];
}

// TODO: Possibly remove later. only for testing
- (void)MAUpdateSMIMEStatus:(void(^)(void))onComplete {
    // Re-Implementation of Mail's updateSMIMEStatus.
    // updateSMIMEStatus is invoked by updateSecurityControls, which is responsible for any UI updates.
    // If we're *not* on the main thread, we let Mail handle the logging of the error.
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MAUpdateSMIMEStatus:onComplete];
        return;
    }
    if(![NSThread isMainThread]) {
        [self MAUpdateSMIMEStatus:onComplete];
        return;
    }
    [MAIL_SELF setDefaultSenderIfNeeded];
    NSString *sender = nil;
//    if([MAIL_SELF respondsToSelector:@selector(senderWithValidation:)]) {
//        sender = [MAIL_SELF senderWithValidation:YES];
//    }
//    else {
        sender = [MAIL_SELF sender];
//    }
    NSArray *recipients = [MAIL_SELF allRecipients];
    if(sender) {
        recipients = [recipients arrayByAddingObject:sender];
    }
    
    NSOperationQueue *smimeQueue = [MAIL_SELF smimeQueue];
    [smimeQueue cancelAllOperations];
    [smimeQueue addOperationWithBlock:^{
        void (^checkCertificates)(void) = ^{
            NSMutableDictionary *signingIdentitiesMap = [self valueForKey:@"_signingIdentities"];
            // Remove signing identities not matching the current sender.
            NSSet *signingIdentities = [signingIdentitiesMap keysOfEntriesPassingTest:^BOOL(id key, __unused id obj, __unused BOOL *stop) {
                return ![key isEqual:sender];
            }];
            [signingIdentitiesMap removeObjectsForKeys:[signingIdentities allObjects]];
            
            // Remove encryption certificates not matching the current recipients.
            NSMutableDictionary *encryptionCertificatesMap = [self valueForKey:@"_encryptionCertificates"];
            NSSet *encryptionCertificates = [encryptionCertificatesMap keysOfEntriesPassingTest:^BOOL(id key, __unused id obj, __unused BOOL *stop) {
                return ![recipients containsObject:key];
            }];
            [encryptionCertificatesMap removeObjectsForKeys:[encryptionCertificates allObjects]];
            
            // If there are already preferredSecurityProperties determined, copy the userShouldSignMessage and
            // userShouldEncryptMessage on to the new security properties.
            GMComposeMessagePreferredSecurityProperties *currentSecurityProperties = self.preferredSecurityProperties;
            GPGKey *signingKey = [currentSecurityProperties.signingSender isEqualToString:sender] ? currentSecurityProperties.signingKey : nil;
            GMComposeMessagePreferredSecurityProperties *preferredSecurityProperties = [[GMComposeMessagePreferredSecurityProperties alloc] initWithSender:sender signingKey:signingKey invalidSigningIdentityError:currentSecurityProperties.invalidSigningIdentityError recipients:recipients userShouldSignMessage:currentSecurityProperties ? currentSecurityProperties.userShouldSignMessage : ThreeStateBooleanUndetermined userShouldEncryptMessage:currentSecurityProperties ? currentSecurityProperties.userShouldEncryptMessage : ThreeStateBooleanUndetermined];
            preferredSecurityProperties.cachedSigningIdentities = [self valueForKey:@"_signingIdentities"];
            preferredSecurityProperties.cachedEncryptionCertificates = [self valueForKey:@"_encryptionCertificates"];
            
            [preferredSecurityProperties addHintsFromBackEnd:self];
            [preferredSecurityProperties computePreferredSecurityPropertiesForSecurityMethod:currentSecurityProperties.securityMethod];
            
            [MAIL_SELF setCanSign:preferredSecurityProperties.canSign];
            [MAIL_SELF setCanEncrypt:preferredSecurityProperties.canEncrypt];
            [self setValue:[preferredSecurityProperties.cachedSigningIdentities mutableCopy] forKey:@"_signingIdentities"];
            [self setValue:[preferredSecurityProperties.cachedEncryptionCertificates mutableCopy] forKey:@"_encryptionCertificates"];
            if([MAIL_SELF respondsToSelector:@selector(setInvalidSigningIdentityError:)]) {
                [MAIL_SELF setInvalidSigningIdentityError:preferredSecurityProperties.invalidSigningIdentityError];
            }

            self.preferredSecurityProperties = preferredSecurityProperties;
        };

        id smimeLock = [self valueForKey:@"_smimeLock"];
        // Bug #957: Adapt GPGMail to the S/MIME changes introduced in Mail for 10.13.2b3
        //
        // _smimeLock is no longer a simple object to be used with @synchronized but instead
        // a real NSLock.
        if([smimeLock isKindOfClass:[NSLock class]]) {
            @try {
                [smimeLock lock];
                checkCertificates();
            }
            @catch(NSException *e) {}
            @finally {
                [smimeLock unlock];
            }
        }
        else {
            @synchronized(smimeLock) {
                checkCertificates();
            }
        }
        
        // We have our certificate information, now onto running the UI code.
        if(onComplete) {
            onComplete();
        }
    }];
}

- (void)MA_generateParsedMessageFromOriginalMessages {
    // It's necessary to tell GPGMal that the whole body is required in preparation
    // for a reply and that its allowed to decrypt the content, if necessary.
    [[[NSThread currentThread] threadDictionary] setObject:@(YES) forKey:kLibraryMimeBodyReturnCompleteBodyDataForComposeBackendKey];
    [self MA_generateParsedMessageFromOriginalMessages];
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kLibraryMimeBodyReturnCompleteBodyDataForComposeBackendKey];
}

// Bug #1031: If a message fails to send, it might be replaced by its draft version prior
//              to being sent at a later time.
//
// -[ComposeBackEnd setIsUndeliverable:] is called when sending a message
// has failed. When this method is called, a new compose view controller has
// been created, so the old prevent-auto-save-flag is no longer available
// and has to be set again on the new compose view controller so auto-save is
// prevented from running, until the user has made any changes.
- (void)MASetIsUndeliverable:(BOOL)isUndeliverable {
    if(isUndeliverable) {
        [[MAIL_SELF delegate] setIvar:kComposeViewControllerPreventAutoSave value:@(YES)];
    }
    [self MASetIsUndeliverable:isUndeliverable];
}

@end

#undef MAIL_SELF

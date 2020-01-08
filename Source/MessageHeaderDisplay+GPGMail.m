//
//  MessageHeaderDisplay+GPGMail.m
//  GPGMail
//
//  Created by Lukas Pitschl on 31.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/NSColor.h>
#import <MCMimePart.h>
//#import <MessageHeaderDisplay.h>
//#import <MessageViewingState.h>
//#import <NSAlert-MFErrorSupport.h>
#import "CCLog.h"
#import "NSObject+LPDynamicIvars.h"
#import "GPGSignatureView.h"
#import "GPGAttachmentController.h"
#import "GPGMailBundle.h"
#import "Message+GPGMail.h"
#import "MimePart+GPGMail.h"
#import "MimeBody+GPGMail.h"
#import "NSAttributedString+GPGMail.h"
#import "MessageHeaderDisplay+GPGMail.h"
#import "MessageContentController+GPGMail.h"
//#import "EmailViewController.h"
#import "HeaderViewController.h"
#import "ComposeBackEnd.h"
#import "ConversationMember.h"
#import "MCMessage.h"

#import "GMMessageSecurityFeatures.h"

@implementation MessageHeaderDisplay_GPGMail

- (BOOL)MATextView:(id)textView clickedOnLink:(id)link atIndex:(unsigned long long)index {
    if(![link isEqualToString:@"gpgmail://show-signature"] && ![link isEqualToString:@"gpgmail://decrypt"] &&
       ![link isEqualToString:@"gpgmail://show-attachments"])
        return [self MATextView:textView clickedOnLink:link atIndex:index];
//    if([link isEqualToString:@"gpgmail://decrypt"]) {
//        [self _decryptMessage];
//        return YES;
//    }
    if([link isEqualToString:@"gpgmail://show-signature"]) {
        [self _showSignaturePanel];
    }
    if([link isEqualToString:@"gpgmail://show-attachments"]) {
        [self _showAttachmentsPanel];
    }
    return NO;
}

/* In Mavericks the above message was renamed and works differently. */

- (void)MATextView:(id)textView clickedOnCell:(id)cell inRect:(struct CGRect)rect atIndex:(unsigned long long)index {
    if([[cell attachment] getIvar:@"ShowSignaturePanel"])
        return [self _showSignaturePanel];
    
    if([[cell attachment] getIvar:@"ShowAttachmentPanel"])
        return [self _showAttachmentsPanel];
    
    return [self MATextView:textView clickedOnCell:cell inRect:rect atIndex:index];
}

- (NSWindow *)modalWindow {
	NSWindow *window = [GPGMailBundle isElCapitan] ? [[(id)self view] window] : [NSApp mainWindow];
	return window;
}

- (void)_showAttachmentsPanel {
    NSArray *pgpAttachments = nil;
    GM_CAST_CLASS(MCMessage *, id) message = (Message_GPGMail *)[(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage];
    GMMessageSecurityFeatures *securityFeatures = [message securityFeatures];
    pgpAttachments = [securityFeatures PGPAttachments];
    
    GPGAttachmentController *attachmentController = [[GPGAttachmentController alloc] initWithAttachmentParts:pgpAttachments];
    attachmentController.keyList = [[GPGMailBundle sharedInstance] allGPGKeys];
	
	[attachmentController beginSheetModalForWindow:[self modalWindow] completionHandler:^(NSInteger result) {
    }];
    // Set is an an ivar of MessageHeaderDisplay so it's released, once
    // the Message Header Display is closed.
    [self setIvar:@"AttachmentController" value:attachmentController];
}

- (void)_showSignaturePanel {
    NSArray *messageSigners = [self getIvar:@"messageSigners"];
    if(![messageSigners count])
        return;
    BOOL notInKeychain = NO;
    for(GPGSignature *signature in messageSigners) {
        if(!signature.primaryKey) {
            notInKeychain = YES;
            break;
        }
    }
    if(notInKeychain) {
        NSString *title = GMLocalizedString(@"MESSAGE_ERROR_ALERT_PGP_VERIFY_NOT_IN_KEYCHAIN_TITLE");
        NSString *message = GMLocalizedString(@"MESSAGE_ERROR_ALERT_PGP_VERIFY_NOT_IN_KEYCHAIN_MESSAGE");
        
        // The error domain is checked in certain occasion, so let's use the system
        // dependent one.
        NSString *errorDomain = [GPGMailBundle isMavericks] ? @"MCMailErrorDomain" : @"MFMessageErrorDomain";
        // TODO: Fix to use the new Sierra method!
        NSError *error = nil;/*[GM_MAIL_CLASS(@"MFError") errorWithDomain:errorDomain code:1035 localizedDescription:message title:title helpTag:nil userInfo:@{@"_MFShortDescription": title, @"NSLocalizedDescription": message}];*/
        // NSAlert has different category methods based on the version of OS X.
		NSAlert *alert = nil;
		if([[NSAlert class] respondsToSelector:@selector(alertForError:defaultButton:alternateButton:otherButton:)]) {
			alert = [NSAlert alertForError:error defaultButton:@"OK" alternateButton:nil otherButton:nil];
		}
		else if([[NSAlert class] respondsToSelector:@selector(alertForError:firstButton:secondButton:thirdButton:)]) {
			alert = [NSAlert alertForError:error firstButton:@"OK" secondButton:nil thirdButton:nil];
		}
		
		[alert beginSheetModalForWindow:[self modalWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    GPGSignatureView *signatureView = [GPGSignatureView signatureView];
    signatureView.signatures = messageSigners;
	[signatureView beginSheetModalForWindow:[self modalWindow] completionHandler:^(NSInteger result) {
//        DebugLog(@"Signature panel was closed: %d", result);
    }];
}

//- (id)MA_attributedStringForSecurityHeader {
//    MessageViewingState *viewingState = [((MessageHeaderDisplay *)self) viewingState];
//    GM_CAST_CLASS(Message *, id) message = [viewingState message];
//    GM_CAST_CLASS(MimeBody *, id) mimeBody = [viewingState mimeBody];
//    
//    // TODO: Re-implement using security features.
//    return [[NSAttributedString alloc] initWithString:@""];
////    if(![message shouldBePGPProcessed])
////        return [self MA_attributedStringForSecurityHeader];
////    
////    // If no viewingState is set, return an empty string.
////    if(!viewingState || viewingState.headerDetailLevel == 0)
////        return [[NSAttributedString alloc] initWithString:@""];
////    
////    NSAttributedString *headerSecurityString = viewingState.headerSecurityString;
////    if(headerSecurityString)
////        return headerSecurityString;
////    
////    // Check the mime body, is more reliable.
////    BOOL isPGPSigned = (BOOL)[message PGPSigned];
////    BOOL isPGPEncrypted = (BOOL)[message PGPEncrypted] && ![mimeBody ivarExists:@"PGPEarlyAlphaFuckedUpEncrypted"];
////    BOOL hasPGPAttachments = (BOOL)[message numberOfPGPAttachments] > 0 ? YES : NO;
////    
////    if(!isPGPSigned && !isPGPEncrypted && !hasPGPAttachments)
////        return [self MA_attributedStringForSecurityHeader];
////    
////    NSMutableAttributedString *securityHeader = [self securityHeaderForMessage:message mimeBody:mimeBody];
////    
////    NSMutableAttributedString *finalSecurityHeader = [[NSMutableAttributedString alloc] init];
////    [finalSecurityHeader appendAttributedString:securityHeader];
////    [finalSecurityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
////    [finalSecurityHeader addAttribute:NSParagraphStyleAttributeName value:[(MessageHeaderDisplay *)self _paragraphStyleWithLineHeight:16.0f indent:19] range:NSMakeRange(0, 1)];
////    [finalSecurityHeader addAttribute:@"header label" value:@"yes" range:NSMakeRange(1, [finalSecurityHeader length] - 1)];
////    [finalSecurityHeader addAttribute:@"key" value:@"security" range:NSMakeRange(1, [finalSecurityHeader length] - 1)];
////    
////    viewingState.headerSecurityString = finalSecurityHeader;
////    
////    return finalSecurityHeader;
//}

- (void)MAToggleDetails:(id)target {
    // Make sure loading stage is removed, so the detail view
    // can be toggled on and off, otherwise it would be always forced to on.
    Message_GPGMail *message = (Message_GPGMail *)[(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage];
    if([message getIvar:@"LoadingStage"])
        [message removeIvar:@"LoadingStage"];
    [self MAToggleDetails:target];
}



- (NSAttributedString *)MASecurityHeaderString {
    NSAttributedString *securityHeaderString = [self MA_displayStringForSecurityKey];
    if(!securityHeaderString || [securityHeaderString length] == 0) {
        return [self MASecurityHeaderString];
    }
    return securityHeaderString;
}

- (void)MA_updateTextStorageWithHardInvalidation:(BOOL)hardValidation {
    [self MA_updateTextStorageWithHardInvalidation:hardValidation];
    
    // If hard validation is set, _displayStringsByHeaderKey is emptied,
    // before readding the NSAttributedStrings for each header key.
    // In order to insert our own security key, we'll overwrite whatever
    // Mail itself stores under the x-apple-security key, and afterwards
    // run _updateTextStorageWithHardInvalidation:NO.
    // As a result, Mail will recreate the header display, but without emptying
    // _displayStringsByHeaderKey first, thus, using our own security string.
    // This way we don't have to use the loop-through-attributes-and-insert-after-the-to-header-trick.
    if([GPGMailBundle isYosemite]) {
        if(hardValidation) {
            NSAttributedString *securityHeaderString = [self MA_displayStringForSecurityKey];
            if(!securityHeaderString || [securityHeaderString length] == 0)
                return;
            NSMutableDictionary *displayStringsByHeaderKey = [self valueForKey:@"_displayStringsByHeaderKey"];
            displayStringsByHeaderKey[@"x-apple-security"] = securityHeaderString;
            [self MA_updateTextStorageWithHardInvalidation:NO];
        }
        
        return;
    }
    else {
        // Force details to always be shown on Mavericks for PGP processed messages.
        // Works differently on < 10.9.
        
        Message_GPGMail *message = (Message_GPGMail *)[(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage];
        // If we set _detailsHidden too early, it's ignored as it seems,
        // so we check the PGPInfoCollected flag, to know whether or not the message
        // has already been processed. If is has, and this method is called, force _detailsHidden to be
        // false and update the details button.
        
        if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
            [self setIvar:@"RealShowDetails" value:[self valueForKey:@"_showDetails"]];
            [self setShowDetails:1];
        }
        
        // TODO: Re-implement using security features.
//        
//        if(message.PGPInfoCollected && (message.PGPEncrypted || message.PGPSigned) && [message getIvar:@"LoadingStage"]) {
//            if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
//                [self setIvar:@"RealShowDetails" value:[self valueForKey:@"_showDetails"]];
//                [self setShowDetails:1];
//            }
//            else {
//                [self setIvar:@"RealDetailsHidden" value:[self valueForKey:@"_detailsHidden"]];
//                [self setValue:@(0) forKey:@"_detailsHidden"];
//                [self _updateDetailsButton];
//            }
//            [self MA_updateTextStorageWithHardInvalidation:YES];
//            return;
//        }
//        
        [self MA_updateTextStorageWithHardInvalidation:hardValidation];
    }
}

- (id)MA_displayStringForSecurityKey {
    //if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
		// MA_displayStringForSecurityKey no longer exists on High Sierra or Mojave,
		// so return nil instead.
    // return nil;
    //}
    GM_CAST_CLASS(MCMessage *, id) message = (Message_GPGMail *)[(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage];
    
    GMMessageSecurityFeatures *securityProperties = [message securityFeatures];
    
    BOOL isPGPSigned = securityProperties.PGPSigned;
    BOOL isPGPEncrypted = securityProperties.PGPEncrypted;
    BOOL hasPGPAttachments = securityProperties.numberOfPGPAttachments > 0 ? YES : NO;

    if(!isPGPSigned && !isPGPEncrypted && !hasPGPAttachments) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    NSMutableAttributedString *displayString = [self securityHeaderForMessage:message];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.baseWritingDirection = [NSParagraphStyle defaultWritingDirectionForLanguage:nil];
    paragraphStyle.alignment = NSLeftTextAlignment;
    paragraphStyle.lineSpacing = [GPGMailBundle isYosemite] ? 0.0f : 1.0f;
    paragraphStyle.tighteningFactorForTruncation = 0.0f;
    paragraphStyle.minimumLineHeight = [GPGMailBundle isYosemite] ? 0.0f : 15.0f;
    paragraphStyle.maximumLineHeight = [GPGMailBundle isYosemite] ? 0.0f : 15.0f;
    paragraphStyle.firstLineHeadIndent = [GPGMailBundle isYosemite] ? 6.0f : 4.0f;
    paragraphStyle.headIndent = [GPGMailBundle isYosemite] ? 6.0f : 4.0f;
    
    NSFont *font = [(NSTextView *)[(HeaderViewController *)self textView] font];
    if(!font) {
        NSLog(@"No font info available. Would usually crash when creating the dictionary later.");
        font = [NSFont systemFontOfSize:12.00f];
    }
    if([GPGMailBundle isYosemite])
        font = [NSFont systemFontOfSize:12.00f];
    NSColor *color = [NSColor blackColor];
    if([GPGMailBundle isYosemite])
        color = [NSColor performSelector:@selector(labelColor)];
    
    NSDictionary *attributes = @{@"HeaderKey": @"x-apple-security", NSFontAttributeName: font, NSForegroundColorAttributeName: color,
                                 NSParagraphStyleAttributeName: paragraphStyle};
    [displayString addAttributes:attributes range:NSMakeRange(0, [displayString length])];
    
    return displayString;
}

- (NSMutableAttributedString *)securityHeaderForMessage:(GM_CAST_CLASS(Message *, id))message {
    // This is also called if the message is neither signed nor encrypted.
    // In that case the empty string is returned.
    // Internally this method checks the message's messageFlags
    // to determine if the message is signed or encrypted and
    // based on that information creates the encrypted symbol
    // and calls copySingerLabels on the topLevelPart.
    
    // TODO: Change method signature if using security features works.
    GMMessageSecurityFeatures *securityFeatures = [message securityFeatures];
    // Check the mime body, is more reliable.
    BOOL isPGPSigned = securityFeatures.PGPSigned;
    BOOL isPGPEncrypted = securityFeatures.PGPEncrypted;// && ![mimeBody ivarExists:@"PGPEarlyAlphaFuckedUpEncrypted"];
    
    NSString *securityHeaderLabelKey = @"SecurityHeaderLabel";
    
    NSString *indentation = @"";
    NSMutableAttributedString *securityHeader = [NSMutableAttributedString new];
    [securityHeader beginEditing];
    
    NSMutableString *securityHeaderString = [securityHeader mutableString];
    
    [securityHeaderString appendFormat:@"%@:", [[NSBundle mainBundle] localizedStringForKey:securityHeaderLabelKey value:@"" table:@"Encryption"]];
    
    // Add the encrypted part to the security header.
    if(isPGPEncrypted) {
        NSImage *encryptedBadge = [NSImage imageNamed:@"NSLockLockedTemplate"];
        NSAttributedString *encryptAttachmentString = [NSAttributedString attributedStringWithAttachment:[[NSTextAttachment alloc] init]
                                                                                                   image:encryptedBadge
                                                                                                    link:nil
                                                                                                  offset:0.0];
        if([GPGMailBundle isMavericks])
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@" "]];
        else {
            if(@available(macOS 10.15, *)) {
                [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:nil]];
            }
            else {
                [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:[NSAttributedString headerAttributes]]];
            }
        }
        
        [securityHeader appendAttributedString:encryptAttachmentString];
        
        NSString *encryptedString = [NSString stringWithFormat:@" %@", [securityFeatures PGPPartlyEncrypted] ? GMLocalizedString(@"MESSAGE_IS_PGP_PARTLY_ENCRYPTED") :
        GMLocalizedString(@"MESSAGE_IS_PGP_ENCRYPTED")];
        if([GPGMailBundle isMavericks])
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:encryptedString]];
        else {
            if(@available(macOS 10.15, *)) {
                [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:encryptedString attributes:nil]];
            }
            else {
                [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:[NSAttributedString headerAttributes]]];
            }
        }
    }
    if(isPGPSigned) {
        NSAttributedString *securityHeaderSignaturePart = [self securityHeaderSignaturePartForMessage:message];
        [self setIvar:@"messageSigners" value:[securityFeatures PGPSignatures]];
        
        // Only add, if message was encrypted.
        if(isPGPEncrypted) {
            if([GPGMailBundle isMavericks])
                [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];
            else {
                if(@available(macOS 10.15, *)) {
                    [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:@", " attributes:nil]];
                }
                else {
                    [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:@", " attributes:[NSAttributedString headerAttributes]]];
                }
            }
        }
        
        [securityHeader appendAttributedString:securityHeaderSignaturePart];
    }
    NSUInteger numberOfPGPAttachments = [securityFeatures numberOfPGPAttachments];
    // And last but not least, add a new line.
    if(numberOfPGPAttachments) {
        NSAttributedString *securityHeaderAttachmentsPart = [self securityHeaderAttachmentsPartForMessage:message];
        
        if([securityFeatures PGPSigned] || [securityFeatures PGPEncrypted])
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];
        [securityHeader appendAttributedString:securityHeaderAttachmentsPart];
    }
    
    return securityHeader;
}

- (NSAttributedString *)securityHeaderAttachmentsPartForMessage:(GM_CAST_CLASS(Message *, id))message {
    GMMessageSecurityFeatures *securityFeatures = [message securityFeatures];
    
    BOOL hasEncryptedAttachments = NO;
    BOOL hasSignedAttachments = NO;
    BOOL singular = [securityFeatures numberOfPGPAttachments] > 1 ? NO : YES;

    NSMutableAttributedString *securityHeaderAttachmentsPart = [[NSMutableAttributedString alloc] init];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    [textAttachment setIvar:@"ShowAttachmentPanel" value:@YES];
    NSImage *attachmentIcon = [NSImage imageNamed:@"attachment_header"];
    float iconOffset = -3.0;

    // On macOS Mojave 10.14.6 attachment_header no longer exists. Instead
    // the icon is now called MessageListAttachmentTemplate.
    if(!attachmentIcon) {
        attachmentIcon = [NSImage imageNamed:@"MessageListAttachmentTemplate"];
        iconOffset = -1.0;
    }

    [securityHeaderAttachmentsPart appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment image:attachmentIcon link:[GPGMailBundle isMavericks] ? nil : @"gpgmail://show-attachments" offset:iconOffset]];

    for(MimePart_GPGMail *attachment in [securityFeatures PGPAttachments]) {
        hasEncryptedAttachments |= [attachment PGPEncrypted];
        hasSignedAttachments |= [attachment PGPSigned];
    }

    NSString *attachmentPart = nil;

    if(hasEncryptedAttachments && hasSignedAttachments) {
        attachmentPart = (singular ?
            GMLocalizedString(@"MESSAGE_SECURITY_HEADER_ATTACHMENT_SIGNED_ENCRYPTED_TITLE") :
            GMLocalizedString(@"MESSAGE_SECURITY_HEADER_ATTACHMENTS_SIGNED_ENCRYPTED_TITLE"));
    }
    else if(hasEncryptedAttachments) {
        attachmentPart = (singular ?
            GMLocalizedString(@"MESSAGE_SECURITY_HEADER_ATTACHMENT_ENCRYPTED_TITLE") :
            GMLocalizedString(@"MESSAGE_SECURITY_HEADER_ATTACHMENTS_ENCRYPTED_TITLE"));
    }
    else if(hasSignedAttachments) {
        attachmentPart = (singular ?
            GMLocalizedString(@"MESSAGE_SECURITY_HEADER_ATTACHMENT_SIGNED_TITLE") :
            GMLocalizedString(@"MESSAGE_SECURITY_HEADER_ATTACHMENTS_SIGNED_TITLE"));
    }

    NSString *encryptionString = [NSString stringWithFormat:@"%li %@", (long)[securityFeatures numberOfPGPAttachments], attachmentPart];
    if(![NSImage imageNamed:@"attachment_header"]) {
        encryptionString = [@" " stringByAppendingString:encryptionString];
    }
    
    if([GPGMailBundle isMavericks])
        [securityHeaderAttachmentsPart appendAttributedString:[NSAttributedString attributedStringWithString:encryptionString]];
    else {
        if(@available(macOS 10.15, *)) {
            [securityHeaderAttachmentsPart appendAttributedString:[[NSAttributedString alloc] initWithString:encryptionString attributes:nil]];
        }
        else {
            [securityHeaderAttachmentsPart appendAttributedString:[[NSAttributedString alloc] initWithString:encryptionString attributes:[NSAttributedString headerAttributes]]];
        }
    }

    return securityHeaderAttachmentsPart;
}

- (NSAttributedString *)securityHeaderSignaturePartForMessage:(Message_GPGMail *)message {
    GMMessageSecurityFeatures *securityFeatures = [message securityFeatures];
    
    GPGErrorCode errorCode = GPGErrorNoError;
    NSImage *signedImage = nil;
    NSSet *signatures = [NSSet setWithArray:securityFeatures.PGPSignatures];
    
    NSMutableAttributedString *securityHeaderSignaturePart = [[NSMutableAttributedString alloc] init];
    
    for(GPGSignature *signature in signatures) {
        if(signature.status != GPGErrorNoError) {
            errorCode = signature.status;
            break;
        }
    }
    
	// Check if MacGPG2 was not found.
	// If that's the case, don't try to append signature labels.
	if(!errorCode) {
		GPGErrorCode __block newErrorCode = GPGErrorNoError;
		[[securityFeatures PGPErrors] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if([obj isKindOfClass:GM_MAIL_CLASS(@"NSError")]) {
				if(((NSDictionary *)[(NSError *)obj userInfo])[@"VerificationErrorCode"])
					newErrorCode = (GPGErrorCode)[((NSDictionary *)[(NSError *)obj userInfo])[@"VerificationErrorCode"] longValue];
				*stop = YES;
			}
		}];
		errorCode = newErrorCode;
	}
	
	NSString *titlePart = nil;
    
    switch (errorCode) {
        case GPGErrorNoPublicKey:
            titlePart = GMLocalizedString(@"MESSAGE_SECURITY_HEADER_SIGNATURE_NO_PUBLIC_KEY_TITLE");
            break;
            
        case GPGErrorCertificateRevoked:
            titlePart = GMLocalizedString(@"MESSAGE_SECURITY_HEADER_SIGNATURE_REVOKED_TITLE");
            break;
            
        case GPGErrorBadSignature:
            titlePart = GMLocalizedString(@"MESSAGE_SECURITY_HEADER_SIGNATURE_BAD_TITLE");
            break;
            
        default:
            titlePart = GMLocalizedString(@"MESSAGE_SECURITY_HEADER_SIGNATURE_TITLE");
            break;
    }
    
    if (errorCode) {
        signedImage = [NSImage imageNamed:@"SignatureOffTemplate"];
	} else if (signatures.count == 0) {
        titlePart = GMLocalizedString(@"MESSAGE_SECURITY_HEADER_NO_SIGNATURE_TITLE");
        signedImage = [NSImage imageNamed:@"SignatureOffTemplate"];
    } else {
        titlePart = GMLocalizedString(@"MESSAGE_SECURITY_HEADER_SIGNATURE_TITLE");
        signedImage = [NSImage imageNamed:@"SignatureOnTemplate"];
    }
    
    
    if(securityFeatures.PGPPartlySigned) {
// TODO: Implement different messages for partly signed messages.
        titlePart = GMLocalizedString(@"MESSAGE_IS_PGP_PARTLY_SIGNED");
    }
    
    NSSet *signerLabels = [NSSet setWithArray:[securityFeatures PGPSignatureLabels]];
    NSTextAttachment *signedTextAttachment = [[NSTextAttachment alloc] init];
    [signedTextAttachment setIvar:@"ShowSignaturePanel" value:@YES];
    NSAttributedString *signedAttachmentString = [NSAttributedString attributedStringWithAttachment:signedTextAttachment
                                                                                              image:signedImage link:[GPGMailBundle isMavericks] ? nil : @"gpgmail://show-signature"
                                                                                             offset:-2.0];
    
    [securityHeaderSignaturePart appendAttributedString:signedAttachmentString];
    [[securityHeaderSignaturePart mutableString] appendString:@" "];
    
    NSMutableString *signerLabelsString = [NSMutableString stringWithString:titlePart];
	// No MacGPG2? No signer labels!
	if(errorCode != GPGErrorNotFound && [[signerLabels allObjects] count] != 0)
		[signerLabelsString appendFormat:@" (%@)", [[signerLabels allObjects] componentsJoinedByString:@", "]];
    
    if([GPGMailBundle isMavericks])
        [securityHeaderSignaturePart appendAttributedString:[NSAttributedString attributedStringWithString:signerLabelsString]];
    else {
        if(@available(macOS 10.15, *)) {
            [securityHeaderSignaturePart appendAttributedString:[[NSAttributedString alloc] initWithString:signerLabelsString attributes:nil]];
        }
        else {
            [securityHeaderSignaturePart appendAttributedString:[[NSAttributedString alloc] initWithString:signerLabelsString attributes:[NSAttributedString headerAttributes]]];
        }
    }
    
    return securityHeaderSignaturePart;
}

@end

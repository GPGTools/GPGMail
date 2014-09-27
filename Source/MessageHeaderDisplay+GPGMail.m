//
//  MessageHeaderDisplay+GPGMail.m
//  GPGMail
//
//  Created by Lukas Pitschl on 31.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <MFError.h>
#import <MimePart.h>
#import <MimeBody.h>
#import <NSAttributedString-FontAdditions.h>
#import <MessageHeaderDisplay.h>
#import <MessageViewingState.h>
#import <NSAlert-MFErrorSupport.h>
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
#import "EmailViewController.h"
#import "HeaderViewController.h"
#import "ComposeBackEnd.h"
#import "ConversationMember.h"
#import "MCMessage.h"

@implementation MessageHeaderDisplay_GPGMail

- (BOOL)MATextView:(id)textView clickedOnLink:(id)link atIndex:(unsigned long long)index {
    if(![link isEqualToString:@"gpgmail://show-signature"] && ![link isEqualToString:@"gpgmail://decrypt"] &&
       ![link isEqualToString:@"gpgmail://show-attachments"])
        return [self MATextView:textView clickedOnLink:link atIndex:index];
    if([link isEqualToString:@"gpgmail://decrypt"]) {
        [self _decryptMessage];
        return YES;
    }
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


- (void)_showAttachmentsPanel {
    NSArray *pgpAttachments = nil;
    if(![GPGMailBundle isMavericks])
        pgpAttachments = [(Message_GPGMail *)[(MessageViewingState *)[((MessageHeaderDisplay *)self) viewingState] message] PGPAttachments];
    else
        pgpAttachments = [(Message_GPGMail *)[(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage] PGPAttachments];
    
    GPGAttachmentController *attachmentController = [[GPGAttachmentController alloc] initWithAttachmentParts:pgpAttachments];
    attachmentController.keyList = [[GPGMailBundle sharedInstance] allGPGKeys];
    [attachmentController beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
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
        MFError *error = [GM_MAIL_CLASS(@"MFError") errorWithDomain:errorDomain code:1035 localizedDescription:message title:title helpTag:nil userInfo:@{@"_MFShortDescription": title, @"NSLocalizedDescription": message}];
        // NSAlert has different category methods based on the version of OS X.
		NSAlert *alert = nil;
		if([[NSAlert class] respondsToSelector:@selector(alertForError:defaultButton:alternateButton:otherButton:)]) {
			alert = [NSAlert alertForError:error defaultButton:@"OK" alternateButton:nil otherButton:nil];
		}
		else if([[NSAlert class] respondsToSelector:@selector(alertForError:firstButton:secondButton:thirdButton:)]) {
			alert = [NSAlert alertForError:error firstButton:@"OK" secondButton:nil thirdButton:nil];
		}
		
		[alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    GPGSignatureView *signatureView = [GPGSignatureView signatureView];
    signatureView.keyList = [[GPGMailBundle sharedInstance] allGPGKeys];
    signatureView.signatures = messageSigners; 
    [signatureView beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
//        DebugLog(@"Signature panel was closed: %d", result);
    }];
}

- (void)_decryptMessage {
    [[[((MessageHeaderDisplay *)self) parentController] parentController] decryptPGPMessage];
}

- (id)MA_attributedStringForSecurityHeader {
    MessageViewingState *viewingState = [((MessageHeaderDisplay *)self) viewingState];
    GM_CAST_CLASS(Message *, id) message = [viewingState message];
    GM_CAST_CLASS(MimeBody *, id) mimeBody = [viewingState mimeBody];
    
    if(![message shouldBePGPProcessed])
        return [self MA_attributedStringForSecurityHeader];
    
    // If no viewingState is set, return an empty string.
    if(!viewingState || viewingState.headerDetailLevel == 0)
        return [[NSAttributedString alloc] initWithString:@""];
    
    NSAttributedString *headerSecurityString = viewingState.headerSecurityString;
    if(headerSecurityString)
        return headerSecurityString;
    
    // Check the mime body, is more reliable.
    BOOL isPGPSigned = (BOOL)[message PGPSigned];
    BOOL isPGPEncrypted = (BOOL)[message PGPEncrypted] && ![mimeBody ivarExists:@"PGPEarlyAlphaFuckedUpEncrypted"];
    BOOL hasPGPAttachments = (BOOL)[message numberOfPGPAttachments] > 0 ? YES : NO;
    
    if(!isPGPSigned && !isPGPEncrypted && !hasPGPAttachments)
        return [self MA_attributedStringForSecurityHeader];
    
    NSMutableAttributedString *securityHeader = [self securityHeaderForMessage:message mimeBody:mimeBody];
    
    NSMutableAttributedString *finalSecurityHeader = [[NSMutableAttributedString alloc] init];
    [finalSecurityHeader appendAttributedString:securityHeader];
    [finalSecurityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
    [finalSecurityHeader addAttribute:NSParagraphStyleAttributeName value:[(MessageHeaderDisplay *)self _paragraphStyleWithLineHeight:16.0f indent:19] range:NSMakeRange(0, 1)];
    [finalSecurityHeader addAttribute:@"header label" value:@"yes" range:NSMakeRange(1, [finalSecurityHeader length] - 1)];
    [finalSecurityHeader addAttribute:@"key" value:@"security" range:NSMakeRange(1, [finalSecurityHeader length] - 1)];
    
    viewingState.headerSecurityString = finalSecurityHeader;
    
    return finalSecurityHeader;
}

- (void)MAToggleDetails:(id)target {
    // Make sure loading stage is removed, so the detail view
    // can be toggled on and off, otherwise it would be always forced to on.
    Message_GPGMail *message = (Message_GPGMail *)[(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage];
    if([message getIvar:@"LoadingStage"])
        [message removeIvar:@"LoadingStage"];
    [self MAToggleDetails:target];
}

- (void)MA_updateTextStorageWithHardInvalidation:(BOOL)arg1 {
    [self MA_updateTextStorageWithHardInvalidation:arg1];
    
    NSAttributedString *headerAttributedString = [[self performSelector:@selector(textView)] attributedString];
    __block NSUInteger foundToHeader = 0;
    NSMutableAttributedString *newHeaderAttributedString = [[NSMutableAttributedString alloc] init];
    [headerAttributedString enumerateAttribute:@"HeaderKey" inRange:NSMakeRange(0, [headerAttributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        
        [newHeaderAttributedString appendAttributedString:[headerAttributedString attributedSubstringFromRange:range]];
        
        if([value isEqualToString:@"to"])
            foundToHeader = 1;
        if(![value isEqualToString:@"to"] && foundToHeader == 1) {
            foundToHeader = 0;
            [newHeaderAttributedString appendAttributedString:[self MA_displayStringForSecurityKey]];
        }
        
        NSLog(@"Value: %@", value);
        NSLog(@"Range: %@", [headerAttributedString attributedSubstringFromRange:range]);
    }];
    
    NSLog(@"New header string: %@", newHeaderAttributedString);
    NSTextView *textView = [self performSelector:@selector(textView)];
    [[textView textStorage] setAttributedString:newHeaderAttributedString];
    
    
    // Force details to always be shown on Mavericks for PGP processed messages.
    // Works differently on < 10.9.
    
    Message_GPGMail *message = (Message_GPGMail *)[(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage];
    // If we set _detailsHidden too early, it's ignored as it seems,
    // so we check the PGPInfoCollected flag, to know whether or not the message
    // has already been processed. If is has, and this method is called, force _detailsHidden to be
    // false and update the details button.
    NSLog(@"Loading Stage: %@", [message getIvar:@"LoadingStage"]);
    NSLog(@"Loading Stage: %d", message.PGPInfoCollected);
    NSLog(@"Loading Stage: %d", message.PGPEncrypted);
    NSLog(@"Loading Stage: %d", message.PGPSigned);
    
    if(message.PGPInfoCollected && (message.PGPEncrypted || message.PGPSigned) && [message getIvar:@"LoadingStage"]) {
        [self setIvar:@"RealDetailsHidden" value:[self valueForKey:@"_detailsHidden"]];
        [self setValue:@(0) forKey:@"_detailsHidden"];
        [(HeaderViewController *)self _updateDetailsButton];
        [self MA_updateTextStorageWithHardInvalidation:YES];
        return;
    }
    
    [self MA_updateTextStorageWithHardInvalidation:arg1];
}

- (id)MA_displayStringForSecurityKey {
    GM_CAST_CLASS(MCMessage *, id) message = [(ConversationMember *)[(HeaderViewController *)self representedObject] originalMessage];
    GM_CAST_CLASS(MCMimeBody *, id) mimeBody = [(ConversationMember *)[(HeaderViewController *)self representedObject] messageBody];
    
    if(![message shouldBePGPProcessed])
        return [self MA_displayStringForSecurityKey];
    
    // Check the mime body, is more reliable.
    BOOL isPGPSigned = (BOOL)[message PGPSigned];
    BOOL isPGPEncrypted = (BOOL)[message PGPEncrypted] && ![mimeBody ivarExists:@"PGPEarlyAlphaFuckedUpEncrypted"];
    BOOL hasPGPAttachments = (BOOL)[message numberOfPGPAttachments] > 0 ? YES : NO;
    
    if(!isPGPSigned && !isPGPEncrypted && !hasPGPAttachments) {
        if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
            return [[NSAttributedString alloc] initWithString:@""];
        }
        else {
            return [self MA_displayStringForSecurityKey];
        }
    }
    
    NSMutableAttributedString *displayString = [self securityHeaderForMessage:message mimeBody:mimeBody];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.baseWritingDirection = [NSParagraphStyle defaultWritingDirectionForLanguage:nil];
    paragraphStyle.alignment = NSLeftTextAlignment;
    paragraphStyle.lineSpacing = 1.0f;
    paragraphStyle.tighteningFactorForTruncation = 0.0f;
    paragraphStyle.minimumLineHeight = 15.0f;
    paragraphStyle.maximumLineHeight = 15.0f;
    paragraphStyle.firstLineHeadIndent = 4.0f;
    paragraphStyle.headIndent = 4.0f;
    
    NSDictionary *attributes = @{@"HeaderKey": @"x-apple-security", NSFontAttributeName: [(NSTextView *)[(HeaderViewController *)self textView] font], NSForegroundColorAttributeName: [NSColor blackColor],
                                 NSParagraphStyleAttributeName: paragraphStyle};
    [displayString addAttributes:attributes range:NSMakeRange(0, [displayString length])];
    
    return displayString;
}

- (NSMutableAttributedString *)securityHeaderForMessage:(GM_CAST_CLASS(Message *, id))message mimeBody:(GM_CAST_CLASS(MimeBody *, id))mimeBody {
    // This is also called if the message is neither signed nor encrypted.
    // In that case the empty string is returned.
    // Internally this method checks the message's messageFlags
    // to determine if the message is signed or encrypted and
    // based on that information creates the encrypted symbol
    // and calls copySingerLabels on the topLevelPart.
    
    // Check the mime body, is more reliable.
    BOOL isPGPSigned = (BOOL)[message PGPSigned];
    BOOL isPGPEncrypted = (BOOL)[message PGPEncrypted] && ![mimeBody ivarExists:@"PGPEarlyAlphaFuckedUpEncrypted"];
    
    NSString *securityHeaderLabelKey = [GPGMailBundle isMavericks] ? @"SecurityHeaderLabel" : @"SECURITY_HEADER";
    
    NSString *indentation = @"";
    if([GPGMailBundle isMountainLion] && ![GPGMailBundle isMavericks])
        indentation = @"";
    else if([GPGMailBundle isMavericks])
        indentation = @"";
    else
        indentation = @"\t";
    NSMutableAttributedString *securityHeader = [NSMutableAttributedString new];
    [securityHeader beginEditing];
    
    NSMutableString *securityHeaderString = [securityHeader mutableString];
    
    if([GPGMailBundle isMavericks]) {
        [securityHeaderString appendFormat:NSLocalizedStringFromTableInBundle(@"MessageHeaderLabelFormat", nil, [NSBundle mainBundle], @""), NSLocalizedStringFromTableInBundle(securityHeaderLabelKey, @"Encryption", [NSBundle mainBundle], @"")];
    }
    else {
        [securityHeaderString appendString:[NSString stringWithFormat:@"%@%@", indentation,
                                            NSLocalizedStringFromTableInBundle(securityHeaderLabelKey, @"Encryption", [NSBundle mainBundle], @"")]];
    }
    
    // Add the encrypted part to the security header.
    if(isPGPEncrypted) {
        NSImage *encryptedBadge = [message PGPDecrypted] ? [NSImage imageNamed:@"NSLockUnlockedTemplate"] : [NSImage imageNamed:@"NSLockLockedTemplate"];
        NSAttributedString *encryptAttachmentString = [NSAttributedString attributedStringWithAttachment:[[NSTextAttachment alloc] init]
                                                                                                   image:encryptedBadge
                                                                                                    link:nil
                                                                                                  offset:0.0];
        if([GPGMailBundle isMavericks])
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@" "]];
        else
            [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:[NSAttributedString headerAttributes]]];
        
        [securityHeader appendAttributedString:encryptAttachmentString];
        
        NSString *encryptedString = [NSString stringWithFormat:@" %@", [message PGPPartlyEncrypted] ? GMLocalizedString(@"MESSAGE_IS_PGP_PARTLY_ENCRYPTED") :
        GMLocalizedString(@"MESSAGE_IS_PGP_ENCRYPTED")];
        if([GPGMailBundle isMavericks])
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:encryptedString]];
        else
            [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:encryptedString attributes:[NSAttributedString headerAttributes]]];
    }
    if(isPGPSigned) {
        NSAttributedString *securityHeaderSignaturePart = [self securityHeaderSignaturePartForMessage:message];
        [self setIvar:@"messageSigners" value:[message PGPSignatures]];
        
        // Only add, if message was encrypted.
        if(isPGPEncrypted) {
            if([GPGMailBundle isMavericks])
                [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];
            else
                [securityHeader appendAttributedString:[[NSAttributedString alloc] initWithString:@", " attributes:[NSAttributedString headerAttributes]]];
        }
        
        [securityHeader appendAttributedString:securityHeaderSignaturePart];
    }
    NSUInteger numberOfPGPAttachments = [message numberOfPGPAttachments];
    // And last but not least, add a new line.
    if(numberOfPGPAttachments) {
        NSAttributedString *securityHeaderAttachmentsPart = [self securityHeaderAttachmentsPartForMessage:message];
        
        if([message PGPSigned] || [message PGPEncrypted])
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];
        [securityHeader appendAttributedString:securityHeaderAttachmentsPart];
    }
    
    return securityHeader;
}

- (NSAttributedString *)securityHeaderAttachmentsPartForMessage:(GM_CAST_CLASS(Message *, id))message {
    BOOL hasEncryptedAttachments = NO;
    BOOL hasSignedAttachments = NO;
    BOOL singular = [message numberOfPGPAttachments] > 1 ? NO : YES;
    
    NSMutableAttributedString *securityHeaderAttachmentsPart = [[NSMutableAttributedString alloc] init];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    [textAttachment setIvar:@"ShowAttachmentPanel" value:@YES];
    [securityHeaderAttachmentsPart appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment image:[NSImage imageNamed:@"attachment_header"] link:[GPGMailBundle isMavericks] ? nil : @"gpgmail://show-attachments" offset:-3.0]];
    
    for(MimePart_GPGMail *attachment in [message PGPAttachments]) {
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
    
    NSString *encryptionString = [NSString stringWithFormat:@"%li %@", (long)[message numberOfPGPAttachments], attachmentPart];
    if([GPGMailBundle isMavericks])
        [securityHeaderAttachmentsPart appendAttributedString:[NSAttributedString attributedStringWithString:encryptionString]];
    else
        [securityHeaderAttachmentsPart appendAttributedString:[[NSAttributedString alloc] initWithString:encryptionString attributes:[NSAttributedString headerAttributes]]];
    
    return securityHeaderAttachmentsPart;
}

- (NSAttributedString *)securityHeaderSignaturePartForMessage:(Message_GPGMail *)message {
    GPGErrorCode errorCode = GPGErrorNoError;
    BOOL errorFound = NO;
    NSImage *signedImage = nil;
    NSSet *signatures = [NSSet setWithArray:message.PGPSignatures];
    
    NSMutableAttributedString *securityHeaderSignaturePart = [[NSMutableAttributedString alloc] init];
    
    for(GPGSignature *signature in signatures) {
        if(signature.status != GPGErrorNoError) {
            errorCode = signature.status;
            break;
        }
    }
    errorFound = errorCode != GPGErrorNoError ? YES : NO;
    
	// Check if MacGPG2 was not found.
	// If that's the case, don't try to append signature labels.
	if(!errorFound) {
		GPGErrorCode __block newErrorCode = GPGErrorNoError;
		[[message PGPErrors] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if([obj isKindOfClass:GM_MAIL_CLASS(@"MFError")]) {
				if(((NSDictionary *)[(MFError *)obj userInfo])[@"VerificationErrorCode"])
					newErrorCode = (GPGErrorCode)[((NSDictionary *)[(MFError *)obj userInfo])[@"VerificationErrorCode"] longValue];
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
    
    if(!errorFound) {
        titlePart = GMLocalizedString(@"MESSAGE_SECURITY_HEADER_SIGNATURE_TITLE");
        signedImage = [NSImage imageNamed:@"SignatureOnTemplate"];
    }
    else {
        signedImage = [NSImage imageNamed:@"SignatureOffTemplate"];
    }
    
    
    if(message.PGPPartlySigned) {
// TODO: Implement different messages for partly signed messages.
        titlePart = GMLocalizedString(@"MESSAGE_IS_PGP_PARTLY_SIGNED");
    }
    
    NSSet *signerLabels = [NSSet setWithArray:[message PGPSignatureLabels]];
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
    else
        [securityHeaderSignaturePart appendAttributedString:[[NSAttributedString alloc] initWithString:signerLabelsString attributes:[NSAttributedString headerAttributes]]];
    
    return securityHeaderSignaturePart;
}

@end

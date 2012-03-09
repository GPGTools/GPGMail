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

@interface NSAttributedString (NSAttributedString_MoreExtensions)

/** 
 * @method allAttachments 
 * @abstract Fetchs all attachments from an NSAttributedString. 
 * @discussion This method searchs for NSAttachmentAttributeName attributes within the string instead of searching for NSAttachmentCharacter characters. 
 */
- (NSArray *)allAttachments;

@end

@implementation NSAttributedString (NSAttributedString_MoreExtensions)
- (NSArray *)allAttachments
{
    NSMutableArray *theAttachments = [NSMutableArray array];
    NSRange theStringRange = NSMakeRange(0, [self length]);
    if (theStringRange.length > 0)
    {
        unsigned long N = 0;
        do
        {
            NSRange theEffectiveRange;
            NSDictionary *theAttributes = [self attributesAtIndex:N longestEffectiveRange:&theEffectiveRange inRange:theStringRange];
            NSTextAttachment *theAttachment = [theAttributes objectForKey:NSAttachmentAttributeName];
            if (theAttachment != NULL)
                [theAttachments addObject:theAttachment];
            N = theEffectiveRange.location + theEffectiveRange.length;
        }
        while (N < theStringRange.length);
    }
    return(theAttachments);
}

@end

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

- (void)_showAttachmentsPanel {
    NSArray *pgpAttachments = ((Message *)[(MessageViewingState *)[((MessageHeaderDisplay *)self) viewingState] message]).PGPAttachments;
    GPGAttachmentController *attachmentController = [[GPGAttachmentController alloc] initWithAttachmentParts:pgpAttachments];
    attachmentController.keyList = [[GPGMailBundle sharedInstance] allGPGKeys];
    [attachmentController beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
//        DebugLog(@"Attachment panel was closed: %d", result);
    }];
    [attachmentController release];
}

- (void)_showSignaturePanel {
    NSArray *messageSigners = [self getIvar:@"messageSigners"];
    if(![messageSigners count])
        return;
    BOOL notInKeychain = NO;
    for(GPGSignature *signature in messageSigners) {
        if(!signature.userID) {
            notInKeychain = YES;
            break;
        }
    }
    if(notInKeychain) {
        NSBundle *gpgMailBundle = [NSBundle bundleForClass:[GPGMailBundle class]];
        NSString *title = NSLocalizedStringFromTableInBundle(@"MESSAGE_ERROR_ALERT_PGP_VERIFY_NOT_IN_KEYCHAIN_TITLE", @"GPGMail", gpgMailBundle, @"");
        NSString *message = NSLocalizedStringFromTableInBundle(@"MESSAGE_ERROR_ALERT_PGP_VERIFY_NOT_IN_KEYCHAIN_MESSAGE", @"GPGMail", gpgMailBundle, @"");
        
        MFError *error = [MFError errorWithDomain:@"MFMessageErrorDomain" code:1035 localizedDescription:message title:title helpTag:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:title, @"_MFShortDescription", message, @"NSLocalizedDescription", nil]];
        NSAlert *alert = [NSAlert alertForError:error defaultButton:@"OK" alternateButton:nil otherButton:nil];
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
    // This is also called if the message is neither signed nor encrypted.
    // In that case the empty string is returned.
    // Internally this method checks the message's messageFlags
    // to determine if the message is signed or encrypted and
    // based on that information creates the encrypted symbol
    // and calls copySingerLabels on the topLevelPart.
    MessageViewingState *viewingState = [((MessageHeaderDisplay *)self) viewingState];
    MimeBody *mimeBody = [viewingState mimeBody];
    Message *message = [viewingState message];
    
    // Check if message should be processed (-[Message shouldBePGPProcessed] - Snippet generation check)
    // otherwise out of here!
    if(![message shouldBePGPProcessed])
        return [self MA_attributedStringForSecurityHeader];
    
    // Check if the securityHeader is already set.
    // If so, out of here!
    if(viewingState.headerSecurityString)
        return viewingState.headerSecurityString;
    
    // Check the mime body, is more reliable.
    BOOL isPGPSigned = message.PGPSigned;
    BOOL isPGPEncrypted = message.PGPEncrypted && ![mimeBody ivarExists:@"PGPEarlyAlphaFuckedUpEncrypted"];
    BOOL hasPGPAttachments = message.numberOfPGPAttachments > 0 ? YES : NO;
    
    if(!isPGPSigned && !isPGPEncrypted && !hasPGPAttachments)
        return [self MA_attributedStringForSecurityHeader];
    
    NSMutableAttributedString *securityHeader = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@\t", NSLocalizedStringFromTableInBundle(@"SECURITY_HEADER", @"Encryption", [NSBundle mainBundle], @"")]];
    [securityHeader addAttributes:[NSAttributedString boldGrayHeaderAttributes] range:NSMakeRange(0, [securityHeader length])];
    
    NSBundle *gpgMailBundle = [NSBundle bundleForClass:[GPGMailBundle class]];
    // Add the encrypted part to the security header.
    if(isPGPEncrypted) {
        NSImage *encryptedBadge = message.PGPDecrypted ? [NSImage imageNamed:@"NSLockUnlockedTemplate"] : [NSImage imageNamed:@"NSLockLockedTemplate"];
        NSString *linkID = message.PGPDecrypted ? nil : @"gpgmail://decrypt";
        NSAttributedString *encryptAttachmentString = [NSAttributedString attributedStringWithAttachment:[[[NSTextAttachment alloc] init] autorelease] 
                                                                                                   image:encryptedBadge
                                                                                                    link:linkID];
        [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@"\t"]];
        [securityHeader appendAttributedString:encryptAttachmentString];
        
        NSString *encryptedString = message.PGPPartlyEncrypted ? NSLocalizedStringFromTableInBundle(@"MESSAGE_IS_PGP_PARTLY_ENCRYPTED", @"GPGMail", gpgMailBundle, @"") : 
                                                                            NSLocalizedStringFromTableInBundle(@"MESSAGE_IS_PGP_ENCRYPTED", @"GPGMail", gpgMailBundle, @""); 
        [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:[NSString stringWithFormat:@" %@", encryptedString]]];
    }
    if(isPGPSigned) {
        NSAttributedString *securityHeaderSignaturePart = [self securityHeaderSignaturePartForMessage:message];
        [self setIvar:@"messageSigners" value:message.PGPSignatures];

        // Only add, if message was encrypted.
        if(isPGPEncrypted)
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];

        [securityHeader appendAttributedString:securityHeaderSignaturePart];
    }
    NSUInteger numberOfPGPAttachments = message.numberOfPGPAttachments;
    // And last but not least, add a new line.
    if(numberOfPGPAttachments) {
        NSAttributedString *securityHeaderAttachmentsPart = [self securityHeaderAttachmentsPartForMessage:message];
        
        if(message.PGPSigned || message.PGPEncrypted)
            [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@", "]];
        [securityHeader appendAttributedString:securityHeaderAttachmentsPart];
    }
    [securityHeader appendAttributedString:[NSAttributedString attributedStringWithString:@"\n"]];
    viewingState.headerSecurityString = securityHeader;
    
    return [securityHeader autorelease];
}

- (NSAttributedString *)securityHeaderAttachmentsPartForMessage:(Message *)message {
    NSBundle *gpgMailBundle = [NSBundle bundleForClass:[GPGMailBundle class]];
    
    BOOL hasEncryptedAttachments = NO;
    BOOL hasSignedAttachments = NO;
    BOOL singular = message.numberOfPGPAttachments > 1 ? NO : YES;
    
    NSMutableAttributedString *securityHeaderAttachmentsPart = [[NSMutableAttributedString alloc] init];
    [securityHeaderAttachmentsPart appendAttributedString:[NSAttributedString attributedStringWithAttachment:[[[NSTextAttachment alloc] init] autorelease] image:[NSImage imageNamed:@"attachment_header"] link:@"gpgmail://show-attachments"]];
    
    
    for(MimePart *attachment in message.PGPAttachments) {
        hasEncryptedAttachments |= attachment.PGPEncrypted;
        hasSignedAttachments |= attachment.PGPSigned;
    }
    
    NSString *attachmentPart = nil;
    
    if(hasEncryptedAttachments && hasSignedAttachments) {
        attachmentPart = (singular ? 
            NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_ATTACHMENT_SIGNED_ENCRYPTED_TITLE", @"GPGMail", gpgMailBundle, @"") : 
            NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_ATTACHMENTS_SIGNED_ENCRYPTED_TITLE", @"GPGMail", gpgMailBundle, @""));
    }
    else if(hasEncryptedAttachments) {
        attachmentPart = (singular ? 
            NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_ATTACHMENT_ENCRYPTED_TITLE", @"GPGMail", gpgMailBundle, @"") : 
            NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_ATTACHMENTS_ENCRYPTED_TITLE", @"GPGMail", gpgMailBundle, @""));
    }
    else if(hasSignedAttachments) {
        attachmentPart = (singular ? 
            NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_ATTACHMENT_SIGNED_TITLE", @"GPGMail", gpgMailBundle, @"") : 
            NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_ATTACHMENTS_SIGNED_TITLE", @"GPGMail", gpgMailBundle, @""));
    }
    
    [securityHeaderAttachmentsPart appendAttributedString:[NSAttributedString attributedStringWithString:[NSString stringWithFormat:@"%d %@", message.numberOfPGPAttachments, attachmentPart]]];
    
    return [securityHeaderAttachmentsPart autorelease];
}

- (NSAttributedString *)securityHeaderSignaturePartForMessage:(Message *)message {
    GPGErrorCode errorCode = GPGErrorNoError;
    BOOL errorFound = NO;
    NSImage *signedImage = nil;
    NSSet *signatures = [NSSet setWithArray:message.PGPSignatures];
    NSBundle *gpgMailBundle = [NSBundle bundleForClass:[GPGMailBundle class]];
    
    NSMutableAttributedString *securityHeaderSignaturePart = [[NSMutableAttributedString alloc] init];
    
    for(GPGSignature *signature in signatures) {
        if(signature.status != GPGErrorNoError) {
            errorCode = signature.status;
            break;
        }
    }
    errorFound = errorCode != GPGErrorNoError ? YES : NO;
    
    NSString *titlePart = nil;
    
    switch (errorCode) {
        case GPGErrorNoPublicKey:
            titlePart = NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_SIGNATURE_NO_PUBLIC_KEY_TITLE", @"GPGMail", gpgMailBundle, @"");
            break;
            
        case GPGErrorCertificateRevoked:
            titlePart = NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_SIGNATURE_REVOKED_TITLE", @"GPGMail", gpgMailBundle, @"");
            break;
            
        case GPGErrorBadSignature:
            titlePart = NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_SIGNATURE_BAD_TITLE", @"GPGMail", gpgMailBundle, @"");
            break;
            
        default:
            titlePart = NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_SIGNATURE_TITLE", @"GPGMail", gpgMailBundle, @"");
            break;
    }
    
    if(!errorFound) {
        titlePart = NSLocalizedStringFromTableInBundle(@"MESSAGE_SECURITY_HEADER_SIGNATURE_TITLE", @"GPGMail", gpgMailBundle, @"");
        signedImage = [NSImage imageNamed:@"SignatureOnTemplate"];
    }
    else {
        signedImage = [NSImage imageNamed:@"SignatureOffTemplate"];
    }
    
    
    if(message.PGPPartlySigned) {
// TODO: Implement different messages for partly signed messages.
        titlePart = NSLocalizedStringFromTableInBundle(@"MESSAGE_IS_PGP_PARTLY_SIGNED", @"GPGMail", gpgMailBundle, @"");
    }
    
    NSSet *signerLabels = [NSSet setWithArray:[message PGPSignatureLabels]];
    NSAttributedString *signedAttachmentString = [NSAttributedString attributedStringWithAttachment:[[[NSTextAttachment alloc] init] autorelease] 
                                                                                              image:signedImage 
                                                                                               link:@"gpgmail://show-signature"];
    
    [securityHeaderSignaturePart appendAttributedString:signedAttachmentString];
    
    NSString *signerLabelsString = [NSString stringWithFormat:@"%@ (%@)", titlePart, 
                                    [[signerLabels allObjects] componentsJoinedByString:@", "]];
    [securityHeaderSignaturePart appendAttributedString:[NSAttributedString attributedStringWithString:signerLabelsString]];
    return [securityHeaderSignaturePart autorelease];
}

@end

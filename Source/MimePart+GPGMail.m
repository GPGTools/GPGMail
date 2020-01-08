/* MimePart+GPGMail.m created by stephane on Mon 10-Jul-2000 */

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
#define restrict
#import <RegexKit/RegexKit.h>
#undef restrict
#import "CCLog.h"
#import "NSData+GPGMail.h"
#import "NSArray+Functional.h"
#import "NSObject+LPDynamicIvars.h"
#import "GPGFlaggedString.h"
#import "GPGException+GPGMail.h"
#import "MimePart+GPGMail.h"
#import "MimeBody+GPGMail.h"
#import "NSString+GPGMail.h"
#import "Message+GPGMail.h"
#import <MCActivityMonitor.h>
#import "NSString-HTMLConversion.h"
//#import <MCMessage.h>
//#import <MessageWriter.h>
//#import <MimeBody.h>
//#import <MutableMessageHeaders.h>
#import "GPGMailBundle.h"

#import "MCMutableMessageHeaders.h"
#import "MCDataAttachmentDataSource.h"
#import "MCAttachment.h"
#import "MCFileTypeInfo.h"

#import "GMMessageSecurityFeatures.h"
#import "MCMessageBody.h"
#import "GMMessageProtectionStatus.h"

#import "NSString-MCFormatFlowedSupport.h"
#import "NSData-HFSDataConversion.h"

#define MAIL_SELF(self) ((MCMimePart *)(self))

extern const NSString *kMimeBodyMessageKey;
NSString * const kMimePartAllowPGPProcessingKey = @"MimePartAllowPGPProcessingKey";

@interface MimePart_GPGMail (NotImplemented2)

- (id)_decodeTextPlain;
- (id)encodedBodyData;
- (id)initWithEncodedData:(id)arg1;
- (void)setDecryptedMimeBody:(id)arg1 isEncrypted:(BOOL)arg2 isSigned:(BOOL)arg3 error:(id)arg4;
- (id)decryptedMimeBody; // @synthesize decryptedMimeBody=_decryptedMimeBody;
- (id)decode;
- (id)dataSource;

@end

@implementation MimePart_GPGMail

/**
 A second attempt to finding messages including PGP data.
 OpenPGP/MIME encrypted/signed messages follow RFC 3156, so those
 messages are no problem to decrypt.

 Inline PGP encrypted/signed messages are a whole other story, since
 there's no standard which describes exactly how to produce them.

 THE THEORY
   * Each message which contains encrypted/signed data is either:
     * One part: text/plain
       * Find data, encrypt it and create a new message with the old message headers
       * Setting the message as the decrypted message.
     * Multi part: multipart/alternative, multipart/mixed
       * Most likely contains a text/html and a text/plain part.
       * Both parts might contain PGP relevant data, but text/html data is
         very hard to process right (it most likely fails.)
       * In that case: ignore the text/html part and simply process the plain part.
         (Users might have a problem with that, but most likely not, since messages including HTML
          should always use OpenPGP/MIME)
 OLD METHOD
   * The old method used several entry points for the different mime types
   * and tried to find pgp data in there.
   * This method often failed, due to compley mime types which needed
   * manual searching and guessing of parts to follow.
   * Useless to say, it wasn't failsafe.

 NEW METHOD
   * The new method performs the following step:
     1.) Check if the message contains the OpenPGP/MIME parts
         * found -> decrpyt the message, return the decrypted message.
         Heck this was easy!
     2.) Check if the message contains any PGP inline data.
         * not found -> call Mail.app's original method and let Mail.app to the heavy leaving.
         * found -> follow step 3
     3.) Loop through every mime part of the message (recursively) and
         find text/plain parts.
     4.) Check each text/plain part if it contains PGP inline data.
         If it does, store its address (or better the mime part object?) in a
         dynamic ivar on the message.
     5.) Check for each subsequent call of decodeWithContext if the current mime part
         matches a found encrypted part.
         * found -> decrypt the part, flag the message as decrypted, build a new decrypted message with the original headers
                    and return that to Mail.app.

     Since Mail.app calls decodeWithContext recursively, at the end of the cycle
     it comes back to the topLevelPart.

     6.) When Mail.app returns to the topLevelPart and no decrypted part was found,
         even though GPGMail knows there was a part which contains PGP data, this means two things:
         1.) Something went wrong (sorry for that ...)
         2.) The message was a multipart message and contains a HTML part, which was chosen
             as the preferred part, due to a setting in Mail.app.
             In that case, decodeWithContext: is never called on the text/plain mime part.

         If the second thing holds true, GPGMail fetches the mime part which is supposed
         to include the PGP data, processes it and returns the result to Mail.app.

    * The advantage of the new method is that it completely ignores complex mime types,
      making the whole decoding process more reliable.

 NEW METHOD 2
   * Well, NEW METHOD is not really suitable, since it completely replaces multipart/mixed
     messages with only the decrypted part, which wouldn't allow to have non-encrypted
     attachments.
 
   The steps which actually make sense are the following:
   
   1.) Directly in decodeWithContext: only check for multipart/encrypted.
       If found, proceed decrypting the application/octet part and replacing
       the whole message with the decrypted data, which must contain a valid
       RFC 822 compliant message including all relevant headers.
   
   2.) Use the hook in decodeTextHtml and decodeTextPart
     
     2.1) Check if the part is decoded with base64. If so decode it.
     2.1) Check the part data for PGP signatures or PGP encrypted data.
     2.2) Decrypt the part data.
     2.2) Replace the encrypted data with the decrypted data (for either the html or text part)
     2.3) Cache the complete data just like the decrypted message body would
          be cached.
     2.4) DON'T REPLACE THE MESSAGE BODY but
          return the complete data
     2.5) Let Mail.app work it's magic for the rest
          of the message.
 
 */

- (id)MA_decode {
    if(![(MimePart_GPGMail *)self shouldBePGPProcessed]) {
        return [self MA_decode];
    }
    
    // Bug #961: EFAIL
    //
    // Since for a long time there's been no standardized way to structure
    // OpenPGP messages, OpenPGP data might be found in any non-multipart/ or non-message/
    // mime part.
    // In order to be as compatible as possible with the different structures
    // possible for OpenPGP messages, PGP data is handled right here in the
    // -[MCMimePart _decode] method, which is called for the top part and every
    // child mime part child except multipart/ and message/
    // In the past, hooks into the specific decode<ContentType> methods were used,
    // which resulted in less readable code and more error prone handling.
    //
    // If a part doesn't contain any PGP data, the original -[MCMimePart _decode]
    // method is invoked.
    //
    // The return value of -[MCMimePart _decode] is one of the following:
    // - NSString -> simple HTML string
    // - MCAttachment -> an attachment which is referenced via <object> tag
    // - MCMessageBody -> the content of a decrypted message.
    //
    // Mail internally concatenates all these values to the final HTML
    // which is also why "efail" (https://efail.de) is so hard to mitigate
    // against.
    //
    // The GMMessageProtectionStatus will be updated for each non-multipart
    // mime part visited by Mail in order to determine if the message
    // is secure (encrypted or signed) in its entirety. This information
    // is crucial to mitigate against "efail"-style-attacks.
    //
    // GMContentPartsIsolator is used to register content parts which should
    // be isolated. Any content that is not marked to be isolated, is put into
    // an iframe. This method makes sure, that no decrypted content can leak.
    MCMimePart *mailself = MAIL_SELF(self);
    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];
    GMContentPartsIsolator *contentIsolator = [self GMContentPartsIsolator];
    id content = nil;
    
    // PGP-Partitioned-Content is an especially evil thing.
    // It contains a PGPexch.htm.pgp attachment which is the alternative part to the
    // text/plain part. So it is necessary to merge that part into a possible
    // multipart/alternative part.
    // However it is also possible, that no multipart/alternative part is available
    // in which case the PGPExch.htm.pgp part replaces any text part before it.
    if(![MAIL_SELF(self) parentPart]) {
        [self GMRemoveContentIDFromTextParts];
        [self GMTransformMimeTreeForPGPPartitionedIfNecessary];
    }
    
    if(([mailself isType:@"multipart" subtype:nil] || [mailself isType:@"message" subtype:nil]) && ![self GMIsEncryptedPGPMIMETree] && ![self GMIsSignedPGPMIMETree]) {
        content = [self MA_decode];
    }
    else {
        BOOL isPGPDataAvailable = [self GMPartMightContainPGPData];
        // If GMWrappedInPGPMIMEEncryptedMessage is set it means
        // that this is the decoding procedure of the decrypted contents of
        // a PGP/MIME encrypted message. In that case, do not process any PGP data.
        // multipart/signed is already handled in verify signature.
        if(isPGPDataAvailable && ![[[self topPart] getIvar:@"GMWrappedInPGPMIMEEncryptedMessage"] boolValue]) {
            content = [self GMContentForPartContainingPGPData];
        }
        if(!isPGPDataAvailable || !content) {
            if(!isPGPDataAvailable) {
                [messageProtectionStatus.plainParts addObject:mailself];
            }
            content = [self MA_decode];
        }
    }
    if(![mailself parentPart] && ([content isKindOfClass:[MCMessageBody class]] || [content isKindOfClass:[NSString class]])) {
        NSString *isolatedContent = [contentIsolator isolatedContentForDecodedContent:content];
        if([content isKindOfClass:[MCMessageBody class]]) {
            [content setHtml:isolatedContent];
        }
        else {
            content = isolatedContent;
        }
    }
    return content;
}

- (MCMimePart *)GMPreviousSiblingPart {
    MCMimePart *parentPart = [MAIL_SELF(self) parentPart];
    if(!parentPart) {
        return nil;
    }
    if([parentPart firstChildPart] == self) {
        return parentPart;
    }
    for(MCMimePart *currentPart in [parentPart  subparts]) {
        if([currentPart nextSiblingPart] == MAIL_SELF(self)) {
            return currentPart;
        }
    }
    return nil;
}
               
- (id)MA_decodeTextHtml {
    if(![self shouldBePGPProcessed] || ![[self getIvar:@"MimePartIsPGPPartitionedEncodingReplacedHTMLPart"] boolValue]) {
        return [self MA_decodeTextHtml];
    }
    return [self GMContentForPlainTextPart];
}

#pragma mark - Content Parts Isolator Delegate

- (NSString *)contentPartsIsolator:(GMContentPartsIsolator *)isolator alternativeContentForIsolatedPart:(GMIsolatedContentPart *)isolatedPart messageBody:(MCMessageBody *)messageBody {
    MimePart_GPGMail *mimePart = (MimePart_GPGMail *)isolatedPart.mimePart;
    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];

    // If the mime part is an attachment
    if((mimePart.PGPEncrypted && mimePart.PGPAttachment) || [(MCMimePart *)mimePart isAttachment]) {
        return isolatedPart.content;
    }

    NSUInteger nrOfEncryptedPartsThatAreNotAttachments = 0;
    for(MimePart_GPGMail *currentPart in [[mimePart GMMessageProtectionStatus] encryptedParts]) {
        if(!currentPart.PGPAttachment) {
            nrOfEncryptedPartsThatAreNotAttachments++;
        }
    }

    if(messageBody && mimePart.PGPEncrypted && nrOfEncryptedPartsThatAreNotAttachments > 1) {
        // Insert an attachment instead of the item content.
        MCAttachment *attachment = [mimePart GMEncryptedPartAsMessageAttachment];
        NSString *attachmentMarkup = [(MCMimePart *)mimePart htmlStringForMimePart:nil attachment:attachment];
        NSMutableDictionary *attachmentsByURL = [[messageBody attachmentsByURL] mutableCopy];
        [attachmentsByURL setValue:attachment forKey:[NSString newURLForContentID:[attachment contentID] percentEscaped:NO]];
        [messageBody setAttachmentsByURL:attachmentsByURL];
        return attachmentMarkup;
    }
    if((self.PGPEncrypted && !messageProtectionStatus.completeMessageIsEncrypted) || (self.PGPSigned && !messageProtectionStatus.completeMessageIsSigned)) {
        return [self protectedContentMarkupForContent:isolatedPart.content mimePart:(MCMimePart *)mimePart];
    }
    return isolatedPart.content;
}

- (BOOL)isContentThatNeedsIsolationAvailableForContentPartsIsolator:(GMContentPartsIsolator *)isolator {
    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];
    if(messageProtectionStatus.completeMessageIsSigned || messageProtectionStatus.completeMessageIsEncrypted || messageProtectionStatus.messageIsUnprotected || messageProtectionStatus.messageContainsOnlyProtectedAttachments) {
        return NO;
    }
    return YES;
}

- (NSString *)protectedContentMarkupForContent:(NSString *)content mimePart:(MCMimePart *)mimePart {
    NSMutableString *partString = [NSMutableString string];
    BOOL isEncrypted = [(MimePart_GPGMail *)mimePart PGPEncrypted];
    BOOL isSigned = [(MimePart_GPGMail *)mimePart PGPSigned];
    MimePart_GPGMail *decryptedMimePart = [(MimePart_GPGMail *)mimePart decryptedTopLevelMimePart];
    if([decryptedMimePart GMMessageProtectionStatus].completeMessageIsSigned) {
        isSigned = YES;
    }

    if(isEncrypted)
        [partString appendString:GMLocalizedString(@"MESSAGE_VIEW_PGP_PART_ENCRYPTED")];
    if(isEncrypted && isSigned)
        [partString appendString:@" & "];
    if(isSigned)
        [partString appendString:GMLocalizedString(@"MESSAGE_VIEW_PGP_PART_SIGNED")];

    [partString appendFormat:@" %@", GMLocalizedString(@"MESSAGE_VIEW_PGP_PART")];

    content = [[[NSString stringWithFormat:@"<div class=\"protected-part\"><div class=\"protected-title\">%@</div><div class=\"protected-content\">", partString] stringByAppendingString:content] stringByAppendingString:@"</div></div><br>"];

    return content;
}

- (GMContentPartsIsolator *)GMContentPartsIsolator {
    MCMimePart *parentPart = [MAIL_SELF(self) parentPart];
    BOOL isTopLevelPart = parentPart == nil;

    GMContentPartsIsolator *contentIsolator = [[self topPart] getIvar:@"GMContentPartsIsolator"];
    if(isTopLevelPart && !contentIsolator) {
        contentIsolator = [GMContentPartsIsolator new];
        [[self topPart] setIvar:@"GMContentPartsIsolator" value:contentIsolator];
    }
    else {
        NSAssert(contentIsolator != nil, @"No content parts isolator was initialized.");
    }

    return contentIsolator;
}

- (GMMessageProtectionStatus *)GMMessageProtectionStatus {
    MCMimePart __strong *parentPart = [MAIL_SELF(self) parentPart];
    BOOL isTopLevelPart = parentPart == nil;
    // The MimeTreeSecurityState will be updated for each non-multipart
    // mime part visited by Mail in order to determine if the message
    // is secure (encrypted or signed) in its entirety. This information
    // is crucial to mitigate against "efail"-style-attacks.
    GMMessageProtectionStatus *messageProtectionStatus = [[self topPart] getIvar:@"GMMessageProtectionStatus"];
    if(isTopLevelPart && !messageProtectionStatus) {
        messageProtectionStatus = [GMMessageProtectionStatus new];
        [[self topPart] setIvar:@"GMMessageProtectionStatus" value:messageProtectionStatus];
    }
    else {
        NSAssert(messageProtectionStatus != nil, @"No mime tree security state was initialized. That's a problem");
    }

    return messageProtectionStatus;
}

- (void)GMRemoveContentIDFromTextParts {
    // As a mitigation against EFAIL kind of attacks, remove Content-ID property
    // of each mime part that is of content type text.
    if(![self mightContainPGPData]) {
        return;
    }

    [self enumerateSubpartsWithBlock:^(MCMimePart *currentPart) {
        if([currentPart isType:@"text" subtype:nil] && [[currentPart contentID] length]) {
            [currentPart setContentID:nil];
        }
    }];
}

- (void)GMTransformMimeTreeForPGPPartitionedIfNecessary {
    if([[GPGMailBundle sharedInstance] shouldNotConvertPGPPartitionedMessages]) {
        return;
    }

    __block MCMimePart *PGPExchPart = nil;
    [self enumerateSubpartsWithBlock:^(MCMimePart *currentPart) {
        if([[[MAIL_SELF(currentPart) attachmentFilename] lowercaseString] isEqualToString:@"pgpexch.htm.pgp"] ||
           [[[MAIL_SELF(currentPart) attachmentFilename] lowercaseString] isEqualToString:@"pgpexch.htm.asc"]) {
            PGPExchPart = currentPart;
            return;
        }
    }];
    
    __block MCMimePart *alternativePart = nil;
    __block MCMimePart *htmlPart = nil;
    
    if(PGPExchPart) {
        [self enumerateSubpartsWithBlock:^(MCMimePart *currentPart) {
            MCMimePart *parentPart = [currentPart parentPart];
            if([currentPart isType:@"text" subtype:@"html"] && [parentPart isType:@"multipart" subtype:@"alternative"]
               && [[parentPart subparts] count] == 2) {
                alternativePart = parentPart;
                htmlPart = currentPart;
            }
        }];
        BOOL isReplacementForAlternativePart = alternativePart && htmlPart;
        BOOL shouldRemovePGPExecPart = NO;
        MCMimePart *previousPart = [(MimePart_GPGMail *)PGPExchPart GMPreviousSiblingPart];
        BOOL isReplacementForMixedPart = !isReplacementForAlternativePart && [previousPart isType:@"text" subtype:@"plain"] && [[previousPart parentPart] isType:@"multipart" subtype:@"mixed"];
        if(isReplacementForMixedPart || isReplacementForAlternativePart) {
            // If an HTML Part and a multipart/alternative parent part is found,
            // the PGPExchPart effectively is supposed to replace the HTML part.
            // Otherwise if its previous part
            [PGPExchPart setType:@"text"];
            [PGPExchPart setSubtype:@"html"];
            [PGPExchPart setDisposition:nil];
            [[PGPExchPart valueForKey:@"_otherIvars"] setValue:[@{} mutableCopy] forKey:@"x-disposition-parameters"];
            [PGPExchPart setIvar:@"MimePartIsPGPPartitionedEncodingReplacedHTMLPart" value:@(YES)];
            
            if(isReplacementForAlternativePart) {
                for(MCMimePart *currentPart in [alternativePart subparts]) {
                    if([currentPart valueForKey:@"_nextPart"] == htmlPart) {
                        [currentPart setValue:PGPExchPart forKey:@"_nextPart"];
                        [PGPExchPart setValue:[htmlPart valueForKey:@"_nextPart"] forKey:@"_nextPart"];
                    }
                }
                [htmlPart setValue:nil forKey:@"_nextPart"];
                shouldRemovePGPExecPart = YES;
            }
            else if(isReplacementForMixedPart) {
                // There's another very odd version of this, where there are two multipart/mixed parts,
                // but the one with the PGPExchPart should actually be a multipart/alternative part,
                // in which case the multipart type is changed in addition to changing the type of the
                // PGPExchPart to text/html.
                MCMimePart *parentPart = [PGPExchPart parentPart];
                // Bug #1012: Support more strange PGP-Partitioned structures.
                // There's yet another version, where there is only a single multipart/mixed part, which
                // should be a multipart/alternative part instead, with a text/plain and an attachment part.
                // The attachment part should be the text/html part.
                if([parentPart isType:@"multipart" subtype:@"mixed"] && [[parentPart subparts] count] == 2 && ![parentPart parentPart] && ([[PGPExchPart nextSiblingPart] isType:@"text" subtype:@"plain"] || [[(MimePart_GPGMail *)PGPExchPart GMPreviousSiblingPart] isType:@"text" subtype:@"plain"])) {
                    [parentPart setSubtype:@"alternative"];
                }
                else if([[parentPart parentPart] isType:@"multipart" subtype:@"mixed"]) {
                    [parentPart setSubtype:@"alternative"];
                }
                else {
                    [[(MimePart_GPGMail *)previousPart GMPreviousSiblingPart] setValue:PGPExchPart forKey:@"_nextPart"];
                    shouldRemovePGPExecPart = YES;
                }
            }
            
            if(shouldRemovePGPExecPart) {
                // Now find the PGPExchPart and remove it.
                [self enumerateSubpartsWithBlock:^(MCMimePart *currentPart) {
                    MCMimePart *parentPart = [currentPart parentPart];
                    if([currentPart valueForKey:@"_nextPart"] == PGPExchPart && parentPart != alternativePart) {
                        [currentPart setValue:[PGPExchPart valueForKey:@"_nextPart"] forKey:@"_nextPart"];
                    }
                }];
            }
        }
    }
}

- (id)GMContentForPartContainingPGPData {
    MCMimePart *mailself = MAIL_SELF(self);
    id content = nil;

    // In order to mitigate against the part of the efail attack, where
    // an attacker includes multiple encrypted parts in one message, in
    // order to have the contents of all these parts decrypted and sent
    // to a controlled server or included in a controlled reply message (
    // hidden using CSS), only one encrypted part is acceptable. Once one
    // encrypted part was decrypted, any further parts will not be processed.
    if([self GMIsEncryptedPGPMIMETree]) {
        content = [self GMContentForEncryptedPGPMIMETree];
        return content;
    }

    if([self GMIsSignedPGPMIMETree]) {
        content = [self GMContentForSignedPGPMIMETree];
        return content;
    }

    // In case a PGP/MIME message fails to decrypt, no content is returned.
    // As consequence, Mail proceeds to parse each part, which leads to this
    // check.
    if([(MimePart_GPGMail *)[mailself parentPart] GMIsEncryptedPGPMIMETree]) {
        return nil;
    }
    // Handle PGP in text/html. This is special case. See
    // -[MimePart_GPGMail GMContentForHTMLPart] for details.
    if([mailself isType:@"text" subtype:@"html"]) {
        content = [self GMContentForHTMLPart];
        return content;
    }

    // Handle inline PGP in text/plain, application/pgp, application/pgp-encrypted.
    // All of these mime content types are used for either inline PGP data or
    // PGP attachments by different OpenPGP plugins. See #911, #938 and #939.
    //
    // Bug #938: iPGMail is not capable of creating a proper PGP/MIME structure due to restrictions of iOS
    // Since the application/pgp-encrypted content-type can be used for any pgp encrypted attachment,
    // GPGMail currently treats it as an attachment, where it should display the contents of the attachment
    // as another text/html part of the message.
    //
    // Bug #939: Mailvelope seems to use text/plain and application/pgp for
    // PGP encrypted attachments. In order to handle these attachment properly,
    // only treat as text part if it's not an attachment.
    //
    BOOL isAttachment = [mailself isAttachment];
    if([self isPseudoPGPMimeTextPartFromiPGMail] ||
       (!isAttachment && ([mailself isType:@"text" subtype:@"plain"] ||
                          [mailself isType:@"application" subtype:@"pgp"]))) {
        content = [self GMContentForPlainTextPart];
        return content;
    }

    // Everything else should be a PGP attachment.
    if(isAttachment) {
        content = [self GMContentForAttachmentPart];
        return content;
    }

    return nil;
    //return @"Yes! This message contains encrypted data!!!";
}

- (MCMessageBody *)GMContentForEncryptedPGPMIMETree {
    MCMimePart *mailself = MAIL_SELF(self);
    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];
    GMContentPartsIsolator *contentIsolator = [self GMContentPartsIsolator];
    id content = nil;

    BOOL containsEncryptedParts = messageProtectionStatus.containsEncryptedParts;
    [messageProtectionStatus.encryptedParts addObject:mailself];

    // Only decrypt if no other content has been decrypted already.
    // See -[MimePart_GPGMail GMContentForPartContainingPGPData] for more info.
    if(!containsEncryptedParts) {
        MCMimePart *decryptedTopLevelPart = [self decodeMultipartEncryptedWithContext:nil];
        // Maybe this should happen in decryptData.
        if(decryptedTopLevelPart) {
            // Add PGP information from mime parts.
            [decryptedTopLevelPart setIvar:@"kMimePartAllowPGPProcessingKey" value:@(YES)];
            [decryptedTopLevelPart setIvar:@"GMWrappedInPGPMIMEEncryptedMessage" value:@(YES)];
            id decryptedContent = [decryptedTopLevelPart _decode];
            MCMessageBody *body = [decryptedTopLevelPart messageBody];
            [(MimePart_GPGMail *)[self topPart] setDecryptedTopLevelMimePart:decryptedTopLevelPart];
            content = body;
            
            // Bug #987: PGP/MIME encrypted and signed message are recognized as partially encrypted
            //           - signature not shown
            //
            // To handle this case, the PGP/MIME tree part is added to the signed parts
            // as well if its signed status is set to YES and signatures are available.
            if([self PGPSigned] && [[self PGPSignatures] count]) {
                [messageProtectionStatus.signedParts addObject:mailself];
            }
            
            // If content is no attachment, flag the content and part as isolated.
            NSString *isolatedContent = [contentIsolator isolationMarkupForContent:[body html] mimePart:MAIL_SELF(self)];
            [content setHtml:isolatedContent];
        }
    }
    else {
        // In order to still allow the user easy access to the encrypted parts though,
        // if they were legitimate, each part is encoded as a new message/rfc822 part
        // and displayed as an attachment.
        content = [self GMEncryptedPartAsMessageAttachment];
    }

    return content;
}

- (id)GMContentForSignedPGPMIMETree {
    MCMimePart *mailself = MAIL_SELF(self);
    id content = [MAIL_SELF(self) decodeMultipartSigned];
    content = [MAIL_SELF(self) _messageBodyFromDecodedContents:content];
    if(self.PGPError) {
        [content setSmimeError:self.PGPError];
    }
    GMContentPartsIsolator *contentIsolator = [self GMContentPartsIsolator];
    NSString *isolatedContent = [contentIsolator isolationMarkupForContent:[content html] mimePart:MAIL_SELF(self)];
    [content setHtml:isolatedContent];
    return content;
}

- (NSString *)MAHtmlStringForMimePart:(MCMimePart *)mimePart attachment:(MCAttachment *)attachment {
    if(![(MimePart_GPGMail *)self shouldBePGPProcessed] || [[[self topPart] getIvar:@"GMWrappedInPGPMIMEEncryptedMessage"] boolValue]) {
        return [self MAHtmlStringForMimePart:mimePart attachment:attachment];
    }
    NSString *htmlString = [self MAHtmlStringForMimePart:mimePart attachment:attachment];
    // Since those bloody fuckers at Apple don't like to use their own methods,
    // it is possible the the html string looks like on of these two versions:
    //
    // <object data="cid:XXX" type=application/x-apple-msg-attachment></object>
    // OR
    // <object data="cid:XXX" type="application/x-apple-msg-attachment"></object>
    //
    // The difference being only the type to be wrapped in quotes the one time
    // but the other not. (The second version is implemented in a block within
    // -[MCMimePart _decodeMultipartRelated].
    //
    // Since this creates problems for the content part isolator, we adjust the
    // html string to always use quotes for the type.
    if([htmlString rangeOfString:@"type=application/x-apple-msg-attachment"].location != NSNotFound) {
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"type=application/x-apple-msg-attachment" withString:@"type=\"application/x-apple-msg-attachment\""];
    }
    // It is necessary to set the represented attachment here, in order to be able
    // to remove it later in case of a detached signature.
    if([@[@"pgp", @"asc", @"gpg"] containsObject:[[attachment filename] pathExtension]]) {
        [mimePart setIvar:@"GMRepresentedAttachment" value:attachment];
    }
    GMContentPartsIsolator *contentIsolator = [self GMContentPartsIsolator];
    // PGP attachments are already scheduled for isolation within -[Mimeart_GPGMail GMContentForEncryptedAttachmentPart]
    // so there's no need to isolate them again in here.
    if(![contentIsolator containsIsolatedMimePart:mimePart]) {
        [contentIsolator isolateAttachmentContent:htmlString mimePart:mimePart];
    }
    return htmlString;
}

- (MCAttachment *)GMEncryptedPartAsMessageAttachment {
    MCMimePart *mailself = MAIL_SELF(self);
    NSMutableData *messageData = [[NSMutableData alloc] init];
    [messageData appendData:[mailself headerData]];
    [messageData appendData:[mailself encodedBodyData]];

    MCMimePart *messagePart = [[MCMimePart alloc] init];
    messagePart.type = @"message";
    messagePart.subtype = @"rfc822";
    messagePart.disposition = @"attachment";
    messagePart.contentLength = [messageData length];
    [messagePart setDispositionParameter:@"Encrypted Part.eml" forKey:@"filename"];

    MCAttachment *attachment = [[MCAttachment alloc] initWithMimePart:messagePart];
    [attachment setDataSource:[[MCDataAttachmentDataSource alloc] initWithData:messageData]];

    return attachment;
}

#pragma mark Methods that determine if PGP Processing is allowed.
- (BOOL)shouldBePGPProcessed {
    // Components are missing? What to do...
    //    if([[GPGMailBundle sharedInstance] componentsMissing])
    //        return NO;
    BOOL allowPGPProcessing = [[[self topPart] getIvar:kMimePartAllowPGPProcessingKey] boolValue];
    if(!allowPGPProcessing) {
        return NO;
    }

    // OpenPGP is disabled for reading? Return false.
    if(![[GPGOptions sharedOptions] boolForKey:@"UseOpenPGPForReading"]) {
        allowPGPProcessing = NO;
    }

    // If this is a subpart of a message/rfc822 or message/partial part,
    // don't process either (for now...)
    MCMimePart *currentPart = (MCMimePart *)self;
    while(currentPart) {
        if([currentPart isType:@"message" subtype:nil]) {
            // Bug #992: Add support for inline message/rfc822 if it contains a PGP/MIME encrypted message.
            //
            // Some companies apparently think it's necessary to add their legal disclaimer on top of the
            // encrypted message and wrap the encrypted message in a message/rfc822 part.
            if([self GMShowMessageSubMimePartsAsAttachment]) {
                [currentPart setDisposition:@"attachment"];
                [currentPart setDispositionParameter:@"Original message.eml" forKey:@"filename"];
                return NO;
            }
            else {
                BOOL containsPGPMIMEPart = [currentPart isType:@"message" subtype:@"rfc822"] && [[currentPart firstChildPart] isType:@"multipart" subtype:@"encrypted"];
                if(!containsPGPMIMEPart) {
                    [[(MimePart_GPGMail *)currentPart topPart] setIvar:kMimePartAllowPGPProcessingKey value:@(NO)];
                    return NO;
                }
            }
        }
        currentPart = [currentPart parentPart];
    }

    // Snippet creation is no longer allowed. If it is to be re-introduced,
    // a separate flag will be made available to determine, if the message
    // is decoded in order to create the snippet, and only then, PGP processing
    // is allowed.
    return allowPGPProcessing;
}

#pragma mark TNEF/Winmail.dat Mime Part Helpers

- (MCMimePart *)mimePartWithTNEFAttachmentContainingSignedMessage {
	MCMimePart * __block tnefPart = nil;
	
	[self enumerateSubpartsWithBlock:^(MCMimePart *part) {
		if(![[[part type] lowercaseString] isEqualToString:@"application"])
			return;
		
		if(![[[part subtype] lowercaseString] isEqualToString:@"ms-tnef"] &&
		   ![[[part bodyParameterForKey:@"name"] lowercaseString] isEqualToString:@"winmail.dat"] &&
		   ![[[part bodyParameterForKey:@"name"] lowercaseString] isEqualToString:@"win.dat"])
			return;
		
		// Last but not least, let's look into the body, to find multipart/signed.
		NSData *bodyData = [part decodedData];
        
		NSData *searchData = [@"multipart/signed" dataUsingEncoding:NSASCIIStringEncoding];
		if([bodyData rangeOfData:searchData options:0 range:NSMakeRange(0, [bodyData length])].location == NSNotFound)
			return;
		
		tnefPart = part;
	}];
	
	return tnefPart;
}

- (BOOL)GMShowMessageSubMimePartsAsAttachment {
    // By default message/rfc822 is presented inline, but that's not what
    // we want in case of PGP/MIME encrypted messages. So based on the default,
    // the message will either be displayed inline or as attachment.
    //
    // This feature can be enabled using:
    //
    // `defaults write org.gpgtools.gpgmail ShowMessageSubMimePartsAsAttachment -bool YES`
    return [[[GPGOptions sharedOptions] valueForKey:@"ShowMessageSubMimePartsAsAttachment"] boolValue];
}

- (id)decodeApplicationMS_tnefWithContext:(id)ctx {
	// TNEF decoding is inspired by tnefparser python extension.
	NSData *bodyData = [MAIL_SELF(self) decodedData];
	
	NSUInteger (^bytesToInt)(NSData *) = ^(NSData *data) {
		const char *bytes = [data bytes];
		NSUInteger n = 0, num = 0;
		
		for(NSUInteger i = 0; i < [data length]; i++) {
			uint8_t byte = bytes[i];
			num += (NSUInteger)(byte << n);
			n += 8;
		}
		return num;
	};
	
	// Some TNEF constants.
	NSUInteger tnefSignature = 0x223e9f78;
	NSUInteger tnefAttachmentRenderingData = 0x9002;
	NSUInteger tnefAttachmentData = 0x800f;
	NSUInteger tnefLevelAttachment = 0x02;
	NSUInteger offset = 0;
	
	// Verify the signature. If it doesn't match, out of here.
	NSUInteger signature = bytesToInt([bodyData subdataWithRange:NSMakeRange(offset, 4)]);
	if(signature != tnefSignature)
		return nil;
	
	NSMutableArray *attachments = [[NSMutableArray alloc] init];
	offset = 6;
	
	NSUInteger dataLength = [bodyData length];
	/* Temporarily store the data of an attachment. */
	NSMutableData *attachmentData = nil;
	
	// For some reason, the internal objects might not all
	// be complete objects. So it might happen, subdataWithRange receives
	// an invalid range and raises an exception.
	// We'll simply catch that exception and ignore it.
	@try {
		while(offset < (dataLength - 7)) {
			NSData *tnefObject = [bodyData subdataWithRange:NSMakeRange(offset, dataLength - offset)];
			NSUInteger internalOffset = 0;
			// Get the object level.
			NSUInteger level = bytesToInt([tnefObject subdataWithRange:NSMakeRange(internalOffset, 1)]);
			// Get the object name. Only attachments are of interest.
			internalOffset += 1;
			NSUInteger name = bytesToInt([tnefObject subdataWithRange:NSMakeRange(internalOffset, 2)]);
			// Get the object length.
			internalOffset += 4;
			NSUInteger length = bytesToInt([tnefObject subdataWithRange:NSMakeRange(internalOffset, 4)]);
			// Get the object data.
			internalOffset += 4;
			NSData *objectData = [tnefObject subdataWithRange:NSMakeRange(internalOffset, length)];
			
			// Length of the entire tnefObject.
			internalOffset += length + 2;
			NSUInteger tnefObjectLength = internalOffset;
			
			// Forward the offset to the next tnefObject.
			offset += tnefObjectLength;
			
			// Only attachments are of interest.
			if(name != tnefAttachmentRenderingData && level != tnefLevelAttachment)
				continue;
			
			// Now name matches tnefAttachmentRenderingData, initialize
			// a new attachment data.
			if(name == tnefAttachmentRenderingData) {
				if(attachmentData != nil) {
					[attachments addObject:attachmentData];
					attachmentData = nil;
				}
				attachmentData = [[NSMutableData alloc] init];
			}
			else if(level == tnefLevelAttachment && name == tnefAttachmentData) {
				[attachmentData appendData:objectData];
			}
		}
	}
	@catch (id exception) {
		if(!([exception isKindOfClass:[NSRangeException class]] && [exception isEqualToString:NSRangeException]))
			@throw exception;
	}
		
	if(attachmentData != nil)
		[attachments addObject:attachmentData];
	
	NSData *signedAttachment = nil;
	NSData *multipartSignedData = [@"multipart/signed" dataUsingEncoding:NSASCIIStringEncoding];
	NSData *pgpSignature = [@"pgp-signature" dataUsingEncoding:NSASCIIStringEncoding];
	
	for(NSData *signedData in attachments) {
		if([signedData rangeOfData:multipartSignedData options:0 range:NSMakeRange(0, [signedData length])].location != NSNotFound ||
		   [signedData rangeOfData:pgpSignature options:0 range:NSMakeRange(0, [signedData length])].location != NSNotFound) {
			signedAttachment = signedData;
			break;
		}
	}
	
	// If attachment data doesn't contain multipart/signed nor application/pgp-signature,
	// return nil;
	if(!signedAttachment)
		return nil;
	
	// Otherwise let's create a new message now.
	MCMessage *signedMessage = [GM_MAIL_CLASS(@"Message") messageWithRFC822Data:signedAttachment sanitizeData:YES];
//    MCMimeBody *messageBody = [MCMimeBody new];
    MCMimePart *topLevelPart = [[MCMimePart alloc] initWithEncodedData:signedMessage];
//    [messageBody setTopLevelPart:topLevelPart];
    if(![topLevelPart parse])
        return nil;
//    [signedMessage setMessageInfoFromMessage:[(MimeBody_GPGMail *)[self mimeBody] message]];
//    // TODO: Find out how to get to the mimeBody.
//    MCMimeBody *messageBody = [signedMessage mimeBody];
	
	// It's necessary to temporarily store this message, so it's retained,
	// otherwise it will be released to early.
    [[self topPart] setIvar:@"TNEFDecodedMessage" value:signedMessage];
    
    return topLevelPart;
//    return messageBody;
}

#pragma mark Mime Part Helpers

- (void)enumerateSubpartsWithBlock:(void (^)(MCMimePart *))partBlock {
    __block void (^walkParts)(MCMimePart *);
    __block void (^__weak weakWalkParts)(MCMimePart *);
	
	walkParts = ^(MCMimePart *currentPart) {
        typeof(walkParts) __strong strongWalkParts = weakWalkParts;
		
		partBlock(currentPart);
        for(MCMimePart *tmpPart in [currentPart subparts]) {
            NSAssert(strongWalkParts != NULL && strongWalkParts != nil, @"BUG! strongWalkParts should not be nil");
			strongWalkParts(tmpPart);
        }
    };
    weakWalkParts = walkParts;
	walkParts((MCMimePart *)self);
}

- (MCMimePart *)topPart {
    MCMimePart *parentPart = [MAIL_SELF(self) parentPart];
    MCMimePart *currentPart = parentPart;
    if(parentPart == nil)
        return (MCMimePart *)self;
    
    do {
        if([currentPart parentPart] == nil)
            return currentPart;
    }
    while((currentPart = [currentPart parentPart]));
    
    return nil;
}

- (BOOL)GMAnyParentMatchesType:(NSString *)type subtype:(NSString *)subtype {
    MCMimePart *parent = [MAIL_SELF(self) parentPart];
    while(parent) {
        if([parent isType:type subtype:subtype]) {
            return YES;
        }
        parent = [parent parentPart];
    }

    return NO;
}

#pragma mark Mime Part Decode Helpers

- (id)GMContentForPlainTextPart {
    // Check if the part is base64 encoded. If so, decode it.
    NSData *partData = [self GMBodyData];
    NSData *decryptedData = nil;

    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];

    // rangeOfString on nil returns a NSRange with {location=0, length=0} which
    // leads to GPGMail thinking the data might contain encrypted or signed data markers.
    // So in that case, simply return nil.
    if(!partData) {
        return nil;
    }

    NSRange encryptedRange = [partData rangeOfPGPInlineEncryptedData];
    NSRange signatureRange = [partData rangeOfPGPInlineSignatures];
    
    // No encrypted PGP data and no signature PGP data found? OUT OF HERE!
    if(encryptedRange.location == NSNotFound && signatureRange.location == NSNotFound) 
        return nil;
    
    if(encryptedRange.location != NSNotFound) {
        [messageProtectionStatus.encryptedParts addObject:MAIL_SELF(self)];
        decryptedData = [self decryptedMessageBodyOrDataForEncryptedData:partData encryptedInlineRange:encryptedRange];
        // It's possible the decrypted content is signed as well.
        if(self.PGPSigned && [self.PGPSignatures count]) {
            [[messageProtectionStatus signedParts] addObject:self];
        }
        // Fetch the decrypted content, since that is already been processed, with markers and stuff.
        // In case of a decryption failure, simply return the decrypted data.
        NSString *content = [decryptedData stringByGuessingEncoding];
        
		return content;
    }
    
    if(signatureRange.location != NSNotFound) {
        // We might have to do this elsewhere, if the data was not in fact a signature.
        [self _verifyPGPInlineSignatureInData:partData];
        return self.PGPVerifiedContent;
    }
    
    return nil;
}

- (id)GMContentForHTMLPart {
    if([[self getIvar:@"MimePartIsPGPPartitionedEncodingReplacedHTMLPart"] boolValue]) {
        return [self GMContentForPlainTextPart];
    }
    // HTML is a bit hard to decrypt, so check if the parent part,
	// if exists is a multipart/alternative.
	// If that's the case, look for a text/plain part, check if
	// it contains a pgp message and decode it.
	MCMimePart *parentPart = [MAIL_SELF(self) parentPart];
	if (parentPart && [parentPart isType:@"multipart" subtype:@"alternative"]) {
		for (MCMimePart *tmpPart in [parentPart subparts]) {
			if ([tmpPart isType:@"text" subtype:@"plain"]) {
				if ([[(MimePart_GPGMail *)tmpPart GMBodyData] mightContainPGPEncryptedDataOrSignatures]) {
					return [(MimePart_GPGMail *)tmpPart GMContentForPlainTextPart];
				}
				break;
			}
		}
	}
	
	// Check if the HTML contains a decodeable pgp message,
	// if that's the case decode it like plain text.
	NSData *bodyData = [self GMBodyData];
	if ([bodyData rangeOfPGPInlineEncryptedData].length > 0 || [bodyData rangeOfPGPInlineSignatures].length > 0) {
		return [self GMContentForPlainTextPart];
	}
	
	return nil;
}

- (id)GMContentForAttachmentPart {
    MCMimePart *mailself = MAIL_SELF(self);

    NSArray *encryptedDataExtensions = @[@"pgp", @"gpg", @"asc"];
    NSArray *signedDataExtensions = @[@"asc", @"sig"];
    NSArray *pgpDataExtensions = [encryptedDataExtensions arrayByAddingObjectsFromArray:signedDataExtensions];
    NSString *filename = [mailself attachmentFilename];
    NSString *extension = [filename pathExtension];


    // Refers to the part being a detached signature requiring
    // a matching data counter mime part with the same name.
    BOOL isDetachedSignature = NO;
    // Refers to the part itself being signed.
    BOOL isSigned = NO;
    BOOL isEncrypted = NO;
    NSData *attachmentData = [self GMBodyData];

    // OpenPGP public key or private key attachments are currently
    // not handled.
    if([attachmentData rangeOfPGPPublicKey].location != NSNotFound || [attachmentData containsPGPKeyPackets]) {
        GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];
        [messageProtectionStatus.plainParts addObject:mailself];
        return nil;
    }
    
    // Bug #942: Attachments that are either signed nor encrypted are falsely detected as signed, since GPGPacket
    // returns a signature packet in some cases (e.g. some PNG files appear to have binary data which is interpreted
    // as a pgp signature packet with an invalid version 71).
    // In order to avoid that, an attachment is only checked for signature packets, if the extension of the filename
    // matches either a known encrypted or signed extension.
    MCMimePart *signedPart = nil;
    if(([pgpDataExtensions containsObject:extension] && ([attachmentData rangeOfPGPSignatures].location != NSNotFound ||
                                                    [attachmentData hasPGPSignatureDataPackets])) || [attachmentData rangeOfPGPInlineSignatures].location != NSNotFound) {
        signedPart = [self signedPartForDetachedSignaturePart:mailself];
        if(signedPart) {
            isDetachedSignature = YES;
        }
        else {
            isSigned = YES;
        }

        // Bug #927: Inline signed content in text/plain attachment part file.
        // This is a very strange case. For now, just return.
        if([attachmentData rangeOfPGPInlineSignatures].location != NSNotFound) {
            return nil;
        }

        // Bug #958: Single signature.asc files is erroneously recognized as encrypted attachment
        // Since the current method to check for encrypted or signed data in attachments is based
        // for the most part on the extension of the file, the signature.asc file looks to GPGMail
        // like a signed attachment. As mentioned above for #936, a signed attachment has to be decrypted
        // in order to strip the signature and get to the raw contents. signature.asc files however
        // should never be treated as containing encrypted data.
        // To further improve this fix, signed (not detached signed) attachments should be treated differently
        // from encrypted attachments.
        if([[filename lowercaseString] isEqualToString:@"signature.asc"]) {
            return nil;
        }

        self.PGPAttachment = YES;
    }

    if(isDetachedSignature) {
        [self GMHandleDetachedSignatureWithSignedPart:signedPart];
        return nil;
    }
    // Check explicitly for inline encrypted data. Previously the check also accepted
    // inline signatures, which doesn't make sense, but the assumption was, that any
    // signatures would already be handled by the above checks.
    isEncrypted = /*[attachmentData rangeOfPGPInlineEncryptedData].location == 0 || */[attachmentData hasPGPEncryptionDataPackets];
    
    if(!isSigned && !isEncrypted) {
        return nil;
    }
    
    // It's a PGP attachment otherwise we wouldn't come in here, so set
    // that status.
    self.PGPAttachment = YES;
    
    // A signed attachment (as in no-detached-signature) also needs to
    // run through the decrypt routine, in order for GnuPG to return
    // the signed data.
    NSData *decryptedData = [self GMDecryptedDataForEncryptedAttachment];
    attachmentData = decryptedData ? decryptedData : attachmentData;
    // Bug #990: Re-add support for embedded filename
    //
    // Even if a embedded filename is available, GPGMail didn't use
    // it, and always used the filename with the pgp extension stripped
    // if decrypting the attachment succeeded.
    if(decryptedData) {
        if(self.PGPEmbeddedFilename && [self.PGPEmbeddedFilename length]) {
            filename = self.PGPEmbeddedFilename;
        }
        else {
			for(NSString *ext in pgpDataExtensions) {
				if([[filename pathExtension] isEqualToStringIgnoringCase:ext]) {
					filename = [filename substringWithRange:NSMakeRange(0, [filename length] - ([extension length] + 1))];
					break;
				}
			}
		}
    }
    MCAttachment *attachment = [[MCAttachment alloc] initWithMimePart:self];
    [attachment setFilename:filename];
    MCDataAttachmentDataSource *attachmentDataSource = [[MCDataAttachmentDataSource alloc] initWithData:attachmentData];
    [attachment setDataSource:attachmentDataSource];
    if([[filename pathExtension] length]) {
        // Create a new MCAttachment for the decrypted data.
        MCFileTypeInfo *fileType = [MCFileTypeInfo new];
        [fileType setPathExtension:[filename pathExtension]];
        if([fileType getTypeInfoForDesiredFields:1]) {
            [attachment setMimeType:[fileType mimeType]];
        }
    }
    
    NSString *htmlString = [MAIL_SELF(self) htmlStringForMimePart:self attachment:attachment];
    
    return attachment;
}

- (BOOL)isPGPMimeEncryptedAttachment {
    // application/pgp-encrypted is also considered to be an attachment, but doesn't have
    // to be the PGP MIME Version attachment, so it makes sense to check for the Version as well.
    BOOL isPGPMimeVersionPart = [MAIL_SELF(self) isType:@"application" subtype:@"pgp-encrypted"] && [[MAIL_SELF(self) decodedData] containsPGPVersionMarker:1];
    if(isPGPMimeVersionPart || [[MAIL_SELF(self) dispositionParameterForKey:@"filename"] isEqualToString:@"encrypted.asc"]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isPGPMimeSignatureAttachment {
    if([MAIL_SELF(self) isType:@"application" subtype:@"pgp-signature"])
        return YES;
    
    return NO;
}


- (id)GMDecryptedDataForEncryptedAttachment {
    NSData *partData = [self GMBodyData];
    NSData *decryptedData = nil;
    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];
    [messageProtectionStatus.encryptedParts addObject:MAIL_SELF(self)];
    decryptedData = [self decryptedMessageBodyOrDataForEncryptedData:partData encryptedInlineRange:NSMakeRange(0, [partData length]) isAttachment:YES];
    
    return decryptedData;
}

- (MCMimePart *)signedPartForDetachedSignaturePart:(MCMimePart *)signaturePart {
    MCMimePart *parentPart = [signaturePart parentPart];
    MCMimePart *signedPart = nil;
    NSString *signatureFilename = [[signaturePart attachmentFilename] lastPathComponent];
    NSString *signedFilename = [signatureFilename stringByDeletingPathExtension];
    for(MCMimePart *part in [parentPart subparts]) {
        if([[[part attachmentFilename] lastPathComponent] isEqualToString:signedFilename]) {
            signedPart = part;
            break;
        }
    }
    
    return signedPart;
}

- (void)GMHandleDetachedSignatureWithSignedPart:(MCMimePart *)signedPart {
    [self verifyData:[(MimePart_GPGMail *)signedPart GMBodyData] signatureData:[self GMBodyData]];
    // TODO: Handle NO_DATA!!
    // Remove the signature attachment also if verification failed.
    BOOL removeAllSignatureAttachments = [[GPGOptions sharedOptions] boolForKey:@"HideAllSignatureAttachments"];
    DebugLog(@"Hide All attachments: %@", removeAllSignatureAttachments ? @"YES" : @"NO");
    BOOL remove = removeAllSignatureAttachments ? YES : self.PGPVerified;
    
    if(remove) {
        [self scheduleSignatureAttachmentForRemoval:[MAIL_SELF(self) attachmentFilename]];
    }
}

- (void)scheduleSignatureAttachmentForRemoval:(NSString *)attachment {
    if(![[self topPart] ivarExists:@"PGPSignatureAttachmentsToRemove"]) {
        [[self topPart] setIvar:@"PGPSignatureAttachmentsToRemove" value:[NSMutableArray array]];
    }
    
    [[[self topPart] getIvar:@"PGPSignatureAttachmentsToRemove"] addObject:attachment];
}

- (NSArray *)signatureAttachmentScheduledForRemoval {
    return [[self topPart] getIvar:@"PGPSignatureAttachmentsToRemove"];
}

- (id)decodeMultipartEncryptedWithContext:(id)ctx {
    // 1. Step, check if the message was already decrypted.
#warning this lookup should be locked as Mail.app does it in decryptedMessageBodyIsEncrypted:isSigned:error
	if(self.PGPDecryptedBody || self.PGPError)
        return self.PGPDecryptedBody ? self.PGPDecryptedBody : nil;
    
    // 2. Fetch the data part.
    // To support exchange server modified messages, the first found octect-stream part
    // is used as data part. In case of exchange server modified messages, this part
    // is not necessarily the second immediately after the application/pgp-encrypted.
	// The data might also be included in the application/pgp-encrypted part if available.
    MCMimePart *dataPart = nil;
    for(MCMimePart *part in [MAIL_SELF(self) subparts]) {
        if([part isType:@"application" subtype:@"octet-stream"] && ![(MimePart_GPGMail *)[self topPart] isPseudoPGPMimeMessageFromiPGMail]) {
            dataPart = part;
        }
		// application/octet-stream still takes precedence and will overwrite
		// the dataPart store here.
		// In the same way, application/pgp-encrypted is only used, if no previous
		// application/octet-stream part was found.
		if([part isType:@"application" subtype:@"pgp-encrypted"] && !dataPart)
			dataPart = part;
    }
	
    MCMimeBody *decryptedMessageBody = nil;
    NSData *encryptedData = [dataPart decodedData];
	
	// If encrytedData is nil, rangeOfData returns 0 instead of NSNotFound.
	// Makes sense probably.
	if(!encryptedData)
		return nil;
	
//    // Check if the data part contains the Content-Type string.
//    // If so, this is a message which was created by a very early alpha
//    // of GPGMail 2.0 which sent out completely corrupted messages.
//    if([encryptedData rangeOfData:[@"Content-Type" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [encryptedData length])].location != NSNotFound)
//        return [self decodeFuckedUpEarlyAlphaData:encryptedData context:ctx];

    // The message is definitely encrypted, otherwise this method would never
    // be entered, so set that flag.
    decryptedMessageBody = [self decryptedMessageBodyOrDataForEncryptedData:encryptedData encryptedInlineRange:NSMakeRange(NSNotFound, 0)];
    
    return decryptedMessageBody;
}

// TODO: Don't do this on older versions. Also, it's not clear, if this might not cause problems!
// Whatchout! it's used in message generation somehow.
- (id)MAMimeBody {
    if([self getIvar:@"MimeBody"]) {
        return [self getIvar:@"MimeBody"];
    }
    return [self MAMimeBody];
}

- (id)decryptData:(NSData *)encryptedData {
    // Decrypt data should not run if Mail.app is generating snippets
    // and NeverCreateSnippetPreviews is set or the passphrase is not in cache
    // and CreatePreviewSnippets is not set.
    if(![(MimePart_GPGMail *)[self topPart] shouldBePGPProcessed]) {
        return nil;
    }
	
	NSData *deArmoredEncryptedData = nil;
    // De-armor the message and catch any CRC-Errors.
    @try {
        deArmoredEncryptedData = [[GPGUnArmor unArmor:[GPGMemoryStream memoryStreamForReading:encryptedData]] readAllData];
    }
    @catch (NSException *exception) {
		self.PGPError = [self errorForDecryptionError:exception status:nil errorText:nil];
		return nil;
    }

	
	// Find key needed to decrypt. We do this to lock until last decyption using this key is done.
	__block NSString *decryptKey = nil;
	
	[GPGPacket enumeratePacketsWithData:deArmoredEncryptedData block:^(GPGPacket *packet, BOOL *stop) {
		if(packet.tag != GPGPublicKeyEncryptedSessionKeyPacketTag) {
			return;
		}
		
		GPGPublicKeyEncryptedSessionKeyPacket *keyPacket = (GPGPublicKeyEncryptedSessionKeyPacket *)packet;
		GPGKey *key = [[GPGMailBundle sharedInstance] secretGPGKeyForKeyID:keyPacket.keyID includeDisabled:YES];
		if (key) {
			decryptKey = [key description];
			*stop = YES;
		}
	}];

	
	GPGController *gpgc = [[GPGController alloc] init];
    gpgc.delegate = self;
	NSData *decryptedData = nil;
	
	if (!decryptKey || [gpgc isPassphraseForKeyInCache:decryptKey]) { //
		decryptedData = [gpgc decryptData:deArmoredEncryptedData];
	} else { // Only lock if the passphrase is not cached.
		@synchronized(decryptKey) {
			decryptedData = [gpgc decryptData:deArmoredEncryptedData];
		}
	}
	
    // Due to an oddity in GnuPG it is possible to create a PGP message
    // which pretends to be encrypted but isn't really and has plaintext
    // after the encrypted part, which is not distinguishable from content
    // that might actually have been encrypted.
    // For more see: https://neopg.io/blog/encryption-spoof/
    // TODO: This has to be a special error code in Libmacgpg!
    BOOL unencryptedPlaintextError = gpgc.error && [gpgc.error.reason length] && ([gpgc.error.reason rangeOfString:@"Unencrypted Plaintext"].location != NSNotFound || (((GPGException *)gpgc.error).errorCode == GPGErrorBadData && [gpgc.gpgTask.errText rangeOfString:@"handle plaintext failed"].location != NSNotFound));
    if(unencryptedPlaintextError) {
        // Remove from message protection status.
        GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];
        if([[messageProtectionStatus encryptedParts] containsObject:MAIL_SELF(self)]) {
            [[messageProtectionStatus encryptedParts] removeObject:MAIL_SELF(self)];
        }
        return nil;
    }
	
    // Bug #980: If the message doesn't contain a MDC or contains a modified MDC,
    //           GPGMail currently believes that the message is non-clear-signed and
    //           ignores the failed decryption.
    //
    // Libmacgpg has since been patched to no longer return the decrypted content
    // if no MDC or a modified MDC is detected, so if data is returned and no DECRYPTION_OKAY
    // status line is issued, there's a high chance, that the message was non-clear-signed instead of
    // encrypted. In addition a check is added, to see if BEGIN_DECRYPTION wasn't issued either.
    BOOL nonClearSigned = ![[gpgc.statusDict objectForKey:@"BEGIN_DECRYPTION"] boolValue] && !gpgc.decryptionOkay &&
                          [decryptedData length] != 0 && [encryptedData hasPGPSignatureDataPackets];

	NSError *error = [self errorFromGPGOperation:GPG_OPERATION_DECRYPTION controller:gpgc];
	
	// Sometimes decryption okay is issued even though a NODATA error occured.
	BOOL success = gpgc.decryptionOkay && !error;
	
    if(gpgc.filename) {
        self.PGPEmbeddedFilename = gpgc.filename;
    }

    // Bug #982: Allow messages which don't include an MDC
    //
    // Some users have reported that after Libmacgpg has been patched,
    // they can now no longer open their old messages. It turns out that
    // quite a few users are still using old keys which don't support MDCs.
    // In order to accomodate those users, a defaults key has been introduced
    // which if true allows to decrypt messages without MDC.
    // If a message has an AEAD (position 3), MDC will always be 0, so account for that.
    NSArray *decryptionInfo = [gpgc.statusDict[@"DECRYPTION_INFO"] count] > 0 && [gpgc.statusDict[@"DECRYPTION_INFO"][0] count] > 0 ? gpgc.statusDict[@"DECRYPTION_INFO"][0] : nil;
    BOOL hasAEAD = [decryptionInfo count] > 2 && [decryptionInfo[2] integerValue] > 0;
    BOOL noMDCStatus = [decryptionInfo count] > 0 && [decryptionInfo[0] integerValue] == 0 && !hasAEAD;
    BOOL hasNoMDCButNoMDCIsAllowed = noMDCStatus && [self gpgControllerShouldDecryptWithoutMDC:gpgc];
    if(hasNoMDCButNoMDCIsAllowed && !nonClearSigned && [decryptedData length]) {
        NSLog(@"[GPGMail] is missing MDC but missing MDC is allowed");
        success = YES;
        // 1035 represents an encryption error. Signature errors should not
        // be reset.
        if(error.code == 1035) {
            error = nil;
        }
    }

	// Let's reset the error if the message is not clear-signed,
	// since error will be general error.
	if (nonClearSigned)
		error = nil;
	
    // Part is encrypted, otherwise we wouldn't come here, so
    // set that status.
    self.PGPEncrypted = nonClearSigned ? NO : YES;
    
    // No error for decryption? Check the signatures for errors.
    if(!error) {
        // Decryption succeed, so set that status.
        self.PGPDecrypted = nonClearSigned ? NO : YES;
        error = [self errorFromGPGOperation:GPG_OPERATION_VERIFICATION controller:gpgc];
    }
    
	// Signatures found, set is signed status, also store the signatures.
	NSArray *signatures = gpgc.signatures;
	if (signatures.count) {
		self.PGPSigned = YES;
		self.PGPSignatures = signatures;
		
		// If there is an error and decrypted is yes, there was an error
		// with a signature. Set verified to false.
		self.PGPVerified = !(success && error);
	}
	
    // Unset the filename if the attachment failed to decrypt.
    if(!self.PGPDecrypted) {
        self.PGPEmbeddedFilename = nil;
	}

    // Last, store the error itself.
    self.PGPError = error;
    
    if (!success && !nonClearSigned)
        return nil;
    
    return decryptedData;
}

- (BOOL)gpgControllerShouldDecryptWithoutMDC:(GPGController *)gpgc {
    // Implement this method to allow decryption of messages without
    // an MDC to allow users with old keys to still open their old
    // emails.
    //
    // This feature can be enabled using:
    //
    // `defaults write org.gpgtools.gpgmail AllowDecryptionOfPotentiallyDangerousMessagesWithoutMDC -bool YES`
    return [[GPGMailBundle sharedInstance] allowDecryptionOfPotentiallyDangerousMessagesWithoutMDC];
}

#pragma mark PGP Error Helpers

- (id)errorFromGPGOperation:(GPG_OPERATION)operation controller:(GPGController *)gpgc {
    if(operation == GPG_OPERATION_DECRYPTION)
        return [self errorFromDecryptionOperation:gpgc];
    if(operation == GPG_OPERATION_VERIFICATION)
        return [self errorFromVerificationOperation:gpgc];
        
    return nil;
}

- (NSError *)errorForDecryptionError:(NSException *)operationError status:(NSDictionary *)status
                          errorText:(NSString *)errorText {
    
    // Might be an NSException or a GPGException
    NSError *error = nil;
    NSArray *noDataErrors = [status valueForKey:@"NODATA"];
    
    NSString *title = nil, *message = nil;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    BOOL isAttachment = [MAIL_SELF(self) isAttachment] && ![self isPGPMimeEncryptedAttachment];
    NSString *prefix = !isAttachment ? @"MESSAGE_BANNER_PGP" : @"MESSAGE_BANNER_PGP_ATTACHMENT";
    
    NSString *titleKey = nil;
    NSString *messageKey = nil;
    
    if([operationError isMemberOfClass:[NSException class]]) {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_SYSTEM_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_SYSTEM_ERROR_MESSAGE", prefix];
        
        title = GMLocalizedString(titleKey);
        message = GMLocalizedString(messageKey);
    }
    else if(((GPGException *)operationError).errorCode == GPGErrorNoSecretKey) {
		NSArray *missingKeys = ([(GPGException *)operationError gpgTask].statusDict)[@"NO_SECKEY"]; //Array of Arrays of String!
		NSMutableString *keyIDs = [NSMutableString string];
		NSUInteger count = missingKeys.count - 1;
		NSUInteger i = 0;
		for (; i < count; i++) {
			[keyIDs appendFormat:@"%@, ", [(NSString *)missingKeys[i][0] shortKeyID]];
		}
		[keyIDs appendFormat:@"%@", [(NSString *)missingKeys[i][0] shortKeyID]];
		
		
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_SECKEY_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_SECKEY_ERROR_MESSAGE", prefix];
        
        title = GMLocalizedString(titleKey);
        message = GMLocalizedString(messageKey);
		
		message = [NSString stringWithFormat:message, keyIDs];
    }
    else if(((GPGException *)operationError).errorCode == GPGErrorWrongSecretKey) {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_WRONG_SECKEY_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_WRONG_SECKEY_ERROR_MESSAGE", prefix];
        
        title = GMLocalizedString(titleKey);
        message = GMLocalizedString(messageKey);
    }
	else if(((GPGException *)operationError).errorCode == GPGErrorNotFound) {
		title = GMLocalizedString(@"MESSAGE_BANNER_PGP_DECRYPT_ERROR_NO_GPG_TITLE");
        message = GMLocalizedString(@"MESSAGE_BANNER_PGP_DECRYPT_ERROR_NO_GPG_MESSAGE");
	}
	else if(((GPGException *)operationError).errorCode == GPGErrorCancelled) {
		titleKey = [NSString stringWithFormat:@"%@_DECRYPT_ERROR_PASSPHRASE_REQUEST_CANCELLED_TITLE", prefix];
		messageKey = [NSString stringWithFormat:@"%@_DECRYPT_ERROR_PASSPHRASE_REQUEST_CANCELLED_MESSAGE", prefix];
		title = GMLocalizedString(titleKey);
		message = GMLocalizedString(messageKey);
	}
	else if(((GPGException *)operationError).errorCode == GPGErrorEOF) {
		titleKey = [NSString stringWithFormat:@"%@_DECRYPT_ERROR_PINENTRY_CRASHED_TITLE", prefix];
		messageKey = [NSString stringWithFormat:@"%@_DECRYPT_ERROR_PINENTRY_CRASHED_MESSAGE", prefix];
		title = GMLocalizedString(titleKey);
		message = GMLocalizedString(messageKey);
	}
    else if(((GPGException *)operationError).errorCode == GPGErrorXPCBinaryError ||
			((GPGException *)operationError).errorCode == GPGErrorXPCConnectionError ||
			((GPGException *)operationError).errorCode == GPGErrorXPCConnectionInterruptedError) {
		titleKey = [NSString stringWithFormat:@"%@_DECRYPT_ERROR_XPC_DAMAGED_TITLE", prefix];
		messageKey = [NSString stringWithFormat:@"%@_DECRYPT_ERROR_XPC_DAMAGED_MESSAGE", prefix];
		
		title = GMLocalizedString(titleKey);
		message = GMLocalizedString(messageKey);
	}
	else if(((GPGException *)operationError).errorCode == GPGErrorNoMDC ||
			((GPGException *)operationError).errorCode == GPGErrorBadMDC) {
		titleKey = [NSString stringWithFormat:@"%@_DECRYPT_MDC_ERROR_TITLE", prefix];
		messageKey = [NSString stringWithFormat:@"%@_DECRYPT_MDC_ERROR_MESSAGE", prefix];

		title = GMLocalizedString(titleKey);
		message = GMLocalizedString(messageKey);
	}
    else if([self hasError:@"NO_ARMORED_DATA" noDataErrors:noDataErrors] || 
            [self hasError:@"INVALID_PACKET" noDataErrors:noDataErrors] || 
            [(GPGException *)operationError isCorruptedInputError]) {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_CORRUPTED_DATA_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_CORRUPTED_DATA_ERROR_MESSAGE", prefix];
        
        title = GMLocalizedString(titleKey);
        message = GMLocalizedString(messageKey);
    }
    else {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_GENERAL_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_GENERAL_ERROR_MESSAGE", prefix];
        
        title = GMLocalizedString(titleKey);
        message = GMLocalizedString(messageKey);
        message = [NSString stringWithFormat:message, errorText];
    }
    
	userInfo[@"_MFShortDescription"] = title;
	userInfo[@"NSLocalizedDescription"] = message;
    userInfo[@"DecryptionError"] = @YES;
	
    if([operationError isKindOfClass:[GPGException class]])
		userInfo[@"DecryptionErrorCode"] = @((long)((GPGException *)operationError).errorCode);
	
    error = (NSError *)[GPGMailBundle errorWithCode:1035 userInfo:userInfo];
//    
//    // The error domain is checked in certain occasion, so let's use the system
//    // dependent one.
//    NSString *errorDomain = [GPGMailBundle isMavericks] ? @"MCMailErrorDomain" : @"MFMessageErrorDomain";
//    
//    if([GPGMailBundle isSierra]) {
//        userInfo[@"NSLocalizedRecoverySuggestion"] = message;
//        userInfo[@"NSLocalizedDescription"] = title;
//        error = [NSError errorWithDomain:errorDomain code:1035 userInfo:userInfo];
//    }
//    else {
//        error = [GM_MAIL_CLASS(@"NSError") errorWithDomain:errorDomain code:1035 localizedDescription:nil title:title helpTag:nil
//                                                  userInfo:userInfo];
//    }
    
    return error;
}

- (NSError *)errorFromDecryptionOperation:(GPGController *)gpgc {
    // No error? OUT OF HEEEEEAAAR!
    // Decryption Okay is sometimes issued even if NODATA
    // came up. In that case the file is damaged.
    if(gpgc.decryptionOkay && ![(NSArray *)(gpgc.statusDict)[@"NODATA"] count] && !gpgc.error)
        return nil;
    
    return [self errorForDecryptionError:gpgc.error status:gpgc.statusDict errorText:gpgc.gpgTask.errText];
}

- (NSError *)errorForVerificationError:(NSException *)operationError status:(NSDictionary *)status signatures:(NSArray *)signatures {
    NSError *error = nil;
    
    NSArray *noDataErrors = [status valueForKey:@"NODATA"];
    
    NSString *title = nil, *message = nil;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    BOOL isAttachment = [MAIL_SELF(self) isAttachment] && ![self isPGPMimeSignatureAttachment];
    NSString *prefix = !isAttachment ? @"MESSAGE_BANNER_PGP" : @"MESSAGE_BANNER_PGP_ATTACHMENT";
    
    NSString *titleKey = nil;
    NSString *messageKey = nil;
    
    BOOL errorFound = NO;
    
    // If there was a GPG exception, the type should be GPGException, otherwise
    // there was an error with the execution of the gpg executable or some other
    // system error.
    // Don't use is kindOfClass here, 'cause it will be true for GPGException as well,
    // since it checks inheritance. memberOfClass doesn't.
    if([operationError isMemberOfClass:[NSException class]]) {
        titleKey = [NSString stringWithFormat:@"%@_VERIFY_SYSTEM_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_VERIFY_SYSTEM_ERROR_MESSAGE", prefix];
        
        title = GMLocalizedString(titleKey);
        message = GMLocalizedString(messageKey);
        errorFound = YES;
    }
    else if([self hasError:@"EXPECTED_SIGNATURE_NOT_FOUND" noDataErrors:noDataErrors] ||
            [(GPGException *)operationError isCorruptedInputError]) {
        titleKey = [NSString stringWithFormat:@"%@_VERIFY_CORRUPTED_DATA_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_VERIFY_CORRUPTED_DATA_ERROR_MESSAGE", prefix];
        
        title = GMLocalizedString(titleKey);
        message = GMLocalizedString(messageKey);
        errorFound = YES;
    }
	else if(((GPGException *)operationError).errorCode == GPGErrorNotFound) {
		title = GMLocalizedString(@"MESSAGE_BANNER_PGP_VERIFY_ERROR_NO_GPG_TITLE");
		message = GMLocalizedString(@"MESSAGE_BANNER_PGP_VERIFY_ERROR_NO_GPG_MESSAGE");
		errorFound = YES;
	}
	else if(((GPGException *)operationError).errorCode == GPGErrorXPCBinaryError ||
			((GPGException *)operationError).errorCode == GPGErrorXPCConnectionError ||
			((GPGException *)operationError).errorCode == GPGErrorXPCConnectionInterruptedError) {
		titleKey = [NSString stringWithFormat:@"%@_VERIFY_ERROR_XPC_DAMAGED_TITLE", prefix];
		messageKey = [NSString stringWithFormat:@"%@_VERIFY_ERROR_XPC_DAMAGED_MESSAGE", prefix];
		
		title = GMLocalizedString(titleKey);
		message = GMLocalizedString(messageKey);
		errorFound = YES;
	}
    else {
        GPGErrorCode errorCode = GPGErrorNoError;
        GPGSignature *signatureWithError = nil;
		NSString *signatureKeyID = nil;
		NSString *signatureKeyIDString = nil;
        for(GPGSignature *signature in signatures) {
            if(signature.status != GPGErrorNoError) {
                errorCode = signature.status;
                signatureWithError = signature;
				signatureKeyID = signature.fingerprint;
				signatureKeyIDString = [NSString stringWithFormat:@"0x%@", signatureKeyID];
                break;
            }
        }
        errorFound = errorCode != GPGErrorNoError ? YES : NO;
        
        switch (errorCode) {
            case GPGErrorNoPublicKey:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_NO_PUBKEY_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_NO_PUBKEY_ERROR_MESSAGE", prefix];
                
                title = GMLocalizedString(titleKey);
                message = GMLocalizedString(messageKey);
                message = [NSString stringWithFormat:message, signatureKeyIDString];
                break;
                
            case GPGErrorUnknownAlgorithm:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_ALGORITHM_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_ALGORITHM_ERROR_MESSAGE", prefix];
                
                title = GMLocalizedString(titleKey);
                message = GMLocalizedString(messageKey);
                break;
                
            case GPGErrorCertificateRevoked:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_REVOKED_CERTIFICATE_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_REVOKED_CERTIFICATE_ERROR_MESSAGE", prefix];
                
                title = GMLocalizedString(titleKey);
                message = GMLocalizedString(messageKey);
                message = [NSString stringWithFormat:message, signatureKeyIDString];
                break;
                
            case GPGErrorKeyExpired:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_KEY_EXPIRED_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_KEY_EXPIRED_ERROR_MESSAGE", prefix];
                
                title = GMLocalizedString(titleKey);
                message = GMLocalizedString(messageKey);
                message = [NSString stringWithFormat:message, signatureKeyIDString];
                break;
                
            case GPGErrorSignatureExpired:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_SIGNATURE_EXPIRED_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_SIGNATURE_EXPIRED_ERROR_MESSAGE", prefix];
                
                title = GMLocalizedString(titleKey);
                message = GMLocalizedString(messageKey);
                break;
                
            case GPGErrorBadSignature:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_BAD_SIGNATURE_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_BAD_SIGNATURE_ERROR_MESSAGE", prefix];
                
                title = GMLocalizedString(titleKey);
                message = GMLocalizedString(messageKey);
                break;
                
            default:
                // Set errorFound to 0 for Key expired and signature expired.
                // Those are warnings, not actually errors. Should only be displayed in the signature view.
                errorFound = 0;
                break;
        }
    }
    
	if(errorFound) {
		userInfo[@"_MFShortDescription"] = title;
		userInfo[@"NSLocalizedDescription"] = message;
		userInfo[@"VerificationError"] = @YES;
		
		if([operationError isKindOfClass:[GPGException class]])
			userInfo[@"VerificationErrorCode"] = @((long)((GPGException *)operationError).errorCode);
		
        // The error domain is checked in certain occasion, so let's use the system
        // dependent one.
        error = (NSError *)[GPGMailBundle errorWithCode:1036 userInfo:userInfo];
	}
    
    
    return error;
}

- (NSError *)errorFromVerificationOperation:(GPGController *)gpgc {
    return [self errorForVerificationError:gpgc.error status:gpgc.statusDict signatures:gpgc.signatures];
}

- (BOOL)hasError:(NSString *)errorName noDataErrors:(NSArray *)noDataErrors {
    const NSDictionary *errorCodes = @{@"NO_ARMORED_DATA": @"1",
                                @"EXPECTED_PACKAGE_NOT_FOUND": @"2",
                                @"INVALID_PACKET": @"3",
                                @"EXPECTED_SIGNATURE_NOT_FOUND": @"4"};
    
    for(id parts in noDataErrors) {
        if([parts[0] isEqualTo:[errorCodes valueForKey:errorName]])
            return YES;
    }
    
    return NO;
}                           

- (MimeBody *)decryptedMessageBodyFromDecryptedData:(NSData *)decryptedData {
    if([decryptedData length] == 0)
        return nil;
    // 1. Create a new Message using messageWithRFC822Data:
    // This creates the message store automatically!
    MCMessage *decryptedMessage;
//    MCMimeBody *decryptedMimeBody;
    // Unfortunately the Evolution PGP plugins seems to fuck up the encrypted message,
    // which renders it unreadable for Mail.app. This is frustrating but fixable.
    // Actually even easier than i thought at first. Instead of messageWithRFC822Data:
    // messageWithRFC822Data:sanitizeData: can be used to make the problem go away.
    // BOOYAH!
    decryptedData = [[NSData alloc] initWithDataConvertingLineEndingsFromNetworkToUnix:decryptedData];
    decryptedMessage = [MCMessage messageWithRFC822Data:decryptedData sanitizeData:YES];
    
    // 2. Set message info from the original encrypted message.
    // Seems to be no longer necessary on Sierra...
    //[decryptedMessage setMessageInfoFromMessage:[(MimeBody_GPGMail *)[self mimeBody] message]];
    
    // 3. Call message body updating flags to set the correct flags for the new message.
    // This will setup the decrypted message, run through all parts and find signature part.
    // We'll save the message body for later, since it will be used to do a last
    // decodeWithContext and the output returned.
    // Fake the message flags on the decrypted message.
    // messageBodyUpdatingFlags: calls isMimeEncrypted. Set MimeEncrypted on the message,
    // so the correct info is returned.
    [decryptedMessage setIvar:@"MimeEncrypted" value:@YES];
//    decryptedMimeBody = [MCMimeBody new];
    [decryptedMessage setIvar:@"UserSelectedMessage" value:@YES];
//    [decryptedMimeBody setIvar:kMimeBodyMessageKey value:decryptedMessage];
    id decryptedMimePart = [[MCMimePart alloc] initWithEncodedData:decryptedData];
//    [decryptedMimePart setIvar:@"MimeBody" value:decryptedMimeBody];
    [decryptedMimePart setIvar:kMimePartAllowPGPProcessingKey value:@(YES)];
//    [decryptedMimeBody setTopLevelPart:decryptedMimePart];
    [decryptedMimePart parse];
    
    //[decryptedMessage messageBodyUpdatingFlags:YES];
    
    // Top Level part reparses the message. This method doesn't.
    MCMimePart *topPart = [self topPart];
    // Set the decrypted message here, otherwise we run into a memory problem.
    // TODO: Figure out what methods are used on High Sierra.
    [topPart _setCMSExtractedContent:decryptedMimePart isEncrypted:self.PGPEncrypted isSigned:self.PGPSigned error:self.PGPError];
    self.PGPDecryptedBody = decryptedMimePart;
    //    [(id)topPart setDecryptedMimeBody:decryptedMimeBody isEncrypted:self.PGPEncrypted isSigned:self.PGPSigned error:self.PGPError];
    //self.PGPDecryptedBody = [self decryptedMimeBody];
          
    return decryptedMimePart;
}

- (NSData *)partDataByReplacingEncryptedData:(NSData *)originalPartData decryptedData:(NSData *)decryptedData encryptedRange:(NSRange)encryptedRange {
    NSMutableData *partData = [[NSMutableData alloc] init];
    NSData *inlineEncryptedData = [originalPartData subdataWithRange:encryptedRange];
    
    BOOL (^otherDataFound)(NSData *) = ^(NSData *data) {
        unsigned char *dataBytes = (unsigned char *)[data bytes];
		NSUInteger length = [data length];
        for (NSUInteger i = 0; i < length; i++) {
			switch (dataBytes[i]) {
				case '\n':
				case '\r':
				case '\t':
				case ' ':
					break;
				default:
					return YES;
			}
        }
        return NO;
    };
    
    NSData *originalData = originalPartData;
	NSData *leadingData = [originalData subdataWithRange:NSMakeRange(0, encryptedRange.location)];
	// Only add surrounding data, if we have plain text.
	[partData appendData:leadingData];
    NSData *restData = [originalData subdataWithRange:NSMakeRange(encryptedRange.location + encryptedRange.length,
                                                                  [originalData length] - encryptedRange.length - encryptedRange.location)];

    // If there was data before or after the encrypted data, signal this
    // with a banner.
    BOOL hasOtherData = otherDataFound(leadingData) || otherDataFound(restData);
    if(hasOtherData) {
        GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];
        [[messageProtectionStatus plainParts] addObject:(MCMimePart *)self];
    }
    NSData *dataForMarker = decryptedData ? decryptedData : inlineEncryptedData;
    [self addPGPPartMarkerToData:partData partData:dataForMarker];
    
    [partData appendData:restData];
    
    BOOL decryptionError = !decryptedData ? YES : NO;
    
    // If there was no decryption error, look for signatures in the partData.
    if(!decryptionError) { 
        NSRange signatureRange = [decryptedData rangeOfPGPInlineSignatures];
        if(signatureRange.location != NSNotFound)
            [self _verifyPGPInlineSignatureInData:decryptedData];
    }
    
    //self.PGPDecryptedData = partData;
    // Decrypted content is a HTML string generated from the decrypted data
    // If the content is only partly encrypted or partly signed, that information
    // is added to the HTML as well.
    NSString *decryptedContent = [partData stringByGuessingEncoding];
    if(![[self getIvar:@"MimePartIsPGPPartitionedEncodingReplacedHTMLPart"] boolValue]) {
        decryptedContent = [decryptedContent markupString];
    }
    decryptedContent = [self contentWithReplacedPGPMarker:decryptedContent isEncrypted:self.PGPEncrypted isSigned:self.PGPSigned];
    // The decrypted data might contain an inline signature.
    // If that's the case the armor is stripped from the data and stored
    // under decryptedPGPContent.
    if(self.PGPSigned)
        decryptedContent = [self stripSignatureFromContent:decryptedContent];
    
    if([self containsPGPMarker:partData]) {
        self.PGPPartlySigned = self.PGPSigned;
        self.PGPPartlyEncrypted = self.PGPEncrypted;
    }

    return [[[NSString alloc] initWithUTF8String:[decryptedContent UTF8String]] dataUsingEncoding:NSUTF8StringEncoding];
}

- (id)decryptedMessageBodyOrDataForEncryptedData:(NSData *)encryptedData encryptedInlineRange:(NSRange)encryptedRange {
	return [self decryptedMessageBodyOrDataForEncryptedData:encryptedData encryptedInlineRange:encryptedRange isAttachment:NO];
}

- (id)decryptedMessageBodyOrDataForEncryptedData:(NSData *)encryptedData encryptedInlineRange:(NSRange)encryptedRange isAttachment:(BOOL)isAttachment {
    __block NSData *decryptedData = nil;
    __block id decryptedMimeBody = nil;
    __block NSData *partDecryptedData = nil;
    
    BOOL inlineEncrypted = encryptedRange.location != NSNotFound ? YES : NO;
    
    NSData *inlineEncryptedData = nil;
    if(inlineEncrypted)
        inlineEncryptedData = [encryptedData subdataWithRange:encryptedRange];
    
    // Decrypt the data. This will already set the most important flags on the part.
    // decryptData used to be run in a serial queue. This is no longer necessary due to
    // the fact that the password dialog blocks just fine.
    partDecryptedData = [self decryptData:inlineEncrypted ? inlineEncryptedData : encryptedData];
    
    BOOL error = partDecryptedData == nil;
    
	// If this a a pgp encrypted attachment, there's no need to further handle it,
	// then return the data.
	if(isAttachment && inlineEncrypted)
		return partDecryptedData;
	
    // Creating a new message from the PGP decrypted data for PGP/MIME encrypted messages
    // is not supposed to happen within the decryption task.
    // Otherwise it could block the decryption queue for new jobs if the decrypted message contains
    // PGP inline encrypted data which GPGMail tries to decrypt but can't since the old job didn't finish
    // yet.
    if(inlineEncryptedData) {
		
        // This part serachs for a "Charset" header and if it's found and it's not UTF-8 convert the data to UTF-8.
        NSStringEncoding encoding = [self stringEncodingFromPGPData:inlineEncryptedData];
        if (encoding != NSUTF8StringEncoding) {
            // Convert the data to UTF-8.
            NSString *decryptedString = [[NSString alloc] initWithData:partDecryptedData encoding:encoding];
            partDecryptedData = [decryptedString dataUsingEncoding:NSUTF8StringEncoding];
        }
		
        // Part decrypted data is always an NSData object,
        // due to the charset finding attempt above.
        // So if there was an error reset it to nil, otherwise
        // the original encrypted data is replaced with an empty
        // NSData object.
        if(error)
            partDecryptedData = nil;
		
        decryptedData = [self partDataByReplacingEncryptedData:encryptedData decryptedData:partDecryptedData encryptedRange:encryptedRange];
    } else
        decryptedMimeBody = [self decryptedMessageBodyFromDecryptedData:partDecryptedData];
    
    if(inlineEncrypted)
        return decryptedData;
    
    return decryptedMimeBody;    
}

- (NSStringEncoding)stringEncodingFromPGPData:(NSData *)PGPData {
    NSString *asciiData = [[NSString alloc] initWithData:PGPData encoding:NSASCIIStringEncoding];
    __autoreleasing NSString *charsetName = nil;
    [asciiData getCapturesWithRegexAndReferences:@"Charset:\\s*(?<charset>.+)\r?\n", @"${charset}", &charsetName, nil];
    
    if(![charsetName length])
        return NSUTF8StringEncoding;
    
    CFStringEncoding stringEncoding= CFStringConvertIANACharSetNameToEncoding((CFStringRef)charsetName);
    if (stringEncoding != kCFStringEncodingInvalidId) {
        stringEncoding = (CFStringEncoding)CFStringConvertEncodingToNSStringEncoding(stringEncoding);
    }
    
    return stringEncoding;
}


- (void)importAttachedKeyIfNeeded {
	GPGController *gpgc = [[GPGController alloc] init];
	
    [(GM_CAST_CLASS(MCMimePart *, id))[self topPart] enumerateSubpartsWithBlock:^(MCMimePart *part) {
		if ([part isType:@"application" subtype:@"pgp-keys"] && ![[part getIvar:@"pgp-keys-imported"] boolValue]) {
			
			NSData *unArmored = [[GPGUnArmor unArmor:[GPGMemoryStream memoryStreamForReading:[part decodedData]]] readAllData];
			
			if (unArmored) {
				NSDictionary *keysByID = [[GPGKeyManager sharedInstance] keysByKeyID];
				
				[GPGPacket enumeratePacketsWithData:unArmored block:^(GPGPacket *packet, BOOL *stop) {
					if (packet.tag == GPGPublicKeyPacketTag && !keysByID[((GPGPublicKeyPacket *)packet).keyID]) {
						*stop = YES;
						[part setIvar:@"pgp-keys-imported" value:@(YES)];
						[gpgc importFromData:unArmored fullImport:NO];
					}
				}];
			}
		}
	}];
}


#pragma mark Methods for verification

- (void)verifyData:(NSData *)signedData signatureData:(NSData *)signatureData {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return;
    }
    // In order to protect against EFAIL type of attacks, only verify part data
    // if there's no parent multipart/related involved, since in that case
    // it is very easy to hide the signed part and insert non-signed content.
    // The same goes for multipart/mixed if the multipart/signed message is not the
    // first part following. So the rule is, if any parent is multipart/mixed
    // and this is a multipart/signed part which is not the first child part,
    // don't verify.

    // Bug #1053: Detached signature recognized but not verified - results in (null) in security header
    // If however this is a attachment detached signature part, do verify it.
    MCMimePart *signedPart = [self signedPartForDetachedSignaturePart:MAIL_SELF(self)];
    if([self GMAnyParentMatchesType:@"multipart" subtype:nil] && !signedPart) {
        if([[MAIL_SELF(self) parentPart] firstChildPart] != MAIL_SELF(self)) {
            return;
        }
    }

    GPGController *gpgc = [[GPGController alloc] init];

    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];

    // If signatureData is set, the signature is detached, otherwise it's inline.
    NSArray *signatures = nil;
    if([signatureData length]) {
		
		// If the signature is type 0x00 and the text doesn't contain a \r\n, convert \n to \r\n.
		// This is needed because Mail converts \r\n to \n.
		NSArray *packets = [GPGPacket packetsWithData:signatureData];
		if([packets count]) {
			GPGSignaturePacket *packet = packets[0];
			if(packet.tag == GPGSignaturePacketTag && packet.type == 0) {
				if([signedData rangeOfData:[NSData dataWithBytes:"\r\n" length:2] options:0 range:NSMakeRange(0, [signedData length])].location == NSNotFound) {
					signedData = [[NSData alloc] initWithDataConvertingLineEndingsFromUnixToNetwork:signedData];
				}
			}
		}
		
        signatures = [gpgc verifySignature:signatureData originalData:signedData];
	} else { // Inline
		NSUInteger location = 0;
		NSRange range = [signedData rangeOfPGPInlineSignatures];
		BOOL hasOtherData = range.length != signedData.length - 1;
		
		// Is it partially signed?
		if (hasOtherData) {
            [[messageProtectionStatus plainParts] addObject:self];

			// Yes, it's partially signed.
			NSMutableData *signedDataWithMarkers = [NSMutableData data];
			NSMutableSet *allSignatures = [NSMutableSet set];
			
			// Loop through all signed parts.
			do {
				// Append the unsigned data.
				[signedDataWithMarkers appendData:[signedData subdataWithRange:NSMakeRange(location, range.location - location)]];
				
				// Get signed data.
				NSData *subData = [signedData subdataWithRange:range];
				
				// Unarmor and get cleartext.
				GPGMemoryStream *subDataStream = [GPGMemoryStream memoryStreamForReading:subData];
				NSData *cleartext = nil;
				NSData *sigData = [[GPGUnArmor unArmor:subDataStream clearText:&cleartext] readAllData];
				
				
				// Verify signature and add the GPGSignatures to our set.
				[allSignatures addObjectsFromArray:[gpgc verifySignature:sigData originalData:cleartext]];
				
				if (cleartext.length) {
					// ... and add it with markers.
					[self addPGPPartMarkerToData:signedDataWithMarkers partData:cleartext];
				}
				
				// Calculate new location and range.
				location = range.location + range.length;
				range = NSMakeRange(location, signedData.length - location);
				
				// Find next signed part.
			} while ((range = [signedData rangeOfPGPInlineSignaturesInRange:range]).length);
			
			//Append trailing unsigend data.
			[signedDataWithMarkers appendData:[signedData subdataWithRange:NSMakeRange(location, signedData.length - location)]];
			
			
			//Replace markers.
			NSString *verifiedContent = [[signedDataWithMarkers stringByGuessingEncodingWithHint:[self bestStringEncoding]] markupString];
            verifiedContent = [self stripSignatureFromContent:verifiedContent];
            verifiedContent = [self contentWithReplacedPGPMarker:verifiedContent isEncrypted:NO isSigned:YES];
			
			// Set results.
			self.PGPVerifiedContent = verifiedContent;
			signedData = signedDataWithMarkers;
			
			signatures = [allSignatures allObjects];
		} else { // Not partially signed.
			signatures = [gpgc verifySignedData:signedData];
            NSMutableData *signedDataWithMarkers = [NSMutableData data];
            [self addPGPPartMarkerToData:signedDataWithMarkers partData:signedData];
            NSString *verifiedContent = [[signedDataWithMarkers stringByGuessingEncodingWithHint:[self bestStringEncoding]] markupString];
            verifiedContent = [self stripSignatureFromContent:verifiedContent];
            verifiedContent = [self contentWithReplacedPGPMarker:verifiedContent isEncrypted:NO isSigned:YES];

            self.PGPVerifiedContent = verifiedContent;
		}
	}
    
    NSError *error = [self errorFromGPGOperation:GPG_OPERATION_VERIFICATION controller:gpgc];
    self.PGPError = error;
	// If MacGPG2 is not installed, don't flag the message as signed,
	// since we can't know.
    // Only recognize the part as signed if signature information is available.
    self.PGPSigned = [gpgc.error isKindOfClass:[GPGException class]] && ((GPGException *)gpgc.error).errorCode == GPGErrorNotFound ? NO : [signatures count] != 0;
    self.PGPVerified = self.PGPError ? NO : YES;
    self.PGPSignatures = signatures;
    
    // To better protect against EFAIL kind of attacks, a CID on a signed text part
    // is removed, since it doesn't really make much sense in the first place.
    if([MAIL_SELF(self) isType:@"text" subtype:nil] && [[MAIL_SELF(self) contentID] length]) {
        [MAIL_SELF(self) setContentID:nil];
    }

    if([signatures count]) {
        [[messageProtectionStatus signedParts] addObject:self];
    }
    
    self.PGPVerifiedData = signedData;
    
}

- (NSStringEncoding)bestStringEncoding {
    NSString *charsetName = [MAIL_SELF(self) bodyParameterForKey:@"charset"];
    // No charset name available on current part? Test top part.
    if(![charsetName length]) {
        charsetName = [[self topPart] bodyParameterForKey:@"charset"];
        if(![charsetName length])
            return NSUTF8StringEncoding;
    }
    CFStringEncoding stringEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)charsetName);
    
    if (stringEncoding != kCFStringEncodingInvalidId)
        stringEncoding = (CFStringEncoding)CFStringConvertEncodingToNSStringEncoding(stringEncoding);
    
    return stringEncoding;
}

- (BOOL)hasPGPInlineSignature:(NSData *)data {
    NSData *inlineSignatureMarkerHead = [PGP_SIGNED_MESSAGE_BEGIN dataUsingEncoding:NSASCIIStringEncoding];
    if([data rangeOfData:inlineSignatureMarkerHead options:0 range:NSMakeRange(0, [data length])].location != NSNotFound)
        return YES;
    return NO;
}

- (NSData *)signedDataWithAddedPGPPartMarkersIfNecessaryForData:(NSData *)signedData {
    NSRange signedRange = NSMakeRange(NSNotFound, 0);
    if([signedData length] != 0)
        signedRange = [signedData rangeOfPGPInlineSignatures];
    
    // Should never happen!
    if(signedRange.location == NSNotFound)
        return signedData;
    
    
    NSMutableData *partData = [[NSMutableData alloc] init];
    
    // Use a regular expression to find data before and after the signed part.
    NSString *regex = [NSString stringWithFormat:@"(?sm)^(?<whitespace_before>(\r?\n)*)(?<before>.*)%@\r?\n(?<headers>[\\w\\s:]*)\r?\n\r?\n(?<signed_text>.*)%@.*%@(?<whitespace_after>(\r?\n)*)(?<after>.*)$",PGP_SIGNED_MESSAGE_BEGIN, PGP_MESSAGE_SIGNATURE_BEGIN, PGP_MESSAGE_SIGNATURE_END];
    
    NSStringEncoding bestEncoding = [self bestStringEncoding];
    RKEnumerator *matches = [[signedData stringByGuessingEncodingWithHint:bestEncoding] matchEnumeratorWithRegex:regex];
    
    NSMutableData *markedPart = [NSMutableData data];
    __autoreleasing NSString *before = nil, *signedText = nil, *after = nil, *whitespaceBefore = nil,
             *whitespaceAfter = nil, *headers = nil;
    
    while([matches nextRanges] != NULL) {
        [matches getCapturesWithReferences:@"${before}", &before, nil];
        [matches getCapturesWithReferences:@"${signed_text}", &signedText, nil];
        [matches getCapturesWithReferences:@"${after}", &after, nil];
        [matches getCapturesWithReferences:@"${whitespace_before}", &whitespaceBefore, nil];
        [matches getCapturesWithReferences:@"${whitespace_after}", &whitespaceAfter, nil];
        [matches getCapturesWithReferences:@"${headers}", &headers, nil];
        
        [self addPGPPartMarkerToData:markedPart partData:[signedText dataUsingEncoding:bestEncoding]];
    }
    
    if(![before length] && ![after length]) {
        return signedData;
    }
    
    [partData appendData:[whitespaceBefore dataUsingEncoding:bestEncoding]];
    [partData appendData:[before dataUsingEncoding:bestEncoding]];
    [partData appendData:markedPart];
    [partData appendData:[whitespaceAfter dataUsingEncoding:bestEncoding]];
    [partData appendData:[after dataUsingEncoding:bestEncoding]];
    
    return partData;
}

- (void)MAVerifySignature {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![(MimePart_GPGMail *)self shouldBePGPProcessed]) {
        return [self MAVerifySignature];
    }
    // If this is a non GPG signed message, let's call the original method
    // and get out of here!    
    if(![[MAIL_SELF(self) bodyParameterForKey:@"protocol"] isEqualToString:@"application/pgp-signature"]) {
        [self MAVerifySignature];
        return;
    }
    
    if(self.PGPVerified || self.PGPError || self.PGPVerifiedData) {
        // Save the status for isMimeSigned call.
        [[self topPart] setIvar:@"MimeSigned" value:@(self.PGPSigned)];
        return;
    }
	
    // Now on to fetching the signed data.
    NSData *signedData = [MAIL_SELF(self) signedData];
    // And last finding the signature.
    MCMimePart *signaturePart = nil;
    for(MCMimePart *part in [MAIL_SELF(self) subparts]) {
        if([part isType:@"application" subtype:@"pgp-signature"]) {
            signaturePart = part;
            break;
        }
    }
    
    if(![signedData length] || !signaturePart) {
        self.PGPSigned = NO;
        return;
    }
    
    // And now the funny part, the actual verification.
    NSData *signatureData = [signaturePart decodedData];
	if (![signatureData length]) {
		self.PGPSigned = NO;
        return;
	}
    
    [self verifyData:signedData signatureData:signatureData];
    GMMessageProtectionStatus *messageProtectionStatus = [self GMMessageProtectionStatus];

    if([self.PGPSignatures count]) {
        self.PGPSigned = YES;
    }
    else {
        self.PGPSigned = NO;
        [messageProtectionStatus.plainParts addObject:MAIL_SELF(self)];
    }
    [[self topPart] setIvar:@"MimeSigned" value:@(self.PGPSigned)];
	
    return;
}

- (void)_verifyPGPInlineSignatureInData:(NSData *)data {
    // Pass in the entire NSData to detect part-signed messages.
    [self verifyData:data signatureData:nil];
}

- (id)stripSignatureFromContent:(id)content {
    if([content isKindOfClass:[NSString class]]) {
        // Find -----BEGIN PGP SIGNED MESSAGE----- and
        // remove everything to the next empty line.
        NSRange beginRange = [content rangeOfString:PGP_SIGNED_MESSAGE_BEGIN];
        if(beginRange.location == NSNotFound)
            return content;

        NSString *contentBefore = [content substringWithRange:NSMakeRange(0, beginRange.location)];
        
        NSString *remainingContent = [content substringWithRange:NSMakeRange(beginRange.location + beginRange.length, 
                                                                             [(NSString *)content length] - (beginRange.location + beginRange.length))];
        // Find the first occurence of two newlines (\n\n). This is HTML so it's <BR><BR> (can't be good!)
        // This delimits the signature part.
        NSRange signatureDelimiterRange = [remainingContent rangeOfString:@"<BR><BR>"];
        // Signature delimiter range only contains the range from the first <BR> to the
        // second <BR>. But it's necessary to remove everything before that.
        if(signatureDelimiterRange.location == NSNotFound)
            return content;
        
        signatureDelimiterRange.length = signatureDelimiterRange.location + signatureDelimiterRange.length;
        signatureDelimiterRange.location = 0;
        
        remainingContent = [remainingContent stringByReplacingCharactersInRange:signatureDelimiterRange withString:@""];

        // Now, there might be signatures in the quoted text, but the only interesting signature, will be at the end of the mail, that's
        // why the search is time done from the end.
        NSRange startRange = [remainingContent rangeOfString:PGP_MESSAGE_SIGNATURE_BEGIN options:NSBackwardsSearch];
        if(startRange.location == NSNotFound)
            return content;
        NSRange endRange = [remainingContent rangeOfString:PGP_MESSAGE_SIGNATURE_END options:NSBackwardsSearch];
        if(endRange.location == NSNotFound)
            return content;
        NSRange gpgSignatureRange = NSUnionRange(startRange, endRange);
        NSString *strippedContent = [remainingContent stringByReplacingCharactersInRange:gpgSignatureRange withString:@""];

        NSString *completeContent = [contentBefore stringByAppendingString:strippedContent];
        
        return completeContent;
    }
    return content;
}

- (BOOL)MAUsesKnownSignatureProtocol {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    
	// It looks like, among other things, Mail.app uses this method to determine
	// whether the message is S/MIME signed, in order to then decide,
	// HOW the message body should be fetched from the server, which
	// is pretty significant for signed messages.
	// See ticket #600 to find out more.
	// In order to force Mail.app to fetch PGP/MIME signed messages the exact
	// same way as S/MIME signed messages, return YES if the protocol
	// of the mime part matches application/pgp-signature.
	// shouldBePGPProcessed is ignored at this stage, since the mimeBody
	// nor the message are yet available.
	
	if(![(MimePart_GPGMail *)[self topPart] shouldBePGPProcessed])
        return [self MAUsesKnownSignatureProtocol];
    
    if([[[MAIL_SELF(self) bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pgp-signature"])
        return YES;
    return [self MAUsesKnownSignatureProtocol];
}

- (void)addPGPPartMarkerToData:(NSMutableData *)data partData:(NSData *)partData {
    [data appendData:[PGP_PART_MARKER_START dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:partData];
    [data appendData:[PGP_PART_MARKER_END dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)contentWithReplacedPGPMarker:(NSString *)content isEncrypted:(BOOL)isEncrypted isSigned:(BOOL)isSigned {
    NSMutableString *partString = [NSMutableString string];
    if(isEncrypted)
        [partString appendString:GMLocalizedString(@"MESSAGE_VIEW_PGP_PART_ENCRYPTED")];
    if(isEncrypted && isSigned)
        [partString appendString:@" & "];
    if(isSigned)
        [partString appendString:GMLocalizedString(@"MESSAGE_VIEW_PGP_PART_SIGNED")];
    
    [partString appendFormat:@" %@", GMLocalizedString(@"MESSAGE_VIEW_PGP_PART")];
    
    NSRange pgpContentPartStartRange = [content rangeOfString:PGP_PART_MARKER_START];
    NSRange pgpContentPartEndRange = [content rangeOfString:PGP_PART_MARKER_END];
    
    NSString *pgpContentPart = [content substringWithRange:NSMakeRange(pgpContentPartStartRange.location + pgpContentPartStartRange.length,
                                                                       pgpContentPartEndRange.location - (pgpContentPartStartRange.location + pgpContentPartStartRange.length))];
    GMContentPartsIsolator *contentIsolator = [self GMContentPartsIsolator];
    NSString *isolatedContent = [contentIsolator isolationMarkupForContent:pgpContentPart mimePart:MAIL_SELF(self)];

    content = [content stringByReplacingCharactersInRange:NSMakeRange(pgpContentPartStartRange.location,(pgpContentPartEndRange.location + pgpContentPartEndRange.length) - pgpContentPartStartRange.location) withString:isolatedContent];

    return content;
}

- (BOOL)containsPGPMarker:(NSData *)data {
    if(![data length])
        return NO;
    return [data rangeOfData:[PGP_PART_MARKER_START dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [data length])].location != NSNotFound;
}

#pragma mark MimePart property implementation.

- (void)setPGPEncrypted:(BOOL)PGPEncrypted {
    [self setIvar:@"PGPEncrypted" value:@(PGPEncrypted)];
}

- (BOOL)PGPEncrypted {
    return [[self getIvar:@"PGPEncrypted"] boolValue];
}

- (void)setPGPSigned:(BOOL)PGPSigned {
    [self setIvar:@"PGPSigned" value:@(PGPSigned)];
}

- (BOOL)PGPSigned {
    return [[self getIvar:@"PGPSigned"] boolValue];
}

- (void)setPGPPartlySigned:(BOOL)PGPPartlySigned {
    [self setIvar:@"PGPPartlySigned" value:@(PGPPartlySigned)];
}

- (BOOL)PGPPartlySigned {
    return [[self getIvar:@"PGPPartlySigned"] boolValue];
}

- (void)setPGPPartlyEncrypted:(BOOL)PGPPartlyEncrypted {
    [self setIvar:@"PGPPartlyEncrypted" value:@(PGPPartlyEncrypted)];
}

- (BOOL)PGPPartlyEncrypted {
    return [[self getIvar:@"PGPPartlyEncrypted"] boolValue];
}

- (void)setPGPDecrypted:(BOOL)PGPDecrypted {
    [self setIvar:@"PGPDecrypted" value:@(PGPDecrypted)];
}

- (BOOL)PGPDecrypted {
    return [[self getIvar:@"PGPDecrypted"] boolValue];
}

- (void)setPGPVerified:(BOOL)PGPVerified {
    [self setIvar:@"PGPVerified" value:@(PGPVerified)];
}

- (BOOL)PGPVerified {
    return [[self getIvar:@"PGPVerified"] boolValue];
}

- (void)setPGPAttachment:(BOOL)PGPAttachment {
    [self setIvar:@"PGPAttachment" value:@(PGPAttachment)];
}

- (BOOL)PGPAttachment {
    return [[self getIvar:@"PGPAttachment"] boolValue];
}

- (void)setPGPSignatures:(NSArray *)PGPSignatures {
    [self setIvar:@"PGPSignatures" value:PGPSignatures];
}

- (NSArray *)PGPSignatures {
    return [self getIvar:@"PGPSignatures"];
}

- (void)setPGPError:(NSError *)PGPError {
    [self setIvar:@"PGPError" value:PGPError];
}

- (NSError *)PGPError {
    return [self getIvar:@"PGPError"];
}

// TODO: Remove - should no longer be necessary.
//- (void)setPGPDecryptedData:(NSData *)PGPDecryptedData {
//    [self setIvar:@"PGPDecryptedData" value:PGPDecryptedData];
//}
//
//- (NSData *)PGPDecryptedData {
//    return [self getIvar:@"PGPDecryptedData"];
//}
//
//- (void)setPGPDecryptedContent:(NSString *)PGPDecryptedContent {
//    [self setIvar:@"PGPDecryptedContent" value:PGPDecryptedContent];
//}
//
//- (NSString *)PGPDecryptedContent {
//    return [self getIvar:@"PGPDecryptedContent"];
//}

- (void)setPGPDecryptedBody:(MCMimeBody *)PGPDecryptedBody {
    [self setIvar:@"PGPDecryptedBody" value:PGPDecryptedBody];
}

- (MCMimeBody *)PGPDecryptedBody {
    return [self getIvar:@"PGPDecryptedBody"];
}

- (void)setPGPVerifiedContent:(NSString *)PGPVerifiedContent {
    [self setIvar:@"PGPVerifiedContent" value:PGPVerifiedContent];
}

- (NSString *)PGPVerifiedContent {
    return [self getIvar:@"PGPVerifiedContent"];
}

- (void)setPGPVerifiedData:(NSData *)PGPVerifiedData {
    [self setIvar:@"PGPVerifiedData" value:PGPVerifiedData];
}

- (NSData *)PGPVerifiedData {
    return [self getIvar:@"PGPVerifiedData"];
}

- (void)setPGPEmbeddedFilename:(NSString *)filename {
    [self setIvar:@"MimePartPGPEmbeddedFilename" value:filename];
}

- (NSString *)PGPEmbeddedFilename {
    return [self getIvar:@"MimePartPGPEmbeddedFilename"];
}

#pragma mark other stuff to test Xcode code folding.

- (BOOL)MAIsSigned {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![(MimePart_GPGMail *)[self topPart] shouldBePGPProcessed])
        return [self MAIsSigned];
    
    BOOL ret = [self MAIsSigned];
    // For plain text message is signed doesn't automatically find
    // the right signed status, so we check if copy signers are available.
    return ret || self.PGPSigned;
}

- (BOOL)_isExchangeServerModifiedPGPMimeEncrypted {
    if(![MAIL_SELF(self) isType:@"multipart" subtype:@"mixed"])
        return NO;
    // Find the application/pgp-encrypted subpart.
    NSArray *subparts = [MAIL_SELF(self) subparts];
    MCMimePart *applicationPGPEncrypted = nil;
    MCMimePart *PGPDataPart = nil;
    for(MCMimePart *part in subparts) {
        // There's a new kid on the block, which apparently sends messages which look exactly
        // like an Exchange Modified message (multipart/mixed and application/pgp-encrypted part), but
        // instead is a simple message with a pgp attachment with mime type application/pgp-encrypted.
        // In order to be super-compatible to all kind of bullshit structures, the assumption is,
        // that if the extension of the filename is .asc, this is a exchange server modified message
        // otherwise not.
        if([part isType:@"application" subtype:@"pgp-encrypted"] && [[(MimePart_GPGMail *)part GMBodyData] containsPGPVersionMarker:1]) {
            applicationPGPEncrypted = part;
        }
        BOOL partHasPGPFilename = [[[part attachmentFilename] lowercaseString] isEqualToString:@"encrypted.asc"] ||
                                  [[[part bodyParameterForKey:@"name"] lowercaseString] isEqualToString:@"encrypted.asc"];
        BOOL partHasPGPExtension = [[[[part attachmentFilename] pathExtension] lowercaseString] isEqualToString:@"asc"] ||
                                   [[[part bodyParameterForKey:@"name"] pathExtension] lowercaseString];
        if([part isType:@"application" subtype:@"octet-stream"] && (partHasPGPFilename || partHasPGPExtension)) {
            PGPDataPart = part;
        }
    }
    // If such a part is found, the message is exchange modified, otherwise
    // not.
    return applicationPGPEncrypted != nil && PGPDataPart != nil;
}

- (BOOL)_isPretendPGPMIME {
    // Pretend PGP MIME is a part that has the content-type application/pgp-encrypted,
    // but as body data contains a simple PGP encrypted file and not a PGP encrypted file
    // with an RFC message.
    // To simplify the check, the filename is tested for an extension != .asc

    __block MCMimePart *applicationPGPEncrypted = nil;
    __block BOOL hasMultipartEncryptedPart = NO;
    NSArray *pgpEncryptedFileExtensions = @[@"pgp", @"gpg"];
    [(MimePart_GPGMail *)[self topPart] enumerateSubpartsWithBlock:^(MCMimePart *part) {
        if([part isType:@"application" subtype:@"pgp-encrypted"] &&
           ([pgpEncryptedFileExtensions containsObject:[[[part bodyParameterForKey:@"name"] pathExtension] lowercaseString]] ||
            [pgpEncryptedFileExtensions containsObject:[[[part attachmentFilename] pathExtension] lowercaseString]])) {
            applicationPGPEncrypted = part;
            return;
        }
        if([part isType:@"multipart" subtype:@"encrypted"]) {
            hasMultipartEncryptedPart = YES;
            return;
        }
    }];

    return applicationPGPEncrypted != nil && ![self _isExchangeServerModifiedPGPMimeEncrypted] && !hasMultipartEncryptedPart;
}

- (BOOL)_isDraftThatHasBeenReEncryptedWithoutBeingDecrypted {
	// Problem:
	//
	//   When a user continues composing a draft, the draft should always be automatically
	//   decrypted, so that the detail that the draft is encrypted is invisible to the user.
	//   Under some circumstances, the automated decryption of the draft fails.
	//   If at the same time Mail's autosave of drafts kicks in, the still encrypted draft,
	//   is saved again as a multipart/related message with a text/html part for the actual contents
	//   and two attachments: the PGP/MIME application/pgp-encrypted version part and the encrypted.asc
	//   data part.
	//   Now if the user tries to continue working on the draft, GPGMail no longer recognizes
	//   the draft as PGP/MIME encrypted, and fails to properly decrypt it.
	//
	// Solution:
	//
	//   The solution is to teach GPGMail the structure of those falsely encrypted not automatically decrypted
	//   drafts, in order to recognize that it should still treat them as normal PGP/MIME encrypted messages.
	//   In order to do that, the following facts have to be true:
	//
	//   - Must have a multipart/related part
	//   - Must have an application/pgp-encrypted attachment
	//   - Must have an application/octet-stream attachment with filename set to encrypted.asc
	//
	if(![[self topPart] isType:@"multipart" subtype:@"related"]) {
		return NO;
	}

	__block MCMimePart *versionPart = nil;
	__block MCMimePart *dataPart = nil;
	__block MCMimePart *htmlPart = nil;
	[(MimePart_GPGMail *)[self topPart] enumerateSubpartsWithBlock:^(MCMimePart *mimePart) {
		if([mimePart isType:@"application" subtype:@"pgp-encrypted"]) {
			versionPart = mimePart;
			return;
		}
		if([mimePart isType:@"application" subtype:@"octet-stream"] && [[[mimePart dispositionParameterForKey:@"filename"] lowercaseString] isEqualToString:@"encrypted.asc"]) {
			dataPart = mimePart;
			return;
		}
		if([mimePart isType:@"text" subtype:@"html"]) {
			htmlPart = mimePart;
			return;
		}
	}];

	return versionPart && dataPart && htmlPart;
}

- (BOOL)isPseudoPGPMimeMessageFromiPGMail {
    // Following requirements have to be satisfied:
    // 1.) Part with content-type application/pgp-encrypted
    // 2.) "Version: iPGMail" in the PGP encrypted part.
    __block MCMimePart *encryptedDataPart = nil;

    [(MimePart_GPGMail *)[self topPart] enumerateSubpartsWithBlock:^(MCMimePart *mimePart) {
        if([mimePart isType:@"application" subtype:@"pgp-encrypted"]) {
            encryptedDataPart = mimePart;
            return;
        }
    }];

    if(!encryptedDataPart) {
        return NO;
    }

    return [[encryptedDataPart decodedData] containsPGPVersionString:@"iPGMail"];
}

- (BOOL)isPseudoPGPMimeTextPartFromiPGMail {
    // Following requirements have to be satisfied:
    // 1.) Part with content-type application/pgp-encrypted
    // 2.) "Version: iPGMail" in the PGP encrypted part.
    return [MAIL_SELF(self) isType:@"application" subtype:@"pgp-encrypted"] && [[MAIL_SELF(self) decodedData] containsPGPVersionString:@"iPGMail"];
}

- (BOOL)isPGPMimeEncrypted {
    // Special case for PGP/MIME encrypted emails, which were sent through an
    // exchange server, which unfortunately modifies the header.
    if([self _isExchangeServerModifiedPGPMimeEncrypted] && ![self isPseudoPGPMimeMessageFromiPGMail])
        return YES;
	if([self _isDraftThatHasBeenReEncryptedWithoutBeingDecrypted])
		return YES;

    // Bug #938: iPGMail is not capable of creating a proper PGP/MIME structure due to restrictions of iOS
    // Since the application/pgp-encrypted content-type can be used for any pgp encrypted attachment,
    // GPGMail currently treats it as an attachment, where it should display the contents of the attachment
    // as another text/html part of the message.
    // In order to properly treat it as non-PGP/MIME message, return false
    // if -[MCMimePart isPseudoPGPMimeMessageFromiPGMail] returns true.
    if([self isPseudoPGPMimeMessageFromiPGMail]) {
        return NO;
    }
	// Check for multipart/encrypted, protocol application/pgp-encrypted, otherwise exit!
    if(![MAIL_SELF(self) isType:@"multipart" subtype:@"encrypted"])
        return NO;
    
    if([self _isPretendPGPMIME]) {
        return NO;
    }

    if([MAIL_SELF(self) bodyParameterForKey:@"protocol"] != nil && ![[[MAIL_SELF(self) bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pgp-encrypted"])
        return NO;
    
	// While the standard says there are to be exactly 2 child parts,
	// there are some services like Microsoft Exchange (what a surprise)
	// and MyMailWall which like to add parts.
	// Also most iOS solutions are not able to create fully PGP/MIME compatible messages.
	// So let's show some leniency for the greater good.
	// IF we can find both parts, the version part and the data part, let's pretend
	// like everything's fine.
	
	// Past me believes FireGPG < 0.7.1 included the actual encrypted data in a pgp-signature
	// part so let's check for that as well.
	
	__block MCMimePart *versionPart = nil;
	__block MCMimePart *dataPart = nil;
    // It appears that Avast antivirus doesn't like the pre-amble of PGP/MIME message, which is
    // often placed before the application/pgp-encrypted part, and creates a second application/pgp-encrypted
    // part, using that pre-amble.
    // Unfortunately this moves the PGP/MIME version marker from the first version part, to the second and causes
    // the old check to fail, which only assumed one version part. Now each version part is checked
    // for the PGP/MIME version marker.
    __block NSMutableArray *versionParts = [[NSMutableArray alloc] init];
    [self enumerateSubpartsWithBlock:^(MCMimePart *part) {
		if([part isType:@"application" subtype:@"pgp-encrypted"]) {
            [versionParts addObject:part];
            if(!versionPart)
				versionPart = part;
		}
		else if([part isType:@"application" subtype:@"octet-stream"] || [part isType:@"application" subtype:@"pgp-signature"]) {
			if(!dataPart)
				dataPart = part;
		}
	}];

    BOOL hasVersion = NO;
    for(MCMimePart *part in versionParts) {
        if([[part decodedData] containsPGPVersionMarker:1]) {
            hasVersion = YES;
            break;
        }
    }
	// Should we check the version...?
	if(versionPart && hasVersion && dataPart)
		return YES;
	
	return NO;
}

- (BOOL)MAIsAttachment {
    BOOL ret = [self MAIsAttachment];
    if([self isPseudoPGPMimeTextPartFromiPGMail]) {
        return NO;
    }
    return ret;
}

- (BOOL)MAIsEncrypted {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![(MimePart_GPGMail *)[self topPart] shouldBePGPProcessed])
        return [self MAIsEncrypted];
    
    if(self.PGPEncrypted)
        return YES;
    
    // Otherwise to also support S/MIME encrypted messages, call
    // the original method.
    return [self MAIsEncrypted];
}

// TODO: Remove - should no longer be necessary.
//- (BOOL)MAIsMimeEncrypted {
//    BOOL ret = [self MAIsMimeEncrypted];
//    BOOL isPGPMimeEncrypted = [[[(MimeBody_GPGMail *)[[self topPart] mimeBody] message] getIvar:@"MimeEncrypted"] boolValue];
//    return ret || isPGPMimeEncrypted;
//}
//
//- (BOOL)MAIsMimeSigned {
//    BOOL ret = [self MAIsMimeSigned];
//    BOOL isPGPMimeSigned = [[[self topPart] getIvar:@"MimeSigned"] boolValue];
//    return ret || isPGPMimeSigned;
//}

//- (Message *)messageWithMessageData:(NSData *)messageData {
//    MCMutableMessageHeaders *headers = [MCMutableMessageHeaders new];
//    NSMutableString *contentTypeString = [[NSMutableString alloc] init];
//    [contentTypeString appendFormat:@"%@/%@", MAIL_SELF(self).type, MAIL_SELF(self).subtype];
//    if([MAIL_SELF(self) bodyParameterForKey:@"charset"])
//        [contentTypeString appendFormat:@"; charset=\"%@\"", [MAIL_SELF(self) bodyParameterForKey:@"charset"]];
//    [headers setHeader:[contentTypeString dataUsingEncoding:NSASCIIStringEncoding] forKey:@"Content-Type"];
//    if(MAIL_SELF(self).contentTransferEncoding)
//        [headers setHeader:MAIL_SELF(self).contentTransferEncoding forKey:@"Content-Transfer-Encoding"];
//
//    NSMutableData *completeMessageData = [[NSMutableData alloc] init];
//    [completeMessageData appendData:[headers encodedHeadersIncludingFromSpace:NO]];
//    [completeMessageData appendData:messageData];
//
//    Message *message = [GM_MAIL_CLASS(@"Message") messageWithRFC822Data:completeMessageData];
//
//    return message;
//}

- (void)MAClearCachedDecryptedMessageBody {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![(MimePart_GPGMail *)[self topPart] shouldBePGPProcessed])
        return [self MAClearCachedDecryptedMessageBody];
    
    /* The original method is called to clear PGP/MIME messages. */
    // Loop through the parts and clear them.
    [self enumerateSubpartsWithBlock:^(MCMimePart *currentPart) {
        [currentPart removeIvars];
    }];
    //[[[self mimeBody] message] clearPGPInformation];
    [self MAClearCachedDecryptedMessageBody];
}

#pragma mark Methods for creating a new message.

- (NSMutableSet *)flattenedKeyList:(NSSet *)keyList {
    NSMutableSet *flattenedList = [NSMutableSet setWithCapacity:0];
    for(id item in keyList) {
        if([item isKindOfClass:[NSArray class]]) {
            [flattenedList addObjectsFromArray:item];
        }
        else if([item isKindOfClass:[NSSet class]]) {
            [flattenedList unionSet:item];
        }
        else
            [flattenedList addObject:item];
    }
    return flattenedList;
}


//- (id)MANewEncryptedPartWithData:(NSData *)data recipients:(id)recipients encryptedData:(NSData **)encryptedData NS_RETURNS_RETAINED {
- (id)newEncryptedPartWithData:(NSData *)data certificates:(NSArray *)certificates partData:(__autoreleasing NSMapTable **)partData {
    NSMapTable *encryptedPartData = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    
    BOOL isDraft = NO;
    
    GPGKey *senderPublicKey = nil;
    
    // TODO: Move encrypttoself logic to ComposeBackEnd.
    // Split the recipients in normal and bcc recipients.
    BOOL encryptToSelf = [[GPGOptions sharedOptions] boolForKey:@"EncryptToSelf"];
    NSMutableArray *normalRecipients = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *bccRecipients = [NSMutableArray arrayWithCapacity:1];
    
    __block NSMutableArray *flattenedCertificates = [NSMutableArray array];
    // In order to support gnupg groups, each certificate array entry is an array
    // with one or more than one key. (#903)
    [certificates enumerateObjectsUsingBlock:^(id  obj, __unused NSUInteger idx, __unused BOOL * stop) {
        if(![obj isKindOfClass:[NSArray class]]) {
            [flattenedCertificates addObject:obj];
        }
        else {
            [flattenedCertificates addObjectsFromArray:obj];
        }
    }];

    for (GPGKey *recipient in flattenedCertificates) {
        // TODO: Make sure no cert type is in recipients.
        if(![recipient isKindOfClass:[GPGKey class]]) {
            continue;
        }
        // TODO: Add logic to handle bcc recipients.
//        NSString *recipientType = [recipient valueForFlag:@"recipientType"];
        NSString *recipientType = nil;
        if ([recipientType isEqualTo:@"bcc"]) {
            [bccRecipients addObject:recipient];
        } else {
            // If encryptToSelf is disabled, don't add the sender to the recipients.
            // Of course this has the effect that the sent mails can't be read by the sender,
            // but that's exactly what this option is for.
            if ([recipientType isEqualToString:@"from"]) {
                //senderPublicKey = [recipient valueForFlag:@"gpgKey"];
                
                // TODO: Handle this logic in ComposeBackEnd if possible (probably not).
                // Drafts are only encrypted with the senders key.
//                if ([[certificates valueForFlag:@"isDraft"] boolValue]) {
//                    isDraft = YES;
//                    [normalRecipients removeAllObjects];
//                    [bccRecipients removeAllObjects];
//                    senderPublicKey = [[recipient valueForFlag:@"DraftPublicKey"] primaryKey];
//                    [normalRecipients addObject:senderPublicKey];
//                    
//                    break;
//                }
                
                
                if (!encryptToSelf)
                    continue;
                
                // In order to fix a problem where a random key matching an address
                // is chosen for encrypt-to-self, the senderKey is queried for its
                // public key and the from address is not added to the list of normal
                // recipients. (#608)
                if (senderPublicKey) {
                    continue;
                }
            }
            [normalRecipients addObject:recipient];
        }
    }
    
    NSMutableSet *flattenedNormalKeyList = nil, *flattenedBCCKeyList = nil;
    
    // Ask the mail bundle for the GPGKeys matching the email address.
    NSMutableSet *normalKeyList = [[NSMutableSet alloc] initWithArray:normalRecipients];
    if(senderPublicKey)
        [normalKeyList addObject:senderPublicKey];
    NSMutableSet *bccKeyList = [[NSMutableSet alloc] initWithArray:bccRecipients];
    [bccKeyList minusSet:normalKeyList];
    
    flattenedNormalKeyList = normalKeyList;
    flattenedBCCKeyList = bccKeyList;
    
    
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.useArmor = YES;
    gpgc.useTextMode = YES;
    // Automatically trust keys, even though they are not specifically
    // marked as such.
    // Eventually add warning for this.
    gpgc.trustAllKeys = YES;
    NSData *encryptedData = nil;
    @try {
        GPGEncryptSignMode encryptMode = GPGPublicKeyEncrypt;
        
        encryptedData = [gpgc processData:data withEncryptSignMode:encryptMode recipients:flattenedNormalKeyList hiddenRecipients:flattenedBCCKeyList];
        
        if (gpgc.error) {
            @throw gpgc.error;
        }
    }
    @catch(NSException *e) {
        GPGErrorCode errorCode = [e isKindOfClass:[GPGException class]] ? ((GPGException *)e).errorCode : 1;
        [self failedToEncryptForRecipients:certificates gpgErrorCode:errorCode error:gpgc.error];
        if (errorCode == GPGErrorCancelled) {
            // TODO: This sure is not right.
            return [NSData data];
        }
        return nil;
    }
    @finally {
        gpgc = nil;
    }
    
    if(!encryptedData) {
        return nil;
    }
    
    // 1. Create a new mime part for the encrypted data.
    // -> Problem in the past was that S/MIME only has one mime part GPG/MIME has two, one for
    // -> the version, one for the data.
    // -> To work around this in Sierra, GPGMail has been adjusted to hook into the message creation
    // -> method of MCMessageGenerator, -[MCMessageGenerator _newOutgoingMessageFromTopLevelMimePart:topLevelHeaders:withPartData:]
    // -> newEncryptedPartWithData:certificates:partData is more powerful now than its previous version.
    // -> Now it's possible to configure the entire mime tree for the multipart/encrypted message
    // -> and return the data to be associated with each part as well, by using the partData map.
    MCMimePart *dataPart = [[MCMimePart alloc] init];
    
    [dataPart setType:@"application"];
    [dataPart setSubtype:@"octet-stream"];
    [dataPart setBodyParameter:@"encrypted.asc" forKey:@"name"];
    dataPart.contentTransferEncoding = @"7bit";
    [dataPart setDisposition:@"inline"];
    [dataPart setDispositionParameter:@"encrypted.asc" forKey:@"filename"];
    [dataPart setContentDescription:@"OpenPGP encrypted message"];
    
    MCMimePart *versionPart = [[MCMimePart alloc] init];
    [versionPart setType:@"application"];
    [versionPart setSubtype:@"pgp-encrypted"];
    [versionPart setContentDescription:@"PGP/MIME Versions Identification"];
    versionPart.contentTransferEncoding = @"7bit";
    
    MCMimePart *topLevelEncryptedPart = [[MCMimePart alloc] init];
    [topLevelEncryptedPart setType:@"multipart"];
    [topLevelEncryptedPart setSubtype:@"encrypted"];
    [topLevelEncryptedPart setBodyParameter:@"application/pgp-encrypted" forKey:@"protocol"];
    
    [topLevelEncryptedPart addSubpart:versionPart];
    [topLevelEncryptedPart addSubpart:dataPart];

    if(encryptedData) {
        [encryptedPartData setObject:encryptedData forKey:dataPart];
    }
    // TODO: Maybe necessary to re-add \r\n at the end.
    NSData *versionData = [@"Version: 1\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    [encryptedPartData setObject:versionData forKey:versionPart];

    NSData *topData = [@"This is an OpenPGP/MIME encrypted message (RFC 2440 and 3156)" dataUsingEncoding:NSASCIIStringEncoding];
    [encryptedPartData setObject:topData forKey:topLevelEncryptedPart];

    *partData = encryptedPartData;
    
    return topLevelEncryptedPart;
    
////    DebugLog(@"[DEBUG] %s enter", __PRETTY_FUNCTION__);
//    // First thing todo, check if an address with the gpg-mail prefix is found.
//    // If not, S/MIME is wanted.
//    NSArray *prefixedAddresses = [recipients filter:^id (id recipient){
//        //TODO: Make sure no cert instance are in the recipients.
//        if(![recipient isKindOfClass:[NSString class]]) {
//            return nil;
//        }
//        return [(NSString *)recipient isFlaggedValue] ? recipient : nil;
//    }];
//    if(![prefixedAddresses count])
//        return [self MANewEncryptedPartWithData:data recipients:recipients encryptedData:encryptedData];
//
//	
//	// Search for gpgErrorIdentifier in data.
//	NSRange range = [data rangeOfData:[gpgErrorIdentifier dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [data length])];
//	if (range.length > 0) {
//		// Simply set data as encryptedData to preserve the errorCode.
//		*encryptedData = data;
//		MCMimePart *dataPart = [[GM_MAIL_CLASS(@"MimePart") alloc] init];
//		return dataPart;
//	}
//	
//	BOOL symmetricEncrypt = NO;
//	BOOL doNotPublicEncrypt = NO;
//	BOOL isDraft = NO;
//	
//	GPGKey *senderPublicKey = nil;
//	
//	// Split the recipients in normal and bcc recipients.
//	BOOL encryptToSelf = [[GPGOptions sharedOptions] boolForKey:@"EncryptToSelf"];
//    NSMutableArray *normalRecipients = [NSMutableArray arrayWithCapacity:1];
//    NSMutableArray *bccRecipients = [NSMutableArray arrayWithCapacity:1];
//	
//    for (NSString *recipient in recipients) {
//		// TODO: Make sure no cert type is in recipients.
//        if(![recipient isKindOfClass:[NSString class]]) {
//            continue;   
//        }
//        NSString *recipientType = [recipient valueForFlag:@"recipientType"];
//        if ([recipientType isEqualTo:@"bcc"]) {
//            [bccRecipients addObject:recipient];
//        } else {
//			// If encryptToSelf is disabled, don't add the sender to the recipients.
//			// Of course this has the effect that the sent mails can't be read by the sender,
//			// but that's exactly what this option is for.
//			if ([recipientType isEqualToString:@"from"]) {
//				
//				// The from recipient can be flagged to indicate symmetric encryption.
//				if ([[recipient valueForFlag:@"symmetricEncrypt"] boolValue]) {
//					symmetricEncrypt = YES;
//					// The from recipient can be flagged to indicate no public key encryption.
//					if ([[recipient valueForFlag:@"doNotPublicEncrypt"] boolValue]) {
//						doNotPublicEncrypt = YES;
//						break;
//					}
//				}
//				
//				
//				senderPublicKey = [recipient valueForFlag:@"gpgKey"];
//
//				// Drafts are only encrypted with the senders key.
//				if ([[recipient valueForFlag:@"isDraft"] boolValue]) {
//					isDraft = YES;
//					[normalRecipients removeAllObjects];
//					[bccRecipients removeAllObjects];
//					senderPublicKey = [[recipient valueForFlag:@"DraftPublicKey"] primaryKey];
//					[normalRecipients addObject:senderPublicKey];
//					
//					break;
//				}
//				
//				
//				if (!encryptToSelf)
//					continue;
//				
//				// In order to fix a problem where a random key matching an address
//				// is chosen for encrypt-to-self, the senderKey is queried for its
//				// public key and the from address is not added to the list of normal
//				// recipients. (#608)
//				if (senderPublicKey) {
//					continue;
//				}
//			}
//			[normalRecipients addObject:recipient];
//		}
//    }
//	
//	NSMutableSet *flattenedNormalKeyList = nil, *flattenedBCCKeyList = nil;
//	
//	if (!doNotPublicEncrypt) {  // We need no keys, if only symmetric is set.
//		// Ask the mail bundle for the GPGKeys matching the email address.
//		NSMutableSet *normalKeyList = [[[GPGMailBundle sharedInstance] publicKeyListForAddresses:normalRecipients] mutableCopy];
//		if(senderPublicKey)
//			[normalKeyList addObject:senderPublicKey];
//		NSMutableSet *bccKeyList = [[GPGMailBundle sharedInstance] publicKeyListForAddresses:bccRecipients];
//		[bccKeyList minusSet:normalKeyList];
//		
//		flattenedNormalKeyList = [self flattenedKeyList:normalKeyList];
//		flattenedBCCKeyList = [self flattenedKeyList:bccKeyList];
//	}
//    
//	
//    GPGController *gpgc = [[GPGController alloc] init];
//    gpgc.useArmor = YES;
//    gpgc.useTextMode = YES;
//    // Automatically trust keys, even though they are not specifically
//    // marked as such.
//    // Eventually add warning for this.
//    gpgc.trustAllKeys = YES;
//    @try {
//		GPGEncryptSignMode encryptMode = doNotPublicEncrypt ? 0 : GPGPublicKeyEncrypt;
//		encryptMode |= symmetricEncrypt ? GPGSymetricEncrypt : 0;
//		
//        *encryptedData = [gpgc processData:data withEncryptSignMode:encryptMode recipients:flattenedNormalKeyList hiddenRecipients:flattenedBCCKeyList];
//		
//		if (gpgc.error) {
//			@throw gpgc.error;
//		}
//    }
//	@catch(NSException *e) {
//		GPGErrorCode errorCode = [e isKindOfClass:[GPGException class]] ? ((GPGException *)e).errorCode : 1;
//        [self failedToEncryptForRecipients:recipients gpgErrorCode:errorCode error:gpgc.error];
//		if (errorCode == GPGErrorCancelled) {
//			return [NSData data];
//		}
//        return nil;
//    }
//    @finally {
//        gpgc = nil;
//    }
//
//    // 1. Create a new mime part for the encrypted data.
//    // -> Problem S/MIME only has one mime part GPG/MIME has two, one for
//    // -> the version, one for the data.
//    // -> Therefore it's necessary to manipulate the message mime parts in
//    // -> _makeMessageWithContents:
//    // -> Not great, but not a big problem either (let's hope)
//    MCMimePart *dataPart = [[GM_MAIL_CLASS(@"MimePart") alloc] init];
//
//    [dataPart setType:@"application"];
//    [dataPart setSubtype:@"octet-stream"];
//    [dataPart setBodyParameter:@"encrypted.asc" forKey:@"name"];
//    dataPart.contentTransferEncoding = @"7bit";
//    [dataPart setDisposition:@"inline"];
//    [dataPart setDispositionParameter:@"encrypted.asc" forKey:@"filename"];
//    [dataPart setContentDescription:@"OpenPGP encrypted message"];
//
//    return dataPart;
}

- (id)newSignedPartWithData:(NSData *)data sender:(NSString *)sender signingKey:(GPGKey *)signingKey signatureData:(__autoreleasing id *)signatureData {
    if (!signingKey) {
        //Should not happen!
        signingKey = [[[GPGMailBundle sharedInstance] signingKeyListForAddress:sender] anyObject];
        // Should also not happen, but if no valid signing keys are found
        // raise an error. Returning nil tells Mail that an error occured.
        if (!signingKey) {
            [self failedToSignForSender:sender gpgErrorCode:1 error:nil];
            return nil;
        }
    }
    if (signingKey.canSign == NO && signingKey.primaryKey != signingKey) {
        signingKey = signingKey.primaryKey;
    }
    
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.useArmor = YES;
    gpgc.useTextMode = YES;
    // Automatically trust keys, even though they are not specifically
    // marked as such.
    // Eventually add warning for this.
    gpgc.trustAllKeys = YES;
    
    gpgc.signerKey = signingKey;
    
    GPGHashAlgorithm hashAlgorithm = 0;
    NSString *hashAlgorithmName = nil;
    
    @try {
        *signatureData = [gpgc processData:data withEncryptSignMode:GPGDetachedSign recipients:nil hiddenRecipients:nil];
        hashAlgorithm = gpgc.hashAlgorithm;
        
        if (gpgc.error) {
            @throw gpgc.error;
        }
    }
    @catch (GPGException *e) {
        if (e.errorCode == GPGErrorCancelled) {
            // TODO: Make sure setting the error on ActivityMonitor suffices to cancel the operation.
            // Write the errorCode in signatureData, so the back-end can cancel the operation.
            //*signatureData = [[gpgErrorIdentifier stringByAppendingFormat:@"%i:", GPGErrorCancelled] dataUsingEncoding:NSUTF8StringEncoding];
            
            [self failedToSignForSender:sender gpgErrorCode:GPGErrorCancelled error:e];
        } else {
            [self failedToSignForSender:sender gpgErrorCode:e.errorCode error:e];
            return nil;
        }
    }
    @catch(NSException *e) {
        [self failedToSignForSender:sender gpgErrorCode:1 error:e];
        return nil;
    }
    @finally {
        gpgc = nil;
    }
    
    if(hashAlgorithm) {
        hashAlgorithmName = [GPGController nameForHashAlgorithm:hashAlgorithm];
    }
    else {
        hashAlgorithmName = @"sha1";
    }
    
    // This doesn't work for PGP Inline,
    // But actually the signature could be created inline
    // Just the same way the pgp/signature is created and later
    // extracted.
    MCMimePart *topPart = [[MCMimePart alloc] init];
    topPart.type = @"multipart";
    topPart.subtype = @"signed";
    [topPart setBodyParameter:[NSString stringWithFormat:@"pgp-%@", hashAlgorithmName] forKey:@"micalg"];
    [topPart setBodyParameter:@"application/pgp-signature" forKey:@"protocol"];
    
    MCMimePart *signaturePart = [[MCMimePart alloc] init];
    signaturePart.type = @"application";
    signaturePart.subtype = @"pgp-signature";
    [signaturePart setBodyParameter:@"signature.asc" forKey:@"name"];
    signaturePart.contentTransferEncoding = @"7bit";
    signaturePart.disposition = @"attachment";
    [signaturePart setDispositionParameter:@"signature.asc" forKey:@"filename"];
    signaturePart.contentDescription = @"Message signed with OpenPGP";
    
    // Self is actually the whole current message part.
    // So the only thing to do is, add self to our top part
    // and add the signature part to the top part and voila!
    [topPart addSubpart:self];
    [topPart addSubpart:signaturePart];
    
    return topPart;
}



//// TODO: Translate the error message if creating the signature fails.
////       At the moment the standard S/MIME message is used.
//- (id)MANewSignedPartWithData:(id)data sender:(id)sender signatureData:(id *)signatureData NS_RETURNS_RETAINED {
//    // If sender doesn't show any injected header values, S/MIME is wanted,
//    // hence the original method called.
//    if(![@"from" isEqualTo:[sender valueForFlag:@"recipientType"]]) {
//        id newPart = [self MANewSignedPartWithData:data sender:sender signatureData:signatureData];
//        return newPart;
//    }
//	
//	GPGKey *keyForSigning = [sender valueForFlag:@"gpgKey"];
//	if (!keyForSigning) {
//		//Should not happen!
//		keyForSigning = [[[GPGMailBundle sharedInstance] signingKeyListForAddress:sender] anyObject];
//		// Should also not happen, but if no valid signing keys are found
//		// raise an error. Returning nil tells Mail that an error occured.
//		if (!keyForSigning) {
//			[self failedToSignForSender:sender gpgErrorCode:1 error:nil];
//			return nil;
//		}
//	}
//	if (keyForSigning.canSign == NO && keyForSigning.primaryKey != keyForSigning) {
//		keyForSigning = keyForSigning.primaryKey;
//	}
//	
//    GPGController *gpgc = [[GPGController alloc] init];
//    gpgc.useArmor = YES;
//    gpgc.useTextMode = YES;
//    // Automatically trust keys, even though they are not specifically
//    // marked as such.
//    // Eventually add warning for this.
//    gpgc.trustAllKeys = YES;
//    
//	[gpgc setSignerKey:keyForSigning];
//    
//    GPGHashAlgorithm hashAlgorithm = 0;
//	NSString *hashAlgorithmName = nil;
//    
//    @try {
//        *signatureData = [gpgc processData:data withEncryptSignMode:GPGDetachedSign recipients:nil hiddenRecipients:nil];
//        hashAlgorithm = gpgc.hashAlgorithm;
//        
//		if (gpgc.error) {
//			@throw gpgc.error;
//		}
//	}
//	@catch (GPGException *e) {
//		if (e.errorCode == GPGErrorCancelled) {
//			// Write the errorCode in signatureData, so the back-end can cancel the operation.
//			*signatureData = [[gpgErrorIdentifier stringByAppendingFormat:@"%i:", GPGErrorCancelled] dataUsingEncoding:NSUTF8StringEncoding];
//			
//			[self failedToSignForSender:sender gpgErrorCode:GPGErrorCancelled error:e];
//		} else {
//			[self failedToSignForSender:sender gpgErrorCode:e.errorCode error:e];
//			return nil;
//		}
//	}
//    @catch(NSException *e) {
//		[self failedToSignForSender:sender gpgErrorCode:1 error:e];
//        return nil;
//    }
//    @finally {
//        gpgc = nil;
//    }
//
//    if(hashAlgorithm) {
//        hashAlgorithmName = [GPGController nameForHashAlgorithm:hashAlgorithm];
//    }
//    else {
//        hashAlgorithmName = @"sha1";
//    }
//    
//    // This doesn't work for PGP Inline,
//    // But actually the signature could be created inline
//    // Just the same way the pgp/signature is created and later
//    // extracted.
//    MCMimePart *topPart = [[GM_MAIL_CLASS(@"MimePart") alloc] init];
//    [topPart setType:@"multipart"];
//    [topPart setSubtype:@"signed"];
//    // TODO: sha1 the right algorithm?
//    [topPart setBodyParameter:[NSString stringWithFormat:@"pgp-%@", hashAlgorithmName] forKey:@"micalg"];
//    [topPart setBodyParameter:@"application/pgp-signature" forKey:@"protocol"];
//
//    MCMimePart *signaturePart = [[GM_MAIL_CLASS(@"MimePart") alloc] init];
//    [signaturePart setType:@"application"];
//    [signaturePart setSubtype:@"pgp-signature"];
//    [signaturePart setBodyParameter:@"signature.asc" forKey:@"name"];
//    signaturePart.contentTransferEncoding = @"7bit";
//    [signaturePart setDisposition:@"attachment"];
//    [signaturePart setDispositionParameter:@"signature.asc" forKey:@"filename"];
//    // TODO: translate this string.
//    [signaturePart setContentDescription:@"Message signed with OpenPGP using GPGMail"];
//
//    // Self is actually the whole current message part.
//    // So the only thing to do is, add self to our top part
//    // and add the signature part to the top part and voila!
//    [topPart addSubpart:self];
//    [topPart addSubpart:signaturePart];
//
//    return topPart;
//}

- (NSData *)inlineSignedDataForData:(id)data sender:(id)sender {
//    DebugLog(@"[DEBUG] %s enter", __PRETTY_FUNCTION__);
//    DebugLog(@"[DEBUG] %s data: [%@] %@", __PRETTY_FUNCTION__, [data class], data);
//    DebugLog(@"[DEBUG] %s sender: [%@] %@", __PRETTY_FUNCTION__, [sender class], sender);
    
	
	GPGKey *keyForSigning = [sender valueForFlag:@"gpgKey"];
	
	if (!keyForSigning) {
		//Should not happen!
		keyForSigning = [[[GPGMailBundle sharedInstance] signingKeyListForAddress:sender] anyObject];
		// Should also not happen, but if no valid signing keys are found
		// raise an error. Returning nil tells Mail that an error occured.
		if (!keyForSigning) {
			[self failedToSignForSender:sender gpgErrorCode:1 error:nil];
			return nil;
		}
	}
	
	
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.useArmor = YES;
    gpgc.useTextMode = YES;
    // Automatically trust keys, even though they are not specifically
    // marked as such.
    // Eventually add warning for this.
    gpgc.trustAllKeys = YES;
	[gpgc setSignerKey:keyForSigning];
    NSData *signedData = nil;
	
	
    @try {
        signedData = [gpgc processData:data withEncryptSignMode:GPGClearSign recipients:nil hiddenRecipients:nil];
        if (gpgc.error) {
			@throw gpgc.error;
		}
    }
	@catch (GPGException *e) {
		if (e.errorCode == GPGErrorCancelled) {
			[self failedToSignForSender:sender gpgErrorCode:GPGErrorCancelled error:e];
            return nil;
		}
		@throw e;
	}
    @catch(NSException *e) {
//        DebugLog(@"[DEBUG] %s sign error: %@", __PRETTY_FUNCTION__, e);
		@throw e;
    }
    @finally {
        gpgc = nil;
    }
    
    return signedData;
}

- (void)failedToSignForSender:(NSString *)sender gpgErrorCode:(GPGErrorCode)errorCode error:(NSException *)error {
	NSString *title = nil;
	NSString *description = nil;
	NSString *errorText = nil;
	if([error isKindOfClass:[GPGException class]])
		errorText = ((GPGException *)error).gpgTask.errText;
	else if([error isKindOfClass:[NSException class]])
		errorText = ((NSException *)error).reason;
	
	BOOL appendContactGPGToolsInfo = YES;
	
	switch (errorCode) {
		case GPGErrorNoPINEntry: {
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_NO_PINENTRY_TITLE");
			
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_NO_PINENTRY_DESCRIPTION");
			break;
		}
		case GPGErrorNoAgent: {
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_NO_AGENT_TITLE");
			
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_NO_AGENT_DESCRIPTION");
			
			break;
		}
		case GPGErrorAgentError: {
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_AGENT_ERROR_TITLE");
			
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_AGENT_ERROR_DESCRIPTION");
			
			break;
		}
		case GPGErrorBadPassphrase: {
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_WRONG_PASSPHRASE_TITLE");
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_WRONG_PASSPHRASE_DESCRIPTION");
			
			appendContactGPGToolsInfo = NO;
			
			break;
		}
		case GPGErrorEOF: {
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_PINENTRY_CRASH_TITLE");
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_PINENTRY_CRASH_DESCRIPTION");
			
			break;
		}
		case GPGErrorXPCBinaryError:
		case GPGErrorXPCConnectionError:
		case GPGErrorXPCConnectionInterruptedError: {
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_XPC_DAMAGED_TITLE");
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_XPC_DAMAGED_DESCRIPTION");
			
			appendContactGPGToolsInfo = NO;
			
			break;
		}
		default:
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_UNKNOWN_ERROR_TITLE");
			
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_UNKNOWN_ERROR_DESCRIPTION");
			
			break;
	}
	
	if(errorText.length && appendContactGPGToolsInfo) {
		description = [description stringByAppendingFormat:GMLocalizedString(@"CONTACT_GPGTOOLS_WITH_INFO_MESSAGE"), errorText];
	}
	
    // The error domain is checked in certain occasion, so let's use the system
    // dependent one.
    
    id mailError = [GPGMailBundle errorWithCode:1036 userInfo:@{@"NSLocalizedDescription": description,
                                                    @"_MFShortDescription": title,
                                                    @"GPGErrorCode": @((long)errorCode)}];
    // Puh, this was all but easy, to find out where the error is used.
    // Overreleasing allows to track it's path as an NSZombie in Instruments!
    [(MCActivityMonitor *)[GM_MAIL_CLASS(@"ActivityMonitor") currentMonitor] setError:mailError];
}

- (void)failedToEncryptForRecipients:(NSArray *)recipients gpgErrorCode:(GPGErrorCode)errorCode error:(NSException *)error {
	NSString *title = nil;
	NSString *description = nil;
	NSString *errorText = nil;
	if([error isKindOfClass:[GPGException class]])
		errorText = ((GPGException *)error).gpgTask.errText;
	else if([error isKindOfClass:[NSException class]])
		errorText = ((NSException *)error).reason;
	
	switch (errorCode) {
		case GPGErrorXPCBinaryError:
		case GPGErrorXPCConnectionError:
		case GPGErrorXPCConnectionInterruptedError: {
			title = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_XPC_DAMAGED_TITLE");
			description = GMLocalizedString(@"MESSAGE_SIGNING_ERROR_XPC_DAMAGED_DESCRIPTION");
			
			break;
		}
		default: {
			title = GMLocalizedString(@"MESSAGE_ENCRYPTION_ERROR_UNKNOWN_ERROR_TITLE");
			
			description = GMLocalizedString(@"MESSAGE_ENCRYPTION_ERROR_UNKNOWN_ERROR_DESCRIPTION");
			
			break;
		}
	}
	
	if(errorText.length) {
		description = [description stringByAppendingFormat:GMLocalizedString(@"CONTACT_GPGTOOLS_WITH_INFO_MESSAGE"), errorText];
	}
	
    // The error domain is checked in certain occasion, so let's use the system
    // dependent one.
    NSError *mailError = (NSError *)[GPGMailBundle errorWithCode:1035 userInfo:@{@"NSLocalizedDescription": description,
													@"_MFShortDescription": title,
													@"GPGErrorCode": @((long)errorCode)}];
    
	// Puh, this was all but easy, to find out where the error is used.
    // Overreleasing allows to track it's path as an NSZombie in Instruments!
    [(MCActivityMonitor *)[GM_MAIL_CLASS(@"ActivityMonitor") currentMonitor] setError:mailError];
}

- (BOOL)GMIsPGPMimeVersionPart {
    return [MAIL_SELF(self) isType:@"application" subtype:@"pgp-encrypted"] && [[MAIL_SELF(self) decodedData] containsPGPVersionMarker:1];
}

- (BOOL)GMIsEncryptedPGPMIMETree {
    BOOL isPGPMIMETree = NO;
    MCMimePart *mailself = MAIL_SELF(self);
    if([self _isExchangeServerModifiedPGPMimeEncrypted]) {
        return YES;
    }
    if([self _isDraftThatHasBeenReEncryptedWithoutBeingDecrypted]) {
        return YES;
    }
    if(![mailself isType:@"multipart" subtype:@"encrypted"]) {
        return NO;
    }
    if(![[[mailself bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pgp-encrypted"]) {
        return NO;
    }

    MCMimePart *versionPart = [mailself firstChildPart];
    if(![versionPart isType:@"application" subtype:@"pgp-encrypted"]) {
        return NO;
    }
    MCMimePart *dataPart = [versionPart nextSiblingPart];
    if(![dataPart isType:@"application" subtype:@"octet-stream"]) {
        return NO;
    }

    // Check if the dataPart really contains PGP encryted data.
    NSData *dataPartData = [(MimePart_GPGMail *)dataPart GMBodyData];
    isPGPMIMETree = [dataPartData mightContainPGPEncryptedDataOrSignatures] || [dataPartData hasPGPEncryptionDataPackets];

    // TODO: In addition a version check could be performed.

    return isPGPMIMETree;
}

- (BOOL)GMIsSignedPGPMIMETree {
    BOOL isPGPMIMETree = NO;
    MCMimePart *mailself = MAIL_SELF(self);
    if(![mailself isType:@"multipart" subtype:@"signed"]) {
        return NO;
    }
    if(![[[mailself bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pgp-signature"]) {
        return NO;
    }
    if(![[[mailself subparts] lastObject] isType:@"application" subtype:@"pgp-signature"]) {
        return NO;
    }

    NSData *dataPartData = [(MimePart_GPGMail *)[[mailself subparts] lastObject] GMBodyData];
    isPGPMIMETree = [dataPartData mightContainPGPEncryptedDataOrSignatures] || [dataPartData hasPGPSignatureDataPackets];

    return isPGPMIMETree;
}

- (NSData *)GMBodyData {
    MCMimePart *mailself = MAIL_SELF(self);
    NSData *bodyData = [mailself decodedData];
    if(!bodyData) {
        bodyData = [mailself encodedBodyData];
    }

    return bodyData;
}

#pragma mark - Methods previously on MCMimeBody.

- (BOOL)mightContainPGPMIMESignedData {
    __block BOOL foundMIMESignedTopLevel = NO;
    __block BOOL foundMIMESignature = NO;
    [(MimePart_GPGMail *)[self topPart] enumerateSubpartsWithBlock:^(MCMimePart *mimePart) {
        if([mimePart isType:@"multipart" subtype:@"signed"]) {
            foundMIMESignedTopLevel = YES;
        }
        if([mimePart isType:@"application" subtype:@"pgp-signature"]) {
            foundMIMESignature = YES;
        }
    }];
    
    return foundMIMESignedTopLevel && foundMIMESignature;
}

- (BOOL)GMPartMightContainPGPData {
    // Check if the current mime part contains PGP data.
    NSArray *pgpExtensions = @[@"pgp", @"gpg", @"asc", @"sig"];
    NSArray *pgpContentTypes = @[@"multipart/encrypted", @"application/pgp", @"application/pgp-encrypted", @"application/pgp-signature"];

    if([self GMIsEncryptedPGPMIMETree]) {
        return YES;
    }
    
    MCMimePart *mailself = MAIL_SELF(self);

    BOOL hasPGPExtension = NO;
    BOOL hasPGPContentType = NO;
    BOOL hasPGPASCIIData = NO;
    BOOL isPGPMimeVersionPart = [self GMIsPGPMimeVersionPart];

    // application/pgp-encrypted is a special case, since it is
    // used to signal PGP encrypted data, as well as the version marker
    // for PGP/MIME messages.
    if(isPGPMimeVersionPart) {
        return YES;
    }

    for(NSString *contentType in pgpContentTypes) {
        NSArray *typeComponents = [contentType componentsSeparatedByString:@"/"];
        if([mailself isType:typeComponents[0] subtype:typeComponents[1]]) {
            hasPGPContentType = YES;
            break;
        }
    }

    NSString *nameParameter = [[mailself bodyParameterForKey:@"name"] lowercaseString];
    NSString *filenameParameter = [[mailself bodyParameterForKey:@"filename"] lowercaseString];

    if([pgpExtensions containsObject:[nameParameter pathExtension]] || [pgpExtensions containsObject:[filenameParameter pathExtension]]) {
        hasPGPExtension = YES;
    }

    // -[MCMimePart decodedData] runs the encodedBodyData through
    // decoding routines like base64 or quoted-printable, if content-transfer-encoding
    // requires it.
    NSData *bodyData = [self GMBodyData];
    hasPGPASCIIData = [bodyData mightContainPGPEncryptedDataOrSignatures];
    if(hasPGPASCIIData) {
        return YES;
    }

    if(hasPGPContentType || hasPGPExtension) {
        return [bodyData hasPGPEncryptionDataPackets] || [bodyData hasPGPSignatureDataPackets];
    }

    // If the current part is a text/html part and it is
    // part of a multipart/alternative tree, look for the text/plain
    // part since it is not possible to reliably recognize PGP Data
    // in text/html.
    if([[mailself parentPart] isType:@"multipart" subtype:@"alternative"]) {
        MCMimePart *textPart = nil;
        for(MCMimePart *part in [[mailself parentPart] subparts]) {
            if([part isType:@"text" subtype:@"plain"]) {
                textPart = part;
                break;
            }
        }
        if([[(MimePart_GPGMail *)textPart GMBodyData] mightContainPGPEncryptedDataOrSignatures]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)mightContainPGPData {
    __block BOOL mightContainPGPData = NO;
    __block BOOL mightContainSMIMEData = NO;
    __block BOOL mightBeSMIMESigned = NO;
    
    NSArray *pgpExtensions = @[@"pgp", @"gpg", @"asc", @"sig"];
    NSArray *smimeExtensions = @[@"p7m", @"p7s", @"p7c", @"p7z"];
    [(MimePart_GPGMail *)[self topPart] enumerateSubpartsWithBlock:^(MCMimePart *mimePart) {
        // Bug #973: PGP Data within a S/MIME signed message is not decrypted properly
        // At the moment, if any S/MIME data is detected in a message, GPGMail will stop processing
        // any PGP data which might be contained as well.
        // Unfortunately there are now messages around which are S/MIME signed, but contain PGP-Partitioned data
        // as well. In that case, GPGMail will process any found PGP data and ignore the S/MIME signature.
        // Of course some fuckwits have to use x-pkcs7-signature instead of pkcs7-signature.
        if([mimePart isType:@"multipart" subtype:@"signed"] && ([[[mimePart bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pkcs7-signature"] || [[[mimePart bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/x-pkcs7-signature"])) {
            mightBeSMIMESigned = YES;
            return;
        }
        // Check for S/MIME hints.
        if(([mimePart isType:@"multipart" subtype:@"signed"] && [[[mimePart bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pkcs7-signature"]) ||
           [smimeExtensions containsObject:[[[mimePart bodyParameterForKey:@"filename"] lowercaseString] pathExtension]] ||
           [smimeExtensions containsObject:[[[mimePart bodyParameterForKey:@"name"] lowercaseString] pathExtension]] ||
           [mimePart isType:@"application" subtype:@"pkcs7-mime"]) {
            mightContainSMIMEData = YES;
            return;
        }
        BOOL mimeSigned = [mimePart isType:@"multipart" subtype:@"signed"] && ![[[mimePart bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pkcs7-signature"];
        if([mimePart isType:@"multipart" subtype:@"encrypted"] ||
           mimeSigned ||
           [mimePart isType:@"application" subtype:@"pgp-encrypted"] ||
           [mimePart isType:@"application" subtype:@"pgp-signature"]) {
            mightContainPGPData = YES;
            return;
        }
        
        NSString *nameParameter = [[mimePart bodyParameterForKey:@"name"] lowercaseString];
        NSString *filenameParameter = [[mimePart bodyParameterForKey:@"filename"] lowercaseString];
        
        NSString *nameExt = [nameParameter pathExtension];
        NSString *filenameExt = [filenameParameter pathExtension];
        
        if([pgpExtensions containsObject:nameExt] || [pgpExtensions containsObject:filenameExt]) {
            mightContainPGPData = YES;
            return;
        }
        
        // Last but not least, check for winmail.dat files, which could contain
        // signed or encrypted data, where the mime structure was altered by
        // MS Exchange.
        if([mimePart isType:@"application" subtype:@"ms-tnef"] ||
           [nameParameter isEqualToString:@"winmail.dat"] ||
           [nameParameter isEqualToString:@"win.dat"] ||
           [filenameParameter isEqualToString:@"winmail.dat"] ||
           [filenameParameter isEqualToString:@"win.dat"]) {
            // Bug #950: Ignore winmail.dat files if Letter Opener is installed.
            if(!NSClassFromString(@"OMiCBundle")) {
                mightContainPGPData = YES;
            }
            return;
        }
        
        // And another special case seems to be fixed by rebuilding the message.
        // If message/rfc822 mime part is included in the received message,
        // Mail seems to fuck up the data source necessary to decode that message.
        // As a result, only parts of the message are displayed.
        // If however GPGMail rebuilds the message internally from cached data,
        // the data source is properly setup and it's possible to decode the message.
        // While the message might not contain PGP data, YES is still returned
        // from this method, in order to instruct GPGMail to rebuild the message.
        if([mimePart isType:@"message" subtype:@"rfc822"]) {
            if(!NSClassFromString(@"OMiCBundle")) {
                mightContainPGPData = YES;
            }
            return;
        }
        
        // Bug #945: GPGMail does not detect inline PGP in incoming messages.
        // If a message contains inline PGP in the text/plain or text/html file,
        // none of the above methods will detect that and thus GPGMail is led to believe,
        // that the message doesn't contain any PGP data.
        // In order to properly detect inline PGP, it is necessary to check the body data
        // that is available for each mime part. (Even partial contain the non-attachment
        // mime part body data).
        if(![mimePart isAttachment]) {
            NSData *partBodyData = [mimePart decodedData];

            // Bug #972: Due to the use of base64 encoding, GPGMail does not recognize PGP Data in inline encrypted messages
            //           from gpg4o
            // In order to fix this issue, GPGMail will search the decodedData for inline PGP markers, if content-transfer-encoding
            // is base64.
            if(partBodyData && ![[[mimePart contentTransferEncoding] lowercaseString] isEqualToString:@"base64"]) {
                partBodyData = [mimePart encodedBodyData];
            }
            if(partBodyData && [partBodyData mightContainPGPEncryptedDataOrSignatures]) {
                mightContainPGPData = YES;
            }
        }
    }];
    
    // If the message contains PGP data *and* is S/MIME signed it's treated as if it
    // only contained PGP data. Before it was treated as if it *didn't* contain any PGP data
    // at all. Have a look at #973 for details.
    return mightContainPGPData && (!mightContainSMIMEData || mightBeSMIMESigned);
}

- (MCMessageBody *)MAMessageBody {
    MCMessageBody *messageBody = [self MAMessageBody];
    if(![self shouldBePGPProcessed]) {
        return messageBody;
    }
    GMMessageSecurityFeatures *securityFeatures = [GMMessageSecurityFeatures securityFeaturesFromMessageProtectionStatus:[self GMMessageProtectionStatus] topLevelMimePart:[self topPart]];
    // Still have to decided, if the security features should be on MessageBody or MimePart.
    //((MimeBody_GPGMail *)messageBody).securityFeatures = securityFeatures;
    [self setIvar:@"SecurityFeatures" value:securityFeatures];
    if(securityFeatures.PGPMainError) {
        [messageBody setSmimeError:securityFeatures.PGPMainError];
    }
    [messageBody setIsEncrypted:messageBody.isEncrypted || securityFeatures.PGPEncrypted || securityFeatures.PGPPartlyEncrypted || [(MimePart_GPGMail *)[self topPart] GMHasAnyEncryptedSMIMEPart]];
    return messageBody;
}

- (void)setDecryptedTopLevelMimePart:(MCMimePart *)decryptedTopLevelMimePart {
    @synchronized([self valueForKey:@"_encryptSignLock"]) {
        [[self topPart] setIvar:@"MimePartDecryptedTopLevelMimePart" value:decryptedTopLevelMimePart];
    }
}

- (MCMimePart *)decryptedTopLevelMimePart {
    MCMimePart *decryptedTopLevelMimePart = nil;
    @synchronized([self valueForKey:@"_encryptSignLock"]) {
        decryptedTopLevelMimePart = [[self topPart] getIvar:@"MimePartDecryptedTopLevelMimePart"];
    }
    return decryptedTopLevelMimePart;
//    return [MAIL_SELF(self) cmsExtractedContent];
}

- (GMMessageSecurityFeatures *)securityFeatures {
    return [[self topPart] getIvar:@"SecurityFeatures"];
}

- (BOOL)GMHasAnyEncryptedSMIMEPart {
    __block BOOL hasEncryptedSMIMEPart = NO;
    [(MimePart_GPGMail *)[self topPart] enumerateSubpartsWithBlock:^(MCMimePart *mimePart) {
        if([mimePart isType:@"application" subtype:@"pkcs7-mime"]) {
            hasEncryptedSMIMEPart = YES;
        }
    }];

    return hasEncryptedSMIMEPart;
}

- (id)MADecodeApplicationPkcs7 {
    // Bug #981: Efail
    //
    // Usually macOS Mail will decrypt any application/pkcs7 encrypted part
    // of a message and concatenate their content.
    // As Efail has demonstrated, this can be abused by an attacker to have
    // different encrypted messages decrypted and sent via form submit or other
    // exfiltration method to a controlled server.
    //
    // In order to mitigate against this issue, only the first encrypted part
    // of a message will be decrypted.
    GMMessageProtectionStatus *messageProtectionStatus = [[self topPart] getIvar:@"GMSMIMEMessageProtectionStatus"];
    if(!messageProtectionStatus) {
        messageProtectionStatus = [GMMessageProtectionStatus new];
        [[self topPart] setIvar:@"GMSMIMEMessageProtectionStatus" value:messageProtectionStatus];
    }
    id content = nil;
    if(!messageProtectionStatus.containsEncryptedParts) {
        content = [self MADecodeApplicationPkcs7];
        [[messageProtectionStatus encryptedParts] addObject:(MCMimePart *)self];
    }

    return content;
}


@end

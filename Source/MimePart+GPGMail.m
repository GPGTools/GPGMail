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
#import <Libmacgpg/GPGKey.h>
#define restrict
#import <RegexKit/RegexKit.h>
#undef restrict
#import "CCLog.h"
#import "NSData+GPGMail.h"
#import "NSArray+Functional.h"
#import "NSObject+LPDynamicIvars.h"
#import "GPGFlaggedString.h"
#import "MimePart+GPGMail.h"
#import "MimeBody+GPGMail.h"
#import "NSString+GPGMail.h"
#import "Message+GPGMail.h"
#import <MFMessageFramework.h>
#import <ActivityMonitor.h>
#import <NSString-NSStringUtils.h>
#import <NSData-MimeDataEncoding.h>
#import <MFMimeDecodeContext.h>
#import <MFError.h>
#import <NSString-HTMLConversion.h>
#import <Message.h>
#import <MessageWriter.h>
#import <MimeBody.h>
#import <MutableMessageHeaders.h>
#import "ParsedMessage.h"
#import "GPGMailBundle.h"

@implementation MimePart (GPGMail)

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
// TODO: Extend to find multiple signatures and encrypted data parts, if necessary.
- (id)MADecodeWithContext:(id)ctx {
    Message *currentMessage = [(MimeBody *)[self mimeBody] message];
//    DebugLog(@"[DEBUG] %s enter - decoding: %@ - part: %@", __PRETTY_FUNCTION__,
//             [currentMessage subject], self);
    
    // _calculateSnippetForMessages doesn't attempt to decode
    // attachments. That's a problem, because once a message is displayed
    // the PGPInfoCollected flag is already set on the message,
    // but attachment were never taken into account.
    // Resetting PGPInfoCollected on each decoding might solve
    // this issue. (doesn't completely fix it, read on, fixes it better, but might cause other problems.)
    // If the message is already selected when Mail.app is opened, the message doesn't seem
    // to be reparsed, but the info from _calculateSnippetForMessages is somehow reused. 
    if(![self parentPart]) {
        ((Message *)[(MimeBody *)[self mimeBody] message]).PGPInfoCollected = NO;  
        ((MFMimeDecodeContext *)ctx).decodeTextPartsOnly = NO;
    }
        
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![currentMessage shouldBePGPProcessed])
        return [self MADecodeWithContext:ctx];
    
    id ret = nil;
    if([self isPGPMimeEncrypted]) {
        MimeBody *decryptedBody = [self decodeMultipartEncryptedWithContext:ctx];
        // Add PGP information from mime parts.
        ((MFMimeDecodeContext *)ctx).shouldSkipUpdatingMessageFlags = YES;
        ret = [decryptedBody parsedMessageWithContext:ctx];
        [currentMessage collectPGPInformationStartingWithMimePart:self decryptedBody:decryptedBody];
        // If decryption failed, call the original method.
        if(!ret)
            ret = [self MADecodeWithContext:ctx];
    }
    else {
        ret = [self MADecodeWithContext:ctx];
    }
    
    // Loop through all the mime parts that have been processed and set
    // all necessary flags.
    // This is pretty much crazy, in case of mailing list emails, the multipart/encrypted
    // part is NOT the top part. So at this point all the information found for the message
    // would be overwritten. To avoid this, a check is performed if the PGP info was already
    // collected. If that's the case, skip the collecting
    if([self parentPart] == nil && !currentMessage.PGPInfoCollected) {
        [currentMessage collectPGPInformationStartingWithMimePart:self
                                        decryptedBody:nil];
    }

    // To remove .sig attachments, they have to be removed.
    // from the ParsedMessage html.
    if([ret isKindOfClass:NSClassFromString(@"ParsedMessage")] && [[self signatureAttachmentScheduledForRemoval] count]) {
        DebugLog(@"Parsed Message without objects: %@", [((ParsedMessage *)ret).html stringByDeletingAttachmentsWithNames:[[(MimeBody *)[self mimeBody] message] getIvar:@"PGPSignatureAttachmentsToRemove"]]);
        ((ParsedMessage *)ret).html = [((ParsedMessage *)ret).html stringByDeletingAttachmentsWithNames:[self signatureAttachmentScheduledForRemoval]];
    }
    return ret;
}

- (void)enumerateSubpartsWithBlock:(void (^)(MimePart *))partBlock {
    __block void (^_walkParts)(MimePart *);
    _walkParts = ^(MimePart *currentPart) {
        partBlock(currentPart);
        for(MimePart *tmpPart in [currentPart subparts]) {
            _walkParts(tmpPart);
        }
    };
    _walkParts(self);
}

- (MimePart *)topPart {
    MimePart *parentPart = [self parentPart];
    MimePart *currentPart = parentPart;
    if(parentPart == nil)
        return self;
    // Call parentPart till we are on top.
    while((currentPart = [currentPart parentPart])) {
        if([currentPart parentPart] == nil)
            return currentPart;
    }
    return nil;
}

- (id)MADecodeTextPlainWithContext:(MFMimeDecodeContext *)ctx {
    // Check if message should be processed (-[Message shouldBePGPProcessed] - Snippet generation check)
    // otherwise out of here!
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MADecodeTextPlainWithContext:ctx];
    
    // 1. Step, check if the message was already decrypted.
    if(self.PGPEncrypted && self.PGPDecryptedData)
        return self.PGPDecryptedData ? self.PGPDecryptedContent : [self MADecodeTextPlainWithContext:ctx];
    if(self.PGPSigned && self.PGPVerifiedContent)
        return self.PGPVerifiedContent ? self.PGPVerifiedContent : [self MADecodeTextPlainWithContext:ctx];
    
    // Check if the part is base64 encoded. If so, decode it.
    NSData *partData = [self bodyData];
    NSData *decryptedData = nil;
    
    NSRange encryptedRange = [partData rangeOfPGPInlineEncryptedData];
    NSRange signatureRange = [partData rangeOfPGPInlineSignatures];
    
    // No encrypted PGP data and no signature PGP data found? OUT OF HERE!
    if(encryptedRange.location == NSNotFound && signatureRange.location == NSNotFound) 
        return [self MADecodeTextPlainWithContext:ctx];
    
    if(encryptedRange.location != NSNotFound) {
        decryptedData = [self decryptedMessageBodyOrDataForEncryptedData:partData encryptedInlineRange:encryptedRange];
        // Fetch the decrypted content, since that is already been processed, with markers and stuff.
        // In case of an error, simply return the decrypted data.
        NSString *content = nil;
        if(self.PGPError)
            content = [[decryptedData stringByGuessingEncoding] markupString];
        else
            content = self.PGPDecryptedContent;
        
        return content; 
    }
    
    if(signatureRange.location != NSNotFound) {
        [self _verifyPGPInlineSignatureInData:partData range:signatureRange];
        return self.PGPVerifiedContent;
    }
    
    id ret = [self MADecodeTextPlainWithContext:ctx];
    if(signatureRange.location != NSNotFound)
        ret = [self stripSignatureFromContent:ret];
    
    return ret;
}

- (id)MADecodeTextHtmlWithContext:(MFMimeDecodeContext *)ctx {
    // Check if message should be processed (-[Message shouldBePGPProcessed] - Snippet generation check)
    // otherwise out of here!
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MADecodeTextHtmlWithContext:ctx];

    if([[self bodyData] mightContainPGPEncryptedDataOrSignatures]) {
        // HTML is a bit hard to decrypt, so check if the parent part, if exists is a
        // multipart/alternative.
        // If that's the case, look for a text/plain part
        MimePart *parentPart = [self parentPart];
        MimePart *textPart = nil;
        if(parentPart && [parentPart isType:@"multipart" subtype:@"alternative"]) {
            for(MimePart *tmpPart in [parentPart subparts]) {
                if([tmpPart isType:@"text" subtype:@"plain"]) {
                    textPart = tmpPart;
                    break;
                }
            }
            if(textPart) {
                return [textPart decodeTextPlainWithContext:ctx];
            }
        }
    }
    
    return [self MADecodeTextHtmlWithContext:ctx];
}

- (id)MADecodeApplicationOctet_streamWithContext:(MFMimeDecodeContext *)ctx {
    // Check if message should be processed (-[Message shouldBePGPProcessed] - Snippet generation check)
    // otherwise out of here!
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MADecodeApplicationOctet_streamWithContext:ctx];
    
    BOOL mightBeEncrypted;
    BOOL mightBeSignature;
    [self attachmentMightBePGPEncrypted:&mightBeEncrypted orSigned:&mightBeSignature];
    if(!mightBeEncrypted && !mightBeSignature)
        return [self MADecodeApplicationOctet_streamWithContext:ctx];
    
    // It's a PGP attachment otherwise we wouldn't come in here, so set
    // that status.
    self.PGPAttachment = YES;
    
    if(mightBeEncrypted)
        return [self decodePGPEncryptedAttachment];
    
    if(mightBeSignature)
        return [self decodePGPSignatureAttachment];
    
    // Should not come here, but if it does... well.
    return [self MADecodeApplicationOctet_streamWithContext:ctx];
} 

- (BOOL)isPGPMimeEncryptedAttachment {
    // application/pgp-encrypted is also considered to be an attachment.
    if([[self dispositionParameterForKey:@"filename"] isEqualToString:@"encrypted.asc"] || 
       [self isType:@"application" subtype:@"pgp-encrypted"])
        return YES;
    
    return NO;
}

- (BOOL)isPGPMimeSignatureAttachment {
    if([self isType:@"application" subtype:@"pgp-signature"])
        return YES;
    
    return NO;
}


- (id)decodePGPEncryptedAttachment {
    if(self.PGPDecryptedData)
        return [self.PGPDecryptedData length] != 0 ? self.PGPDecryptedData : [self MADecodeApplicationOctet_streamWithContext:nil];
    
    NSData *partData = [self bodyData];
    NSData *decryptedData = nil;
    decryptedData = [self decryptedMessageBodyOrDataForEncryptedData:partData encryptedInlineRange:NSMakeRange(0, [partData length])];
    
    return decryptedData;
}

- (id)decodePGPSignatureAttachment {
    MimePart *parentPart = [self parentPart];
    MimePart *signedPart = nil;
    NSString *signatureFilename = [[self dispositionParameterForKey:@"filename"] lastPathComponent];
    NSString *signedFilename = [signatureFilename stringByDeletingPathExtension];
    for(MimePart *part in [parentPart subparts]) {
        if([[[part dispositionParameterForKey:@"filename"] lastPathComponent] isEqualToString:signedFilename]) {
            signedPart = part;
            break;
        }
    }
    
    // Now try to verify.
    [self verifyData:[signedPart bodyData] signatureData:[self bodyData]];
    
    // Remove the signature attachment also if verification failed.
    BOOL removeAllSignatureAttachments = [[GPGOptions sharedOptions] boolForKey:@"HideAllSignatureAttachments"];
    DebugLog(@"Hide All attachments: %@", removeAllSignatureAttachments ? @"YES" : @"NO");
    BOOL remove = removeAllSignatureAttachments ? YES : self.PGPVerified;
    
    if(remove)
        [self scheduleSignatureAttachmentForRemoval:signatureFilename];
    
    return [self MADecodeApplicationOctet_streamWithContext:nil];
}

- (void)scheduleSignatureAttachmentForRemoval:(NSString *)attachment {
    Message *message = [(MimeBody *)[self mimeBody] message];
    if(![message ivarExists:@"PGPSignatureAttachmentsToRemove"])
        [message setIvar:@"PGPSignatureAttachmentsToRemove" value:[NSMutableArray array]];
    
    [[message getIvar:@"PGPSignatureAttachmentsToRemove"] addObject:attachment];
}

- (NSArray *)signatureAttachmentScheduledForRemoval {
    return [[(MimeBody *)[self mimeBody] message] getIvar:@"PGPSignatureAttachmentsToRemove"];
}

- (void)attachmentMightBePGPEncrypted:(BOOL *)mightEnc orSigned:(BOOL *)mightSig {
    *mightEnc = NO;
    *mightSig = NO;
    NSString *nameExt = [[self bodyParameterForKey:@"name"] pathExtension];
    NSString *filenameExt = [[self dispositionParameterForKey:@"filename"] pathExtension];
    
    // Check if the attachment is part of a pgp/mime encrypted message.
    // In that case, don't try to inline decrypt it.
    // This is necessary since decodeMultipartWithContext checks the attachments
    // first and after that runs decodeWithContext apparently.
    if([[self topPart] isType:@"multipart" subtype:@"encrypted"])
        return;

    NSArray *encExtensions = [NSArray arrayWithObjects:@"pgp", @"gpg", @"asc", nil];
    *mightEnc = ([encExtensions containsObject:nameExt] || [encExtensions containsObject:filenameExt]);
    NSArray *sigExtensions = [NSArray arrayWithObjects:@"sig", nil];
    *mightSig = ([sigExtensions containsObject:nameExt] || [sigExtensions containsObject:filenameExt]);
    
    // .asc attachments might contain a public key. See #123.
    // So to avoid decrypting such attachments, check if the attachment
    // contains a public key.
    if((*mightEnc || *mightSig) 
       && [[self bodyData] rangeOfPGPPublicKey].location != NSNotFound) {
        *mightEnc = NO;
        *mightSig = NO;
        return;
    }
}

- (id)decodeMultipartEncryptedWithContext:(id)ctx {
    // 1. Step, check if the message was already decrypted.
    if(self.PGPDecryptedBody || self.PGPError)
        return self.PGPDecryptedBody ? self.PGPDecryptedBody : nil;
    
    // 2. Fetch the data part.
    // To support exchange server modified messages, the first found octect-stream part
    // is used as data part. In case of exchange server modified messages, this part
    // is not necessarily the second immediately after the application/pgp-encrypted.
    MimePart *dataPart = nil;
    for(MimePart *part in [self subparts]) {
        if([part isType:@"application" subtype:@"octet-stream"])
            dataPart = part;
    }
    MessageBody *decryptedMessageBody = nil;
    NSData *encryptedData = [dataPart bodyData];
    
    // Check if the data part contains the Content-Type string.
    // If so, this is a message which was created by a very early alpha
    // of GPGMail 2.0 which sent out completely corrupted messages.
    if([encryptedData rangeOfData:[@"Content-Type" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [encryptedData length])].location != NSNotFound)
        return [self decodeFuckedUpEarlyAlphaData:encryptedData context:ctx];

    if([[dataPart.contentTransferEncoding lowercaseString] isEqualToString:@"base64"] && 
       [encryptedData isValidBase64Data])
        encryptedData = [encryptedData decodeBase64];
    else if([[dataPart.contentTransferEncoding lowercaseString] isEqualToString:@"quoted-printable"])
        encryptedData = [encryptedData decodeQuotedPrintableForText:YES];
    
    // The message is definitely encrypted, otherwise this method would never
    // be entered, so set that flag.
    decryptedMessageBody = [self decryptedMessageBodyOrDataForEncryptedData:encryptedData encryptedInlineRange:NSMakeRange(NSNotFound, 0)];
    
    return decryptedMessageBody;
}

- (id)decodeFuckedUpEarlyAlphaData:(NSData *)data context:(MFMimeDecodeContext *)ctx {
    // This data might contain a signature part.
    // In that case it's a little bit more complicated since it's necessary to add a
    // top level mime part.
    if([data rangeOfData:[@"application/pgp-signature" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [data length])].location != NSNotFound) {
        NSMutableData *newData = [NSMutableData data];
        NSString *boundary = (NSString *)[MimeBody newMimeBoundary];
        [newData appendData:[boundary dataUsingEncoding:NSUTF8StringEncoding]];
        [boundary release];
        [newData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        NSRange boundaryStart = [data rangeOfData:[@"--Apple-Mail=_" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [data length])];
        NSRange boundaryEnd = [data rangeOfData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(boundaryStart.location, [data length] - boundaryStart.location)];
        NSString *partBoundary = [NSString stringWithData:[data subdataWithRange:NSMakeRange(boundaryStart.location+2, boundaryEnd.location-3)] encoding:NSUTF8StringEncoding];
        [newData appendData:[[NSString stringWithFormat:@"Content-Type: multipart/signed; boundary=\"%@\"; protocol=\"application/pgp-signature\";\r\n", partBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [newData appendData:[@"Content-Transfer-Encoding: 7bit\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [newData appendData:data];
        [newData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", partBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        data = newData;
    }

    Message *newMessage = [Message messageWithRFC822Data:data];
    ctx.shouldSkipUpdatingMessageFlags = YES;
    // Skip PGP Processing, otherwise this ends up in an endless loop.
    // Process the message like a really encrypted message.
    // Otherwise the decoding is creates a loop which is really slow!
    [newMessage setMessageInfoFromMessage:[(MimeBody *)[self mimeBody] message]];
    // 3. Call message body updating flags to set the correct flags for the new message.
    // This will setup the decrypted message, run through all parts and find signature part.
    // We'll save the message body for later, since it will be used to do a last
    // decodeWithContext and the output returned.
    // Fake the message flags on the decrypted message.
    MessageBody *decryptedMimeBody = [newMessage messageBodyUpdatingFlags:YES];
    // Check if the decrypted message contains any signatures, if so it's necessary
    // to unset the attachment flag.
    BOOL isSigned = [(MimeBody *)decryptedMimeBody containsPGPSignedData];
    // Fixes the problem where an attachment icon is shown, when a message is either encrypted or signed.
    unsigned int numberOfAttachments = [(MimePart *)[self topPart] numberOfAttachments];
    if(numberOfAttachments > 0)
        numberOfAttachments -= 2;
    // Set the new number of attachments.
    [[(MimeBody *)[self mimeBody] message] setNumberOfAttachments:numberOfAttachments isSigned:isSigned isEncrypted:YES];
    // After that set the decryptedMessage body with encrypted to yes!
    MFError *error = [[(MimeBody *)decryptedMimeBody topLevelPart] valueForKey:@"_smimeError"];
    if(error)
        [[ActivityMonitor currentMonitor] setError:error];
    [decryptedMimeBody setIvar:@"PGPEarlyAlphaFuckedUpEncrypted" value:[NSNumber numberWithBool:YES]];
    self.PGPEncrypted = YES;
    self.PGPSigned = isSigned;
    self.PGPError = error;
    [[self topPart] setDecryptedMessageBody:decryptedMimeBody isEncrypted:self.PGPEncrypted isSigned:isSigned error:error];
    self.PGPDecryptedBody = self.decryptedMessageBody;
    
    // Flag the message as process.
    [[(MimeBody *)[self mimeBody] message] setIvar:@"PGPMessageProcessed" value:[NSNumber numberWithBool:YES]];
    //[[[self mimeBody] topLevelPart] removeIvar:@"PGPEncryptedPart"];
    //[self removeIvar:@"PGPEncryptedDataRange"];
    // I could really smash myself for ever introducing this bug!!!
    // For the security header to correctly show the signatures,
    // the message has to be flagged as specially encrypted.
    [[self mimeBody] setIvar:@"PGPEarlyAlphaFuckedUpEncrypted" value:[NSNumber numberWithBool:YES]];

    return decryptedMimeBody;
}

- (id)decryptData:(NSData *)encryptedData {
    // Decrypt data should not run if Mail.app is generating snippets
    // and NeverCreateSnippetPreviews is set or the passphrase is not in cache
    // and CreatePreviewSnippets is not set.
    if(![[(MimeBody *)[self mimeBody] message] shouldCreateSnippetWithData:encryptedData])    
        return nil;
    
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.verbose = NO;
    //gpgc.verbose = (GPGMailLoggingLevel > 0);
    NSData *decryptedData = [gpgc decryptData:encryptedData];
    MFError *error = [self errorFromGPGOperation:GPG_OPERATION_DECRYPTION controller:gpgc];
    NSArray *signatures = gpgc.signatures;
    BOOL success = gpgc.decryptionOkay;
    // Check if this is a non-clear-signed message.
    // Conditions: decryptionOkay == false and encrypted data has signature packets.
    // If decryptedData length != 0 && !decryptionOkay signature packets are expected.
    BOOL nonClearSigned = !success && [encryptedData hasSignaturePacketsWithSignaturePacketsExpected:[decryptedData length] != 0 && !success];
    
    // Let's reset the error if the message is non-clear-signed,
    // since error will be general error.
    if(nonClearSigned)
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
    if([signatures count]) {
        self.PGPSigned = YES;
        self.PGPSignatures = signatures;
        // If there is an error and decrypted is yes, there was an error
        // with a signature. Set verified to false.
        if(success && error)
            self.PGPVerified = NO;
        else
            self.PGPVerified = YES;
    }
    
    // Last, store the error itself.
    self.PGPError = error;
    
    [gpgc release];
    
    if(!success && !nonClearSigned)
        return nil;
    
    return decryptedData;
}

- (id)errorFromGPGOperation:(GPG_OPERATION)operation controller:(GPGController *)gpgc {
    if(operation == GPG_OPERATION_DECRYPTION)
        return [self errorFromDecryptionOperation:gpgc];
    if(operation == GPG_OPERATION_VERIFICATION)
        return [self errorFromVerificationOperation:gpgc];
        
    return nil;
}

- (MFError *)errorFromDecryptionOperation:(GPGController *)gpgc {
    // No error? OUT OF HEEEEEAAAR!
    if(gpgc.decryptionOkay)
        return nil;
    
    // Might be an NSException or a GPGException
    NSException *operationError = gpgc.error;
    MFError *error = nil;
    NSArray *noDataErrors = [gpgc.statusDict valueForKey:@"NODATA"];
    
    NSBundle *gpgMailBundle = [NSBundle bundleForClass:[GPGMailBundle class]];
    NSString *title = nil, *message = nil;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    BOOL isAttachment = [self isAttachment] && ![self isPGPMimeEncryptedAttachment];
    NSString *prefix = !isAttachment ? @"MESSAGE_BANNER_PGP" : @"MESSAGE_BANNER_PGP_ATTACHMENT";
    
    NSString *titleKey = nil;
    NSString *messageKey = nil;
    
    if([operationError isMemberOfClass:[NSException class]]) {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_SYSTEM_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_SYSTEM_ERROR_MESSAGE", prefix];
        
        title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
        message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
    }
    else if(((GPGException *)operationError).errorCode == GPGErrorNoSecretKey) {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_SECKEY_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_SECKEY_ERROR_MESSAGE", prefix];
        
        title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
        message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
    }
    else if(((GPGException *)operationError).errorCode == GPGErrorWrongSecretKey) {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_WRONG_SECKEY_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_WRONG_SECKEY_ERROR_MESSAGE", prefix];
        
        title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
        message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
    }
    else if([self hasError:@"NO_ARMORED_DATA" noDataErrors:noDataErrors] || 
            [self hasError:@"INVALID_PACKET" noDataErrors:noDataErrors]) {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_CORRUPTED_DATA_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_CORRUPTED_DATA_ERROR_MESSAGE", prefix];
        
        title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
        message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
    }
    else {
        titleKey = [NSString stringWithFormat:@"%@_DECRYPT_GENERAL_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_DECRYPT_GENERAL_ERROR_MESSAGE", prefix];
        
        title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
        message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
        message = [NSString stringWithFormat:message, gpgc.gpgTask.errText];
    }
    
    [userInfo setValue:title forKey:@"_MFShortDescription"];
    [userInfo setValue:message forKey:@"NSLocalizedDescription"];
    [userInfo setValue:[NSNumber numberWithBool:YES] forKey:@"DecryptionError"];
    
    error = [MFError errorWithDomain:@"MFMessageErrorDomain" code:1035 localizedDescription:nil title:title helpTag:nil 
                            userInfo:userInfo];
    
    [userInfo release];
    
    return error;
}

- (MFError *)errorFromVerificationOperation:(GPGController *)gpgc {
    NSException *operationError = gpgc.error;
    NSArray *noDataErrors = [gpgc.statusDict valueForKey:@"NODATA"];
    MFError *error = nil;
    
    NSBundle *gpgMailBundle = [NSBundle bundleForClass:[GPGMailBundle class]];
    NSString *title = nil, *message = nil;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    BOOL isAttachment = [self isAttachment] && ![self isPGPMimeSignatureAttachment];
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
        
        title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
        message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
        errorFound = YES;
    }
    else if([self hasError:@"EXPECTED_SIGNATURE_NOT_FOUND" noDataErrors:noDataErrors]) {
        titleKey = [NSString stringWithFormat:@"%@_VERIFY_CORRUPTED_DATA_ERROR_TITLE", prefix];
        messageKey = [NSString stringWithFormat:@"%@_VERIFY_CORRUPTED_DATA_ERROR_MESSAGE", prefix];
        
        title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
        message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
        errorFound = YES;
    }
    else {
        GPGErrorCode errorCode = GPGErrorNoError;
        GPGSignature *signatureWithError = nil;
        for(GPGSignature *signature in gpgc.signatures) {
            if(signature.status != GPGErrorNoError) {
                errorCode = signature.status;
                signatureWithError = signature;
                break;
            }
        }
        errorFound = errorCode != GPGErrorNoError ? YES : NO;
        
        switch (errorCode) {
            case GPGErrorNoPublicKey:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_NO_PUBKEY_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_NO_PUBKEY_ERROR_MESSAGE", prefix];
                
                title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
                message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
                message = [NSString stringWithFormat:message, signatureWithError.fingerprint];
                break;
            
            case GPGErrorUnknownAlgorithm:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_ALGORITHM_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_ALGORITHM_ERROR_MESSAGE", prefix];
                
                title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
                message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
                break;
            
            case GPGErrorCertificateRevoked:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_REVOKED_CERTIFICATE_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_REVOKED_CERTIFICATE_ERROR_MESSAGE", prefix];
                
                title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
                message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
                message = [NSString stringWithFormat:message, signatureWithError.fingerprint];
                break;
            
            case GPGErrorKeyExpired:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_KEY_EXPIRED_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_KEY_EXPIRED_ERROR_MESSAGE", prefix];
                
                title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
                message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
                message = [NSString stringWithFormat:message, signatureWithError.fingerprint];
                break;
            
            case GPGErrorSignatureExpired:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_SIGNATURE_EXPIRED_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_SIGNATURE_EXPIRED_ERROR_MESSAGE", prefix];
                
                title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
                message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
                break;
                
            case GPGErrorBadSignature:
                titleKey = [NSString stringWithFormat:@"%@_VERIFY_BAD_SIGNATURE_ERROR_TITLE", prefix];
                messageKey = [NSString stringWithFormat:@"%@_VERIFY_BAD_SIGNATURE_ERROR_MESSAGE", prefix];
                
                title = NSLocalizedStringFromTableInBundle(titleKey, @"GPGMail", gpgMailBundle, @"");
                message = NSLocalizedStringFromTableInBundle(messageKey, @"GPGMail", gpgMailBundle, @"");
                break;
            
            default:
                // Set errorFound to 0 for Key expired and signature expired.
                // Those are warnings, not actually errors. Should only be displayed in the signature view.
                errorFound = 0;
                break;
        }
    }
    
    [userInfo setValue:title forKey:@"_MFShortDescription"];
    [userInfo setValue:message forKey:@"NSLocalizedDescription"];
    [userInfo setValue:[NSNumber numberWithBool:YES] forKey:@"VerificationError"];
    
    if(errorFound)
        error = [MFError errorWithDomain:@"MFMessageErrorDomain" code:1036 localizedDescription:nil title:title helpTag:nil 
                                userInfo:userInfo];
    [userInfo release];
    
    return error;
}

- (BOOL)hasError:(NSString *)errorName noDataErrors:(NSArray *)noDataErrors {
    const NSDictionary *errorCodes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:1], @"NO_ARMORED_DATA",
                                [NSNumber numberWithInt:2], @"EXPECTED_PACKAGE_NOT_FOUND",
                                [NSNumber numberWithInt:3], @"INVALID_PACKET",
                                [NSNumber numberWithInt:4], @"EXPECTED_SIGNATURE_NOT_FOUND", nil];
    
    if([noDataErrors containsObject:[errorCodes valueForKey:errorName]])
        return YES;
    
    return NO;
}                           

- (MimeBody *)decryptedMessageBodyFromDecryptedData:(NSData *)decryptedData {
    if([decryptedData length] == 0)
        return nil;
    // 1. Create a new Message using messageWithRFC822Data:
    // This creates the message store automatically!
    Message *decryptedMessage;
    MimeBody *decryptedMimeBody;
    // Unfortunately the Evolution PGP plugins seems to fuck up the encrypted message,
    // which renders it unreadable for Mail.app. This is frustrating but fixable.
    // Actually even easier than i thought at first. Instead of messageWithRFC822Data:
    // messageWithRFC822Data:sanitizeData: can be used to make the problem go away.
    // BOOYAH!
    decryptedMessage = [Message messageWithRFC822Data:decryptedData sanitizeData:YES];
    
    // 2. Set message info from the original encrypted message.
    [decryptedMessage setMessageInfoFromMessage:[(MimeBody *)[self mimeBody] message]];
    
    // 3. Call message body updating flags to set the correct flags for the new message.
    // This will setup the decrypted message, run through all parts and find signature part.
    // We'll save the message body for later, since it will be used to do a last
    // decodeWithContext and the output returned.
    // Fake the message flags on the decrypted message.
    // messageBodyUpdatingFlags: calls isMimeEncrypted. Set MimeEncrypted on the message,
    // so the correct info is returned.
    [decryptedMessage setIvar:@"MimeEncrypted" value:[NSNumber numberWithBool:YES]];
    decryptedMimeBody = [decryptedMessage messageBodyUpdatingFlags:YES];
    
    // Top Level part reparses the message. This method doesn't.
    MimePart *topPart = [self topPart];
    // Set the decrypted message here, otherwise we run into a memory problem.
    [topPart setDecryptedMessageBody:decryptedMimeBody isEncrypted:self.PGPEncrypted isSigned:self.PGPSigned error:self.PGPError];
    self.PGPDecryptedBody = self.decryptedMessageBody;
          
    return decryptedMimeBody;
}

- (NSData *)partDataByReplacingEncryptedData:(NSData *)originalPartData decryptedData:(NSData *)decryptedData encryptedRange:(NSRange)encryptedRange {
    NSMutableData *partData = [[NSMutableData alloc] init];
    NSData *inlineEncryptedData = [originalPartData subdataWithRange:encryptedRange];
    
    BOOL (^otherDataFound)(NSData *) = ^(NSData *data) {
        unsigned char *dataBytes = (unsigned char *)[data bytes];
        for(NSUInteger i = 0; i < [data length]; i++) {
            if(*dataBytes != '\n' && *dataBytes != '\r')
                return YES;
            dataBytes++;
        }
        return NO;
    };
    
    NSData *originalData = originalPartData;
    [partData appendData:[originalData subdataWithRange:NSMakeRange(0, encryptedRange.location)]];
    NSData *restData = [originalData subdataWithRange:NSMakeRange(encryptedRange.location + encryptedRange.length, 
                                                                  [originalData length] - encryptedRange.length - encryptedRange.location)];
    if(decryptedData) {
        // If there was data before or after the encrypted data, signal this
        // with a banner.
        BOOL hasOtherData = (encryptedRange.location != 0) || otherDataFound(restData);
            
        if(hasOtherData)
            [self addPGPPartMarkerToData:partData partData:decryptedData];
        else
            [partData appendData:decryptedData];
    }
    else
        [partData appendData:inlineEncryptedData];
    
    [partData appendData:restData];
    
    BOOL decryptionError = !decryptedData ? YES : NO;
    
    // If there was no decryption error, look for signatures in the partData.
    if(!decryptionError) { 
        NSRange signatureRange = [decryptedData rangeOfPGPInlineSignatures];
        if(signatureRange.location != NSNotFound)
            [self _verifyPGPInlineSignatureInData:decryptedData range:signatureRange];
    }
    
    self.PGPDecryptedData = partData;
    // Decrypted content is a HTML string generated from the decrypted data
    // If the content is only partly encrypted or partly signed, that information
    // is added to the HTML as well.
    NSString *decryptedContent = [[partData stringByGuessingEncoding] markupString];
    decryptedContent = [self contentWithReplacedPGPMarker:decryptedContent isEncrypted:self.PGPEncrypted isSigned:self.PGPSigned];
    // The decrypted data might contain an inline signature.
    // If that's the case the armor is stripped from the data and stored
    // under decryptedPGPContent.
    if(self.PGPSigned)
        self.PGPDecryptedContent = [self stripSignatureFromContent:decryptedContent];
    else
        self.PGPDecryptedContent = decryptedContent;
    
    if([self containsPGPMarker:partData]) {
        self.PGPPartlySigned = self.PGPSigned;
        self.PGPPartlyEncrypted = self.PGPEncrypted;
    }
    
    [partData release];
    
    return self.PGPDecryptedData;
}

- (id)decryptedMessageBodyOrDataForEncryptedData:(NSData *)encryptedData encryptedInlineRange:(NSRange)encryptedRange {
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
            [decryptedString release];
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
    NSString *asciiData = [NSString stringWithData:PGPData encoding:NSASCIIStringEncoding];
    NSString *charsetName = nil;
    [asciiData getCapturesWithRegexAndReferences:@"Charset:\\s*(?<charset>.+)\r?\n", @"${charset}", &charsetName, nil];
    
    if(![charsetName length])
        return NSUTF8StringEncoding;
    
    CFStringEncoding stringEncoding= CFStringConvertIANACharSetNameToEncoding((CFStringRef)charsetName);
    if (stringEncoding != kCFStringEncodingInvalidId) {
        stringEncoding = CFStringConvertEncodingToNSStringEncoding(stringEncoding);
    }
    
    return stringEncoding;
}

#pragma mark Methods for verification

- (void)verifyData:(NSData *)signedData signatureData:(NSData *)signatureData {
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.verbose = NO; //(GPGMailLoggingLevel > 0);
    
    // If signature data is set, the signature is detached, otherwise it's inline.
    NSArray *signatures = nil;
    if([signatureData length])
        signatures = [gpgc verifySignature:signatureData originalData:signedData];
    else
        signatures = [gpgc verifySignedData:signedData];
    
    MFError *error = [self errorFromGPGOperation:GPG_OPERATION_VERIFICATION controller:gpgc];
    self.PGPError = error;
    self.PGPSigned = YES;
    self.PGPVerified = self.PGPError ? NO : YES;
    self.PGPSignatures = signatures;
    
    
    if([self hasPGPInlineSignature:signedData]) {
        NSData *signedDataWithMarkers = [self signedDataWithAddedPGPPartMarkersIfNecessaryForData:signedData];
        NSString *verifiedContent = [[signedDataWithMarkers stringByGuessingEncodingWithHint:[self bestStringEncoding]] markupString];
        verifiedContent = [self contentWithReplacedPGPMarker:verifiedContent isEncrypted:NO isSigned:YES];
        self.PGPVerifiedContent = [self stripSignatureFromContent:verifiedContent];
        signedData = signedDataWithMarkers;
    }
    self.PGPVerifiedData = signedData;
    
    [gpgc release];
}

- (NSStringEncoding)bestStringEncoding {
    NSString *charsetName = [self bodyParameterForKey:@"charset"];
    // No charset name available on current part? Test top part.
    if(![charsetName length]) {
        charsetName = [[self topPart] bodyParameterForKey:@"charset"];
        if(![charsetName length])
            return NSUTF8StringEncoding;
    }
    CFStringEncoding stringEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)charsetName);
    
    if (stringEncoding != kCFStringEncodingInvalidId)
        stringEncoding = CFStringConvertEncodingToNSStringEncoding(stringEncoding);
    
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
    NSString *regex = [NSString stringWithFormat:@"(?sm)^(?<whitespace_before>(\r?\n)*)(?<before>.*)%@\r?\n.*\r?\n\r?\n(?<signed_text>.*)%@.*%@(?<whitespace_after>(\r?\n)*)(?<after>.*)$",PGP_SIGNED_MESSAGE_BEGIN, PGP_MESSAGE_SIGNATURE_BEGIN, PGP_MESSAGE_SIGNATURE_END];
    
    NSStringEncoding bestEncoding = [self bestStringEncoding];
    RKEnumerator *matches = [[signedData stringByGuessingEncodingWithHint:bestEncoding] matchEnumeratorWithRegex:regex];
    
    NSMutableData *markedPart = [NSMutableData data];
    NSString *before = nil, *signedText = nil, *after = nil, *whitespaceBefore = nil,
             *whitespaceAfter = nil;
    
    while([matches nextRanges] != NULL) {
        [matches getCapturesWithReferences:@"${before}", &before, nil];
        [matches getCapturesWithReferences:@"${signed_text}", &signedText, nil];
        [matches getCapturesWithReferences:@"${after}", &after, nil];
        [matches getCapturesWithReferences:@"${whitespace_before}", &whitespaceBefore, nil];
        [matches getCapturesWithReferences:@"${whitespace_after}", &whitespaceAfter, nil];
        
        [self addPGPPartMarkerToData:markedPart partData:[signedText dataUsingEncoding:bestEncoding]];
    }
    
    if(![before length] && ![after length]) {
        [partData release];
        return signedData;
    }
    
    [partData appendData:[whitespaceBefore dataUsingEncoding:bestEncoding]];
    [partData appendData:[before dataUsingEncoding:bestEncoding]];
    [partData appendData:markedPart];
    [partData appendData:[whitespaceAfter dataUsingEncoding:bestEncoding]];
    [partData appendData:[after dataUsingEncoding:bestEncoding]];
    
    return [partData autorelease];
}

- (void)MAVerifySignature {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MAVerifySignature];
    
    // If this is a non GPG signed message, let's call the original method
    // and get out of here!    
    if(![[self bodyParameterForKey:@"protocol"] isEqualToString:@"application/pgp-signature"]) {
        [self MAVerifySignature];
        return;
    }
    
    if(self.PGPVerified || self.PGPError || self.PGPVerifiedData) {
        // Save the status for isMimeSigned call.
        [[self topPart] setIvar:@"MimeSigned" value:[NSNumber numberWithBool:self.PGPSigned]];
        return;
    }
    
    // Set the signed status, otherwise we wouldn't be in here.
    self.PGPSigned = YES;
    
    // Now on to fetching the signed data.
    NSData *signedData = [self signedData];
    // And last finding the signature.
    MimePart *signaturePart = nil;
    for(MimePart *part in [self subparts]) {
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
    NSData *signatureData = [signaturePart bodyData];
	if (![signatureData length]) {
		self.PGPSigned = NO;
        return;
	}
    
    [self verifyData:signedData signatureData:signatureData];
    [[self topPart] setIvar:@"MimeSigned" value:[NSNumber numberWithBool:self.PGPSigned]];
	
    return;
}

- (void)_verifyPGPInlineSignatureInData:(NSData *)data range:(NSRange)signedRange {
    if(![data length] || signedRange.location == NSNotFound)
        return;
    
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
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MAUsesKnownSignatureProtocol];
    
    if([[self bodyParameterForKey:@"protocol"] isEqualToString:@"application/pgp-signature"])
        return YES;
    return [self MAUsesKnownSignatureProtocol];
}

- (void)addPGPPartMarkerToData:(NSMutableData *)data partData:(NSData *)partData {
    [data appendData:[PGP_PART_MARKER_START dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:partData];
    [data appendData:[PGP_PART_MARKER_END dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)contentWithReplacedPGPMarker:(NSString *)content isEncrypted:(BOOL)isEncrypted isSigned:(BOOL)isSigned {
    NSBundle *bundle = [NSBundle bundleForClass:[GPGMailBundle class]];
    
    NSMutableString *partString = [NSMutableString string];
    if(isEncrypted)
        [partString appendString:NSLocalizedStringFromTableInBundle(@"MESSAGE_VIEW_PGP_PART_ENCRYPTED", @"GPGMail", bundle, @"")];
    if(isEncrypted && isSigned)
        [partString appendString:@" & "];
    if(isSigned)
        [partString appendString:NSLocalizedStringFromTableInBundle(@"MESSAGE_VIEW_PGP_PART_SIGNED", @"GPGMail", bundle, @"")];
    
    [partString appendFormat:@" %@", NSLocalizedStringFromTableInBundle(@"MESSAGE_VIEW_PGP_PART", @"GPGMail", bundle, @"")];
    
    content = [content stringByReplacingString:PGP_PART_MARKER_START withString:[NSString stringWithFormat:@"<fieldset style=\"padding-top:10px; border:0px; border: 3px solid #CCC; padding-left: 20px;\"><legend style=\"font-weight:bold\">%@</legend><div style=\"padding-left:3px;\">", partString]];
    content = [content stringByReplacingString:PGP_PART_MARKER_END withString:@"</div></fieldset>"];
    
    return content;
}

- (BOOL)containsPGPMarker:(NSData *)data {
    if(![data length])
        return NO;
    return [data rangeOfData:[PGP_PART_MARKER_START dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [data length])].location != NSNotFound;
}

#pragma mark MimePart property implementation.

- (void)setPGPEncrypted:(BOOL)PGPEncrypted {
    [self setIvar:@"PGPEncrypted" value:[NSNumber numberWithBool:PGPEncrypted]];
}

- (BOOL)PGPEncrypted {
    return [[self getIvar:@"PGPEncrypted"] boolValue];
}

- (void)setPGPSigned:(BOOL)PGPSigned {
    [self setIvar:@"PGPSigned" value:[NSNumber numberWithBool:PGPSigned]];
}

- (BOOL)PGPSigned {
    return [[self getIvar:@"PGPSigned"] boolValue];
}

- (void)setPGPPartlySigned:(BOOL)PGPPartlySigned {
    [self setIvar:@"PGPPartlySigned" value:[NSNumber numberWithBool:PGPPartlySigned]];
}

- (BOOL)PGPPartlySigned {
    return [[self getIvar:@"PGPPartlySigned"] boolValue];
}

- (void)setPGPPartlyEncrypted:(BOOL)PGPPartlyEncrypted {
    [self setIvar:@"PGPPartlyEncrypted" value:[NSNumber numberWithBool:PGPPartlyEncrypted]];
}

- (BOOL)PGPPartlyEncrypted {
    return [[self getIvar:@"PGPPartlyEncrypted"] boolValue];
}

- (void)setPGPDecrypted:(BOOL)PGPDecrypted {
    [self setIvar:@"PGPDecrypted" value:[NSNumber numberWithBool:PGPDecrypted]];
}

- (BOOL)PGPDecrypted {
    return [[self getIvar:@"PGPDecrypted"] boolValue];
}

- (void)setPGPVerified:(BOOL)PGPVerified {
    [self setIvar:@"PGPVerified" value:[NSNumber numberWithBool:PGPVerified]];
}

- (BOOL)PGPVerified {
    return [[self getIvar:@"PGPVerified"] boolValue];
}

- (void)setPGPAttachment:(BOOL)PGPAttachment {
    [self setIvar:@"PGPAttachment" value:[NSNumber numberWithBool:PGPAttachment]];
}

- (BOOL)PGPAttachment {
    return [[self getIvar:@"PGPAttachment"] boolValue];
}

- (void)setPGPSignatures:(NSArray *)PGPSignatures {
    NSMutableArray *signatures = nil;
    if(![self getIvar:@"PGPSignatures"]) {
        signatures = [[NSMutableArray alloc] initWithCapacity:0];
        [self setIvar:@"PGPSignatures" value:signatures];
    }
    [[self getIvar:@"PGPSignatures"] addObjectsFromArray:PGPSignatures];
    [signatures release];
}

- (NSArray *)PGPSignatures {
    return [self getIvar:@"PGPSignatures"];
}

- (void)setPGPError:(MFError *)PGPError {
    [self setIvar:@"PGPError" value:PGPError];
}

- (MFError *)PGPError {
    return [self getIvar:@"PGPError"];
}

- (void)setPGPDecryptedData:(NSData *)PGPDecryptedData {
    [self setIvar:@"PGPDecryptedData" value:PGPDecryptedData];
}

- (NSData *)PGPDecryptedData {
    return [self getIvar:@"PGPDecryptedData"];
}

- (void)setPGPDecryptedContent:(NSString *)PGPDecryptedContent {
    [self setIvar:@"PGPDecryptedContent" value:PGPDecryptedContent];
}

- (NSString *)PGPDecryptedContent {
    return [self getIvar:@"PGPDecryptedContent"];
}

- (void)setPGPDecryptedBody:(MessageBody *)PGPDecryptedBody {
    [self setIvar:@"PGPDecryptedBody" value:PGPDecryptedBody];
}

- (MessageBody *)PGPDecryptedBody {
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


#pragma mark other stuff to test Xcode code folding.

- (BOOL)MAIsSigned {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MAIsSigned];
    
    BOOL ret = [self MAIsSigned];
    // For plain text message is signed doesn't automatically find
    // the right signed status, so we check if copy signers are available.
    return ret || self.PGPSigned;
}

- (BOOL)_isExchangeServerModifiedPGPMimeEncrypted {
    if(![self isType:@"multipart" subtype:@"mixed"])
        return NO;
    // Find the application/pgp-encrypted subpart.
    NSArray *subparts = [self subparts];
    MimePart *applicationPGPEncrypted = nil;
    for(MimePart *part in subparts) {
        if([part isType:@"application" subtype:@"pgp-encrypted"]) {
            applicationPGPEncrypted = part;
            break;
        }
    }
    // If such a part is found, the message is exchange modified, otherwise
    // not.
    return applicationPGPEncrypted != nil;
}

- (BOOL)isPGPMimeEncrypted {
    // Special case for PGP/MIME encrypted emails, which were sent through an
    // exchange server, which unfortunately modifies the header.
    if([self _isExchangeServerModifiedPGPMimeEncrypted])
        return YES;
    // Check for multipart/encrypted, protocol application/pgp-encrypted, otherwise exit!
    if(![[[self type] lowercaseString] isEqualToString:@"multipart"] || ![[[self subtype] lowercaseString] isEqualToString:@"encrypted"])
        return NO;
    
    if([self bodyParameterForKey:@"protocol"] != nil && ![[[self bodyParameterForKey:@"protocol"] lowercaseString] isEqualToString:@"application/pgp-encrypted"])
        return NO;
    
    // Alright, passed. So next, subparts must be exactly 2!
    if([(NSArray *)[self subparts] count] != 2)
        return NO;
    
    MimePart *versionPart = [self subpartAtIndex:0];
    MimePart *dataPart = [self subpartAtIndex:1];
    
    // Version Part is application/pgp- encrypted.
    // Data Part is application/octet-stream OR application/pgp-signature (for FireGPG < 0.7.1)
    if([[[versionPart type] lowercaseString] isEqualToString:@"application"] && [[[versionPart subtype] lowercaseString] isEqualToString:@"pgp-encrypted"] &&
       [[[dataPart type] lowercaseString] isEqualToString:@"application"] && ([[[dataPart subtype] lowercaseString] isEqualToString:@"octet-stream"] ||
                                                                              [[[dataPart subtype] lowercaseString] isEqualToString:@"pgp-signature"])) {
           return [[versionPart bodyData] containsPGPVersionMarker:1];
       }
    
    return NO;
}

- (BOOL)MAIsEncrypted {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MAIsEncrypted];
    
    if(self.PGPEncrypted)
        return YES;
    
    // Otherwise to also support S/MIME encrypted messages, call
    // the original method.
    return [self MAIsEncrypted];
}

- (BOOL)MAIsMimeEncrypted {
    BOOL ret = [self MAIsMimeEncrypted];
    BOOL isPGPMimeEncrypted = [[[(MimeBody *)[self mimeBody] message] getIvar:@"MimeEncrypted"] boolValue];
    return ret || isPGPMimeEncrypted;
}

- (BOOL)MAIsMimeSigned {
    BOOL ret = [self MAIsMimeSigned];
    BOOL isPGPMimeSigned = [[[self topPart] getIvar:@"MimeSigned"] boolValue];
    return ret || isPGPMimeSigned;
}

- (Message *)messageWithMessageData:(NSData *)messageData {
    MutableMessageHeaders *headers = [[MutableMessageHeaders alloc] init];
    NSMutableString *contentTypeString = [[NSMutableString alloc] init];
    [contentTypeString appendFormat:@"%@/%@", self.type, self.subtype];
    if([self bodyParameterForKey:@"charset"])
        [contentTypeString appendFormat:@"; charset=\"%@\"", [self bodyParameterForKey:@"charset"]];
    [headers setHeader:[contentTypeString dataUsingEncoding:NSASCIIStringEncoding] forKey:@"Content-Type"];
    [contentTypeString release];
    if(self.contentTransferEncoding)
        [headers setHeader:self.contentTransferEncoding forKey:@"Content-Transfer-Encoding"];

    NSMutableData *completeMessageData = [[NSMutableData alloc] init];
    [completeMessageData appendData:[headers encodedHeadersIncludingFromSpace:NO]];
    [completeMessageData appendData:messageData];
    [headers release];

    Message *message = [Message messageWithRFC822Data:completeMessageData];
    [completeMessageData release];

    return message;
}

- (void)MAClearCachedDecryptedMessageBody {
    // Check if message should be processed (-[Message shouldBePGPProcessed])
    // otherwise out of here!
    if(![[(MimeBody *)[self mimeBody] message] shouldBePGPProcessed])
        return [self MAClearCachedDecryptedMessageBody];
    
    /* The original method is called to clear PGP/MIME messages. */
    // Loop through the parts and clear them.
    [self enumerateSubpartsWithBlock:^(MimePart *currentPart) {
        [currentPart removeIvars];
    }];
    [(Message *)[(MimeBody *)[self mimeBody] message] clearPGPInformation];
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


- (id)MANewEncryptedPartWithData:(NSData *)data recipients:(id)recipients encryptedData:(NSData **)encryptedData {
//    DebugLog(@"[DEBUG] %s enter", __PRETTY_FUNCTION__);
    // First thing todo, check if an address with the gpg-mail prefix is found.
    // If not, S/MIME is wanted.
    NSArray *prefixedAddresses = [recipients filter:^(id recipient){
        return [(NSString *)recipient isFlaggedValue] ? recipient : nil;
    }];
    if(![prefixedAddresses count])
        return [self MANewEncryptedPartWithData:data recipients:recipients encryptedData:encryptedData];

	
	// Search for gpgErrorIdentifier in data.
	NSRange range = [data rangeOfData:[gpgErrorIdentifier dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, [data length])];
	if (range.length > 0) {
		// Simply set data as encryptedData to preserve the errorCode.
		*encryptedData = data;
		MimePart *dataPart = [[MimePart alloc] init];
		return dataPart;
	}

	// Split the recipients in normal and bcc recipients.
    NSMutableArray *normalRecipients = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray *bccRecipients = [[NSMutableArray alloc] initWithCapacity:1];
    for(NSString *recipient in recipients) {
		
        if([@"bcc" isEqualTo:[recipient valueForFlag:@"recipientType"]])
            [bccRecipients addObject:recipient];
        else
            [normalRecipients addObject:recipient];
    }
    
    // Ask the mail bundle for the GPGKeys matching the email address.
    NSSet *normalKeyList = [[GPGMailBundle sharedInstance] publicKeyListForAddresses:normalRecipients];
    NSMutableSet *bccKeyList = [[GPGMailBundle sharedInstance] publicKeyListForAddresses:bccRecipients];
	[bccKeyList minusSet:normalKeyList];
    
    NSMutableSet *flattenedNormalKeyList = [self flattenedKeyList:normalKeyList];
    NSMutableSet *flattenedBCCKeyList = [self flattenedKeyList:bccKeyList];
    
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.verbose = NO; //(GPGMailLoggingLevel > 0);
    gpgc.useArmor = YES;
    gpgc.useTextMode = YES;
    // Automatically trust keys, even though they are not specifically
    // marked as such.
    // Eventually add warning for this.
    gpgc.trustAllKeys = YES;
    gpgc.printVersion = YES;
    @try {
        *encryptedData = [gpgc processData:data withEncryptSignMode:GPGPublicKeyEncrypt recipients:flattenedNormalKeyList hiddenRecipients:flattenedBCCKeyList];
		if (gpgc.error) {
			@throw gpgc.error;
		}
    }
    @catch(NSException *e) {
#warning TODO - use correct error mesage.
        [self failedToSignForSender:@"t@t.com" gpgErrorCode:1];
//        DebugLog(@"[DEBUG] %s encryption error: %@", __PRETTY_FUNCTION__, e);
        // TODO: Add encryption error handling. (Re-use the dialogs shown for S/MIME
        //       encryption errors?
        return nil;
    }
    @finally {
        [gpgc release];
    }

    // 1. Create a new mime part for the encrypted data.
    // -> Problem S/MIME only has one mime part GPG/MIME has two, one for
    // -> the version, one for the data.
    // -> Therefore it's necessary to manipulate the message mime parts in
    // -> _makeMessageWithContents:
    // -> Not great, but not a big problem either (let's hope)
    MimePart *dataPart = [[MimePart alloc] init];

    [dataPart setType:@"application"];
    [dataPart setSubtype:@"octet-stream"];
    [dataPart setBodyParameter:@"encrypted.asc" forKey:@"name"];
    dataPart.contentTransferEncoding = @"7bit";
    [dataPart setDisposition:@"inline"];
    [dataPart setDispositionParameter:@"encrypted.asc" forKey:@"filename"];
    [dataPart setContentDescription:@"OpenPGP encrypted message"];

    return dataPart;
}


// TODO: Translate the error message if creating the signature fails.
//       At the moment the standard S/MIME message is used.
- (id)MANewSignedPartWithData:(id)data sender:(id)sender signatureData:(id *)signatureData {
    // If sender doesn't show any injected header values, S/MIME is wanted,
    // hence the original method called.
    if(![@"from" isEqualTo:[sender valueForFlag:@"recipientType"]]) {
        id newPart = [self MANewSignedPartWithData:data sender:sender signatureData:signatureData];
        return newPart;
    }
	
	GPGKey *keyForSigning = [sender valueForFlag:@"gpgKey"];
	
	if (!keyForSigning) {
		//Should not happen!
		keyForSigning = [[[GPGMailBundle sharedInstance] signingKeyListForAddress:sender] anyObject];
		// Should also not happen, but if no valid signing keys are found
		// raise an error. Returning nil tells Mail that an error occured.
		if (!keyForSigning) {
			[self failedToSignForSender:sender gpgErrorCode:1];
			return nil;
		}
	}	
	
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.verbose = NO; //(GPGMailLoggingLevel > 0);
    gpgc.useArmor = YES;
    gpgc.useTextMode = YES;
    // Automatically trust keys, even though they are not specifically
    // marked as such.
    // Eventually add warning for this.
    gpgc.trustAllKeys = YES;
    gpgc.printVersion = YES;
    
	[gpgc setSignerKey:keyForSigning];
    
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
			// Write the errorCode in signatureData, so the back-end can cancel the operation.
			*signatureData = [[gpgErrorIdentifier stringByAppendingFormat:@"%i:", GPGErrorCancelled] dataUsingEncoding:NSUTF8StringEncoding];
			
			[self failedToSignForSender:sender gpgErrorCode:GPGErrorCancelled];
		} else {
			[self failedToSignForSender:sender gpgErrorCode:e.errorCode];
			return nil;
		}
	}
    @catch(NSException *e) {
		[self failedToSignForSender:sender gpgErrorCode:1];
        return nil;
    }
    @finally {
        [gpgc release];
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
    MimePart *topPart = [[MimePart alloc] init];
    [topPart setType:@"multipart"];
    [topPart setSubtype:@"signed"];
    // TODO: sha1 the right algorithm?
    [topPart setBodyParameter:[NSString stringWithFormat:@"pgp-%@", hashAlgorithmName] forKey:@"micalg"];
    [topPart setBodyParameter:@"application/pgp-signature" forKey:@"protocol"];

    MimePart *signaturePart = [[MimePart alloc] init];
    [signaturePart setType:@"application"];
    [signaturePart setSubtype:@"pgp-signature"];
    [signaturePart setBodyParameter:@"signature.asc" forKey:@"name"];
    signaturePart.contentTransferEncoding = @"7bit";
    [signaturePart setDisposition:@"attachment"];
    [signaturePart setDispositionParameter:@"signature.asc" forKey:@"filename"];
    // TODO: translate this string.
    [signaturePart setContentDescription:@"Message signed with OpenPGP using GPGMail"];

    // Self is actually the whole current message part.
    // So the only thing to do is, add self to our top part
    // and add the signature part to the top part and voila!
    [topPart addSubpart:self];
    [topPart addSubpart:signaturePart];

    return topPart;
}

- (NSData *)newInlineSignedDataForData:(id)data sender:(id)sender {
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
			[self failedToSignForSender:sender gpgErrorCode:1];
			return nil;
		}
	}
	
	
    GPGController *gpgc = [[GPGController alloc] init];
    gpgc.verbose = NO; //(GPGMailLoggingLevel > 0);
    gpgc.useArmor = YES;
    gpgc.useTextMode = YES;
    // Automatically trust keys, even though they are not specifically
    // marked as such.
    // Eventually add warning for this.
    gpgc.trustAllKeys = YES;
    gpgc.printVersion = YES;
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
			[self failedToSignForSender:sender gpgErrorCode:GPGErrorCancelled];
            return nil;
		}
		@throw e;
	}
    @catch(NSException *e) {
//        DebugLog(@"[DEBUG] %s sign error: %@", __PRETTY_FUNCTION__, e);
		@throw e;
    }
    @finally {
        [gpgc release];
    }
    
    return signedData;
}

- (void)failedToSignForSender:(NSString *)sender gpgErrorCode:(GPGErrorCode)errorCode{
    NSBundle *messagesFramework = [NSBundle bundleForClass:[MimePart class]];
    NSString *localizedDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"SMIME_CANT_SIGN_MESSAGE", @"Delayed", messagesFramework, @""),
                                      [sender gpgNormalizedEmail]];
    NSString *titleDescription = NSLocalizedStringFromTableInBundle(@"SMIME_CANT_SIGN_TITLE", @"Delayed", messagesFramework, @"");
    MFError *error = [MFError errorWithDomain:@"MFMessageErrorDomain" code:1036 localizedDescription:nil title:titleDescription
                                      helpTag:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:localizedDescription,
                                                            @"NSLocalizedDescription", titleDescription, @"_MFShortDescription", [NSNumber numberWithInt:errorCode], @"GPGErrorCode", nil]];
    // Puh, this was all but easy, to find out where the error is used.
    // Overreleasing allows to track it's path as an NSZombie in Instruments!
    [[ActivityMonitor currentMonitor] setError:error];
}

@end

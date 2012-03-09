/* MimePart+GPGMail.h created by stephane on Mon 10-Jul-2000 */
/* MimePart+GPGMail.h re-created by Lukas Pitschl (@lukele) on Wed 03-Aug-2011 */

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

#import <MimePart.h>
#import <Libmacgpg/Libmacgpg.h>

@class MimeBody;

#define PGP_ATTACHMENT_EXTENSION @"pgp"
#define PGP_PART_MARKER_START @"::gpgmail-start-pgp-part::"
#define PGP_PART_MARKER_END @"::gpgmail-end-pgp-part::"

typedef enum {
    /* This error describes any error but a non found secret key and NO_DATA 1 (No armored data). */
    GPG_OPERATION_DECRYPTION_GENERAL_ERROR = 100,
    /* This error describes the lack of a secret key, if no decryption okay is received. */
    GPG_OPERATION_DECRYPTION_NO_SECKEY_ERROR,
    /* This error describes a no armored data error, if the data armor was modified or corrupted. */
    GPG_OPERATION_DECRYPTION_CORRUPTED_DATA_ERROR, 
    /* This errors describes if on verification a signature was expected but not found 
       (data might have been modified.)
     */
    GPG_OPERATION_VERIFICATION_CORRUPTED_DATA_ERROR,
    /* This error describes the lack of the public key used to sign the data. */
    GPG_OPERATION_VERIFICATION_NO_PUBKEY_ERROR
} GPG_OPERATION_ERRORS;

typedef enum {
    GPG_OPERATION_DECRYPTION = 200,
    GPG_OPERATION_VERIFICATION
}  GPG_OPERATION;

@class MFMimeDecodeContext, _NSDataMessageStoreMessage;

@interface MimePart (GPGMail)

@property (assign) BOOL PGPEncrypted;
@property (assign) BOOL PGPPartlyEncrypted;
@property (assign) BOOL PGPSigned;
@property (assign) BOOL PGPPartlySigned;
@property (assign) BOOL PGPDecrypted;
@property (assign) BOOL PGPVerified;
@property (assign) BOOL PGPAttachment;
@property (retain) NSArray *PGPSignatures;
@property (retain) MFError *PGPError;
@property (retain) NSData *PGPDecryptedData;
@property (retain) MessageBody *PGPDecryptedBody;
@property (retain) NSString *PGPDecryptedContent;
@property (retain) NSString *PGPVerifiedContent;
@property (retain) NSData *PGPVerifiedData;

/**
 Creates the parsed message (content of the emai) which is then
 displayed to the user.
 It's called for every mime part once. It might return a string, an instance
 of parsed message or information to an attachment.
 
 For each part also decryptedMessageBodyIsEncrypted is called, which returns
 the message body of the decrypted message, which is set by either the S/MIME
 methods of Mail.app or the GPG methods. This also allows Mail.app to cache
 the decrypted body internally. (GPGMail might, but does not interfere with that
 cache at the moment.)
 
 GPGMail uses this method to implement support for GPG related mime parts, being
 pgp-encrypted and pgp-signature for the moment. It's also used for text/plain
 to support inline gpg encrypted messages.
 */
- (id)MADecodeWithContext:(id)ctx;

/**
 * Loops through all mime parts and runs a block on them.
 */
- (void)enumerateSubpartsWithBlock:(void (^)(MimePart *))partBlock;

/**
 Calling topLevelPart on the mimeBody forces the parts to be regenerated.
 This way it's possible to access the top level part by walking up
 the mime part tree avoiding the regeneration.
 */
- (MimePart *)topPart;

/**
 Is called for every text/plain part. Firt checks if it contains any encrypted or
 signed data and if so operates on it.
 */
- (id)MADecodeTextPlainWithContext:(MFMimeDecodeContext *)ctx;

/**
 Is called for every text/html part. text/html is not easy to parse, so
 if any PGP data if found the text/part is used instead, if it exists.
 */
- (id)MADecodeTextHtmlWithContext:(MFMimeDecodeContext *)ctx;

/**
 Is called for every application/octet-stream part which might contain
 a PGP encrypted/signed attachment.
 If any PGP data is found, decrypt is called on it.
 */
- (id)MADecodeApplicationOctet_streamWithContext:(MFMimeDecodeContext *)ctx;

/**
 Detects if the attachment is the PGP/MIME encrypted attachment.
 Important to exclude from the attachment count.
 */
- (BOOL)isPGPMimeEncryptedAttachment;

/**
 Detects if the attachment is the PGP/MIME signature attachment.
 Important to exclude from the attachment count.
 */
- (BOOL)isPGPMimeSignatureAttachment;

- (id)decodePGPEncryptedAttachment;
- (id)decodePGPSignatureAttachment;

/**
 Adds the filename of a signature attachment which should not be displayed.
 */
- (void)scheduleSignatureAttachmentForRemoval:(NSString *)attachment;

/**
 Returns a list of all filenames of attachments scheduled for removal.
 */
- (NSArray *)signatureAttachmentScheduledForRemoval;

/**
 Checks the extension for known PGP Data extensions and sets the values
 */
- (void)attachmentMightBePGPEncrypted:(BOOL *)mightEnc orSigned:(BOOL *)mightSig;

/**
 Is called by GPGDecodeWithContext if a multipart/encrypted mime part
 is found. Performs the decryption and returns the result.
 */
- (id)decodeMultipartEncryptedWithContext:(id)ctx;

/**
 Fixes an issue with a very early alpha of GPGMail 2.0
 which sent out completely fucked up messages.
 The encrypted part of those messages doesn't contain any encrypted data
 but the plain data of the message.
 Returns the plain data.
 */
- (id)decodeFuckedUpEarlyAlphaData:(NSData *)data context:(MFMimeDecodeContext *)ctx;

/**
 Decrypts the data and sets all important PGP information for the mime part.
 */
- (id)decryptData:(NSData *)encryptedData;

/**
 Helper method which calls either errorFromDecryptionOperation: or errorFromVerificationOperation:
 based on the operation.
 */
- (id)errorFromGPGOperation:(GPG_OPERATION)operation controller:(GPGController *)gpgc;

/**
 Checks the GPGController for decryption errors and returns the appropriate
 error message.
 */
- (MFError *)errorFromDecryptionOperation:(GPGController *)gpgc;


/**
 Checks the GPGController for verification errors and returns the appropriate
 error message.
 */
- (MFError *)errorFromVerificationOperation:(GPGController *)gpgc;

/**
 Helper method to process GPGController NODATA errors.
 */
- (BOOL)hasError:(NSString *)errorName noDataErrors:(NSArray *)noDataErrors;

/**
 Reads the charset of a PGP message from the armor headers.
 No charset is found return UTF8.
 */
- (NSStringEncoding)stringEncodingFromPGPData:(NSData *)PGPData;

/**
 Return the charset found in the current mime part or top part.
 */
- (NSStringEncoding)bestStringEncoding;

/**
 Checks for a signed message begin marker.
 */
- (BOOL)hasPGPInlineSignature:(NSData *)data;

/**
 Returns the signed data with PGP part markers, if the message is part signed.
 Otherwise the input data is the output data.
 */
- (NSData *)signedDataWithAddedPGPPartMarkersIfNecessaryForData:(NSData *)signedData;

/**
 Creates a new message similar the way S/MIME does it, from the decryptedData.
 */
- (MimeBody *)decryptedMessageBodyFromDecryptedData:(NSData *)decryptedData;

/**
 Returns the complete part data but replaces the encrypted data with the decrypted
 first or leaves the encrypted data in, if there was an decryption error.
 */
- (NSData *)partDataByReplacingEncryptedData:(NSData *)originalPartData decryptedData:(NSData *)decryptedData encryptedRange:(NSRange)encryptedRange;

/**
 Calls decryptData: for either PGP/MIME or PGP/Inline encrypted data.
 */
- (id)decryptedMessageBodyOrDataForEncryptedData:(NSData *)encryptedData encryptedInlineRange:(NSRange)encryptedRange;

/**
 Verifies the passed data and sets the PGP information for the part.
 */
- (void)verifyData:(NSData *)signedData signatureData:(NSData *)signatureData;

/**
 For signed messages Mail.app automatically calls verifySignature.
 After first checking if the verification has not already been performed,
 using the MimePart.needsSignatureVerification method, this method
 verifies the signature, and stores all found signatures in MimePart._messageSigners.
 
 Unfortunately verifySignature understands that the signature
 is no MIME signature, hence never calls _verifySignatureWithCMSDecoder,
 therefore we have to hijack this method and re-implement it for our own.
 To decide whether or not the original method should be called, we'll
 use the protocol information.
 */
- (void)MAVerifySignature;

/**
 Is used to verify PGP/inline signatures.
 */
- (void)_verifyPGPInlineSignatureInData:(NSData *)data range:(NSRange)signedRange;

/**
 Strips the PGP SIGNED markes from the part HTML string.
 */
- (id)stripSignatureFromContent:(id)content;

/**
 Is called internally from Mail.app by verify signature.
 Needs to be overridden to allow application/pgp-signature parts
 which ensures that the PGP/MIME signed message is actually verified.
 */
- (BOOL)MAUsesKnownSignatureProtocol;

/**
 Adds markers for encrypted/signed parts which are later replaced
 by the HTML to display the markers in the message.
 */
- (void)addPGPPartMarkerToData:(NSMutableData *)data partData:(NSData *)partData;

/**
 Replace the markers with the appropriate HTML for display.
 */
- (NSString *)contentWithReplacedPGPMarker:(NSString *)content isEncrypted:(BOOL)isEncrypted isSigned:(BOOL)isSigned;

/**
 Checks if the data contains markers.
 */
- (BOOL)containsPGPMarker:(NSData *)data;

/**
 Is called by Mail.app to check if a message is signed. It's not yet entirely
 clear how Mail finds out whether a message is signed or not, but GPGMail uses
 the MimePart.PGPSigned variable. 
 If message signers are available, this returns true.
 */
- (BOOL)MAIsSigned;

/**
 If a PGP/MIME message is sent through an Exchange Server the
 message headers are being modified.
 This method checks for those modified headers.
 */
- (BOOL)_isExchangeServerModifiedPGPMimeEncrypted;

/**
 Checks if the message is PGP/MIME Encrypted.
 */
- (BOOL)isPGPMimeEncrypted;

/**
 Create a new message text/plain message for decrypted pgp inline data.
 */
- (Message *)messageWithMessageData:(NSData *)messageData;

/**
 Is called when the decrypted body is supposed to be cleared.
 Mostly happens when a message is deselected.
 In that case all data added to the message has to be removed.
 */
- (void)MAClearCachedDecryptedMessageBody;

/**
 This methods is called internally by Mail's MessageWriter. The MessageWriter
 class is used to create outgoing messages and has various flags among them shouldSign
 and shouldEncrypt.
 If shouldEncrypt is set, this method is called the data to encrypt and returns the
 mime part which will contain the encrypted data.
 
 The actual encrypted data is stored in the pointer *encryptedData.
 */
- (id)MANewEncryptedPartWithData:(NSData *)data recipients:(id)recipients encryptedData:(NSData **)encryptedData;

/**
 Like newEncryptedPartWithData (see above), this method is called from MessageWriter
 too when creating the outgoing message and shouldSign is set to true.
 
 Only the data to actually sign is passed in (some transformation necessary, to help
 with signature verification problems?)
 
 Again, the mime part containing the data is returned and the signature written
 to the *signatureData pointer. 
 */
- (id)MANewSignedPartWithData:(id)data sender:(id)sender signatureData:(id *)signatureData;

/**
 Get the (autoreleased) data for a new PGP/Inline signed message.
 EXPERIMENTAL!
 */
- (NSData *)inlineSignedDataForData:(id)data sender:(id)sender;

/**
 Uses the ActivityMonitor to display an error message if the signing process failed.
 Analog to what S/MIME uses.
 */
- (void)failedToSignForSender:(NSString *)sender gpgErrorCode:(GPGErrorCode)errorCode;

@end


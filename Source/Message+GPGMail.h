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

#import "MCMimePart.h"
#import "MCMessage.h"

@class GMMessageSecurityFeatures;

@interface Message_GPGMail : NSObject

/**
 Mail.app uses -[Message messageFlags] to gather various internal information
 about the message, including whether the email is encrypted and|or
 signed.
 It's also used to determine whether or not the message error banner
 should be displayed in the event that decrypt or verify of a message
 fails.
 Unfortunately PGP messages are not recognized as signed or encrypted
 and hence, the error banner is never shown.
 
 To fix whenever a PGP encrypted and|or signed message is encountered
 a call to this method temporarily adds the signed (0x00800000) and 
 encrypted bits (0x00000008) to the current flags.
 
 This way the banner is shown for PGP messages as well, since Mail now believes
 this message is indeed encrypted and|or signed.
 
 N.B.: Previously setIvar was used. messageFlags is called a bazillion times
       which caused getIvar to deadlock. DON'T USE setIvar FOR METHODS
       which are called very often.
 */

- (void)fakeMessageFlagsIsEncrypted:(BOOL)isEncrypted isSigned:(BOOL)isSigned;

// This is now on the GMMessageSecurityParseResult
//- (void)collectPGPInformationStartingWithMimePart:(GM_CAST_CLASS(MimePart *, id))topPart decryptedBody:(GM_CAST_CLASS(MimeBody *, id))decryptedBody;
//- (void)clearPGPInformation;

/**
 Determines whetehr or not the message should be processed with PGP operations.
 
 Always returns false if OpenPGP for reading is disabled in Preferences.
 Returns true if the user actively selected the message.
 Returns false if the user didn't select the message and NeverCreatePreviewSnippet is set.
 
 This allows GPGMail to avoid processing every message on startup which leads to
 many annoying pinentry password entry dialogs, if the user didn't choose to store
 passwords in the keychain.
 */
- (BOOL)shouldBePGPProcessed;

/**
 Determines whether or not the preview snippet for the message should be created.
 Always returns true if the Create List Preview preference is set.
 Also returns true if the Create List Preview preference is NOT set, BUT the
 passphrase for the message is already in cache.
 */
- (BOOL)shouldCreateSnippetWithData:(NSData *)data;

/**
 Checks whether dataSource (10.8) or messageStore (10.7) is available
 and calls the correct method.
 */
- (id)dataSourceProxy;

/**
 Returns whether the user did in fact actively select the message or not.
 */
- (BOOL)userDidActivelySelectMessageCheckingMessageOnly:(BOOL)messageOnly;

// These are now on the GMMessageSecurityParseResult
//@property (assign) BOOL PGPInfoCollected;
//@property (assign) BOOL PGPEncrypted;
//@property (assign) BOOL PGPPartlyEncrypted;
//@property (assign) BOOL PGPSigned;
//@property (assign) BOOL PGPPartlySigned;
//@property (assign) BOOL PGPDecrypted;
//@property (assign) BOOL PGPVerified;
//@property (retain) NSArray *PGPSignatures;
//@property (retain, readonly) NSArray *PGPSignatureLabels;
//@property (retain) NSArray *PGPErrors;
//@property (assign) NSUInteger numberOfPGPAttachments;
//@property (retain) NSArray *PGPAttachments; 

/**
 Check if the message is genereally signed or encrypted, either S/MIME or PGP/MIME
 by checking the flags.
 */
@property (assign, readonly) BOOL isSigned;
@property (assign, readonly) BOOL isEncrypted;

/**
 Check if the message is S/MIME signed or encrypted. In case the message is not PGP/MIME
 but still encrypted or signed.
*/
@property (assign, readonly) BOOL isSMIMEEncrypted;
@property (assign, readonly) BOOL isSMIMESigned;

- (GMMessageSecurityFeatures *)securityFeatures;

@end

@interface Message_GPGMail (MailMethods)

- (id)subject;
- (id)dataSource;
- (id)messageStore;
- (id)messageBody;
- (id)messageBodyIfAvailable;

@end


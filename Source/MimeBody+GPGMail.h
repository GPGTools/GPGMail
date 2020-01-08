/* MimeBody+GPGMail.h created by stephane on Thu 06-Jul-2000 */
/* MimeBody+GPGMail.h re-created by Lukas Pitschl (@lukele) on Wed 03-Aug-2011 */

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

@class GMMessageSecurityFeatures, MCMessage;

@interface MCMimeBody : NSObject

- (MCMimePart *)topLevelPart;

@end

@interface MimeBody_GPGMail : NSObject

/**
 This method is call by Mail internally and it's not exactly clear
 what it is used for, but if not replaced, Mail crashes, if PGP signatures
 are found for this message, since Mail doesn't know how to deal
 with GPGMail's GPGSignatures.
 
 TODO: Should probably check, if one of the signatures matches a mail account
 configured in Mail. (Not necessary at the moment though)
 */
- (BOOL)MAIsSignedByMe;

/**
 It's not exactly clear when this method is used, but internally it
 checks the message for mime parts signaling S/MIME encrypted or signed
 messages.
 
 It can't be bad to fix it for PGP messages, anyway.
 Instead of the mime parts, which due to inline PGP are not reliable enough,
 GPGMail checks for PGP armor, which is included in inline and PGP/MIME messages.
 */
- (BOOL)MA_isPossiblySignedOrEncrypted;

- (void)collectSecurityFeatures;
- (void)setSecurityFeatures:(GMMessageSecurityFeatures *)securityFeatures;
- (GMMessageSecurityFeatures *)securityFeatures;

- (BOOL)mightContainPGPData;
- (BOOL)mightContainPGPMIMESignedData;
@end

@interface MimeBody_GPGMail (MissingInSierra)

- (MCMessage *)GMMessage;

@end

//@interface MimeBody_GPGMail (NativeMailMethod)
//
//- (GM_CAST_CLASS(Message *, id))message;
//- (NSData *)bodyData;
//- (GM_CAST_CLASS(MimePart *, id))topLevelPart;
//
//@end

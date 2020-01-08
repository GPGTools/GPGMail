/* ConversationMember+GPGMail.m created by Lukas Pitschl (@lukele) on Thu 18-Oct-2013 */

/*
 * Copyright (c) 2000-2013, GPGTools Team <team@gpgtools.org>
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of GPGTools nor the names of GPGMail
 *       contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE GPGTools Team ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE GPGTools Team BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ConversationMember+GPGMail.h"
#import "CCLog.h"
#import "MCMessage.h"
#import "Message+GPGMail.h"
#import "GMMessageSecurityFeatures.h"
#import "MUIWebDocument.h"

#define MAIL_SELF ((ConversationMember *)self)

@interface MUIWebDocument (macOS_10_14_1)

- (void)setHasBlockedMessageContent:(BOOL)has;
- (void)setMessageContentTypeToBlock:(long)contentType;

@end

@implementation ConversationMember_GPGMail

- (void)MA_reloadSecurityProperties {
    // TODO: If still necessary, re-implement using security features.
    [self MA_reloadSecurityProperties];
    return;
//    /* Doesn't seem to be used under Yosemite. */
//    MCMessage *message = [(ConversationMember *)self originalMessage];
//    if(((Message_GPGMail *)message).PGPSigned || ((Message_GPGMail *)message).PGPEncrypted) {
//        [self setIsEncrypted:((Message_GPGMail *)message).PGPEncrypted];
//        [self setIsSigned:((Message_GPGMail *)message).PGPSigned];
//        [self setSigners:((Message_GPGMail *)message).PGPSignatures];
//        [self setSignerNames:[((Message_GPGMail *)message) PGPSignatureLabels]];
//        return;
//    }
    
//    [self MA_reloadSecurityProperties];
}

- (void)MASetWebDocument:(MUIWebDocument *)webDocument {
    [self MASetWebDocument:webDocument];
    if(!webDocument) {
        return;
    }
    // Bug #981: Prevent Mail from loading any remote content if a message is encrypted
    //
    // A maliciously crafted email could otherwise exploit an error in Apple's mime parser
    // to exfiltrate the decrypted content, by using a non-closed HTML tag (for example img)
    // which is started in one mime part and continued in a different one, with a PGP/MIME
    // tree in between.
    // Once each mime part is processed, the single parts are concatenated and the decrypted
    // contents sent to the URL given in the img tag.
    // For more details see https://efail.de
    //
    // Mail internally calls updateBlockRemoteContent, which should already make sure
    // that remote content is blocked if -[MCMessageBody isEncrypted] returns YES. While
    // that should be the case for PGP messages already, re-check here.
    //
    // == NOTE FOR FUTURE LUKAS ==
    // In High Sierra, even if -[MUIWebDocument setBlockRemoteContent:YES] is called,
    // and remote content is available, the "load remote content" banner or the message
    // that remote content is available is not always displayed. After countless hours
    // of debugging it turns out that, remote content is cached by Mail or a
    // com.apple.WebKit.WebContent process invoked by Mail to display the mail contents,
    // which results in the following problematic behavior:
    //
    // 1.) If remote content was loaded once (even if in a different message) and was
    //     cached, each message which contains the same remote content (for example image)
    //     will display the image, regardless of whether the users allow to display
    //     remote content or not.
    // 2.) If all remote content of a message has already been cached,
    //     -[MUIWebDocument hasBlockedRemoteContent] might return NO, even if the user chose
    //     to block remote content and remote content is available in the message.
    //     It might however also return YES, if the document was rendered in a different
    //     com.apple.WebKit.WebContent process than the one, responsible for loading the
    //     remote content at first try.
    // 3.) The banner alerting users of the existence of remote content in a message
    //     and asking them if they want to load the remote content, relies upon
    //     -[MUIWebDocument hasBlockedRemoteContent] and will thus sometimes be displayed
    //     and sometimes not, based on the cache status of the remote content to be displayed.
    //
    // So Lukas, no, you were not losing your mind, Apple simply tried to fuck with you.
    // Lucky for us, since we don't want the load remote content banner to be displayed
    // for encrypted messages at all, we don't have to care about its faulty behavior,
    // but simply make sure, it is not displayed for encrypted messages.
    GMMessageSecurityFeatures *securityFeatures = [(Message_GPGMail *)[MAIL_SELF originalMessage] securityFeatures];
    BOOL isPGPEncrypted = securityFeatures.PGPEncrypted || securityFeatures.PGPPartlyEncrypted;
    BOOL isEncrypted = [webDocument isEncrypted] || isPGPEncrypted;

    DebugLog(@"Is document encrypted?: %@", isEncrypted ? @"YES" : @"NO");
    if(isEncrypted) {
		/*if([webDocument respondsToSelector:@selector(setBlockRemoteContent:)]) {
			[webDocument setBlockRemoteContent:YES];
			// Apple's implementation allows the user to choose whether or not
			// they want to load the remote content. We won't allow that, unless
			// a specific default is set. In order for the "load remote content"
			// button not to be displayed, the -[MUIWebDocument hasBlockedRemoteContent]
			// property is set to NO.
			[webDocument setHasBlockedRemoteContent:NO];
		}
		else */if([webDocument respondsToSelector:@selector(setHasBlockedMessageContent:)]) {
            // From macOS Mojave 10.14.1b3, the Mail team has decided to rename these
            // methods, even though for now they are still doing the exact same thing...
            // Content-Type 1 means that the message contains encrypted content and should
            // thus make sure that no remote content is loaded.
            // Interestingly enough Content-Type 2 seems to block the message from loading at all. This one is going to be interesting.
            if(isPGPEncrypted) {
                DebugLog(@"Setting message content type to block to 1");
                [webDocument setMessageContentTypeToBlock:1];
                DebugLog(@"Setting setHasBlockedMessageContent to NO");
                [webDocument setHasBlockedMessageContent:NO];
            }
        }
    }
}

- (long long)MAMessageContentBlockingReason {
    // On 10.14.1 this method is checked in order to determine if
    // the user has actively decided to load remote content.
    // Since for encrypted messages GPG Mail doesn't allow that,
    // return 1.
    MUIWebDocument *webDocument = [MAIL_SELF webDocument];
    GMMessageSecurityFeatures *securityFeatures = [(Message_GPGMail *)[MAIL_SELF originalMessage] securityFeatures];
    BOOL isEncrypted = securityFeatures.PGPEncrypted || securityFeatures.PGPPartlyEncrypted;

    if(isEncrypted) {
        DebugLog(@"Message is encrypted - prevent remote content loading.");
        return 1;
    }

    DebugLog(@"Content blocking reason: %lld", [self MAMessageContentBlockingReason]);
    return [self MAMessageContentBlockingReason];
}

- (BOOL)MAHasBlockedMessageContent {
    // On 10.14.1 this method is checked in order to determine if
    // the load remote content banner should be displayed.
    // In case of an encrypted message, never display it.
    GMMessageSecurityFeatures *securityFeatures = [(Message_GPGMail *)[MAIL_SELF originalMessage] securityFeatures];
    BOOL isEncrypted = securityFeatures.PGPEncrypted || securityFeatures.PGPPartlyEncrypted;

    if(isEncrypted) {
        DebugLog(@"Message is encrypted - do not display the remote content loading button.");
        return NO;
    }

    return [self MAHasBlockedMessageContent];
}

- (long long)MARemoteContentBlockingReason {
    // On 10.13 this method is checked in order to determine if
    // the user has actively decided to load remote content.
    // Since for encrypted messages GPG Mail doesn't allow that,
    // return 1.
    MUIWebDocument *webDocument = [MAIL_SELF webDocument];
    GMMessageSecurityFeatures *securityFeatures = [(Message_GPGMail *)[MAIL_SELF originalMessage] securityFeatures];
    BOOL isEncrypted = [webDocument isEncrypted] || securityFeatures.PGPEncrypted || securityFeatures.PGPPartlyEncrypted;

    if(isEncrypted) {
        DebugLog(@"Message is encrypted - prevent remote content loading.");
        return 1;
    }

    // Bug #1040: Infinite loop.
    //
    // Called MAMessageContentBlockingReason before, which resulted in
    // and infinite loop.
    long long reason = [self MARemoteContentBlockingReason];
    DebugLog(@"Content blocking reason: %lld", reason);
    return reason;
}

- (BOOL)MAHasBlockedRemoteContent {
    // Bug #
    // On 10.13 this method is checked in order to determine if
    // the load remote content banner should be displayed.
    // In case of an encrypted message, never display it.
    GMMessageSecurityFeatures *securityFeatures = [(Message_GPGMail *)[MAIL_SELF originalMessage] securityFeatures];
    BOOL isEncrypted = securityFeatures.PGPEncrypted || securityFeatures.PGPPartlyEncrypted;

    if(isEncrypted) {
        DebugLog(@"Message is encrypted - do not display the remote content loading button.");
        return NO;
    }

    return [self MAHasBlockedRemoteContent];
}

@end

#undef MAIL_SELF

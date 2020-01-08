/* MailDocumentEditor+GPGMail.m re-created by Lukas Pitschl (@lukele) on Sat 27-Aug-2011 */

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

#import <Libmacgpg/Libmacgpg.h>
#import "NSObject+LPDynamicIvars.h"
#import <MFMailAccount.h>
#import <HeadersEditor.h>
#import "ComposeBackEnd.h"
//#import <MailDocumentEditor.h>
//#import <MailNotificationCenter.h>
#import "GMSecurityMethodAccessoryView.h"
#import "NSWindow+GPGMail.h"
#import "Message+GPGMail.h"
#import "HeadersEditor+GPGMail.h"
#import "MailDocumentEditor+GPGMail.h"
#import "ComposeBackEnd+GPGMail.h"
#import "GPGMailBundle.h"
//#import <MFError.h>
#import "ComposeWindowController+GPGMail.h"
#import "ComposeViewController.h"
#import "ComposeWindowController.h"
#import "GMMessageSecurityFeatures.h"

#import "GMComposeMessagePreferredSecurityProperties.h"

static const NSString *kUnencryptedReplyToEncryptedMessage = @"unencryptedReplyToEncryptedMessage";
extern const NSString *kComposeWindowControllerAllowWindowTearDown;

NSString * const kComposeViewControllerPreventAutoSave = @"ComposeViewControllerPreventAutoSave";

#define MAIL_SELF(object) ((ComposeViewController *)(object))

@implementation MailDocumentEditor_GPGMail

- (void)didExitFullScreen:(NSNotification *)notification {
    [self performSelectorOnMainThread:@selector(configureSecurityMethodAccessoryViewForNormalMode) withObject:nil waitUntilDone:NO];
}

- (void)configureSecurityMethodAccessoryViewForNormalMode {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return;
    }
	GMSecurityMethodAccessoryView *accessoryView = [self securityMethodAccessoryView]; //[self getIvar:@"SecurityMethodHintAccessoryView"];
    [accessoryView configureForWindow:[self valueForKey:@"_window"]];
}

- (void)setSecurityMethodAccessoryView:(GMSecurityMethodAccessoryView *)securityMethodAccessoryView {
	[self setIvar:@"SecurityMethodAccessoryView" value:securityMethodAccessoryView];
}

- (GMSecurityMethodAccessoryView *)securityMethodAccessoryView {
	return (GMSecurityMethodAccessoryView *)[(NSObject *)[MAIL_SELF(self) delegate] getIvar:@"SecurityMethodAccessoryView"];
}

- (void)updateSecurityMethodHighlight {
    [self updateSecurityMethodAccessoryView];
}

- (void)updateSecurityMethodAccessoryView {
    GMSecurityMethodAccessoryView *accessoryView = [self securityMethodAccessoryView];
    GMComposeMessagePreferredSecurityProperties *securityProperties = ((ComposeBackEnd_GPGMail *)MAIL_SELF(self).backEnd).preferredSecurityProperties;
    
    // Once the security method has been set by the user, it MUST never be changed.
    if(securityProperties.userDidChooseSecurityMethod != YES && accessoryView.previousSecurityMethod != securityProperties.securityMethod) {
        accessoryView.securityMethod = securityProperties.securityMethod;
    }
    accessoryView.active = securityProperties.shouldSignMessage || securityProperties.shouldEncryptMessage;
    
    // TODO: Re-implement the update of the from field somewhere else. The accessory view has nothing to do with it.
}

- (void)updateSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod {
    GMSecurityMethodAccessoryView *accessoryView = [self securityMethodAccessoryView];
    accessoryView.securityMethod = securityMethod;
}

- (void)MABackEndDidLoadInitialContent:(id)content {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MABackEndDidLoadInitialContent:content];
        return;
    }
	if(![GPGMailBundle isElCapitan]) {
		[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didExitFullScreen:) name:@"NSWindowDidExitFullScreenNotification" object:nil];
	}
	
	// Setup security method hint accessory view in top right corner of the window.
	[self setupSecurityMethodHintAccessoryView];

    ComposeBackEnd *backEnd = MAIL_SELF(self).backEnd;
    GPGMAIL_SECURITY_METHOD securityMethod = ((ComposeBackEnd_GPGMail *)MAIL_SELF(self).backEnd).preferredSecurityProperties.securityMethod;
    [self updateSecurityMethod:securityMethod];

    [self MABackEndDidLoadInitialContent:content];
}

// Bug #1058: Switcher for S/MIME | OpenPGP has no effect
//
// The switcher was not working properly as the delegate was never set.
- (void)MABackEndDidLoadInitialContent:(id)content mayUseDarkAppearance:(BOOL)mayUseDarkAppearance {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MABackEndDidLoadInitialContent:content mayUseDarkAppearance:mayUseDarkAppearance];
        return;
    }
    if(![GPGMailBundle isElCapitan]) {
        [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didExitFullScreen:) name:@"NSWindowDidExitFullScreenNotification" object:nil];
    }

    // Setup security method hint accessory view in top right corner of the window.
    [self setupSecurityMethodHintAccessoryView];

    ComposeBackEnd *backEnd = MAIL_SELF(self).backEnd;
    GPGMAIL_SECURITY_METHOD securityMethod = ((ComposeBackEnd_GPGMail *)MAIL_SELF(self).backEnd).preferredSecurityProperties.securityMethod;
    [self updateSecurityMethod:securityMethod];

    [self MABackEndDidLoadInitialContent:content mayUseDarkAppearance:mayUseDarkAppearance];
}

- (void)setupSecurityMethodHintAccessoryView {
	// On El Capitan there's no more space on top of the title bar, so
	// the security method accessory view is inserted as toolbar item in
	// -[ComposeViewController toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:]
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return;
    }
    GMSecurityMethodAccessoryView *accessoryView = nil;
	accessoryView = [self securityMethodAccessoryView];
	accessoryView.delegate = self;
}

- (void)hideSecurityMethodAccessoryView {
	GMSecurityMethodAccessoryView *accessoryView = [self securityMethodAccessoryView]; //[self getIvar:@"SecurityMethodHintAccessoryView"];
    accessoryView.hidden = YES;
}

- (void)securityMethodAccessoryView:(GMSecurityMethodAccessoryView *)accessoryView didChangeSecurityMethod:(GPGMAIL_SECURITY_METHOD)securityMethod {
    ComposeBackEnd *backEnd = MAIL_SELF(self).backEnd;
    ((ComposeBackEnd_GPGMail *)(MAIL_SELF(self)).backEnd).preferredSecurityProperties.securityMethod = securityMethod;
    [(HeadersEditor_GPGMail *)[MAIL_SELF(self) headersEditor] updateFromAndAddSecretKeysIfNecessary:@(securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP ? YES : NO)];
    [[MAIL_SELF(self) headersEditor] _updateSecurityControls];
}

- (void)MADealloc {
    // Sometimes this fails, so simply ignore it.
    @try {
		[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] removeObserver:self];
//        [(MailNotificationCenter *)[NSClassFromString(@"MailNotificationCenter") defaultCenter] removeObserver:self];
    }
    @catch(NSException *e) {
        
    }
	[self MADealloc];
}

- (BOOL)isUnencryptedReplyToEncryptedMessageWithChecklist:(NSMutableArray *)checklist {
	// While Mail.app internally removes objects from the checklist, we instead add one
	// if the user explicitly told us to continue with sending.
	// We have to handle it this way, since sendMessageAfterChecking is called for each failing
	// check and we can't determine which one is the first call, to correctly add our own item to the checklist,
	// and later remove it, when the check has cleared.
	// So instead we add an item.

	// If there is no checklist, we have nothing to check.
	// If we would still check, we head an infinite loop.
	if (!checklist) {
		return NO;
	}


	ComposeBackEnd *backEnd = (ComposeBackEnd *)[MAIL_SELF(self) backEnd];
	GMComposeMessagePreferredSecurityProperties *securityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];

	BOOL isReply = [(ComposeBackEnd_GPGMail *)backEnd messageIsBeingReplied];
	BOOL isForward = [(ComposeBackEnd_GPGMail *)backEnd messageIsBeingForwarded];
    BOOL originalMessageIsEncrypted = securityProperties.referenceMessageIsEncrypted;
    BOOL replyShouldBeEncrypted = securityProperties.shouldEncryptMessage;

    // If GPG Mail is installed but expired, the original Mail methods are called
    // to check for encryption keys, and thus securityProperties will not properly
    // the encryption status of the message. Instead use `-[HeadersEditor messageIsToBeEncrypted]`
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        replyShouldBeEncrypted = [[MAIL_SELF(self) headersEditor] messageIsToBeEncrypted];
    }

	// If checklist contains the unencryptedReplyToEncryptedMessage item, it means
	// that the user decided to send the message regardless of our warning.
	if((isReply || isForward) && originalMessageIsEncrypted && !replyShouldBeEncrypted && ![checklist containsObject:kUnencryptedReplyToEncryptedMessage]) {
		// Warn the user.
		return YES;
	}

	// Isn't a un-encrypted reply to an encrypted message or
	// the user decided to send the message regardless of our warning
	return NO;
}

- (void)displayWarningForUnencryptedReplyToEncryptedMessageUpdatingChecklist:(NSMutableArray *)checklist {
	NSArray *recipientsMissingCertificates = [(ComposeBackEnd *)[MAIL_SELF(self) backEnd] recipientsThatHaveNoKeyForEncryption];

    ComposeBackEnd *backEnd = (ComposeBackEnd *)[MAIL_SELF(self) backEnd];

    BOOL isForward = [(ComposeBackEnd_GPGMail *)backEnd messageIsBeingForwarded];

    NSString *typePrefix = isForward ? @"UNENCRYPTED_FORWARD_OF_" : @"UNENCRYPTED_REPLY_TO_";

	NSMutableString *recipientWarning = [NSMutableString new];
	for(NSString *recipient in recipientsMissingCertificates) {
		[recipientWarning appendFormat:@"- %@\n", recipient];
	}

    NSMutableString *explanation = [NSMutableString new];
	if([recipientsMissingCertificates count]) {
		NSString *missingKeysString = [GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_MISSING_KEYS", typePrefix]];
		if([recipientsMissingCertificates count] == 1)
			missingKeysString = [GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_MISSING_KEYS_SINGULAR", typePrefix]];
		[explanation appendFormat:@"%@\n", [NSString stringWithFormat:missingKeysString, recipientWarning]];
	}

	[explanation appendString:[GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_EXPLANATION", typePrefix]]];

	NSMutableString *solutionProposals = [NSMutableString new];
    if(!isForward) {
        [solutionProposals appendString:[GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_SOLUTION_REMOVE_PREVIOUS_CORRESPONDENCE", typePrefix]]];
    }
	if([recipientsMissingCertificates count]) {
		[solutionProposals appendString:@"\n"];
		if([recipientsMissingCertificates count] == 1)
			[solutionProposals appendString:[GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_SOLUTION_IMPORT_KEYS_SINGULAR", typePrefix]]];
		else
			[solutionProposals appendString:[GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_SOLUTION_IMPORT_KEYS", typePrefix]]];
	}
	[explanation appendString:solutionProposals];
	[explanation appendString:@"\n"];

	NSAlert *unencryptedReplyAlert = [NSAlert new];
	[unencryptedReplyAlert setMessageText:[GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_TITLE", typePrefix]]];
	[unencryptedReplyAlert setInformativeText:explanation];
	[unencryptedReplyAlert addButtonWithTitle:[GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_BUTTON_CANCEL", typePrefix]]];
	[unencryptedReplyAlert addButtonWithTitle:[GPGMailBundle localizedStringForKey:[NSString stringWithFormat:@"%@ENCRYPTED_MESSAGE_BUTTON_SEND_ANYWAY", typePrefix]]];
	[unencryptedReplyAlert setIcon:[NSImage imageNamed:@"GPGMail"]];

	// On Mavericks and later we can use, beginSheetModalForWindow:.
	// Before that, we have to use NSBeginAlertSheet.
    id __weak weakSelf = self;
    [unencryptedReplyAlert beginSheetModalForWindow:[[MAIL_SELF(self) view] window] completionHandler:^(NSModalResponse returnCode) {
        id __strong strongSelf = weakSelf;

        if(returnCode == NSAlertSecondButtonReturn) {
            // The user pressed send anyway, so add the kUnencryptedReplyToEncryptedMessage item
            // to the checklist, so the next time around sendMessageAfterChecking: is called,
            // we no longer check if the message is sent unencrypted.
            [checklist addObject:kUnencryptedReplyToEncryptedMessage];
            [strongSelf sendMessageAfterChecking:checklist];
        }
    }];
}

- (void)warnAboutUnecryptedReplySheetClosed:(NSWindow *)sheet returnCode:(long long)returnCode contextInfo:(void *)contextInfo {
	NSDictionary *_contextInfo = (__bridge_transfer NSDictionary *)contextInfo;
	if(returnCode == NSAlertAlternateReturn) {
		NSMutableArray *checklist = _contextInfo[@"ThingsToCheck"];
		[checklist addObject:kUnencryptedReplyToEncryptedMessage];
		[MAIL_SELF(self) sendMessageAfterChecking:checklist];
	}
}


- (void)MASendMessageAfterChecking:(NSMutableArray *)checklist {
	// If this is an unencrypted reply to an encrypted message, display a warning
    // to the user and simply return. The message won't be sent until the checklist is cleared.
	// Otherwise call sendMessageAfterChecking so that Mail.app can perform its internal checks.
    // TODO: Fix for Sierra.
    if([self isUnencryptedReplyToEncryptedMessageWithChecklist:checklist]) {
		[self displayWarningForUnencryptedReplyToEncryptedMessageUpdatingChecklist:checklist];
        return;
    }

	[self MASendMessageAfterChecking:checklist];
}

- (BOOL)backEnd:(id __unused)backEnd handleDeliveryError:(NSError *)error {
	
	NSNumber *errorCode = ((NSDictionary *)error.userInfo)[@"GPGErrorCode"];
	// If the pinentry dialog was cancelled, there's no need to show any error.
	// Simply let the user continue editing.
	if(errorCode && [errorCode integerValue] == GPGErrorCancelled) {
		return NO;
	}
	
	return YES;
}

- (void)MABackEnd:(id)backEnd didCancelMessageDeliveryForEncryptionError:(NSError *)error {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MABackEnd:backEnd didCancelMessageDeliveryForEncryptionError:error];
        return;
    }
	if([self backEnd:backEnd handleDeliveryError:error])
		[self MABackEnd:backEnd didCancelMessageDeliveryForEncryptionError:error];
    else {
        [MAIL_SELF(self) show];
    }
}

- (void)MABackEnd:(id)backEnd didCancelMessageDeliveryForError:(NSError *)error {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MABackEnd:backEnd didCancelMessageDeliveryForError:error];
        return;
    }
	if([self backEnd:backEnd handleDeliveryError:error])
		[self MABackEnd:backEnd didCancelMessageDeliveryForEncryptionError:error];
    else {
        [MAIL_SELF(self) show];
    }
}

- (void)MABackEndDidAppendMessageToOutbox:(id)backEnd result:(long long)result {
    [self MABackEndDidAppendMessageToOutbox:backEnd result:result];

    // A result code other than 3 signals an error.
    if(result != 3) {
        return;
    }

    // Bug #998: Canceling a pinentry request might result in losing a message
    //
    // As described in the `-[ComposeWindowController composeViewControllerDidSend:` method
    // the tear down of the compose view controller might have been postponed, to properly recover
    // from errors that occur during sending. At this point the compose view controller
    // can savely be torn down.
    // `-[ComposeViewController forceClose]` needs to be called on the main thread.
    // This is already guaranteed, since this method is always called on the main thread.
    [MAIL_SELF(self) forceClose];
}

// Bug #998: Canceling a pinentry request might result in losing a message
//
// See `-[ComposeWindowController composeViewControllerDidSend:]` for further details.
//
// The tear down of the compose view controller is to be postponed, if the message
// is either being encrypted or signed.
//
// Apple's S/MIME implementation suffers from the same bug as well,
// this workaround will fix it for S/MIME as well.
- (BOOL)GMShouldPostponeTearDown {
    GMComposeMessagePreferredSecurityProperties *securityProperties = ((ComposeBackEnd_GPGMail *)[MAIL_SELF(self) backEnd]).preferredSecurityProperties;
    return securityProperties.shouldEncryptMessage || securityProperties.shouldSignMessage;
}

#pragma mark - Bug #1031

// Bug #1031: If a message fails to send, it might be replaced by its draft version prior
//              to being sent at a later time.
//
//
// Fixes also: #933
//
// Once a user presses the send button, the final message is created and placed in the
// "Outbox" folder. If for some reason sending the message fails however – most likely
// due to a failure to connect to the SMTP server – this final message might have been
// replaced by its latest draft version, since the auto-save timer is still running
// and overwriting the message in "Outbox".
// If the user then chooses to "Send later", the draft version of the message is sent out
// at a later time and based on the status of "Encrypt drafts" that version might either
// be encrypted to sender's public key *but not* the recipient's public key or sent in plain.
//
// In order to prevent Mail from replacing the final message, the auto-save method
// is suspended until the user changes the message, which indicates that they chose
// to continue editing the message instead of sending it later automatically.
//
// -[ComposeViewController hasUserMadeChanges] returns if the user made any changes to the message.
//
// -[ComposeViewController setIsBeingPreparedForSending:] is invoked from -[ComposeViewController sendMessageAfterChecking:] after the user presses the send button. Within
// this method a flag is set, that auto-save is no longer allowed to operate.
//
// -[ComposeViewController saveDocument:] is invoked by the auto-save timer. It checks the flag
// if it is ok to save a draft version which is determined by the fact if a message is about to be sent and `-[ComposeViewController hasUserMadeChanges]`
//
// -[ComposeViewController setUserHasMadChanges:] is invoked whenever the user modifies the message.
// If the prevent-auto-save-flag is set, it is removed to make sure that subsequent
// auto-saves are allowed to go through.

- (void)MASetIsBeingPreparedForSending:(BOOL)isBeingPreparedForSending {
    [self MASetIsBeingPreparedForSending:isBeingPreparedForSending];
    // This method is always invoked on the main thread so it is save
    // to set the flag here.
    [self setIvar:kComposeViewControllerPreventAutoSave value:@(YES)];
}

- (void)MASetHasUserMadeChanges:(BOOL)hasUserMadeChanges {
    if([self ivarExists:kComposeViewControllerPreventAutoSave]) {
        [self removeIvar:kComposeViewControllerPreventAutoSave];
    }
    [self MASetHasUserMadeChanges:hasUserMadeChanges];
}

- (void)MASaveDocument:(id)document {
    // If auto-save should be prevented, make sure that there are no user made changes.
    //
    // NOTE: If an error occurs during sending, a new compose view controller
    // is created, so it appears that preventing saving a draft if `hasUserMadeChanges`
    // is still false might be enough to keep the message to be sent from being replaced.
    // But it's probably still safer to track the status via the prevent-auto-save-flag.
    if([[self getIvar:kComposeViewControllerPreventAutoSave] boolValue] && ![MAIL_SELF(self) hasUserMadeChanges]) {
        return;
    }
    [self MASaveDocument:document];
}

#pragma mark

#pragma mark - Bug #976

- (void)MASetRepresentedObject:(id __unused)representedObject {
    [self MASetRepresentedObject:representedObject];

    // The security properties of the compose backed are updated with the
    // information about the message being edited, as that might influence the decision
    // on what security method to use, and the status of the security buttons.
    GMComposeMessagePreferredSecurityProperties *preferredSecurityProperties = [(ComposeBackEnd_GPGMail *)[MAIL_SELF(self) backEnd] preferredSecurityProperties];
    [preferredSecurityProperties updateWithHintsFromComposeBackEnd:[MAIL_SELF(self) backEnd]];
}

#pragma mark

@end

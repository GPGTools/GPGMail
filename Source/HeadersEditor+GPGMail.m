/* HeadersEditor+GPGMail.m re-created by Lukas Pitschl (@lukele) on Wed 25-Aug-2011 */

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
#import "CCLog.h"
#import "MFMailAccount.h"
//#import "AddressAttachment.h"
//#import <MailDocumentEditor.h>
//#import "MailNotificationCenter.h"
#import "Message+GPGMail.h"
#import "MailDocumentEditor+GPGMail.h"
#import "HeadersEditor.h"
//#import "ComposeHeaderView.h"
#import "HeadersEditor+GPGMail.h"
#import "ComposeBackEnd.h"
#import "ComposeBackEnd+GPGMail.h"
#import "GPGMailBundle.h"
#import "NSString+GPGMail.h"
#import "GMSecurityControl.h"
#import "NSObject+LPDynamicIvars.h"
//#import <NSString-EmailAddressString.h>
#import "GMComposeKeyEventHandler.h"
//#import "OptionalView.h"
#import "GMSecurityHistory.h"
#import "MUITokenAddress.h"
#import "MUIAddressTokenAttachmentCell.h"
#import "ComposeViewController.h"
#import "MailApp.h"

#import "GMComposeMessagePreferredSecurityProperties.h"

#define mailself ((HeadersEditor *)self)
#define tomailself(obj) ((HeadersEditor *)obj)

@interface HeadersEditor_GPGMail (NoImplementation)
- (void)changeFromHeader:(NSPopUpButton *)sender;
@end

const NSString *kHeadersEditorFromControlGPGKeyKey = @"HeadersEditorFromControlGPGKey";
const NSString *kHeadersEditorFromControlParentItemKey = @"HeadersEditorFromControlParentItem";

@implementation HeadersEditor_GPGMail

- (void)MAAwakeFromNib {
    [self MAAwakeFromNib];

    // Setup additional HeadersEditor components, like accessibility for sign and lock items,
    // keyboard shortcuts for sign and lock items and listening to keychain changes.
    [self GMSetup];
}

- (void)GMSetup {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return;
    }
    if([self getIvar:@"HeadersEditorIsSetup"]) {
        return;
    }
    [self setIvar:@"HeadersEditorIsSetup" value:@(YES)];

    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyringUpdated:) name:GPGMailKeyringUpdatedNotification object:nil];
    
    // VoiceOver uses the accessibilityDescription of NSImage for the encrypt and sign buttons, if there is no other text for accessibility.
    // The lock-images have a default of "lock" and "unlocked lock". (NSLockLockedTemplate and NSLockUnlockedTemplate)
    NSImage *signOnImage = [NSImage imageNamed:@"SignatureOnTemplate"];
    if (signOnImage) {
        [signOnImage setAccessibilityDescription:[GPGMailBundle localizedStringForKey:@"ACCESSIBILITY_SIGN_ON_IMAGE"]];
    }
    NSImage *signOffImage = [NSImage imageNamed:@"SignatureOffTemplate"];
    if (signOffImage) {
        [signOffImage setAccessibilityDescription:[GPGMailBundle localizedStringForKey:@"ACCESSIBILITY_SIGN_OFF_IMAGE"]];
    }
    
    // Configure setting the tool tip by unbinding the controls toolTip.
    // We will update it, after _updateSecurityStateInBackground is run.
    [[mailself signButton] unbind:@"toolTip"];
    [[mailself encryptButton] unbind:@"toolTip"];

    NSView *optionalView = (NSView *)[[self valueForKey:@"_signButton"] superview];
    GMComposeKeyEventHandler *handler = [[GMComposeKeyEventHandler alloc] initWithView:optionalView];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
    handler.eventsAndSelectors = [NSArray arrayWithObjects:
                                  @{@"keyEquivalent": @"y", @"keyEquivalentModifierMask": @(NSCommandKeyMask | NSAlternateKeyMask), @"target": [mailself signButton], @"selector": [NSValue valueWithPointer:@selector(performClick:)]},
                                  @{@"keyEquivalent": @"x", @"keyEquivalentModifierMask": @(NSCommandKeyMask | NSAlternateKeyMask), @"target": [mailself encryptButton], @"selector": [NSValue valueWithPointer:@selector(performClick:)]},
                                  nil];
#pragma clang diagnostic pop
}

- (void)MA_updateFromControl {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MA_updateFromControl];
        return;
    }
    // _updateFromAndSignatureControls: was renamed to to updateFromControl on Yosemite.
    // Unfortunately updateFromControl doesn't take any arguments, which means,
    // that we have to define a new method to hook into it.
    // This method has to be run on the mainthread.
    if(![NSThread mainThread])
        [self performSelectorOnMainThread:@selector(_updateFromControl) withObject:nil waitUntilDone:NO];
    
    [self MA_updateFromControl];
    [self setupFromControlCrossVersion];
}

- (void)setupFromControlCrossVersion {
    // Adjusted to work on Yosemite as well.
    
    // Thanks to Hopper (YES, it's fantastic) it's now clear that
    // _updateFromAndSignatureControls calls setAccountFieldEnabled|Visible
    // and configureAccountPopUpSize on the ComposeHeaderView.
    
    // If there's only one account setup, Mail.app chooses to not to display
    // the "From:" field. That's alright, unless there are multiple secret keys
    // available for the same account. In such a case, GPGMail will fill the
    // popup and force it to be displayed, so that the user can choose which
    // secret key to use.
    NSPopUpButton *fromPopup = [self fromPopup];
    if([[fromPopup itemArray] count] == 1 &&
       ![[[fromPopup itemArray] objectAtIndex:0] attributedTitle]) {
        [self fixEmptyAccountPopUpIfNecessary];
    }
    else {
        [(HeadersEditor *)self _setVisibilityForFromView:YES];
    }
    
    // If any luck, the security option should be known by now.
    // It's not, but it still works as assumed.
    ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    // Make sure that default method is considered, if none is set.
    
    GPGMAIL_SECURITY_METHOD currentSecurityMethod = !((ComposeBackEnd_GPGMail *)backEnd).preferredSecurityProperties ? [GMComposeMessagePreferredSecurityProperties defaultSecurityMethod] : ((ComposeBackEnd_GPGMail *)backEnd).preferredSecurityProperties.securityMethod;
    BOOL addSecretKeys = currentSecurityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP;
    [self updateFromAndAddSecretKeysIfNecessary:@(addSecretKeys)];
}

- (void)fixEmptyAccountPopUpIfNecessary {
    // 1. Find the accounts to be displayed.
    // TODO: Find out what replaces this in sierra
    NSArray *accounts = (NSArray *)[MFMailAccount allEmailAddressesIncludingDisplayName:YES];
    // There should only be on account available, otherwise we wouldn't be here.
	NSString *onlyAccount = [[accounts objectAtIndex:0] gpgNormalizedEmail];
	BOOL multipleKeysAvailable = [[[GPGMailBundle sharedInstance] signingKeyListForAddress:onlyAccount] count] > 1;
	
	if(!multipleKeysAvailable)
		return;
	
	Class AddressAttachmentClass = NSClassFromString(@"MUIAddressTokenAttachmentCell");
	
    NSPopUpButton *fromPopup = [self fromPopup];
    // 3. Construct the style of the menu.
    NSFont *font = [NSFont menuFontOfSize:[[(NSPopUpButtonCell *)[fromPopup cell] font] pointSize]];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *externalAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
										[AddressAttachmentClass colorForExternalDomain], NSForegroundColorAttributeName,
                                        font, NSFontAttributeName, nil];
    NSDictionary *normalAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName,
									  paragraphStyle, NSParagraphStyleAttributeName, nil];
    [fromPopup removeAllItems];
    [fromPopup addItemsWithTitles:accounts];
    if([accounts count]) {
        NSUInteger i = 0;
        for(id account in accounts) {
            NSDictionary *attributes = normalAttributes;
            if([NSClassFromString(@"MUITokenAddress") addressIsExternal:account])
                attributes = externalAttributes;
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:account attributes:attributes];
            [[fromPopup itemAtIndex:i] setAttributedTitle:title];
			[[fromPopup itemAtIndex:i] setRepresentedObject:account];
            i++;
        }
    }
    
    // Set the field visible so the layout will be adjusted accordingly.
    if(multipleKeysAvailable) {
        [self _setVisibilityForFromView:YES];
	}
}

- (void)MAUpdateSecurityControls {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MAUpdateSecurityControls];
        return;
    }
	// New Sierra way to do this.
    ComposeBackEnd *backEnd = [[mailself composeViewController] backEnd];

    __weak HeadersEditor_GPGMail *weakSelf = self;
    
    [backEnd updateSMIMEStatus:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            __strong HeadersEditor_GPGMail *strongSelf = weakSelf;
            BOOL canSign = [backEnd canSign];
            // Apple only sets canEncrypt if canSign is YES, since S/MIME requires a valid signature certificate
            // in order to perform encryptions. In OpenPGP we allow encryption, even if no key to sign a message
            // is available, so canEncrypt will also be set.
            BOOL canEncrypt = [backEnd canEncrypt];
            
            // Bug #957: Adapt GPGMail to the S/MIME changes introduced in Mail for 10.13.2b3
            //
            // Apple Mail team has added a possibility to display errors, if macOS fails to read
            // a signing identity.
            NSError *invalidSigningIdentityError = nil;
            if([backEnd respondsToSelector:@selector(invalidSigningIdentityError)]) {
                invalidSigningIdentityError = [backEnd invalidSigningIdentityError];
            }

            // Apple only shows the buttons to toggle sign and encrypt if signing is possible.
            // OpenPGP does work if only sign or encrypt is available, so we'll also show the buttons
            // if sign is not is possible, but only encrypt.
            // We always show the buttons since that is a much better user experience.
            GMComposeMessagePreferredSecurityProperties *preferredSecurityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
            // Bug #1060: Display error tooltip if no signing key is available
            //
            // Always show the security buttons if the current security method is OpenPGP to show
            // better tool tips.
            if(preferredSecurityProperties.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
                [tomailself(strongSelf) _setVisibilityForEncryptionAndSigning:YES];
            }
            else {
                [tomailself(strongSelf) _setVisibilityForEncryptionAndSigning:(canSign || invalidSigningIdentityError != nil) || canEncrypt];
            }

            if([tomailself(strongSelf) respondsToSelector:@selector(setSignButtonEnabled:)]) {
                [tomailself(strongSelf) setSignButtonEnabled:(canSign || invalidSigningIdentityError != nil)];
                [tomailself(strongSelf) setEncryptButtonEnabled:canEncrypt];
                if(invalidSigningIdentityError != nil) {
                    // Bug #1047: GPG Mail crashes if an expired S/MIME certificate is installed
                    //
                    // Due to a misinterpretation of the disassembly, previously
                    // `-[NSSegmentedController setSelectedSegment:]` was called with NSNotFound,
                    // which as result triggers an assertion and crashes Mail.
                    //
                    // The disassembly shows that the right value to use is -1 instead.
                    // Note: -[NSSegmentedController setSelectedSegment:] seems to be private API
                    //       so it's not documented what passing -1 does exactly.
                    [[tomailself(strongSelf) signButton] setSelectedSegment:-1];
                }
            }
            /*
            else {
                [tomailself(strongSelf) setCanSign:canSign];
                [tomailself(strongSelf) setCanEncrypt:canEncrypt];
            }
            */
            
            // For reference, the original Apple code follows below.
            // Apple uses standard defaults to remember the last set status of sign and encrypt.
            // GPGMail however determines this status based on user preference.
            //
            // Apple Code:
            // MailApp *app = [[GPGMailBundle resolveMailClassFromName:@"MailApp"] sharedApplication];
            // BOOL signIfPossible = canSign ? [app signOutgoingMessages] : NO;
            // BOOL encryptIfPossible = canEncrypt ? [app encryptOutgoingMessages] : NO;
            //
            // GPGMail Code:

            BOOL signIfPossible = preferredSecurityProperties.shouldSignMessage;
            BOOL encryptIfPossible = preferredSecurityProperties.shouldEncryptMessage;
            
            [tomailself(strongSelf) setMessageIsToBeSigned:signIfPossible];
            [backEnd setSignIfPossible:signIfPossible];
            [tomailself(strongSelf) setMessageIsToBeEncrypted:encryptIfPossible];
            [backEnd setEncryptIfPossible:encryptIfPossible];
            // Currently a no-op in Mail, for whatever reason.
            [[tomailself(strongSelf) composeViewController] encryptionStatusDidChange];
            [strongSelf updateSecurityControlToolTips];
            // Last but not least, update the security accessory view.
            [(MailDocumentEditor_GPGMail *)[tomailself(strongSelf) composeViewController] updateSecurityMethodAccessoryView];
        }];
    }];
    
    return;
}

- (void)MASecurityControlChanged:(NSControl *)securityControl {
    // 0x3e8 = 1000 = encrypt button
    // 0x7d0 = 2000 = sign button
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MASecurityControlChanged:securityControl];
        return;
    }
    if([securityControl tag] == 2000) {
        // Toggle the current status.
        BOOL messageIsToBeSigned = ![mailself messageIsToBeSigned];
        ComposeViewController *composeViewController = [self composeViewController];
        ComposeBackEnd *backEnd = [composeViewController backEnd];
        [backEnd setSignIfPossible:messageIsToBeSigned];
        // Update the preferred security properties to reflect the user choice.
        // From this point on, the computed shouldEncryptMessage method, will always return the
        // value set for userShouldSignMessage.
        // Apple uses NSUserDefaults here instead, but that is not good enough for us.
        GMComposeMessagePreferredSecurityProperties *preferredSecurityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
        preferredSecurityProperties.userShouldSignMessage = messageIsToBeSigned;
        [mailself setMessageIsToBeSigned:messageIsToBeSigned];
        [self updateSecurityControlToolTips];
        [(MailDocumentEditor_GPGMail *)composeViewController updateSecurityMethodAccessoryView];
        [composeViewController updateAttachmentStatus];
    }
    else {
        [self performSelectorInBackground:@selector(_toggleEncryption) withObject:nil];
    }
}

- (void)MA_toggleEncryption {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MA_toggleEncryption];
        return;
    }
    ComposeViewController *composeViewController = [self composeViewController];
    ComposeBackEnd *backEnd = [composeViewController backEnd];
    // This is implemented in Mail as:
    // mov        rsi, qword [ds:0x1004b22c0]                 ; @selector(messageIsToBeEncrypted), argument "selector" for method _objc_msgSend
    // mov        rdi, r12                                    ; argument "instance" for method _objc_msgSend
    // call       r13                                         ; _objc_msgSend
    // xor        ebx, ebx
    // test       al, al
    // sete       r15b
    //
    // Which in pseudo code reads:
    // rax = [r12 messageIsToBeEncrypted];
    // LODWORD(rbx) = 0x0;
    // LOBYTE(r15) = COND_BYTE_SET(E);
    //
    // And seems to simply do the following:
    BOOL messageIsToBeEncrypted = ![mailself messageIsToBeEncrypted];
    NSArray *recipientsWithNoKey = nil;
    
    if(messageIsToBeEncrypted) {
        recipientsWithNoKey = [backEnd recipientsThatHaveNoKeyForEncryption];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        // arg0 + 0x28 = composeViewController
        // arg0 + 0x20 = recipientsWithNoKey
        // arg0 + 0x30 = self
        // What is arg0 + 0x38? assuming it's r15 for now. Question is, is this value ever YES?
        if(messageIsToBeEncrypted == YES && [recipientsWithNoKey count]) {
            NSString *missingCertificatesErrorMessage = [composeViewController missingCertificatesMessageForRecipients:recipientsWithNoKey uponDelivery:NO];
            if(missingCertificatesErrorMessage) {
                NSAlert *missingCertificatesAlert = [NSAlert new];
                // TODO: Find out what _MFStringKeyErrorTitle resolves to.
                NSString *alertTitle = [[NSClassFromString(@"MailFramework") bundle] localizedStringForKey:@"MFStringKeyErrorTitle" value:@"" table:@"MailFramework"];
                [missingCertificatesAlert setMessageText:alertTitle];
                [missingCertificatesAlert setInformativeText:missingCertificatesErrorMessage];
                [missingCertificatesAlert beginSheetModalForWindow:[[composeViewController view] window] completionHandler:^(__unused NSModalResponse returnCode) {
                    [mailself setMessageIsToBeEncrypted:NO];
                }];
            }
            else {
                [backEnd setEncryptIfPossible:messageIsToBeEncrypted];
                // Update the preferred security properties to reflect the user choice.
                // From this point on, the computed shouldEncryptMessage method, will always return the
                // value set for userShouldSignMessage.
                // Apple uses NSUserDefaults here instead, but that is not good enough for us.
                GMComposeMessagePreferredSecurityProperties *preferredSecurityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
                preferredSecurityProperties.userShouldEncryptMessage = messageIsToBeEncrypted;
                [mailself setMessageIsToBeEncrypted:messageIsToBeEncrypted];
            }
        }
        else {
            [backEnd setEncryptIfPossible:messageIsToBeEncrypted];
            // Update the preferred security properties to reflect the user choice.
            // From this point on, the computed shouldEncryptMessage method, will always return the
            // value set for userShouldSignMessage.
            // Apple uses NSUserDefaults here instead, but that is not good enough for us.
            GMComposeMessagePreferredSecurityProperties *preferredSecurityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
            preferredSecurityProperties.userShouldEncryptMessage = messageIsToBeEncrypted;
            [mailself setMessageIsToBeEncrypted:messageIsToBeEncrypted];
        }
        [(MailDocumentEditor_GPGMail *)composeViewController updateSecurityMethodAccessoryView];
        [self updateToolTipForSecurityControl:[mailself encryptButton]];
        [composeViewController updateAttachmentStatus];
        
//        r14 = arg0;
//        if ((*(int8_t *)(r14 + 0x38) != 0x0) && ([*(r14 + 0x20) count] != 0x0)) {
//            rax = [*(r14 + 0x28) missingCertificatesMessageForRecipients:*(r14 + 0x20) uponDelivery:0x0];
//            rax = [rax retain];
//            if (rax != 0x0) {
//                var_58 = rax;
//                var_68 = [NSAlert new];
//                r15 = _objc_msgSend;
//                r12 = [[MailFramework bundle] retain];
//                
//                r13 = [[r12 localizedStringForKey:*_MFStringKeyErrorTitle value:@"" table:@"MailFramework"] retain];
//                rax = [var_68 setMessageText:r13];
//                r15 = _objc_release;
//                rax = [r13 release];
//                rax = [r12 release];
//                r15 = r14 + 0x28;
//                rax = [var_68 setInformativeText:var_58];
//                r13 = _objc_msgSend;
//                r12 = [[*(r14 + 0x28) view] retain];
//                r13 = [[r12 window] retain];
//                var_48 = 0xc2000000;
//                var_44 = 0x0;
//                var_40 = sub_1001938ef;
//                var_38 = 0x1003e4cc0;
//                var_30 = [*(r14 + 0x30) retain];
//                rax = [var_68 beginSheetModalForWindow:r13 completionHandler:__NSConcreteStackBlock];
//                rbx = _objc_release;
//                rax = [r13 release];
//                rax = [r12 release];
//                rax = [var_30 release];
//                rax = [var_68 release];
//                rax = [var_58 release];
//            }
//            else {
//                r15 = r14 + 0x28;
//                r12 = _objc_msgSend;
//                rbx = [[*(r14 + 0x28) backEnd] retain];
//                rax = [rbx setEncryptIfPossible:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//                r13 = _objc_release;
//                rax = [rbx release];
//                rbx = [[MailApp sharedApplication] retain];
//                rax = [rbx setEncryptOutgoingMessages:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//                rax = [rbx release];
//                rax = [*(r14 + 0x30) setMessageIsToBeEncrypted:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//            }
//        }
//        else {
//            r15 = r14 + 0x28;
//            r12 = _objc_msgSend;
//            rbx = [[*(r14 + 0x28) backEnd] retain];
//            rax = [rbx setEncryptIfPossible:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//            r13 = _objc_release;
//            rax = [rbx release];
//            rbx = [[MailApp sharedApplication] retain];
//            rax = [rbx setEncryptOutgoingMessages:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//            rax = [rbx release];
//            rax = [*(r14 + 0x30) setMessageIsToBeEncrypted:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//        }
//        rax = [*r15 updateAttachmentStatus];
//        rbx = stack[2042];
//        r12 = stack[2043];
//        r13 = stack[2044];
//        r14 = stack[2045];
//        r15 = stack[2046];
//        rsp = rsp + 0x78;
//        rbp = stack[2047];
//        return;
    }];
    
//    r12 = self;
//    r13 = _objc_msgSend;
//    r14 = [[self composeViewController] retain];
//    rbx = 0x0;
//    r15 = COND_BYTE_SET(E);
//    if ([r12 messageIsToBeEncrypted] == 0x0) {
//        r13 = _objc_msgSend;
//        var_70 = r15;
//        r15 = [[r14 backEnd] retain];
//        rbx = [[r15 recipientsThatHaveNoKeyForEncryption] retain];
//        rdi = r15;
//        r15 = var_70;
//        [rdi release];
//    }
//    r13 = [(r13)(@class(NSOperationQueue), @selector(mainQueue)) retain];
//    var_48 = rbx;
//    var_70 = [rbx retain];
//    var_40 = r14;
//    r14 = [r14 retain];
//    var_38 = [r12 retain];
//    [r13 addOperationWithBlock:^{
//        r14 = arg0;
//        if ((*(int8_t *)(r14 + 0x38) != 0x0) && ([*(r14 + 0x20) count] != 0x0)) {
//            rax = [*(r14 + 0x28) missingCertificatesMessageForRecipients:*(r14 + 0x20) uponDelivery:0x0];
//            rax = [rax retain];
//            if (rax != 0x0) {
//                var_58 = rax;
//                var_68 = [NSAlert new];
//                r15 = _objc_msgSend;
//                r12 = [[MailFramework bundle] retain];
//                r13 = [[r12 localizedStringForKey:*_MFStringKeyErrorTitle value:@"" table:@"MailFramework"] retain];
//                rax = [var_68 setMessageText:r13];
//                r15 = _objc_release;
//                rax = [r13 release];
//                rax = [r12 release];
//                r15 = r14 + 0x28;
//                rax = [var_68 setInformativeText:var_58];
//                r13 = _objc_msgSend;
//                r12 = [[*(r14 + 0x28) view] retain];
//                r13 = [[r12 window] retain];
//                var_48 = 0xc2000000;
//                var_44 = 0x0;
//                var_40 = sub_1001938ef;
//                var_38 = 0x1003e4cc0;
//                var_30 = [*(r14 + 0x30) retain];
//                rax = [var_68 beginSheetModalForWindow:r13 completionHandler:__NSConcreteStackBlock];
//                rbx = _objc_release;
//                rax = [r13 release];
//                rax = [r12 release];
//                rax = [var_30 release];
//                rax = [var_68 release];
//                rax = [var_58 release];
//            }
//            else {
//                r15 = r14 + 0x28;
//                r12 = _objc_msgSend;
//                rbx = [[*(r14 + 0x28) backEnd] retain];
//                rax = [rbx setEncryptIfPossible:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//                r13 = _objc_release;
//                rax = [rbx release];
//                rbx = [[MailApp sharedApplication] retain];
//                rax = [rbx setEncryptOutgoingMessages:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//                rax = [rbx release];
//                rax = [*(r14 + 0x30) setMessageIsToBeEncrypted:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//            }
//        }
//        else {
//            r15 = r14 + 0x28;
//            r12 = _objc_msgSend;
//            rbx = [[*(r14 + 0x28) backEnd] retain];
//            rax = [rbx setEncryptIfPossible:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//            r13 = _objc_release;
//            rax = [rbx release];
//            rbx = [[MailApp sharedApplication] retain];
//            rax = [rbx setEncryptOutgoingMessages:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//            rax = [rbx release];
//            rax = [*(r14 + 0x30) setMessageIsToBeEncrypted:sign_extend_64(*(int8_t *)(r14 + 0x38))];
//        }
//        rax = [*r15 updateAttachmentStatus];
//        rbx = stack[2042];
//        r12 = stack[2043];
//        r13 = stack[2044];
//        r14 = stack[2045];
//        r15 = stack[2046];
//        rsp = rsp + 0x78;
//        rbp = stack[2047];
//        return;
//    }];
//    [r13 release];
//    [var_38 release];
//    [var_40 release];
//    [var_48 release];
//    [r14 release];
//    [var_70 release];
//    return;
}

- (void)updateFromAndAddSecretKeysIfNecessary:(NSNumber *)necessary {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return;
    }
    BOOL display = [necessary boolValue];
    NSPopUpButton *popUp = nil;
    popUp = [self fromPopup];
    
	NSMenu *menu = [popUp menu];
	NSArray *menuItems = [menu itemArray];
	GPGMailBundle *bundle = [GPGMailBundle sharedInstance];
	
    // Is used to properly truncate our own menu items.
    NSMutableParagraphStyle *truncateStyle = [[NSMutableParagraphStyle alloc] init];
    [truncateStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes addEntriesFromDictionary:[[menuItems[0] attributedTitle] fontAttributesInRange:NSMakeRange(0, [[menuItems[0] attributedTitle] length])]];
	attributes[NSParagraphStyleAttributeName] = truncateStyle;
    
	// Also use the proper styling for external addresses.
    NSPopUpButton *fromPopup = ![GPGMailBundle isYosemite] ? [self valueForKey:@"_fromPopup"] : [self fromPopup];
    NSFont *font = [NSFont menuFontOfSize:[[(NSPopUpButtonCell *)[fromPopup cell] font] pointSize]];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *externalAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
										[NSClassFromString(@"MUIAddressTokenAttachmentCell") colorForExternalDomain], NSForegroundColorAttributeName,
                                        font, NSFontAttributeName, nil];
	
	
	NSMenuItem *item, *parentItem, *selectedItem = [popUp selectedItem], *subItemToSelect = nil;
    GMComposeMessagePreferredSecurityProperties *securityProperties = [(ComposeBackEnd_GPGMail *)[[mailself composeViewController] backEnd] preferredSecurityProperties];

    GPGKey *defaultKey = [bundle preferredGPGKeyForSigning];
    // If this is a draft being continued, the GPG key to use is
    // recorded in the draft's headers.
    if([securityProperties signingKey]) {
        defaultKey = [securityProperties signingKey];
    }
	BOOL useTitleFromAccount = [[GPGOptions sharedOptions] boolForKey:@"ShowAccountNameForKeysOfSameAddress"];
	
	// If menu items are not yet set, simply exit.
    // This might happen if securityMethodDidChange notification
    // is posted before the menu items have been configured.
    if(!menuItems.count || (menuItems.count == 1 && ![(NSMenuItem *)[menuItems objectAtIndex:0] representedObject]))
        return;
    
	menu.autoenablesItems = NO;
	
	NSUInteger count = [menuItems count], i = 0;
	NSDictionary *currentAttributes = attributes;
	
	for (; i < count; i++) {
		item = menuItems[i];
		parentItem = [item getIvar:kHeadersEditorFromControlParentItemKey];
		if (parentItem) {
			[menu removeItem:item]; // We remove all elements that represent a key.
		} else if (display) {
            NSString *itemTitle = item.title;
			
			NSString *email = nil;
			if (useTitleFromAccount == NO)
                email = ![GPGMailBundle isYosemite] ? [itemTitle gpgNormalizedEmail] : [item.representedObject gpgNormalizedEmail];
			
            NSString *address = [item.representedObject gpgNormalizedEmail];
            NSSet *keys = [bundle signingKeyListForAddress:address];
			switch ([keys count]) {
				case 0:
					// We have no key for this account.
					[item removeIvar:kHeadersEditorFromControlGPGKeyKey];
					item.hidden = NO;
					break;
				case 1:
					// We have only one key for this account: Set it.
					[item setIvar:kHeadersEditorFromControlGPGKeyKey value:[keys anyObject]];
					item.hidden = NO;
					break;
				default: {
					// We have more than one key for this account:
					// Add menu items to let the user choose.
					NSInteger index = [menu indexOfItem:item];
					
					for (GPGKey *key in keys) {
						NSMenuItem *subItem = nil;
						if (i + 1 < count && (subItem = menuItems[i + 1]) && [subItem getIvar:kHeadersEditorFromControlParentItemKey] && [subItem getIvar:kHeadersEditorFromControlGPGKeyKey] == key) {
							// The next item is the item we want to create: Jump over.
							i++;
							index++;
						} else {
							NSString *title;
							if (useTitleFromAccount) {
								title = [NSString stringWithFormat:@"%@ (%@)", itemTitle, [key.keyID shortKeyID]]; // Compose the title "Name <E-Mail> (KeyID)".
							} else {
                                if([GPGMailBundle isYosemite])
                                    title = [NSString stringWithFormat:@"%@ - %@ (%@)", key.name, email, [key.keyID shortKeyID]]; // Compose the title "key.Name - E-Mail (KeyID)".
                                else
                                    title = [NSString stringWithFormat:@"%@ <%@> (%@)", key.name, email, [key.keyID shortKeyID]]; // Compose the title "key.Name <E-Mail> (KeyID)".
							}
							
							currentAttributes = [NSClassFromString(@"MUITokenAddress") addressIsExternal:email] ? externalAttributes : attributes;
							
							NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:currentAttributes];

							// Create the menu item with the given title...
							subItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
							[subItem setAttributedTitle:attributedTitle];
							[subItem setIvar:kHeadersEditorFromControlGPGKeyKey value:key]; // GPGKey...
							[subItem setIvar:kHeadersEditorFromControlParentItemKey value:item]; // and set the parentItem.
                            [subItem setRepresentedObject:item.representedObject];
							[menu insertItem:subItem atIndex:++index]; // Insert it in the "From:" menu.
                        }
						if (item == selectedItem) {
							if (key == defaultKey) {
								subItemToSelect = subItem;
							}
						}
						
					}
					item.hidden = YES;
					break; }
			}
		} else { // display == NO
			// Restore all original items.
			[item removeIvar:kHeadersEditorFromControlGPGKeyKey];
			item.hidden = NO;
		}
	}
	
	ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
	
    // Select a valid item if needed.
    if (selectedItem.isHidden) {
		NSUInteger index;
		if (subItemToSelect) {
			index = [menu indexOfItem:subItemToSelect];
		} else {
			index = [menu indexOfItem:selectedItem] + 1;
		}
        [popUp selectItemAtIndex:index];
        [popUp synchronizeTitleAndSelectedItem];
		
		[popUp setIvar:@"CalledFromGPGMail" value:@YES];
		[self changeFromHeader:popUp];
    }
    else if ([popUp selectedItem] != selectedItem) {
        if ((parentItem = [selectedItem getIvar:kHeadersEditorFromControlParentItemKey])) {
            selectedItem = parentItem;
        }
        [popUp selectItem:selectedItem];
        [popUp synchronizeTitleAndSelectedItem];
		
		[popUp setIvar:@"CalledFromGPGMail" value:@YES];
        [self changeFromHeader:popUp];
    } else if (![backEnd getIvar:@"gpgKeyForSigning"]) {
		id gpgKey = [selectedItem getIvar:kHeadersEditorFromControlGPGKeyKey];
		if (gpgKey) {
			[backEnd setIvar:@"gpgKeyForSigning" value:gpgKey];
		}
	}
}

- (void)MAChangeFromHeader:(NSPopUpButton *)sender {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MAChangeFromHeader:sender];
        return;
    }
    BOOL calledFromGPGMail = [[sender getIvar:@"CalledFromGPGMail"] boolValue];
    [sender setIvar:@"CalledFromGPGMail" value:@NO];
    
    // Create a new NSPopUpButton with only one item and the correct title.
	NSPopUpButton *button = [[NSPopUpButton alloc] init];
	NSMenuItem *item = [sender selectedItem];
	NSMenuItem *parentItem = [item getIvar:kHeadersEditorFromControlParentItemKey];
    
    // On Yosemite, the representedObject contains the fullAddress (name <email>) of the
    // menu item. If we use addItemWithTitle, the representedObject is no longer set,
    // and mail receives nil when querying the address and thus can't properly set the sender.
    // In order to fix this, we simply use addItem: on the button's menu instead.
    if([GPGMailBundle isYosemite]) {
        // Since according to the documentation, a menuitem must not belong to another menu,
        // we have to create a new version with the same properties.
        NSMenuItem *baseItem = parentItem ? parentItem : item;
        NSMenuItem *fakeItem = [[NSMenuItem alloc] init];
        fakeItem.attributedTitle = baseItem.attributedTitle;
        fakeItem.representedObject = baseItem.representedObject;
        [[button menu] addItem:fakeItem];
    }
    else
        [button addItemWithTitle:(parentItem ? parentItem : item).title];
    
    ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    GMComposeMessagePreferredSecurityProperties *securityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
    GPGKey *signingKey = [item getIvar:kHeadersEditorFromControlGPGKeyKey];
    if(signingKey) {
        // Configure the security properties to always used the specified key for signing,
        // instead of looking up a matching key using the signers email address.
        // This is especially necessary in case multiple signing keys are available for the
        // same email address. (#895)
        [securityProperties updateSigningKey:signingKey forSender:item.representedObject];
    }
    
    [self MAChangeFromHeader:button];
}

- (void)keyringUpdated:(NSNotification *)notification {
    // Will always be called on the main thread!.
	if(![NSThread isMainThread]) {
		DebugLog(@"%@: not called on main thread? What the fuck?!", NSStringFromSelector(_cmd));
		return;
	}

	ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    GMComposeMessagePreferredSecurityProperties *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).preferredSecurityProperties;
	GPGMAIL_SECURITY_METHOD securityMethod = securityProperties.securityMethod;
    if(securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
        // Bug #1059: Internal key state not properly refreshed if key ring changes
        //
        // Due to the caching of key lookups introduced in GPG Mail 4.0 key ring
        // changes were no longer properly picked up in existing composer windows.
        //
        // Clear the cache whenever a key ring change is detected to make sure
        // composer windows also worked with the most current key data.
        [securityProperties resetKeyStatus];
        [self _updateSecurityControls];
    }
}

- (void)updateSecurityControlToolTips {
    [self updateToolTipForSecurityControl:[mailself signButton]];
    [self updateToolTipForSecurityControl:[mailself encryptButton]];
}

- (void)updateToolTipForSecurityControl:(NSSegmentedControl *)control {
    ComposeBackEnd_GPGMail *backEnd = (ComposeBackEnd_GPGMail *)[[mailself composeViewController] backEnd];
    GMComposeMessagePreferredSecurityProperties *preferredSecurityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
    GPGMAIL_SECURITY_METHOD securityMethod = preferredSecurityProperties.securityMethod;

    if(securityMethod != GPGMAIL_SECURITY_METHOD_OPENPGP)
        return;

    NSString *toolTip = @"";

    if(control == [mailself signButton]) {
        toolTip = [self signButtonToolTip];
    }
    else if(control == [mailself encryptButton]) {
        toolTip = [self encryptButtonToolTip];
    }

    [control setToolTip:toolTip];
}

// Bug #970: Error dialog for missing encryption keys might be
//           displayed upon send if reply-to field is filled with an address
//
// The broken handling of the reply-to field in macOS Mail (FB5429632 - rdar://35815871)
// leads to three distinct bugs:
//
// 1. Any address entered into the reply-to field is treated as a recipient internally
//    and thus a message can only be encrypted if a public key for the address in the reply-to
//    field is available.
// 2. Upon send, a user might be mistakenly warned that public keys for a recipient are missing
//    even though they have keys for all recipients.
// 3. Upon entering an address into the reply-to field, the encrypt button does not properly
//    reflect whether or not public keys for all recipients are available.
//
// The first major problem is, that `reply-to` is treated as a recipient and is
// included in the list of addresses returned by `-[ComposeBackEnd allRecipients]`.
// So in order for a message to be sent encrypted, a public keys must be available
// for all recipients enterd in `to`, `cc`, `bcc` as well as for the address in
// `reply-to`.
// In addition however, contrary to the `to`, `cc` and `bcc` fields,
// changes to the `reply-to` field don't trigger an update of the security controls
// and the list of looked up public keys.
// So if the reply-to field is filled in last, Mail doesn't check if a public key
// is available for the address in the reply-to field.
// However upon pressing send, the list returned by -[ComposeBackEnd allRecipients] is also
// checked against the previously looked up public keys and since no entry is available for
// the reply-to address, the error message mentioned in the title is displayed.
// Last but not least, due to the fact that the security controls are not updated, when
// and address is entered into the `reply-to` field, the encrypt button also doesn't reflect
// if the message can really be encrypted or not.
//
// In order to fix the UI inconsistencies, it is necessary to make sure
// that the security controls are updated properly whenever a change to
// `reply-to` is detected. And the properly handle reply-to, it is excluded
// from being treated as a recipient.
- (void)MA_changeHeaderField:(MUIAddressField *)headerField {
	[self MA_changeHeaderField:headerField];

	if(headerField != [mailself replyToField]) {
		return;
	}

	// Make sure the security controls are updated.
	[[mailself composeViewController] updateSendButtonStateInToolbar];
	[mailself _updateSecurityControls];
}

// TODO: Re-Implement for Sierra.
//- (void)MA_updateSignButtonTooltip {
//    // This was replaced by a ValueTransformer in Yosemite.
//    // The NSSegmentedControl encryptButton and signButton have a binding for toolTip
//    // which can be queried like this.
//    // [[[self signButton] control] infoForBinding:@"toolTip"];
//    // Basically replacing it with our own value might suffice.
//    // Or we could simply unbind it and call our own methods which will set the
//    // tooltips directly.
//    // Seems to be the easier way.
//    // So basically.
//    // [[[self signButton] control] unbind:@"toolTip"];
//    // [[[self signButton] control] setToolTip:@"Whatever we want to be written here."];
//    // The binding listens to messageIsToBeEncrypted and messageIsToBeSigned, so maybe we should as well.
//    
//    ComposeBackEnd_GPGMail *backEnd = [GPGMailBundle backEndFromObject:self];
//    if(backEnd.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
//        NSString *signToolTip = [self signButtonToolTip];
//        GMSecurityControl *signControl = [self valueForKey:@"_signButton"];
//        [((NSSegmentedControl *)signControl) setToolTip:signToolTip];
//    }
//    else {
//        [self MA_updateSignButtonTooltip];
//    }
//}

- (NSString *)encryptButtonToolTip {
    ComposeBackEnd_GPGMail *backEnd = (ComposeBackEnd_GPGMail *)[[mailself composeViewController] backEnd];
    GMComposeMessagePreferredSecurityProperties *securityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
    
    NSString *toolTip = @"";
    
    if(!securityProperties.canEncrypt) {
        NSArray *nonEligibleRecipients = [(ComposeBackEnd *)backEnd recipientsThatHaveNoKeyForEncryption];
        if(![nonEligibleRecipients count])
            toolTip = GMLocalizedString(@"COMPOSE_WINDOW_TOOLTIP_CAN_NOT_PGP_ENCRYPT_NO_RECIPIENTS");
        else {
            NSString *recipients = [nonEligibleRecipients componentsJoinedByString:@", "];
            toolTip = [NSString stringWithFormat:GMLocalizedString(@"COMPOSE_WINDOW_TOOLTIP_CAN_NOT_PGP_ENCRYPT"), recipients];
        }
    }
    else {
        NSString *toolTipKey = @"TurnOffEncryptionToolTip";
        if(![mailself messageIsToBeEncrypted]) {
            toolTipKey = @"TurnOnEncryptionToolTip";
        }
        toolTip = [[NSBundle mainBundle] localizedStringForKey:toolTipKey value:@"" table:@"Encryption"];
    }
    return toolTip;
}

- (NSString *)signButtonToolTip {
    ComposeBackEnd_GPGMail *backEnd = (ComposeBackEnd_GPGMail *)[[mailself composeViewController] backEnd];
    GMComposeMessagePreferredSecurityProperties *securityProperties = [(ComposeBackEnd_GPGMail *)backEnd preferredSecurityProperties];
    
    NSString *toolTip = @"";
    
    if(!securityProperties.canSign) {
        NSPopUpButton *button = [mailself fromPopup];
        NSString *sender = [button.selectedItem.representedObject gpgNormalizedEmail];
        
        if([sender length] == 0 && [button.itemArray count])
            sender = [[(button.itemArray)[0] representedObject] gpgNormalizedEmail];
        
        // If sender is still nil, which can be the case if no from menu is displayed
        // as only one account is setup, use the sender currently set on the back end.
        if([sender length] == 0) {
            sender = [[[[mailself composeViewController] backEnd] sender] gpgNormalizedEmail];
        }

        toolTip = [NSString stringWithFormat:GMLocalizedString(@"COMPOSE_WINDOW_TOOLTIP_CAN_NOT_PGP_SIGN"), sender];
    }
    else {
        NSString *toolTipKey = @"TurnOffSigningToolTip";
        if(![mailself messageIsToBeSigned]) {
           toolTipKey = @"TurnOnSigningToolTip";
        }
        toolTip = [[NSBundle mainBundle] localizedStringForKey:toolTipKey value:@"" table:@"Encryption"];
    }
    
    return toolTip;
}

- (void)MADealloc {
    @try {
//        [(MailNotificationCenter *)[NSClassFromString(@"MailNotificationCenter") defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    @catch (id e) {
    }
	[self MADealloc];
}

@end

#undef mailself

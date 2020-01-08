/* ComposeWindowController+GPGMail.m created by Lukas Pitschl on Tue 22-09-2015 */

/*
 * Copyright (c) 2000-2015, GPGTools <team@gpgtools.org>
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
 * THIS SOFTWARE IS PROVIDED BY THE GPGTools ``AS IS'' AND ANY
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

#import "NSObject+LPDynamicIvars.h"
#import "GMSecurityMethodAccessoryView.h"
#import "ComposeWindowController.h"
#import "ComposeWindowController+GPGMail.h"
#import "MessageViewer.h"
#import "ComposeViewController.h"
#import "ComposeWindow.h"
#import "GPGMailBundle.h"

#import "MailDocumentEditor+GPGMail.h"

#define mailself ((ComposeWindowController *)self)

const NSString *kComposeWindowControllerAllowWindowTearDown = @"ComposeWindowControllerAllowWindowTearDown";
const NSString *kComposeWindowControllerLastComposeViewController = @"ComposeWindowControllerLastComposeViewController";
const NSString *kComposeWindowControllerWindowFrameOriginBeforeAnimation = @"ComposeWindowControllerWindowFrameOriginBeforeAnimation";
extern const NSString *kFullScreenWindowControllerCloseModalWindowNotYet;

@implementation ComposeWindowController_GPGMail

#pragma mark Security Indicator in Toolbar

- (id)MAToolbarDefaultItemIdentifiers:(id)toolbar {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return [self MAToolbarDefaultItemIdentifiers:toolbar];
    }
	id defaultItemIdentifiers = [self MAToolbarDefaultItemIdentifiers:toolbar];
	
	// Appending the security method identifier to toggle between OpenPGP and S/MIME.
	NSMutableArray *identifiers = [defaultItemIdentifiers mutableCopy];
	[identifiers addObject:@"toggleSecurityMethod:"];
	
	return identifiers;
}

- (id)MAToolbar:(id)toolbar itemForItemIdentifier:(id)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willBeInsertedIntoToolbar {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        return [self MAToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:willBeInsertedIntoToolbar];
    }
	if(![itemIdentifier isEqualToString:@"toggleSecurityMethod:"]) {
		return [self MAToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:willBeInsertedIntoToolbar];
	}
	
	// Make sure our toolbar item was not already added.
	for(NSToolbarItem *item in [toolbar items]) {
		if([item.itemIdentifier isEqualToString:itemIdentifier])
			return nil;
	}
	
	// The delegate of GMSecurityMethodAccessoryView will be the current composeViewController.
	// At this point it's however not yet set on the ComposeWindowController, so once the
	// compose view controller is ready, it will set if self up as delegate.
    NSSize toolbarItemSize = NSMakeSize(75.0, 23.0);
    GMSecurityMethodAccessoryView *securityMethodAccessoryView = [[GMSecurityMethodAccessoryView alloc] initWithStyle:GMSecurityMethodAccessoryViewStyleToolbarItem size:toolbarItemSize];
	[self setIvar:@"SecurityMethodAccessoryView" value:securityMethodAccessoryView];
	
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	[item setView:securityMethodAccessoryView];
	[item setMinSize:toolbarItemSize];
	[item setTarget:nil];
	
	return item;
}

#pragma mark Allow restoration of Compose Window on send failures

- (void)MAComposeViewControllerDidSend:(id __unused)composeViewController {
    if(![[GPGMailBundle sharedInstance] hasActiveContractOrActiveTrial]) {
        [self MAComposeViewControllerDidSend:composeViewController];
        return;
    }
    // Bug #998: Canceling a pinentry request might result in losing a message
    //
    // Fixes also: #814, #716, #867
    //
    // As soon as the user presses the send button, `-[ComposeWindowController composeViewControllerDidSend:]`
    // is called in order to tear down the compose view controller.
    // Internally `-[ComposeWindowController composeViewControllerDidSend:]` calls `-[ComposeViewController forceClose]`
    // for the tear down.
    //
    // This however leads to the problem, that if an error occurs during the send operation,
    // the compose view controller cannot properly recover the message being sent, since it is already
    // partially torn down. Among other things, auto-save will no longer work, the window can no longer
    // be properly closed, etc.
    //
    // To avoid this dirty state, GPG Mail tries to postpone the tear down until *after* the
    // send operation is completed and `-[ComposeViewController backEndDidAppendMessageToOutbox:result:]`
    // is called with the `result` variable indicating whether or not an error has occurred.
    //
    // If the result is 3 (successfully sent), `-[ComposeViewController forceClose]` is invoked by GPG Mail
    // from `-[ComposeViewController backEndDidAppendMessageToOutbox:result:]`

    // Check if the tear down should be postponed. If not, immediately call the original implementation
    // in order to avoid breaking more than necessary.
    if(![(MailDocumentEditor_GPGMail *)composeViewController GMShouldPostponeTearDown]) {
        [self MAComposeViewControllerDidSend:composeViewController];
    }
    return;
}

@end

#undef mailself

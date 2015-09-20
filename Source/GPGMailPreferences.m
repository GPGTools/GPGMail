/* GPGMailPreferences.m created by dave on Thu 29-Jun-2000 */

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

#import "GPGMailPreferences.h"
#import "GPGMailBundle.h"
#import "MailAccount.h"
#import "ExchangeAccount.h"


#define localized(key) [GPGMailBundle localizedStringForKey:key]

NSString *SUEnableAutomaticChecksKey = @"SUEnableAutomaticChecks";
NSString *SUScheduledCheckIntervalKey = @"SUScheduledCheckInterval";


@implementation GPGMailPreferences

-(id)init {
	self = [super init];
	if (self) {
		NSDictionary *defaults = [[NSDictionary alloc] initWithContentsOfFile:[[GPGMailBundle bundle] pathForResource:@"SparkleDefaults" ofType:@"plist"]];
		GPGOptions *options = [GPGOptions sharedOptions];
		[options registerDefaults:defaults];
	}
	
	return self;
}

- (GPGMailBundle *)bundle {
	return [GPGMailBundle sharedInstance];
}


- (NSString *)copyright {
	return [[GPGMailBundle bundle] infoDictionary][@"NSHumanReadableCopyright"];
}

- (NSAttributedString *)credits {
	NSBundle *mailBundle = [GPGMailBundle bundle];
	NSAttributedString *credits = [[NSAttributedString alloc] initWithURL:[mailBundle URLForResource:@"Credits" withExtension:@"rtf"] documentAttributes:nil];

	return credits;
}

- (NSAttributedString *)websiteLink {
	NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];

	[pStyle setAlignment:NSRightTextAlignment];

	NSDictionary *attributes = @{NSParagraphStyleAttributeName: pStyle,
								NSLinkAttributeName: @"http://www.gpgtools.org/",
								NSForegroundColorAttributeName: [NSColor blueColor],
								NSFontAttributeName: [NSFont fontWithName:@"Lucida Grande" size:9],
								NSUnderlineStyleAttributeName: @1};

	return [[NSAttributedString alloc] initWithString:@"http://www.gpgtools.org" attributes:attributes];
}	


- (NSString *)versionDescription {
	return [NSString stringWithFormat:GMLocalizedString(@"VERSION: %@"), [self.bundle version]];
}

- (NSAttributedString *)buildNumberDescription {
	NSString *string = [NSString stringWithFormat:@"Build: %@", [GPGMailBundle bundleVersion]];
	NSDictionary *attributes = @{NSForegroundColorAttributeName: [NSColor grayColor], NSFontAttributeName: [NSFont systemFontOfSize:11]};
	
	return [[NSAttributedString alloc] initWithString:string attributes:attributes];
}


- (NSImage *)imageForPreferenceNamed:(NSString *)aName {
	return [NSImage imageNamed:@"GPGMail"];
}



- (IBAction)openSupport:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://gpgtools.tenderapp.com/"]];
}
- (IBAction)openDonate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://gpgtools.org/donate"]];
}
- (IBAction)openKnowledgeBase:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://gpgtools.tenderapp.com/kb"]];
}



- (IBAction)openGPGStatusHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://gpgtools.tenderapp.com/kb/how-to/gpg-status"]];
}

- (IBAction)copyVersionInfo:(id)sender {
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	NSString *string = [NSString stringWithFormat:@"%@\n%@", self.versionDescription, self.buildNumberDescription.string];
	[pasteboard writeObjects:@[string]];
}


- (void)willBeDisplayed {
	[[GPGMailBundle sharedInstance] checkGPG];
}

- (NSImage *)gpgStatusImage {
	switch ([[GPGMailBundle sharedInstance] gpgStatus]) {
		case GPGErrorNotFound:
			return [NSImage imageNamed:@"RedDot"];
		case GPGErrorNoError:
			return [NSImage imageNamed:@"GreenDot"];
		default:
			return [NSImage imageNamed:@"YellowDot"];
	}
}
- (NSString *)gpgStatusToolTip {
	switch ([[GPGMailBundle sharedInstance] gpgStatus]) {
		case GPGErrorNotFound:
			return localized(@"GPG_STATUS_NOT_FOUND_TOOLTIP");
		case GPGErrorNoError:
			return localized(@"GPG_STATUS_NO_ERROR_TOOLTIP");
		default:
			return localized(@"GPG_STATUS_OTHER_ERROR_TOOLTIP");
	}
}

- (NSString *)gpgStatusTitle {
    NSString *statusTitle = nil;
    switch ([[GPGMailBundle sharedInstance] gpgStatus]) {
		case GPGErrorNotFound:
			statusTitle = localized(@"GPG_STATUS_NOT_FOUND_TITLE");
            break;
		case GPGErrorNoError:
			statusTitle = localized(@"GPG_STATUS_NO_ERROR_TITLE");
            break;
        default:
			statusTitle = localized(@"GPG_STATUS_OTHER_ERROR_TITLE");
	}
    return statusTitle;
}

+ (NSSet*)keyPathsForValuesAffectingGpgStatusImage {
	return [NSSet setWithObject:@"bundle.gpgStatus"];
}
+ (NSSet*)keyPathsForValuesAffectingGpgStatusToolTip {
	return [NSSet setWithObject:@"bundle.gpgStatus"];
}
+ (NSSet*)keyPathsForValuesAffectingGpgStatusTitle {
	return [NSSet setWithObject:@"bundle.gpgStatus"];
}

- (GPGOptions *)options {
    return [GPGOptions sharedOptions];
}

- (BOOL)isResizable {
	return NO;
}


- (BOOL)enableAutomaticChecks {
	GPGOptions *options = [GPGOptions sharedOptions];
	NSNumber *interval = [options valueForKey:SUScheduledCheckIntervalKey];
	if (interval && interval.integerValue == 0) {
		return false;
	}
	NSNumber *value = [options valueForKey:SUEnableAutomaticChecksKey];
	if (!value) {
		return true;
	}
	return value.boolValue;
}
- (void)setEnableAutomaticChecks:(BOOL)value {
	GPGOptions *options = [GPGOptions sharedOptions];
	[options setBool:value forKey:SUEnableAutomaticChecksKey];
	if (value) {
		NSNumber *interval = [options valueForKey:SUScheduledCheckIntervalKey];
		if (interval && interval.integerValue == 0) {
			[options setValue:@86400 forKey:SUScheduledCheckIntervalKey];
		}
	}
}

- (void)checkForUpdates:(id)sender {
	NSString *updaterPath = @"/Library/Application Support/GPGTools/GPGMail_Updater.app/Contents/MacOS/GPGMail_Updater";
	[GPGTask launchGeneralTask:updaterPath withArguments:@[@"checkNow"]];
}


- (BOOL)validateEncryptDrafts:(NSNumber **)value error:(NSError **)error {
	if ([*value boolValue] == NO) {
		NSArray *accounts = (NSArray *)[GM_MAIL_CLASS(@"MailAccount") allMailAccounts];
		for (id account in accounts) {
			if ([account respondsToSelector:@selector(storeDraftsOnServer)] && [account storeDraftsOnServer]) {
				
				NSWindow *window = [[NSPreferences sharedPreferences] valueForKey:@"_preferencesPanel"];
				
				if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
					NSAlert *unencryptedReplyAlert = [NSAlert new];
					unencryptedReplyAlert.messageText = localized(@"DISABLE_ENCRYPT_DRAFTS_TITLE");
					unencryptedReplyAlert.informativeText = localized(@"DISABLE_ENCRYPT_DRAFTS_MESSAGE");
					[unencryptedReplyAlert addButtonWithTitle:localized(@"DISABLE_ENCRYPT_DRAFTS_CANCEL")];
					[unencryptedReplyAlert addButtonWithTitle:localized(@"DISABLE_ENCRYPT_DRAFTS_CONFIRM")];
					unencryptedReplyAlert.icon = [NSImage imageNamed:@"GPGMail"];

					[unencryptedReplyAlert beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
						[NSApp stopModalWithCode:returnCode];
					}];
				} else {
					NSBeginAlertSheet(localized(@"DISABLE_ENCRYPT_DRAFTS_TITLE"),
									  localized(@"DISABLE_ENCRYPT_DRAFTS_CANCEL"),
									  localized(@"DISABLE_ENCRYPT_DRAFTS_CONFIRM"),
									  nil,
									  window,
									  self,
									  @selector(disableEncryptDraftSheetDidEnd:returnCode:contextInfo:),
									  nil,
									  nil,
									  @"%@", localized(@"DISABLE_ENCRYPT_DRAFTS_MESSAGE"));
				}

				if ([NSApp runModalForWindow:window] != NSAlertSecondButtonReturn) {
					*value = @(YES);
				}
				break;
			}
		}
	}
	return YES;
}
- (void)disableEncryptDraftSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	returnCode = returnCode == NSAlertAlternateReturn ? NSAlertSecondButtonReturn : NSAlertFirstButtonReturn;
	[NSApp stopModalWithCode:returnCode];
}


- (BOOL)encryptDrafts {
	return [self.options boolForKey:@"OptionallyEncryptDrafts"];
}
- (void)setEncryptDrafts:(BOOL)value {
	[self.options setBool:value forKey:@"OptionallyEncryptDrafts"];
}


@end


@implementation NSButton_LinkCursor
- (void)resetCursorRects {
	[self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}
@end

@implementation GMSpecialBox
- (void)showSpecial {
	if (displayed || working) return;	
	working = YES;

	if (!viewPositions) {
		viewPositions = [[NSMapTable alloc] initWithKeyOptions:NSMapTableZeroingWeakMemory valueOptions:NSMapTableStrongMemory capacity:10];
	}
	
	NSSize size = self.bounds.size;
	srandom((unsigned int)time(NULL));

	webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
	webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	webView.drawsBackground = NO;
	webView.UIDelegate = self;
	webView.editingDelegate = self;

	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:2.0f];
	[NSAnimationContext currentContext].completionHandler = ^{
		[self addSubview:webView];
        
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[GPGMailBundle bundle] URLForResource:@"Special" withExtension:@"html"]]];
		displayed = YES;
		working = NO;
	};
	
	for (NSView *view in [self.contentView subviews]) {
		NSRect frame = view.frame;
		
		if (!positionsFilled) {
			[viewPositions setObject:[NSValue valueWithRect:frame] forKey:view];
		}
		
		long angle = (random() % 360);	
		
		double x = (size.width + frame.size.width) / 2 * sin(angle * M_PI / 180) * 1.5;
		double y = (size.height + frame.size.height) / 2 * cos(angle * M_PI / 180) * 1.5;
		
		x += (size.width - frame.size.width) / 2;
		y += (size.height - frame.size.height) / 2;
		
		frame.origin.x = x;
		frame.origin.y = y;
		
		[(NSView *)[view animator] setFrame:frame];
	}
	positionsFilled = YES;
	[NSAnimationContext endGrouping];
}
- (void)hideSpecial {
	if (!displayed || working) return;
	working = YES;

	for (NSView *view in viewPositions) {
		[view setFrame:[[viewPositions objectForKey:view] rectValue]];
	}
	[webView removeFromSuperview];

	displayed = NO;
	working = NO;
}
- (void)keyDown:(NSEvent *)event {
	unsigned short keySequence[] = {126, 125, 47, 5, 35, 5, 17, 31, 31, 37, 1, USHRT_MAX};
	static int index = 0;
	
	if (!displayed) {
		if (keySequence[index] == USHRT_MAX) {
			[super keyDown:event];
			return;
		}
		if (event.keyCode != keySequence[index]) {
			if (event.keyCode == keySequence[0]) {
				index = 1;
			} else {
				[super keyDown:event];
				index = 0;
			}
			return;
		}
		if (keySequence[++index] != USHRT_MAX) return;
		
		index = 0;
		[self showSpecial];
	} else {
		[self hideSpecial];
	}
}
- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	if (newWindow == nil) {
		[self hideSpecial];
	}
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    return nil;
}
- (BOOL)webView:(WebView *)sender shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag {
    return NO;
}


- (BOOL)acceptsFirstResponder {
    return YES;
}
@end


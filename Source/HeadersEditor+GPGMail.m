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
#import "MailAccount.h"
#import "AddressAttachment.h"
#import <MailDocumentEditor.h>
#import "MailNotificationCenter.h"
#import "Message+GPGMail.h"
#import "MailDocumentEditor+GPGMail.h"
#import "HeadersEditor.h"
#import "ComposeHeaderView.h"
#import "HeadersEditor+GPGMail.h"
#import "ComposeBackEnd.h"
#import "ComposeBackEnd+GPGMail.h"
#import "GPGMailBundle.h"
#import "NSString+GPGMail.h"
#import "GMSecurityControl.h"
#import "NSObject+LPDynamicIvars.h"
#import <NSString-EmailAddressString.h>
#import "GMComposeKeyEventHandler.h"
#import "OptionalView.h"
#import "GMSecurityHistory.h"

@interface HeadersEditor_GPGMail (NoImplementation)
- (void)changeFromHeader:(NSPopUpButton *)sender;
@end

@implementation HeadersEditor_GPGMail


- (void)symmetricEncryptClicked:(id)sender {
	ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    NSMutableDictionary *updatedSecurityProperties = [@{} mutableCopy];

    BOOL oldValue = [securityProperties[@"shouldSymmetric"] boolValue];
	BOOL newValue = !oldValue;
	
	if (![securityProperties[@"SymmetricIsPossible"] boolValue]) {
		newValue = NO;
	}
	
	updatedSecurityProperties[@"shouldSymmetric"] = @(newValue);
	if (newValue != oldValue) {
        updatedSecurityProperties[@"ForceSymmetric"] = @(newValue);
	}
	
	[self updateSymmetricButton];
	[(MailDocumentEditor_GPGMail *)[backEnd delegate] updateSecurityMethodHighlight];
}

- (void)updateSymmetricButton {
	if (![[self getIvar:@"AllowSymmetricEncryption"] boolValue]) {
		return;
	}
	ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    NSMutableDictionary *updatedSecurityProperties = [@{} mutableCopy];

	NSSegmentedControl *symmetricButton = [self getIvar:@"_symmetricButton"];
	
	GPGMAIL_SECURITY_METHOD securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).guessedSecurityMethod;
	if (((ComposeBackEnd_GPGMail *)backEnd).securityMethod)
		securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).securityMethod;
	
	
	
	NSString *imageName;
	if ([securityProperties[@"SymmetricIsPossible"] boolValue] && securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
		NSNumber *forceSymmetric = securityProperties[@"ForceSymmetric"];
		if (forceSymmetric) {
			updatedSecurityProperties[@"shouldSymmetric"] = forceSymmetric;
		}
		
		[symmetricButton setEnabled:YES forSegment:0];
		if ([securityProperties[@"shouldSymmetric"] boolValue]) {
			imageName = @"SymmetricEncryptionOn";
		} else {
			imageName = @"SymmetricEncryptionOff";
		}
	} else {
		imageName = @"SymmetricEncryptionOff";
		[symmetricButton setEnabled:NO forSegment:0];
	}
	
	[symmetricButton setImage:[NSImage imageNamed:imageName] forSegment:0];
}


- (void)MAAwakeFromNib {
    [self MAAwakeFromNib];
	
    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyringUpdated:) name:GPGMailKeyringUpdatedNotification object:nil];
	
	NSSegmentedControl *symmetricButton = nil;
	OptionalView *optionalView = (OptionalView *)[[self valueForKey:@"_signButton"] superview];

	
	if ([[GPGOptions sharedOptions] boolForKey:@"AllowSymmetricEncryption"]) {
		symmetricButton = [[NSSegmentedControl alloc] initWithFrame:NSMakeRect(24, -1, 38, 24)];
		symmetricButton.segmentCount = 1;
		[symmetricButton setWidth:32 forSegment:0];
		symmetricButton.segmentStyle = NSSegmentStyleRounded;
		((NSSegmentedCell *)symmetricButton.cell).trackingMode = NSSegmentSwitchTrackingMomentary;
		symmetricButton.target = self;
		symmetricButton.action = @selector(symmetricEncryptClicked:);
		
		NSRect frame = optionalView.frame;
		frame.size.width += 44;
		optionalView.frame = frame;
		
		for (NSView *view in optionalView.subviews) {
			if (![view isKindOfClass:[NSButton class]]) {
				frame = view.frame;
				frame.origin.x += 44;
				view.frame = frame;
			}
		}
		
		
		[self setIvar:@"_symmetricButton" value:symmetricButton];
		[self setIvar:@"AllowSymmetricEncryption" value:@YES];
		[self updateSymmetricButton];
		
		[optionalView addSubview:symmetricButton];
		[optionalView setIvar:@"AdjustedWidth" value:@YES];
	}
	
	
	
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
	
	
	
	GMSecurityControl *signControl = [[GMSecurityControl alloc] initWithControl:[self valueForKey:@"_signButton"] tag:SECURITY_BUTTON_SIGN_TAG];
    [self setValue:signControl forKey:@"_signButton"];
    
    GMSecurityControl *encryptControl = [[GMSecurityControl alloc] initWithControl:[self valueForKey:@"_encryptButton"] tag:SECURITY_BUTTON_ENCRYPT_TAG];
    [self setValue:encryptControl forKey:@"_encryptButton"];
	
    // Configure setting the tool tip by unbinding the controls toolTip.
    // We will update it, after _updateSecurityStateInBackground is run.
    if([GPGMailBundle isYosemite]) {
        [signControl unbind:@"toolTip"];
        [encryptControl unbind:@"toolTip"];
    }
    
	GMComposeKeyEventHandler *handler = [[GMComposeKeyEventHandler alloc] initWithView:optionalView];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
	handler.eventsAndSelectors = [NSArray arrayWithObjects:
		@{@"keyEquivalent": @"y", @"keyEquivalentModifierMask": @(NSCommandKeyMask | NSAlternateKeyMask), @"target": encryptControl, @"selector": [NSValue valueWithPointer:@selector(performClick:)]},
		@{@"keyEquivalent": @"x", @"keyEquivalentModifierMask": @(NSCommandKeyMask | NSAlternateKeyMask), @"target": signControl, @"selector": [NSValue valueWithPointer:@selector(performClick:)]},
		symmetricButton ? @{@"keyEquivalent": @"Y", @"keyEquivalentModifierMask": @(NSCommandKeyMask | NSShiftKeyMask), @"target": symmetricButton, @"selector": [NSValue valueWithPointer:@selector(performClick:)]} : nil,
	nil];
#pragma clang diagnostic pop

	
}

- (void)MASecurityControlChanged:(id)securityControl {
    GMSecurityControl *signControl = [self valueForKey:@"_signButton"];
    GMSecurityControl *encryptControl = [self valueForKey:@"_encryptButton"];
    NSSegmentedControl *originalSecurityControl = securityControl;
	
	    
    securityControl = signControl.control == securityControl ? signControl : encryptControl;
    // The securityControl passed to this method is an NSSegmentControl.
	// So the only chance to find out what the new status of the control is,
	// is to check its current image. (I really thought I was crazy writing this code,
	// now it all makes sense again. WHAT A RELIEF)
	// It's possible this is not necessary on
    //if(![GPGMailBundle isYosemite])
        [securityControl updateStatusFromImage:[originalSecurityControl imageForSegment:0]];
    
    [self MASecurityControlChanged:securityControl];
}

- (void)MA_updateFromControl {
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
    NSPopUpButton *fromPopup = ![GPGMailBundle isYosemite] ? [self valueForKey:@"_fromPopup"] : [(id)self fromPopup];
    if([[fromPopup itemArray] count] == 1 &&
       ![[[fromPopup itemArray] objectAtIndex:0] attributedTitle]) {
        [self fixEmptyAccountPopUpIfNecessary];
    }
    else {
        if([GPGMailBundle isYosemite]) {
            [(HeadersEditor *)self _setVisibilityForFromView:YES];
        }
        else {
            [(ComposeHeaderView *)[self valueForKey:@"_composeHeaderView"] setAccountFieldEnabled:YES];
            [(ComposeHeaderView *)[self valueForKey:@"_composeHeaderView"] setAccountFieldVisible:YES];
        }
    }
    
    // If any luck, the security option should be known by now.
    // It's not, but it still works as assumed.
    ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    GPGMAIL_SECURITY_METHOD securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).guessedSecurityMethod;
    if(((ComposeBackEnd_GPGMail *)backEnd).securityMethod)
        securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).securityMethod;
    
    if(securityMethod == 0)
        securityMethod = [GMSecurityHistory defaultSecurityMethod];
    
    [self updateFromAndAddSecretKeysIfNecessary:@(securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP)];
}

- (void)MA_updateFromAndSignatureControls:(id)arg1 {
    [self MA_updateFromAndSignatureControls:arg1];
    [self setupFromControlCrossVersion];
}

- (void)fixEmptyAccountPopUpIfNecessary {
    // 1. Find the accounts to be displayed.
    NSArray *accounts = (NSArray *)[GM_MAIL_CLASS(@"MailAccount") allEmailAddressesIncludingFullUserName:YES];
	
	// There should only be on account available, otherwise we wouldn't be here.
	NSString *onlyAccount = [[accounts objectAtIndex:0] gpgNormalizedEmail];
	BOOL multipleKeysAvailable = [[[GPGMailBundle sharedInstance] signingKeyListForAddress:onlyAccount] count] > 1;
	
	if(!multipleKeysAvailable)
		return;
	
	Class AddressAttachmentClass = NSClassFromString(@"AddressAttachment");
	
    NSPopUpButton *fromPopup = ![GPGMailBundle isYosemite] ? [self valueForKey:@"_fromPopup"] : [self fromPopup];
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
            if([AddressAttachmentClass addressIsExternal:account])
                attributes = externalAttributes;
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:account attributes:attributes];
            [[fromPopup itemAtIndex:i] setAttributedTitle:title];
			[[fromPopup itemAtIndex:i] setRepresentedObject:account];
            i++;
        }
    }
    
    // Set the field visible so the layout will be adjusted accordingly.
    if(multipleKeysAvailable) {
        if([GPGMailBundle isYosemite]) {
            [self _setVisibilityForFromView:YES];
        }
        else {
            [(ComposeHeaderView *)[self valueForKey:@"_composeHeaderView"] setAccountFieldEnabled:YES];
            [(ComposeHeaderView *)[self valueForKey:@"_composeHeaderView"] setAccountFieldVisible:YES];
            [(ComposeHeaderView *)[self valueForKey:@"_composeHeaderView"] configureAccountPopUpSize];
        }
	}
}

- (void)MAUpdateSecurityControls {
	// Do nothing, if documentEditor is no longer set.
	// Might already have been released, or some such...
	// Belongs to: #624.
    // MailApp seems to call S in Yosemite to cancel previous updates.
    // That's highly interesting!.
	// DocumentEditor no longer exists in El Capitan. Seems to have been replaced by ComposeViewController.
	if([GPGMailBundle isElCapitan]) {
		if([self respondsToSelector:@selector(composeViewController)] && ![self composeViewController])
			return;
	}
	else {
		if(![self valueForKey:@"_documentEditor"])
			return;
	}
	
	[self MAUpdateSecurityControls];
}

- (void)MA_updateSecurityStateInBackgroundForRecipients:(NSArray *)recipients sender:(id)sender {
    [self MA_updateSecurityStateInBackgroundForRecipients:recipients sender:sender];
	
	// Do the same as _updateSecurityStateInBackgroundForRecipients and update the
	// symmetric UI part on the main thread.
	typeof(self) __weak weakSelf = self;
	
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		typeof(weakSelf) __strong strongSelf = weakSelf;
		if(!strongSelf)
			return;
        
        // Update tool tips.
        [strongSelf updateEncryptAndSignButtonToolTips];
		[strongSelf updateSymmetricButton];
	}];
}

- (void)MASetCanSign:(BOOL)canSign {
    // On Yosemite the button state of the sign button is bound to
    // this canSign property. Since canSignFromAddress always returns true in GPGMail,
    // because otherwise, canEncrypt would not always be evaluated, we have
    // to set the real value here, which is contained in SignIsPossible.
    ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    if(securityProperties[@"SignIsPossible"])
        canSign = [securityProperties[@"SignIsPossible"] boolValue];
    [self MASetCanSign:canSign];
}

- (void)MASetCanEncrypt:(BOOL)canEncrypt {
    // Only on Yosemite. See MASetCanSign for explanation.
    ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    if(securityProperties[@"EncryptIsPossible"])
        canEncrypt = [securityProperties[@"EncryptIsPossible"] boolValue];
    [self MASetCanEncrypt:canEncrypt];
}


- (void)MASetMessageIsToBeEncrypted:(BOOL)isToBeEncrypted {
    // On Yosemite, the encrypt and sign button states are no longer directly set
    // in _updateSecurityStateInBackgroundForRecipients, but instead in setMessageIsToBeEncrypted.
    // So we set our preferred state in here.
    ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    
    // It's possible that SetEncrypt is set to true, since that only reflects the defaults
    // set by the user.
    // If EncryptIsPossible (based on the availability of a public key) is true and
    // the user set the default for EncryptNewMessagesByDefault to true (which is reflected by EncryptIsPossible)
    // the message is in fact being encrypted and thus isToBeEncrypted is set to true.
    // ForceEncrypt however reflects the user choice and is thus not questioned.
    if(securityProperties[@"SetEncrypt"] && securityProperties[@"EncryptIsPossible"])
        isToBeEncrypted = [securityProperties[@"SetEncrypt"] boolValue] && [securityProperties[@"EncryptIsPossible"] boolValue];
    // ForceEncrypt overrides SetEncrypt since it reflects the user's choice.
    if(securityProperties[@"ForceEncrypt"])
        isToBeEncrypted = [securityProperties[@"ForceEncrypt"] boolValue];
    // ForceEncrypt must be ignored if EncryptIsPossible is set to NO.
    if(securityProperties[@"EncryptIsPossible"])
        isToBeEncrypted = isToBeEncrypted && [securityProperties[@"EncryptIsPossible"] boolValue];
    
    [self MASetMessageIsToBeEncrypted:isToBeEncrypted];
}

- (void)MASetMessageIsToBeSigned:(BOOL)isToBeSigned {
    // On Yosemite, the encrypt and sign button states are no longer directly set
    // in _updateSecurityStateInBackgroundForRecipients, but instead in setMessageIsToBeSigned.
    // So we set our preferred state in here.
    ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    
    if(securityProperties[@"SetSign"])
        isToBeSigned = [securityProperties[@"SetSign"] boolValue];
    // ForceSign overrides SetSign since it reflects the user's choice.
    if(securityProperties[@"ForceSign"])
        isToBeSigned = [securityProperties[@"ForceSign"] boolValue];
    // ForceSign must be ignored if SignIsPossible is set to NO.
    if(securityProperties[@"SignIsPossible"])
        isToBeSigned = isToBeSigned && [securityProperties[@"SignIsPossible"] boolValue];
    
    [self MASetMessageIsToBeSigned:isToBeSigned];
}

- (void)updateFromAndAddSecretKeysIfNecessary:(NSNumber *)necessary {
    BOOL display = [necessary boolValue];
    NSPopUpButton *popUp = nil;
    if([GPGMailBundle isYosemite]) {
        popUp = [self fromPopup];
    }
    else if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9) {
        popUp = [self valueForKey:@"_fromPopup"];
    }
    else {
        popUp = [[self valueForKey:@"_composeHeaderView"] valueForKey:@"_accountPopUp"];
    }
    
	NSMenu *menu = [popUp menu];
	NSArray *menuItems = [menu itemArray];
	GPGMailBundle *bundle = [GPGMailBundle sharedInstance];
	
	Class AddressAttachmentClass = NSClassFromString(@"AddressAttachment");
	
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
										[AddressAttachmentClass colorForExternalDomain], NSForegroundColorAttributeName,
                                        font, NSFontAttributeName, nil];
	
	
	NSMenuItem *item, *parentItem, *selectedItem = [popUp selectedItem], *subItemToSelect = nil;
	GPGKey *defaultKey = [bundle preferredGPGKeyForSigning];
	BOOL useTitleFromAccount = [[GPGOptions sharedOptions] boolForKey:@"ShowAccountNameForKeysOfSameAddress"];
	
	// If menu items are not yet set, simply exit.
    // This might happen if securityMethodDidChange notification
    // is posted before the menu items have been configured.
    if(!menuItems.count || (menuItems.count == 1 && ![[menuItems objectAtIndex:0] representedObject]))
        return;
    
	menu.autoenablesItems = NO;
	
	NSUInteger count = [menuItems count], i = 0;
	NSDictionary *currentAttributes = attributes;
	
	for (; i < count; i++) {
		item = menuItems[i];
		parentItem = [item getIvar:@"parentItem"];
		if (parentItem) {
			[menu removeItem:item]; // We remove all elements that represent a key.
		} else if (display) {
            NSString *itemTitle = item.title;
			
			NSString *email = nil;
			if (useTitleFromAccount == NO)
                email = ![GPGMailBundle isYosemite] ? [itemTitle gpgNormalizedEmail] : [item.representedObject gpgNormalizedEmail];
				
            NSSet *keys = [bundle signingKeyListForAddress:![GPGMailBundle isYosemite] ? item.title : item.representedObject];
			switch ([keys count]) {
				case 0:
					// We have no key for this account.
					[item removeIvar:@"gpgKey"];
					item.hidden = NO;
					break;
				case 1:
					// We have only one key for this account: Set it.
					[item setIvar:@"gpgKey" value:[keys anyObject]];
					item.hidden = NO;
					break;
				default: {
					// We have more than one key for this account:
					// Add menu items to let the user choose.
					NSInteger index = [menu indexOfItem:item];
					
					for (GPGKey *key in keys) {
						NSMenuItem *subItem = nil;
						if (i + 1 < count && (subItem = menuItems[i + 1]) && [subItem getIvar:@"parentItem"] && [subItem getIvar:@"gpgKey"] == key) {
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
							
							currentAttributes = [AddressAttachmentClass addressIsExternal:email] ? externalAttributes : attributes;
							
							NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:currentAttributes];

							// Create the menu item with the given title...
							subItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
							[subItem setAttributedTitle:attributedTitle];
							[subItem setIvar:@"gpgKey" value:key]; // GPGKey...
							[subItem setIvar:@"parentItem" value:item]; // and set the parentItem.
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
			[item removeIvar:@"gpgKey"];
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
        if ((parentItem = [selectedItem getIvar:@"parentItem"])) {
            selectedItem = parentItem;
        }
        [popUp selectItem:selectedItem];
        [popUp synchronizeTitleAndSelectedItem];
		
		[popUp setIvar:@"CalledFromGPGMail" value:@YES];
        [self changeFromHeader:popUp];
    } else if (![backEnd getIvar:@"gpgKeyForSigning"]) {
		id gpgKey = [selectedItem getIvar:@"gpgKey"];
		if (gpgKey) {
			[backEnd setIvar:@"gpgKeyForSigning" value:gpgKey];
		}
	}
}

- (void)MAChangeFromHeader:(NSPopUpButton *)sender {
    BOOL calledFromGPGMail = [[sender getIvar:@"CalledFromGPGMail"] boolValue];
    [sender setIvar:@"CalledFromGPGMail" value:@NO];
    
    // Create a new NSPopUpButton with only one item and the correct title.
	NSPopUpButton *button = [[NSPopUpButton alloc] init];
	NSMenuItem *item = [sender selectedItem];
	NSMenuItem *parentItem = [item getIvar:@"parentItem"];
    
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
    
    // Set the selected key in the back-end.
	ComposeBackEnd *backEnd = [GPGMailBundle backEndFromObject:self];
	[backEnd setIvar:@"gpgKeyForSigning" value:[item getIvar:@"gpgKey"]];
    
    // Only reset the status if this method is called from a user generated event.
    // Otherwise there's a notification loop, because the security method is set and reset again 
    // and again.
    // Also don't reset it, if the user chose the security method beforehand.
    if(!calledFromGPGMail && !((ComposeBackEnd_GPGMail *)backEnd).userDidChooseSecurityMethod) {
        ((ComposeBackEnd_GPGMail *)backEnd).securityMethod = 0;
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
	GPGMAIL_SECURITY_METHOD securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).guessedSecurityMethod;
    if(((ComposeBackEnd_GPGMail *)backEnd).securityMethod)
        securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).securityMethod;
	// It seems calling updateSecurityControls at this point is most reliable.
    if([GPGMailBundle isYosemite]) {
        [self _updateSecurityControls];
    }
    else {
        [self updateSecurityControls];
    }
}

- (void)updateEncryptAndSignButtonToolTips {
    // This method is currently only used on Yosemite, since Apple
    // switched to a ValueTransformer which is not really adequate for
    // our more advanced tool tips.
    ComposeBackEnd_GPGMail *backEnd = [GPGMailBundle backEndFromObject:self];
    GPGMAIL_SECURITY_METHOD securityMethod = backEnd.securityMethod;
    if(securityMethod == 0)
        securityMethod = backEnd.guessedSecurityMethod;
    
    if(securityMethod != GPGMAIL_SECURITY_METHOD_OPENPGP)
        return;
    
    NSString *signToolTip = [self signButtonToolTip];
    GMSecurityControl *signControl = [self valueForKey:@"_signButton"];
    [((NSSegmentedControl *)signControl) setToolTip:signToolTip];
    
    NSString *encryptToolTip = [self encryptButtonToolTip];
    GMSecurityControl *encryptControl = [self valueForKey:@"_encryptButton"];
    [((NSSegmentedControl *)encryptControl) setToolTip:encryptToolTip];
}

- (void)MA_updateSignButtonTooltip {
    // This was replaced by a ValueTransformer in Yosemite.
    // The NSSegmentedControl encryptButton and signButton have a binding for toolTip
    // which can be queried like this.
    // [[[self signButton] control] infoForBinding:@"toolTip"];
    // Basically replacing it with our own value might suffice.
    // Or we could simply unbind it and call our own methods which will set the
    // tooltips directly.
    // Seems to be the easier way.
    // So basically.
    // [[[self signButton] control] unbind:@"toolTip"];
    // [[[self signButton] control] setToolTip:@"Whatever we want to be written here."];
    // The binding listens to messageIsToBeEncrypted and messageIsToBeSigned, so maybe we should as well.
    
    ComposeBackEnd_GPGMail *backEnd = [GPGMailBundle backEndFromObject:self];
    if(backEnd.securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
        NSString *signToolTip = [self signButtonToolTip];
        GMSecurityControl *signControl = [self valueForKey:@"_signButton"];
        [((NSSegmentedControl *)signControl) setToolTip:signToolTip];
    }
    else {
        [self MA_updateSignButtonTooltip];
    }
}

- (NSString *)encryptButtonToolTip {
    ComposeBackEnd_GPGMail *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    
    NSString *toolTip = @"";
    
    if(![securityProperties[@"EncryptIsPossible"] boolValue]) {
        NSArray *nonEligibleRecipients = [(ComposeBackEnd *)backEnd recipientsThatHaveNoKeyForEncryption];
        if(![nonEligibleRecipients count])
            toolTip = GMLocalizedString(@"COMPOSE_WINDOW_TOOLTIP_CAN_NOT_PGP_ENCRYPT_NO_RECIPIENTS");
        else {
            NSString *recipients = [nonEligibleRecipients componentsJoinedByString:@", "];
            toolTip = [NSString stringWithFormat:GMLocalizedString(@"COMPOSE_WINDOW_TOOLTIP_CAN_NOT_PGP_ENCRYPT"), recipients];
        }
    }
    
    return toolTip;
}

- (NSString *)signButtonToolTip {
    ComposeBackEnd_GPGMail *backEnd = [GPGMailBundle backEndFromObject:self];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    
    NSString *toolTip = @"";
    
    if(![securityProperties[@"SignIsPossible"] boolValue]) {
        NSPopUpButton *button = [self valueForKey:@"_fromPopup"];
        NSString *sender = ![GPGMailBundle isYosemite] ? [button.selectedItem.title gpgNormalizedEmail] : [button.selectedItem.representedObject gpgNormalizedEmail];
        
        if([sender length] == 0 && [button.itemArray count])
            sender = ![GPGMailBundle isYosemite] ? [[(button.itemArray)[0] title] gpgNormalizedEmail] : [[(button.itemArray)[0] representedObject] gpgNormalizedEmail];
        
        toolTip = [NSString stringWithFormat:GMLocalizedString(@"COMPOSE_WINDOW_TOOLTIP_CAN_NOT_PGP_SIGN"), sender];
    }
    
    return toolTip;
}

- (void)MA_updateEncryptButtonTooltip {
    ComposeBackEnd_GPGMail *backEnd = [GPGMailBundle backEndFromObject:self];
    
    GPGMAIL_SECURITY_METHOD securityMethod = backEnd.guessedSecurityMethod;
    if(backEnd.securityMethod)
        securityMethod = backEnd.securityMethod;
    
    if(securityMethod == GPGMAIL_SECURITY_METHOD_OPENPGP) {
        NSString *encryptToolTip = [self encryptButtonToolTip];
        GMSecurityControl *encryptControl = [self valueForKey:@"_encryptButton"];
        [((NSSegmentedControl *)encryptControl) setToolTip:encryptToolTip];
    }
    else {
        [self MA_updateEncryptButtonTooltip];
    }
}

- (void)MADealloc {
    @try {
        [(MailNotificationCenter *)[NSClassFromString(@"MailNotificationCenter") defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    @catch (id e) {
    }
	[self MADealloc];
}

@end

/* ORIGINAL SOURCE OF MAIL.APP FOR LEARING. */

//- (void)configureButtonsAndPopUps {
//    WebViewEditor *webViewEditor = [[self valueForKey:@"_documentEditor"] webViewEditor];
//	[webViewEditor updateIgnoredWordsForHeader:NO];
//	[webViewEditor updateSecurityControls];
//	[webViewEditor updatePriorityPopUpMakeActive:YES];
//
//	ComposeBackEnd *backEnd = [self _valueForKey:@"_documentEditor"];
//	long long messagePriority = [backEnd displayableMessagePriority];
//
//	if(messagePriority != 3) {
//		if([[self valueForKey:@"_priorityPopup"] isHiddenOrHasHiddenAncestor])
//		   [[self valueForKey:@"_composeHeaderView"] setPriorityFieldVisible:YES];
//	}
//
//	[self _updateFromAndSignatureControls];
//}
//
//- (void)changeHeaderField:(id)headerField {
//	NSString *headerKey = [self _headerKeyForView:headerField];
//	if(!headerKey)
//		return;
//
//	if([self valueForKey:@"_subjectField"] != headerField) {
//		NSString *attributedStringValue = [headerField attributedStringValue];
//		NSString *unatomicAddress = [attributedStringValue unatomicAddresses];
//		[[[self valueForKey:@"_documentEditor"] backEnd] setAddressList:unatomicAddress forHeader:headerKey];
//
//		if([self valueForKey:@"_toField"] != headerField && [self valueForKey:@"_ccField"] != headerField) {
//			if([self valueForKey:@"_bccField"] == headerField) {
//				[[self valueForKey:@"_documentEditor"] updateSendButtonStateInToolbar];
//				[self updateSecurityControls];
//				[self updatePresenceButtonState];
//			}
//			else
//				return;
//		}
//		else {
//			[[self valueForKey:@"_documentEditor"] updateSendButtonStateInToolbar];
//			[self updateSecurityControls];
//			[self updatePresenceButtonState];
//		}
//	}
//}
//
//- (void)changeFromHeader:(id)header {
//	ComposeBackEnd *backEnd = [[self valueForKey:@"_documentEditor"] backEnd]; // r15
//	NSString *title = [header titleOfSelectedItem];
//	if(title) {
//		NSString *sender = [backEnd sender];
//		[sender retain];
//		[backEnd setSender:title];
//		[self updateCcOrBccMyselfFieldWithSender:title oldSender:sender];
//		[sender release];
//		[self updateSecurityControls];
//		[self updateSignatureControlOverridingExistingSignature:YES];
//		[[self valueForKey:@"_documentEditor"] updateAttachmentStatus];
//	}
//	// And some more stuff which shall not be our concern currently.
//
//}
//
//- (void)updateSecurityControls {
//	ComposeBackEnd *backEnd = [[self valueForKey:@"_documentEditor"] backEnd];
//	NSArray *recipients = [backEnd allRecipients];
//	NSString *sender = [backEnd sender];
//    NSInvocation *invocation = [NSInvocation invocationWithSelector:@selector(_updateSecurityStateInBackgroundForRecipients:sender:) target:self object1:recipients	object2:sender];
//
//	[WorkerThread addInvocationToQueue:invocation];
//}
//
//- (void)_updateSecurityStateInBackgroundForRecipients:(id)recipients sender:(id)sender {
//	BOOL canSignFromAnyAccount = [self canSignFromAnyAccount];
//
//	BOOL canSignFromAddress = NO;
//	BOOL canEncryptFromAddress = NO;
//	if(canSignFromAnyAccount) {
//		ComposeBackEnd *backEnd = [[self valueForKey:@"_documentEditor"] backEnd];
//		canSignFromAddress = [backEnd canSignFromAddress:sender];
//		if(canSignFromAddress) {
//			canEncryptFromAddress = [backEnd canEncryptForRecipients:recipients sender:sender];
//		}
//	}
//	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
//		[[self valueForKey:@"_composeHeaderView"] setSecurityFieldEnabled:canSignFromAddress];
//		if(canSignFromAddress && canEncryptFromAddress) {
//			if(![[self valueForKey:@"_composeHeaderView"] securityFieldVisible]) {
//				[[self valueForKey:@"_signButton"] setImage:@"" forSegment:0];
//				[[self valueForKey:@"_encryptButton"] setImage:@"" forSegment:0];
//				[[self valueForKey:@"_signButton"] setEnabled:NO];
//				[[self valueForKey:@"_encryptButton"] setEnabled:NO];
//
//				[[[self valueForKey:@"_documentEditor"] backEnd] setSignIfPossible:NO];
//			}
//			else {
//				BOOL sign = (BOOL)[NSApp signOutgoingMessages]; // r15
//				BOOL encrypt = (BOOL)[NSApp encryptOutgoingMessages];
//
//				NSImage *signImage = nil; // some image.
//				NSImage *encryptImage = nil; // some other image.
//				if(sign) {
//					signImage = nil; // different image
//				}
//
//				[[self valueForKey:@"_signButton"] setImage:signImage forSegment:0];
//				[[self valueForKey:@"_signButton"] setEnabled:YES];
//				[[[self valueForKey:@"_documentEditor"] backEnd] setSignIfPossible:sign];
//
//				if(!canEncryptFromAddress) {
//					[[self valueForKey:@"_encryptButton"] setEnabled:canEncryptFromAddress];
//					[[self valueForKey:@"_encryptButton"] setImage:encryptImage forSegment:0];
//
//					[[[self valueForKey:@"_documentEditor"] backEnd] setEncryptIfPossible:NO];
//				}
//				else {
//					[[self valueForKey:@"_encryptButton"] setEnabled:YES];
//
//					NSImage *encryptImage = nil; // some image.
//					if(encrypt)
//						encryptImage = nil; // some other image.
//					[[self valueForKey:@"_encryptButton"] setImage:encryptImage forSegment:0];
//					[[[self valueForKey:@"_documentEditor"] backEnd] setEncryptIfPossible:encrypt];
//
//					[self _updateSignButtonTooltip];
//					[self _updateEncryptButtonTooltip];
//
//					[[self valueForKey:@"_documentEditor"] encryptionStatusDidChange];
//				}
//			}
//		}
//	}];
//}



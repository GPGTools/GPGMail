/*
 * Copyright (c) 2000-2012, GPGTools Project Team <gpgtools-devel@lists.gpgtools.org>
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

#import "NSObject+LPDynamicIvars.h"
#import "Message.h"
#import "GPGMailBundle.h"
#import "ComposeBackEnd.h"
#import "MailDocumentEditor.h"
#import "Message+GPGMail.h"
#import "ComposeBackEnd+GPGMail.h"
#import "GMSecurityControl.h"

@implementation GMSecurityControl

@synthesize control = _control, securityTag = _securityTag, forcedImageName = _forcedImageName;

- (id)initWithControl:(NSSegmentedControl *)control tag:(SECURITY_BUTTON_TAG)tag {
    if(self = [super init]) {
        self.control = control;
        self.securityTag = tag;
    }
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.control;
}

- (void)setEnabled:(BOOL)enabled {
    ComposeBackEnd *backEnd = [(MailDocumentEditor *)[[self.control target] valueForKey:@"_composeViewController"] backEnd];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    
    if(self.securityTag == SECURITY_BUTTON_SIGN_TAG) {
        enabled = [securityProperties[@"SignIsPossible"] boolValue];
    }
    else {
        enabled = [securityProperties[@"EncryptIsPossible"] boolValue];
        GPGMAIL_SECURITY_METHOD securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).guessedSecurityMethod;
        if(((ComposeBackEnd_GPGMail *)backEnd).securityMethod)
            securityMethod = ((ComposeBackEnd_GPGMail *)backEnd).securityMethod;
        if(securityMethod == GPGMAIL_SECURITY_METHOD_SMIME) {
            // Encrypt is for some reason only possible with S/MIME
            // if signing is also possible.
            enabled = enabled && [securityProperties[@"SignIsPossible"] boolValue];
        }
    }
    [self.control setEnabled:enabled];
}

- (void)setImage:(id)image forSegment:(NSInteger)segment {
    ComposeBackEnd *backEnd = [(MailDocumentEditor *)[[((NSSegmentedControl *)self.control) target] valueForKey:@"_composeViewController"] backEnd];
    NSDictionary *securityProperties = ((ComposeBackEnd_GPGMail *)backEnd).securityProperties;
    // forcedImageName is not nil if the user clicked on the control.
    // In that case always change the control to the forced image.
    // NEVER! ignore a user decision!
	// EXCEPT in the case that a user wanted to encrypt/sign but that is no longer
	// possible, due to missing pub keys or secret keys for recipients/sender.
    
	// Determines if the represented button could be enabled.
	// Basically, if this is the encrypt button, and EncryptIsPossible is true,
	// the enabled state is possible. Same goes for the sign button.
	BOOL enabledIsPossible = self.securityTag == SECURITY_BUTTON_ENCRYPT_TAG ? [securityProperties[@"EncryptIsPossible"] boolValue] : [securityProperties[@"SignIsPossible"] boolValue];
	if(self.forcedImageName) {
        // The force image should always be applied, unless it's not possible,
		// which is, when the enabled state is not possible, but the image would
		// show the enabled state.
		NSString *imageToForce = self.forcedImageName;
		if(([imageToForce isEqualToString:ENCRYPT_LOCK_LOCKED_IMAGE] || [imageToForce isEqualToString:SIGN_ON_IMAGE]) &&
		   !enabledIsPossible) {
			imageToForce = [self imageNameForOppositeOfImageName:self.forcedImageName];
		}
		[self.control setImage:[NSImage imageNamed:imageToForce] forSegment:0];
        return;
    }
	
    NSString *imageName = nil;
    
    if(self.securityTag == SECURITY_BUTTON_SIGN_TAG) {
        BOOL setSign = securityProperties[@"ForceSign"] ? [securityProperties[@"ForceSign"] boolValue] : [securityProperties[@"SetSign"] boolValue];
        if(setSign && ![securityProperties[@"SignIsPossible"] boolValue])
            setSign = NO;
        
        imageName = setSign ? SIGN_ON_IMAGE : SIGN_OFF_IMAGE;
    }
    else if(self.securityTag == SECURITY_BUTTON_ENCRYPT_TAG) {
        BOOL setEncrypt = securityProperties[@"ForceEncrypt"] ? [securityProperties[@"ForceEncrypt"] boolValue] : [securityProperties[@"SetEncrypt"] boolValue];
        
        if(setEncrypt && ![securityProperties[@"EncryptIsPossible"] boolValue])
            setEncrypt = NO;
        
        imageName = setEncrypt ? ENCRYPT_LOCK_LOCKED_IMAGE : ENCRYPT_LOCK_UNLOCKED_IMAGE;
    }
	
    [self.control setImage:[NSImage imageNamed:imageName] forSegment:0];
}

- (NSString *)imageNameForOppositeOfImageName:(NSString *)imageName {
	if([imageName isEqualToString:ENCRYPT_LOCK_LOCKED_IMAGE])
		return ENCRYPT_LOCK_UNLOCKED_IMAGE;
	if([imageName isEqualToString:ENCRYPT_LOCK_UNLOCKED_IMAGE])
		return ENCRYPT_LOCK_LOCKED_IMAGE;
	if([imageName isEqualToString:SIGN_ON_IMAGE])
		return SIGN_OFF_IMAGE;
	if([imageName isEqualToString:SIGN_OFF_IMAGE])
		return SIGN_ON_IMAGE;
	return nil;
}

- (void)updateStatusFromImage:(NSImage *)image {
    // setImage is gonna be called a lot of times from the HeadersEditor after
    // -[HeadersEditor securityControlChanged:] was received, but always tries
    // to change it to the old status (before the click).
    // That's why GPGMail forces the right image to be always set regardless from what the HeadersEditor
    // wants.
    ComposeBackEnd *backEnd = [(MailDocumentEditor *)[[((NSSegmentedControl *)self.control) target] valueForKey:@"_composeViewController"] backEnd];
    NSMutableDictionary *updatedSecurityProperties = [@{} mutableCopy];
    
    if(self.securityTag == SECURITY_BUTTON_SIGN_TAG) {
        self.forcedImageName = [[image name] isEqualToString:SIGN_OFF_IMAGE] ? SIGN_ON_IMAGE : SIGN_OFF_IMAGE;
        BOOL forceSign = NO;
        if([[image name] isEqualToString:SIGN_OFF_IMAGE])
            forceSign = YES;
        
        updatedSecurityProperties[@"ForceSign"] = @(forceSign);
    }
    else {
        self.forcedImageName = [[image name] isEqualToString:ENCRYPT_LOCK_UNLOCKED_IMAGE] ? ENCRYPT_LOCK_LOCKED_IMAGE : ENCRYPT_LOCK_UNLOCKED_IMAGE;
        BOOL forceEncrypt = NO;
        if([[image name] isEqualToString:ENCRYPT_LOCK_UNLOCKED_IMAGE])
            forceEncrypt = YES;
        updatedSecurityProperties[@"ForceEncrypt"] = @(forceEncrypt);
    }
    
    [(ComposeBackEnd_GPGMail *)backEnd updateSecurityProperties:updatedSecurityProperties];
}

@end

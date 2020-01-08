/* GPGMailBundle.h created by dave on Thu 29-Jun-2000 */
/* GPGMailBundle.h re-created by Lukas Pitschl (@lukele) on Fri 14-Jun-2013 */

/*
 * Copyright (c) 2000-2013, GPGTools Project Team <gpgtools-devel@lists.gpgtools.org>
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

#import <CoreFoundation/CoreFoundation.h>
#import <Libmacgpg/Libmacgpg.h>
#import "GMSupportPlanAssistantWindowController.h"

#import "GMSupportPlanManager.h"

#if !__has_feature(nullability)
#define nullable
#endif




extern NSString *GPGMailKeyringUpdatedNotification;
extern NSString *gpgErrorIdentifier; // This identifier is used to set and find GPGErrorCodes in NSData.

extern kGMSupportPlanManagerUpgradeState;

@class Message, GMMessageRulesApplier, GMKeyManager;

@interface GPGMailBundle : NSObject <NSToolbarDelegate, GMSupportPlanAssistantDelegate> {
    GMMessageRulesApplier *_messageRulesApplier;
    
    NSMutableArray *_bundleImages;
    
    dispatch_source_t _checkGPGTimer;
	
	GMKeyManager *_keyManager;
	
	BOOL accountExistsForSigning;
    BOOL _warnedAboutMissingPrivateKeys;
    
	GPGErrorCode gpgStatus;

    NSOperationQueue *_messageBodyDataLoadingQueue;
    NSCache *_messageBodyDataLoadingCache;
}

/**
 Checks for multiple installations of GPGMail.mailbundle in
 all Library folders.
 */
+ (NSArray *)multipleInstallations;

/**
 Warn the user that multiple installations were found and
 bail out.
 */
+ (void)showMultipleInstallationsErrorAndExit:(NSArray *)installations;

// Load all necessary images.
- (void)_loadImages;

// Returns the bundle version.
+ (NSString *)bundleVersion;
// Returns the string used for the x-pgp-agent message header.
+ (NSString *)agentHeader;

- (NSString *)version;
+ (BOOL)gpgMailWorks;
- (BOOL)gpgMailWorks;


/**
 Returns the NSBundle for GPGMail.
 It's a bit faster than [NSBundle bundleForClass:[self class]].
 */
+ (NSBundle *)bundle;


/**
 Return if we're running on Mountain Lion or not.
 */
+ (BOOL)isMountainLion;
+ (BOOL)isMavericks;
+ (BOOL)isYosemite;
+ (BOOL)isLion;
+ (BOOL)isElCapitan;
+ (BOOL)isSierra;
+ (BOOL)isHighSierra;
+ (BOOL)isMojave;
+ (BOOL)isCatalina;

/**
 Schedules a message which should have rules applied.
 While the app is running, each message should only have rules applied
 once. This is assured by performing the check if the message was already
 scheduled using a serial queue. The actual applying of the rules, is performed
 on the background.
 */
- (void)scheduleApplyingRulesForMessage:(Message *)message isEncrypted:(BOOL)isEncrypted;

/**
 See GMKeyManager.
 */
- (GPGKey *)anyPersonalPublicKeyWithPreferenceAddress:(NSString *)address;

/**
 Returns the secret key matching ID.
 */
- (GPGKey *)secretGPGKeyForKeyID:(NSString *)keyID;

/**
 Also includes disabled keys when looking for the secret key.
 */
- (GPGKey *)secretGPGKeyForKeyID:(NSString *)keyID includeDisabled:(BOOL)includeDisabled;

/**
 Returns the preferred secret GPG key.
 User can set this via gpg.conf
 */
- (GPGKey *)preferredGPGKeyForSigning;
/**
 Returns the key matching fingerprint.
 */
- (GPGKey *)keyForFingerprint:(NSString *)fingerprint;
/**
 Checks if MacGPG2 is installed and is properly working.
 */
- (BOOL)checkGPG;

/**
 Returns a list of public keys matching the given addresses.
 */
- (NSMutableSet *)publicKeyListForAddresses:(NSArray *)recipients;
/**
 Returns a list of secret keys matching the given addresses.
 */
- (NSMutableSet *)signingKeyListForAddress:(NSString *)sender;
/**
 Returns whether or not a message can be encrypted to an address.
 */
- (BOOL)canEncryptMessagesToAddress:(NSString *)address;
/**
 Returns whether or not a message can be signed from a given address.
 */
- (BOOL)canSignMessagesFromAddress:(NSString *)address;

+ (NSString *)localizedStringForKey:(NSString *)key;

/**
 On Mavericks most Mail classes have been prefixed.
 This method receives the old name and tries to find the matching
 new class.
 */
+ (Class)resolveMailClassFromName:(NSString *)name;

/**
 Returns the ComposeBackEnd which is linked to a given object.
 */
+ (id)backEndFromObject:(id)object;

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;

+ (NSString *)preferencesPanelName;

/**
 * Support contract methods
 */
- (void)checkSupportContractAndStartWizardIfNecessary;
- (void)startSupportContractWizard;
- (BOOL)hasActiveContract;
- (BOOL)hasActiveContractOrActiveTrial;
- (NSNumber *)remainingTrialDays;
- (void)deactivateSupportContract;


@property (readonly) GPGErrorCode gpgStatus;
@property (readonly, strong) NSSet *allGPGKeys;
@property (nonatomic, assign) BOOL accountExistsForSigning;

@property (readonly) NSOperationQueue *messageBodyDataLoadingQueue;
@property (readonly) NSCache *messageBodyDataLoadingCache;

@property (readonly) BOOL allowDecryptionOfPotentiallyDangerousMessagesWithoutMDC;
@property (readonly) BOOL shouldNotConvertPGPPartitionedMessages;

- (void)startSupportContractWizardWithActivationCode:(NSString *)activationCode email:(NSString *)email;

@end

@interface GPGMailBundle (NoImplementation)
// Prevent "incomplete implementation" warning.
+ (id)sharedInstance;
@end



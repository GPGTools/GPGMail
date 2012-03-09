/* GPGMailBundle.m created by dave on Thu 29-Jun-2000 */

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

#import <objc/objc.h>
#import <objc/objc-class.h>
#import <dispatch/dispatch.h>
#import <ExceptionHandling/ExceptionHandling.h>
#import <Sparkle/Sparkle.h>
#import <Libmacgpg/Libmacgpg.h>
#import <MailApp.h>
#import <MailAccount.h>
#import "JRLPSwizzle.h"
#import "CCLog.h"
#import "NSSet+Functional.h"
#import "NSString+GPGMail.h"
//#import "GPGDefaults.h"
#import "GPGMailPreferences.h"
#import "GPGMailBundle.h"
#import "GPGVersionComparator.h"


NSString *GPGMailSwizzledMethodPrefix = @"MA";
NSString *GPGMailAgent = @"GPGMail %@";
NSString *GPGMailKeyringUpdatedNotification = @"GPGMailKeyringUpdatedNotification";
NSString *gpgErrorIdentifier = @"^~::gpgmail-error-code::~^";


int GPGMailLoggingLevel = 1;

static BOOL gpgMailWorks = NO;

@interface GPGMailBundle ()
@property (nonatomic, retain) SUUpdater *updater;
@property GPGErrorCode gpgStatus;
- (void)updateGPGKeys:(NSObject <EnumerationList> *)keys;
@end

// Remove registerBundle warning.
@interface NSObject (GPGMail)
- (void)registerBundle;
@end

@implementation GPGMailBundle

@synthesize publicGPGKeys, secretGPGKeys, allGPGKeys, updater, accountExistsForSigning, secretGPGKeysByEmail = _secretGPGKeysByEmail, 
            publicGPGKeysByEmail = _publicGPGKeysByEmail, gpgc, publicGPGKeysByID = _publicGPGKeysByID, disabledGroups = _disabledGroups,
            disabledUserMappedKeys = _disabledUserMappedKeys, gpgStatus, bundleImages = _bundleImages;

/**
 This method replaces all of Mail's methods which are necessary for GPGMail
 to work correctly.
 
 For each class of Mail that must be extended, a class with the same name
 and suffix _GPGMail (<ClassName>_GPGMail) exists which implements the methods
 to be relaced.
 On runtime, these methods are first added to the original Mail class and
 after that, the original Mail methods are swizzled with the ones of the
 <ClassName>_GPGMail class.
 
 swizzleMap contains all classes and methods which need to be swizzled.
 */
- (void)_installGPGMail {
    //	DebugLog(@"Adding GPGMail methods");
    NSArray *swizzleMap = [NSArray arrayWithObjects:
                           // Mail internal classes.
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MessageHeaderDisplay", @"class",
                            @"MessageHeaderDisplay_GPGMail", @"gpgMailClass",
                            [NSArray arrayWithObjects:
                             @"_attributedStringForSecurityHeader",
                             @"textView:clickedOnLink:atIndex:", nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"ComposeBackEnd", @"class",
                            @"ComposeBackEnd_GPGMail", @"gpgMailClass",
                            [NSArray arrayWithObjects:
                             @"_makeMessageWithContents:isDraft:shouldSign:shouldEncrypt:shouldSkipSignature:shouldBePlainText:",
                             @"canEncryptForRecipients:sender:",
                             @"canSignFromAddress:",
                             @"recipientsThatHaveNoKeyForEncryption",
                             @"setEncryptIfPossible:",
                             @"setSignIfPossible:", 
                             @"_saveThreadShouldCancel", 
                             nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"HeadersEditor", @"class",
                            @"HeadersEditor_GPGMail", @"gpgMailClass",
                            [NSArray arrayWithObjects:
                             @"securityControlChanged:", 
                             @"_updateFromAndSignatureControls:", 
                             @"changeFromHeader:", 
                             @"init", 
                             @"dealloc",
                             @"_updateSecurityStateInBackgroundForRecipients:sender:", 
                             @"awakeFromNib",
                             @"_updateSignButtonTooltip",
                             @"_updateEncryptButtonTooltip",
                             nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MessageAttachment", @"class",
                            @"MessageAttachment_GPGMail", @"gpgMailClass",
                            [NSArray arrayWithObjects:
                             @"filename", nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MailDocumentEditor", @"class",
                            @"MailDocumentEditor_GPGMail", @"gpgMailClass",
                            [NSArray arrayWithObjects:
                             @"backEndDidLoadInitialContent:",
                             @"dealloc",
//                             @"windowForMailFullScreen",
                             @"backEnd:didCancelMessageDeliveryForEncryptionError:",
                             nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"NSWindow", @"class",
                            [NSArray arrayWithObjects:
                             @"toggleFullScreen:",
                             nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MessageContentController", @"class",
                            @"MessageContentController_GPGMail", @"gpgMailClass",
                            [NSArray arrayWithObjects:
                             @"setMessageToDisplay:",
                              nil], @"selectors", nil],
                           // Messages.framework classes. Messages.framework classes can be extended using
                           // categories. No need for a special GPGMail class.
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MimePart", @"class",
                            [NSArray arrayWithObjects:
                             @"isEncrypted",
                             @"newEncryptedPartWithData:recipients:encryptedData:",
                             @"newSignedPartWithData:sender:signatureData:",
                             @"verifySignature",
                             @"decodeWithContext:",
                             @"decodeTextPlainWithContext:",
                             @"decodeTextHtmlWithContext:",
                             @"decodeApplicationOctet_streamWithContext:",
                             @"isSigned",
                             @"isMimeSigned",
                             @"isMimeEncrypted",
                             @"usesKnownSignatureProtocol",
                             @"clearCachedDecryptedMessageBody",
                             nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MimeBody", @"class",
                            [NSArray arrayWithObjects:
                             @"isSignedByMe",
                             @"_isPossiblySignedOrEncrypted", nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"MailAccount", @"class",
                            [NSArray arrayWithObjects:
                             @"accountExistsForSigning", nil], @"selectors", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:
                            @"NSPreferences", @"class",
                            [NSArray arrayWithObjects:
                             @"sharedPreferences",
                             @"windowWillResize:toSize:",
                             @"toolbarItemClicked:",
                             @"showPreferencesPanelForOwner:", nil], @"selectors", nil],
                           nil];
    
    
    NSError *error = nil;
    for(NSDictionary *swizzleInfo in swizzleMap) {
        // If this is a non Messages.framework class, add all methods
        // of the class referenced in gpgMailClass first.
        Class mailClass = NSClassFromString([swizzleInfo objectForKey:@"class"]);
        if([swizzleInfo objectForKey:@"gpgMailClass"]) {
            Class gpgMailClass = NSClassFromString([swizzleInfo objectForKey:@"gpgMailClass"]);
            if(!mailClass) {
                DebugLog(@"WARNING: Class %@ doesn't exist. GPGMail might behave weirdly!", [swizzleInfo objectForKey:@"class"]);
                continue;
            }
            if(!gpgMailClass) {
                DebugLog(@"WARNING: Class %@ doesn't exist. GPGMail might behave weirdly!", [swizzleInfo objectForKey:@"gpgMailClass"]);
                continue;
            }
            [mailClass jrlp_addMethodsFromClass:gpgMailClass error:&error];
            if(error)
                DebugLog(@"[DEBUG] %s Error: %@", __PRETTY_FUNCTION__, error);
            error = nil;
        }
        for(NSString *method in [swizzleInfo objectForKey:@"selectors"]) {
            error = nil;
            NSString *gpgMethod = [NSString stringWithFormat:@"%@%@%@", GPGMailSwizzledMethodPrefix, [[method substringToIndex:1] uppercaseString], [method substringFromIndex:1]];
            [mailClass jrlp_swizzleMethod:NSSelectorFromString(method) withMethod:NSSelectorFromString(gpgMethod) error:&error];
            if(error) {
                error = nil;
                // Try swizzling as class method on error.
                [mailClass jrlp_swizzleClassMethod:NSSelectorFromString(method) withClassMethod:NSSelectorFromString(gpgMethod) error:&error];
                if(error)
                    DebugLog(@"[DEBUG] %s Class Error: %@", __PRETTY_FUNCTION__, error);
            }
        }
    }
    
}

+ (void)initialize {
	// Make sure the initializer is only run once.
    // Usually is run, for every class inheriting from
    // GPGMailBundle.
    if(self != [GPGMailBundle class])
        return;
    
    Class mvMailBundleClass = NSClassFromString(@"MVMailBundle");
    // If this class is not available that means Mail.app
    // doesn't allow plugins anymore. Fingers crossed that this
    // never happens!
    if(!mvMailBundleClass)
        return;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated"
    class_setSuperclass([self class], mvMailBundleClass);
#pragma GCC diagnostic pop
	// Initialize the bundle by swizzling methods, loading keys, ...
    GPGMailBundle *instance = [GPGMailBundle sharedInstance];
    NSLog(@"Loaded GPGMail %@", [instance version]);
    
    [((MVMailBundle *)[self class]) registerBundle];             // To force registering composeAccessoryView and preferences
}

/**
 * Loads all images which are used in the GPGMail User interface.
 */
- (void)_loadImages {
    // We need to load images and name them, because all images are searched by their name; as they are not located in the main bundle,
	// +[NSImage imageNamed:] does not find them.
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    
    // Use something else then NSArray which only retains value. CFArray for example.
    NSMutableArray *bundleImages = [[NSMutableArray alloc] init];
    NSDictionary *bundleImageMap = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"encrypted", @"gpgEncrypted",
                                    @"clear", @"gpgClear",
                                    @"signed", @"gpgSigned",
                                    @"unsigned", @"gpgUnsigned",
                                    @"GPGMail", @"GPGMail",
                                    @"MacGPG", @"MacGPG",
                                    @"GPGMail32", @"GPGMail32",
                                    @"GPGMailPreferences", @"GPGMailPreferences",
                                    @"questionMark", @"gpgQuestionMark",
                                    @"SmallAlert12", @"gpgSmallAlert12",
                                    @"SmallAlert16", @"gpgSmallAlert16",
                                    @"EmptyImage", @"gpgEmptyImage",
                                    @"ValidBadge", @"gpgValidBadge",
                                    @"InvalidBadge", @"gpgInvalidBadge",
                                    @"encryption_unlocked", @"decryptedBadge",
                                    @"invalid-signature-icon-overlay", @"invalid-signature-icon-overlay",
                                    @"GreenDot", @"GreenDot",
                                    @"YellowDot", @"YellowDot",
                                    @"RedDot", @"RedDot",
                                    @"menu-arrow", @"MenuArrow",
                                    @"menu-arrow-white", @"MenuArrowWhite", nil];
    
    for(NSString *name in bundleImageMap) {
        NSString *imageName = [bundleImageMap valueForKey:name];
        NSImage *image = [[NSImage alloc] initByReferencingFile:[myBundle pathForImageResource:imageName]];
        // Shoud an image not exist, log a warning, but don't crash because of inserting
        // nil!
        if(!image) {
            NSLog(@"GPGMail: Image %@ not found in bundle resources.", imageName);
            continue;
        }
        [image setName:name];
        [bundleImages addObject:image];
        [image release];
    }
    
    self.bundleImages = bundleImages;
    
    [bundleImages release];
}

+ (BOOL)hasPreferencesPanel {
	return YES;             // LEOPARD Invoked on +initialize. Else, invoked from +registerBundle
}

+ (NSString *)preferencesOwnerClassName {
	return NSStringFromClass([GPGMailPreferences class]);
}

+ (NSString *)preferencesPanelName {
	return NSLocalizedStringFromTableInBundle(@"PGP_PREFERENCES", @"GPGMail", [NSBundle bundleForClass:self], "PGP preferences panel name");
}

/**
 Installs the sparkle updater.
 TODO: Sparkle should automatically start to check, but sometimes it doesn't work.
 */
- (void)_installSparkleUpdater {
    SUUpdater *sparkleUpdater = [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
	sparkleUpdater.delegate = self;
	[sparkleUpdater resetUpdateCycle];
    self.updater = sparkleUpdater;
}

- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater {
	return @"/Applications/Mail.app";
}

- (id <SUVersionComparison>)versionComparatorForUpdater:(SUUpdater *)updater {
    return [GPGVersionComparator sharedVersionComparator];
}


/**
 Allows to run one decryption task at a time.
 This is necessary to ensure that pinentry password requests
 are not displayed concurrently.
 */
- (void)addDecryptionTask:(gpgmail_decryption_task_t)task {
    dispatch_sync(decryptionQueue, task);
}

- (void)addVerificationTask:(gpgmail_verification_task_t)task {
    dispatch_sync(verificationQueue, task);
}

- (void)addCollectionTask:(gpgmail_verification_task_t)task {
    dispatch_sync(verificationQueue, task);
}


+ (BOOL)gpgMailWorks {
	return gpgMailWorks;
}
- (BOOL)gpgMailWorks {
	return gpgMailWorks;
}


- (BOOL)checkGPG {
    self.gpgStatus = (GPGErrorCode)[GPGController testGPG];
    switch (gpgStatus) {
        case GPGErrorNotFound:
            DebugLog(@"DEBUG: checkGPG - GPGErrorNotFound");
            break;
        case GPGErrorConfigurationError:
            DebugLog(@"DEBUG: checkGPG - GPGErrorConfigurationError");
        case GPGErrorNoError:
            return YES;
        default:
            DebugLog(@"DEBUG: checkGPG - %i", gpgStatus);
            break;
    }
    return NO;
}

- (void)finishInitialization {
    // Create the decryption queue.
    decryptionQueue = dispatch_queue_create("org.gpgmail.decryption", NULL);
    verificationQueue = dispatch_queue_create("org.gpgmail.verification", NULL);
    collectingQueue = dispatch_queue_create("org.gpgmail.collection", NULL);
    keysUpdateQueue = dispatch_queue_create("org.gpgmail.update", DISPATCH_QUEUE_CONCURRENT);
    
    // Init GPGController.
    [self gpgc];
    
    // Swizzling the Mail classes.
    [self _installGPGMail];
    // Load all necessary images.
    [self _loadImages];
    // Install the Sparkle Updater.
    [self _installSparkleUpdater];
    
    self.accountExistsForSigning = YES;
}

- (id)init {
	if (self = [super init]) {
		NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
		NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:[myBundle pathForResource:@"GPGMailBundle" ofType:@"defaults"]];
        
        [[GPGOptions sharedOptions] setStandardDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
		if (defaultsDictionary) {
			[[GPGOptions sharedOptions] registerDefaults:defaultsDictionary];
		}
        
        GPGMailLoggingLevel = [[GPGOptions sharedOptions] integerForKey:@"DebugLog"];
        NSLog(@"Debug Log enabled: %@", [[GPGOptions sharedOptions] integerForKey:@"DebugLog"] > 0 ? @"YES" : @"NO");
        
        gpgMailWorks = [self checkGPG];
        [self finishInitialization];

	}
    
	return self;
}

- (void)dealloc {
    // Release the dispatch queues.
    dispatch_release(decryptionQueue);
    dispatch_release(verificationQueue);
    dispatch_release(collectingQueue);
    dispatch_release(keysUpdateQueue);
    
    self.bundleImages = nil;
    self.secretGPGKeys = nil;
    self.publicGPGKeys = nil;
    self.secretGPGKeysByEmail = nil;
    self.publicGPGKeysByEmail = nil;
    self.updater = nil;
    [gpgc release];
    gpgc = nil;
    [updateLock release];
    updateLock = nil;
    [allGPGKeys release];
    allGPGKeys = nil;
    [_bundleImages release];
    _bundleImages = nil;
    
	//[locale release];

	struct objc_super s = { self, [self superclass] };
    objc_msgSendSuper(&s, @selector(dealloc));

    // Suppress the missing dealloc warning, since the real super dealloc
    // call uses the objc runtime calls directly.
    if(0)
        [super dealloc];
}

- (NSString *)versionDescription {
	return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"VERSION: %@", @"GPGMail", [NSBundle bundleForClass:[self class]], "Description of version prefixed with <Version: >"), [self version]];
}

- (NSString *)buildNumberDescription {
    return [NSString stringWithFormat:@"Build: %@", [[self class] bundleBuildNumber]];
}

- (NSString *)version {
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

/* Set: use OpenPGP to send messages */
- (void)setUsesOpenPGPToSend:(BOOL)flag {
	[[GPGOptions sharedOptions] setBool:flag forKey:@"UseOpenPGPToSend"];
}

/* Get: use OpenPGP to send messages */
- (BOOL)usesOpenPGPToSend {
	return [[GPGOptions sharedOptions] boolForKey:@"UseOpenPGPToSend"];
}

/* Set: use OpenPGP to receive messages */
- (void)setUsesOpenPGPToReceive:(BOOL)flag {
	[[GPGOptions sharedOptions] setBool:flag forKey:@"UseOpenPGPToReceive"];
}

/* Get: use OpenPGP to receive messages */
- (BOOL)usesOpenPGPToReceive {
	return [[GPGOptions sharedOptions] boolForKey:@"UseOpenPGPToReceive"];
}

- (void)setWarnedAboutMissingPrivateKeys:(BOOL)flag {
    [[GPGOptions sharedOptions] setBool:flag forKey:@"WarnAboutMissingPrivateKeys"];
}

- (BOOL)warnedAboutMissingPrivateKeys {
    return [[GPGOptions sharedOptions] boolForKey:@"WarnAboutMissingPrivateKeys"];
}

- (void)warnUserForMissingPrivateKeys:(id)sender {
	NSBundle *aBundle = [NSBundle bundleForClass:[self class]];
	NSString *aTitle = NSLocalizedStringFromTableInBundle(@"NO PGP PRIVATE KEY - TITLE", @"GPGMail", aBundle, "");
	NSString *aMessage = NSLocalizedStringFromTableInBundle(@"NO PGP PRIVATE KEY - MESSAGE", @"GPGMail", aBundle, "");
    
	(void)NSRunAlertPanel(aTitle, @"%@", nil, nil, nil, aMessage);
	[self setWarnedAboutMissingPrivateKeys:YES];
}

- (BOOL)canSignMessagesFromAddress:(NSString *)address {
    GPGKey *key = [self.secretGPGKeysByEmail valueForKey:[address gpgNormalizedEmail]];
    return (key != nil);
}

- (BOOL)canEncryptMessagesToAddress:(NSString *)address {
    GPGKey *key = [self.publicGPGKeysByEmail objectForKey:[address gpgNormalizedEmail]];
    return (key != nil);
}

- (NSMutableSet *)publicKeyListForAddresses:(NSArray *)recipients {
    NSMutableSet *keyList = [NSMutableSet setWithCapacity:[recipients count]];
    id tmpKey;
    for(NSString *recipient in recipients) {
        recipient = [recipient gpgNormalizedEmail];
        tmpKey = [self.publicGPGKeysByEmail objectForKey:recipient];
        if (tmpKey)
            [keyList addObject:tmpKey];
    }
    return keyList;
}

- (NSSet *)signingKeyListForAddress:(NSString *)sender {
    return [self.secretGPGKeysByEmail objectForKey:[sender gpgNormalizedEmail]];
}

- (GPGController *)gpgc {
    if (!gpgMailWorks) return nil;
    if (!gpgc) {
        updateLock = [NSLock new];
        gpgc = [[GPGController alloc] init];
        gpgc.verbose = NO; //(GPGMailLoggingLevel > 0);
        gpgc.delegate = self;
        
        [self allGPGKeys];
    }
    return gpgc;
}

- (void)gpgController:(GPGController *)gpgc keysDidChanged:(NSObject<EnumerationList> *)keys external:(BOOL)external {
    dispatch_async(keysUpdateQueue, ^(void) {
        [self updateGPGKeys:keys];
    });
}

- (void)updateGPGKeys:(NSObject <EnumerationList> *)keys {
    if (!gpgMailWorks) return;
    
	if (![updateLock tryLock])
		return;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@try {
		NSMutableSet *realKeys = [NSMutableSet setWithCapacity:[keys count]];
		
		//Fingerabdrücke wenn möglich durch die entsprechenden Schlüssel ersetzen.
		Class keyClass = [GPGKey class];
		for (GPGKey *key in keys) {
			if (![key isKindOfClass:keyClass]) {
				GPGKey *tempKey = [allGPGKeys member:key];
				if (tempKey) {
					key = tempKey;
				}
			}
			[realKeys addObject:key];
		}
		keys = realKeys;
        
		
		NSSet *updatedKeys;
		if ([keys count] == 0) {
            //Update all keys.
            // Don't use self.gpgc here, since that calls allKeys which stalls
            // if it didn't complete once.
			updatedKeys = [gpgc updateKeys:allGPGKeys searchFor:nil withSigs:NO];
		} else {
            //Update only the keys in 'keys'.
			// Don't use self.gpgc here, since that calls allKeys which stalls
            // if it didn't complete once.
            updatedKeys = [gpgc updateKeys:keys withSigs:NO];
		}
        
        if (gpgc.error) {
			@throw gpgc.error;
		}
		
		if ([keys count] == 0) {
			keys = allGPGKeys;
		}
		NSMutableSet *keysToRemove = [keys mutableCopy];
		[keysToRemove minusSet:updatedKeys];
		
        [allGPGKeys minusSet:keysToRemove];
        [allGPGKeys unionSet:updatedKeys];

        [keysToRemove release];
        keysToRemove = nil;

        //Flush caches.
        self.secretGPGKeys = nil;
        self.publicGPGKeys = nil;
        self.secretGPGKeysByEmail = nil;
        self.publicGPGKeysByEmail = nil;
        
	} @catch (GPGException *e) {
		DebugLog(@"updateGPGKeys: failed - %@ (ErrorText: %@)", e, e.gpgTask.errText);
	} @catch (NSException *e) {
		DebugLog(@"updateGPGKeys: failed - %@", e);
	} @finally {
		[pool drain];
		[updateLock unlock];
	}
	
    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] postNotificationName:GPGMailKeyringUpdatedNotification object:self];
}


/**
 Create a map for the gpg keys which can be accessed by using
 an email address.
 All email addresses of user ids are taking into consideration.
 */
- (NSMutableDictionary *)emailMapForGPGKeys:(NSSet *)keys allowDuplicates:(BOOL)allowDuplicates {
    NSMutableDictionary *keyEmailMap = [NSMutableDictionary dictionary];
    for(GPGKey *key in keys) {
        // TODO:
        NSString *email;
        for(GPGUserID *userID in [key userIDs]) {
            email = [[userID email] gpgNormalizedEmail];
            if(!email)
                continue;
            if(allowDuplicates) {
                if(![keyEmailMap objectForKey:email]) {
                    NSMutableSet *set = [[NSMutableSet alloc] init];
                    [keyEmailMap setObject:set forKey:email];
                    [set release];
                }
                [[keyEmailMap valueForKey:email] addObject:key];
            }
            else {
                if(![keyEmailMap objectForKey:email])
                    [keyEmailMap setObject:key forKey:email];
            }
        }
    }
    return keyEmailMap;
}


- (NSSet *)allGPGKeys {
    if (!gpgMailWorks) return nil;
    
    static dispatch_once_t onceQueue;
    
    dispatch_once(&onceQueue, ^{
        allGPGKeys = [[NSMutableSet alloc] init];
        [self updateGPGKeys:nil];
    });
    
    return allGPGKeys;
}

- (NSSet *)secretGPGKeys {
    if(!gpgMailWorks)
        return nil;
    
    if(!secretGPGKeys) {
        self.secretGPGKeys = [[self allGPGKeys] filter:^(id obj) {
            return ((GPGKey *)obj).secret && [self canKeyBeUsedForSigning:obj] ? obj : nil;
        }];
        
        if ([secretGPGKeys count] == 0 && ![self warnedAboutMissingPrivateKeys]) {
			[self performSelector:@selector(warnUserForMissingPrivateKeys:) withObject:nil afterDelay:0];
		}
    }
    
    return secretGPGKeys;
}

- (NSSet *)publicGPGKeys {
    if(!gpgMailWorks)
        return nil;
    
    if(!publicGPGKeys) {
        NSSet *publicKeys = [[self allGPGKeys] filter:^(id obj) {
            return [self canKeyBeUsedForEncryption:obj] ? obj : nil;
        }];
        NSSet *cleanPublicKeys = [self sanitizedPublicGPGKeys:publicKeys];
        self.publicGPGKeys = cleanPublicKeys;
    }
    
    return publicGPGKeys;
}

- (NSDictionary *)secretGPGKeysByEmail {
    if(!_secretGPGKeysByEmail) {
        self.secretGPGKeysByEmail = [self emailMapForGPGKeys:self.secretGPGKeys allowDuplicates:YES];
    }
    return _secretGPGKeysByEmail;
}

- (NSSet *)sanitizedPublicGPGKeys:(NSSet *)publicKeys {
    // 1.) Create a dictionary with all user ids mapped by email address.
    NSMutableDictionary *userIDEmailMap = [[NSMutableDictionary alloc] init];
    for(GPGKey *key in publicKeys) {
        // PrimaryUserID.
        NSString *email;
        for(GPGUserID *userID in [key userIDs]) {
            email = [[userID email] gpgNormalizedEmail];
            if(!email)
                continue;
            
            if(![userIDEmailMap objectForKey:email]) {
                NSMutableSet *set = [[NSMutableSet alloc] initWithCapacity:0];
                [userIDEmailMap setObject:set forKey:email];
                [set release];
            }
            [[userIDEmailMap objectForKey:email] addObject:userID];
        }
    }
    NSMutableSet *cleanKeys = [NSMutableSet setWithCapacity:0]; 
    // 2.) Loop through the whole map, skip any entry which doesn't have multiple entries.
    
    for(id email in userIDEmailMap) {
        if([(NSMutableSet *)[userIDEmailMap objectForKey:email] count] == 1) {
            GPGKey *key = ((GPGKey *)[(NSMutableSet *)[userIDEmailMap objectForKey:email] anyObject]).primaryKey;
            [cleanKeys addObject:key];
            continue;
        }
        GPGKey *bestKey = [self bestKeyOfUserIDs:[userIDEmailMap objectForKey:email]];
        [cleanKeys addObject:bestKey];
    }
    
    [userIDEmailMap release];
    
    return cleanKeys;
}

- (GPGKey *)bestKeyOfUserIDs:(NSSet *)userIDs {
    // First check if any trusted keys are in there, if so, sort them by date.
    NSMutableArray *trustedUserIDs = [[NSMutableArray alloc] init];
    NSMutableArray *untrustedUserIDs = [[NSMutableArray alloc] init];
    for(GPGUserID *userID in userIDs) {
        if(userID.validity >= 3)
            [trustedUserIDs addObject:userID];
        else
            [untrustedUserIDs addObject:userID];
    }
    
    NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO comparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSDate *)obj1 compare:obj2];
    }];
    
    NSArray *sortedUserIDs = nil;
    if([trustedUserIDs count])
        sortedUserIDs = [trustedUserIDs sortedArrayUsingDescriptors:[NSArray arrayWithObjects:dateSorter, nil]];
    else
        sortedUserIDs = [untrustedUserIDs sortedArrayUsingDescriptors:[NSArray arrayWithObjects:dateSorter, nil]];

    [dateSorter release];
    [trustedUserIDs release];
    [untrustedUserIDs release];
    
    return ((GPGUserID *)[sortedUserIDs objectAtIndex:0]).primaryKey;
}

- (NSDictionary *)publicGPGKeysByEmail {
    if(!_publicGPGKeysByEmail) {
        NSMutableDictionary *keysByEmail = [self emailMapForGPGKeys:self.publicGPGKeys allowDuplicates:NO];
        [keysByEmail addEntriesFromDictionary:[self userMappedKeys]];
        [keysByEmail addEntriesFromDictionary:[self groups]];
        self.publicGPGKeysByEmail = keysByEmail;
    }
    return _publicGPGKeysByEmail;
}

- (NSDictionary *)publicGPGKeysByID {
    if(!_publicGPGKeysByID) {
        NSMutableDictionary *idMap = [[NSMutableDictionary alloc] initWithCapacity:0];
        for(GPGKey *key in self.publicGPGKeys) {
            [idMap setValue:key forKey:key.keyID];
            for(GPGKey *subkey in key.subkeys)
                [idMap setValue:subkey forKey:subkey.keyID];
        }
        self.publicGPGKeysByID = idMap;
        [idMap release];
    }
    return _publicGPGKeysByID;
}

- (NSDictionary *)userMappedKeys {
    NSDictionary *mappedKeys = [[GPGOptions sharedOptions] valueInCommonDefaultsForKey:@"PublicKeyUserMap"];
    NSMutableDictionary *cleanMappedKeys = [NSMutableDictionary dictionary]; 
    NSMutableArray *disabledUserMappedKeys = [NSMutableArray array];
    for(id email in mappedKeys) {
        
        NSString *fingerprint = [mappedKeys objectForKey:email];
        GPGKey *key = [self findPublicKeyByKeyHint:fingerprint];
        if(key)
            [cleanMappedKeys setObject:key forKey:[email gpgNormalizedEmail]];
        else
            [disabledUserMappedKeys addObject:[email gpgNormalizedEmail]];
    }   
    
    self.disabledUserMappedKeys = disabledUserMappedKeys;
    
    return cleanMappedKeys;
}

- (NSDictionary *)groups {
    NSDictionary *groups = [[GPGOptions sharedOptions] valueForKey:@"group"];
    NSMutableDictionary *cleanGroups = [NSMutableDictionary dictionary]; 
    NSMutableArray *disabledGroups = [NSMutableArray array];
    for(id email in groups) {
        NSArray *keyHints = [groups objectForKey:email];
        BOOL allKeysValid = YES;
        NSMutableSet *keys = [NSMutableSet set];
        for(NSString *keyHint in keyHints) {
            GPGKey *key = [self findPublicKeyByKeyHint:keyHint];
            if(!key) {
                allKeysValid = NO;
                break;
            }
            [keys addObject:key];
        }
        if(allKeysValid)
            [cleanGroups setObject:keys forKey:[email gpgNormalizedEmail]];
        else
            [disabledGroups addObject:[email gpgNormalizedEmail]];
    }
    
    self.disabledGroups = disabledGroups;
    
    return cleanGroups;
}

- (GPGKey *)findPublicKeyByKeyHint:(NSString *)hint {
    GPGKey *foundKey = nil;
    if(!hint)
        return nil;
    for(GPGKey *key in self.publicGPGKeys) {
        if([key.textForFilter rangeOfString:hint].location != NSNotFound) {
            foundKey = key;
            break;
        }
    }
    return foundKey;
}

- (GPGKey *)findSecretKeyByKeyHint:(NSString *)hint {
    GPGKey *foundKey = nil;
    if(!hint)
        return nil;
    for(GPGKey *key in self.secretGPGKeys) {
        if([key.textForFilter rangeOfString:hint].location != NSNotFound) {
            foundKey = key;
            break;
        }
    }
    return foundKey;
}


- (BOOL)canKeyBeUsedForEncryption:(GPGKey *)key {
	// Only either the key or one of the subkeys has to be valid,
    // non-expired, non-disabled, non-revoked and be used for encryption.
    // We don't care about ownerTrust, validity
	return key.canAnyEncrypt && key.status < GPGKeyStatus_Invalid;
}

// TODO: Public key might not be available... how can this be?
- (BOOL)canKeyBeUsedForSigning:(GPGKey *)key {
	// Only either the key or one of the subkeys has to be valid,
    // non-expired, non-disabled, non-revoked and be used for encryption.
    // We don't care about ownerTrust, validity
	return key.canAnySign && key.status < GPGKeyStatus_Invalid;
}

- (id)locale {
    //    return [NSLocale autoupdatingCurrentLocale]; // FIXME: does not work as expected
	return [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
}

/**
 Returns the version of the bundle as string.
 */
+ (NSString *)bundleVersion {
    return [[[NSBundle bundleForClass:self] infoDictionary]
            valueForKey:@"CFBundleVersion"];
}

+ (NSNumber *)bundleBuildNumber {
    return [[[NSBundle bundleForClass:self] infoDictionary] valueForKey:@"BuildNumber"];
}

+ (NSString *)agentHeader {
    return [NSString stringWithFormat:GPGMailAgent, [self bundleVersion]];
}

@end

/* GPGMailBundle.m completely re-created by Lukas Pitschl (@lukele) on Thu 13-Jun-2013 */
/*
 * Copyright (c) 2000-2016, GPGTools Project Team <gpgtools-devel@lists.gpgtools.org>
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

#import <mach-o/getsect.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <Libmacgpg/Libmacgpg.h>
#import <Libmacgpg/GPGTaskHelperXPC.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "CCLog.h"
#import "JRLPSwizzle.h"
#import "GMCodeInjector.h"
#import "GMKeyManager.h"
#import "GMMessageRulesApplier.h"
#import "GPGMailBundle.h"
#import "GPGMailPreferences.h"
#import "MVMailBundle.h"
#import "NSString+GPGMail.h"
#import "HeadersEditor+GPGMail.h"
#import "GMSecurityControl.h"
#import "ComposeViewController.h"

#import "GMSupportPlanManager.h"
#import "GMSupportPlan.h"
#import "GMLoaderUpdater.h"

#import "PlugInsViewController.h"
#import "MailBundle.h"

#import "NSArray+Functional.h"

@interface PlugInsViewController_GPGMail : NSObject

@end

@implementation PlugInsViewController_GPGMail

- (void)MAViewWillAppear {
    [self MAViewWillAppear];

    // To facilitate a GPG Mail Loader update without asking the user
    // to re-activate it, two GPG Mail Loaders will be installed in parallel.
    // The user however should never see two loaders, since that would be confusing.
    // In order to make sure that only one is ever visible, all other GPG Mail Loaders
    // are hidden and only the active ones is shown.
    NSArray *bundlesToRemainVisible = [[self valueForKey:@"_bundles"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(MailBundle *mailBundle, __unused NSDictionary<NSString *,id> * _Nullable bindings) {
        return ![GMLoaderUpdater isLoaderBundle:mailBundle] || [mailBundle state] == 2;
    }]];

    [self setValue:bundlesToRemainVisible forKey:@"_bundles"];
    [[self valueForKey:@"_tableView"] reloadData];
    [(PlugInsViewController *)self _updateApplyButton];
}

@end

#import "NSObject+LPDynamicIvars.h"
@interface CertificateBannerViewController_GPGMail : NSObject

@end

#import "MUIWebDocument.h"
#import "WebDocumentGenerator.h"

@interface CertificateBannerViewController_GPGMail (NotImplemented)

- (id)webDocument;
- (NSError *)parseError;
- (void)setWantsDisplay:(BOOL)wantsDisplay;

@end

@implementation CertificateBannerViewController_GPGMail

- (void)MAUpdateWantsDisplay {
    // By default Mail.app only displays the error if it's a verification error.
    // GPGMail however wants to display any error found during verification or decryption.
    // In order to do that, if an error is found on the security properties of the
    // message, it will force the error to be shown, regardless of error code (which is used by Mail's updateWantsDisplay to determine whether or not to show the banner)
    // TODO: Figure out how to fix this for sierra!
    NSError *error = [[self webDocument] smimeError];
    if([error ivarExists:@"ParseErrorIsPGPError"]) {
        [(NSButton *)[self valueForKey:@"_helpButton"] setHidden:YES];
        [self setWantsDisplay:YES];
    }
    else {
        [self MAUpdateWantsDisplay];
    }
}

- (void)MAUpdateBannerContents {
    // The help button of the certificate banner points
    // to entries in Apple's help doc about S/MIME.
    // Doesn't make sense for GPGMail to show it.
    [self MAUpdateBannerContents];
    NSError *error = [[self webDocument] smimeError];
    if([error ivarExists:@"ParseErrorIsPGPError"]) {
        [(NSButton *)[self valueForKey:@"_helpButton"] setHidden:YES];
    }
}

@end

@interface MUIWKWebViewController_GPGMail : NSObject

- (id)representedObject;
- (id)baseURL;

@end

@implementation MUIWKWebViewController_GPGMail
- (void)MAWebView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // Bug #981: Efail
    //
    // By default macOS Mail allows HTML-Emails to contain HTML forms
    // which can be submitted directly from the email.
    // An attack has been shown, which uses mime part concatenation
    // to wrap a form around legitimate encrypted content and uses
    // CSS to make the entire email clickable and thus submitting the
    // form.
    //
    // In order to mitigate against this attack in OpenPGP and S/MIME
    // messages, form submission of any kind is disallowed within
    // messages containing encrypted data.
    //
    // In order for S/MIME to be less broken, introduce a dialog
    // asking the user if they really want to click on that link.
    BOOL isEncrypted = [[self representedObject] isEncrypted];
    BOOL isSMIMEEncrypted = isEncrypted && ![[self representedObject] getIvar:@"GMMessageSecurityFeatures"];

    if(!isEncrypted) {
        [self MAWebView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }

    // Ignore any form events.
    if(navigationAction.navigationType == WKNavigationTypeFormSubmitted ||
       navigationAction.navigationType == WKNavigationTypeFormResubmitted) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    // Ignore any other events besides link clicks.
    if(navigationAction.navigationType != WKNavigationTypeLinkActivated) {
        [self MAWebView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }

    if(isSMIMEEncrypted) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[GPGMailBundle localizedStringForKey:@"NAVIGATION_ACTION_FROM_ENCRYPTED_MESSAGE_TITLE"]];
        [alert setInformativeText:[NSString stringWithFormat:[GPGMailBundle localizedStringForKey:@"NAVIGATION_ACTION_FROM_ENCRYPTED_MESSAGE_MESSAGE"], navigationAction.request.URL]];
        [alert addButtonWithTitle:[GPGMailBundle localizedStringForKey:@"NAVIGATION_ACTION_FROM_ENCRYPTED_MESSAGE_BUTTON_YES"]];
        [alert addButtonWithTitle:[GPGMailBundle localizedStringForKey:@"NAVIGATION_ACTION_FROM_ENCRYPTED_MESSAGE_BUTTON_CANCEL"]];
        [alert setAlertStyle:NSWarningAlertStyle];

        [alert beginSheetModalForWindow:[(id)[(id)self view] window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertSecondButtonReturn) {
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            [self MAWebView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        }];
        return;
    }

    // Invoke original handler, otherwise no navigation action will work.
    [self MAWebView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}


@end



#import "MUIWKWebViewConfigurationManager.h"

@interface _WKUserStyleSheet

- (instancetype)initWithSource:(NSString *)source forMainFrameOnly:(BOOL)forMainFrameOnly;

@end

@interface WKUserContentController (Private)

- (void)_addUserStyleSheet:(_WKUserStyleSheet *)userStyleSheet;

@end

@interface MUIWKWebViewConfigurationManager_GPGMail: NSObject
@end

@implementation MUIWKWebViewConfigurationManager_GPGMail

- (id)MAInit {
    id ret = [self MAInit];
    WKUserScript *resizeScript = [[WKUserScript alloc] initWithSource:@";var __GMIsMainFrame__=!0,console={log:function(){return;for(var e=\"\",t=0;t<arguments.length;t++)e+=\" \"+arguments[t];!function(e){var t=document.getElementsByClassName(\"lp-logger\"),i=t.length?t[0]:null;i||((i=document.createElement(\"div\")).className=\"lp-logger\",document.getElementsByTagName(\"body\")[0].appendChild(i));var n=document.createElement(\"div\");n.innerHTML=e,i.appendChild(n)}(e)}},IFRAME_PREFIX=\"{IFRAME_PREFIX}\";function iframeMatchingName(e){var t=null;return forEachIframe(function(){this.getAttribute(\"name\")===e&&(t=this)}),t}function forEachIframe(e){for(var t=\"untrusted-content-\"+IFRAME_PREFIX,i=document.getElementsByClassName(t),n=0;n<i.length;n++){var a=i[n];e.call(a,n,a)}}function setupIframes(){forEachIframe(function(e,t){this.setAttribute(\"name\",this.className+\"_\"+e),console.log(\"Setting name for iframe \",this.getAttribute(\"name\")),this.onload=resizeIframe,this.src=this.getAttribute(\"data-src\")})}function resizeIframe(e){console.log(\"Asking iframe for height\",this.getAttribute(\"name\"));try{this.contentWindow.postMessage({name:this.getAttribute(\"name\"),width:parseInt(this.getAttribute('width'))},\"*\")}catch(e){console.log(\"Error: \",e)}}function resizeIframes(){lastWindowWidth!==window.innerWidth&&(lastWindowWidth=window.innerWidth,console.log(\"Resizing all iframes...\"),forEachIframe(function(){console.log(\"window width\",window.innerWidth),this.setAttribute(\"width\",(document.body.getBoundingClientRect().width-parseInt(window.getComputedStyle(this).getPropertyValue(\"border-left-width\"))-parseInt(window.getComputedStyle(this).getPropertyValue(\"border-right-width\"))-parseInt(window.getComputedStyle(this).getPropertyValue(\"margin-left\"))-parseInt(window.getComputedStyle(this).getPropertyValue(\"margin-right\"))-20)+\"px\"),console.log('body width', document.body.getBoundingClientRect().width, document.body.getBoundingClientRect().left, document.body.getBoundingClientRect().x, document.body.getBoundingClientRect().right),resizeIframe.call(this)}))}IFRAME_PREFIX=IFRAME_PREFIX.replace(\"{IFRAME_PREFIX}\",\"test\"),window.addEventListener(\"message\",function(e){var t=e.data,i=iframeMatchingName(t.name);console.log(\"Set height: \"+t.height+\"px for iframe '\"+t.name+\"'\"),i.style.height=t.height+\"px\"},!1);var resizeTimeout=!1,resizeDelay=250,lastWindowWidth=0;window.addEventListener(\"resize\",function(){clearTimeout(resizeTimeout),resizeTimeout=setTimeout(resizeIframes,resizeDelay)}),setupIframes();document.getElementsByTagName('html')[0].className+='__main__content'" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserScript *iframeHeightScriptBegin = [[WKUserScript alloc] initWithSource:@"if(\"undefined\"==typeof __GMIsMainFrame__){document.getElementsByTagName('html')[0].className+='unsafe-content';var console={log:function(){return;for(var e=\"\",n=0;n<arguments.length;n++)e+=\" \"+arguments[n];!function(e){var n=document.getElementsByClassName(\"lp-logger\"),t=n.length?n[0]:null;t||((t=document.createElement(\"div\")).className=\"lp-logger\",document.getElementsByTagName(\"body\")[0].insertAdjacentElement(\"afterbegin\",t));var a=document.createElement(\"div\");a.innerHTML=e,t.appendChild(a)}(e)}};function computeContentHeight(){var rect = document.getElementsByTagName(\"iframe-content\")[0].getBoundingClientRect(); console.log('body bottom', document.body.getBoundingClientRect().bottom, document.body.getBoundingClientRect().height); console.log('rect bottom', rect.bottom, rect.height); return rect.height+rect.top+rect.y;}window.addEventListener(\"message\",function(e){var n=e.data||{};document.body.style.width = n.width + 'px',n.height=computeContentHeight(),console.log(\"Sending message: \",n.height,n.name),window.parent.postMessage(n,\"*\")},!1)}" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [[[(MUIWKWebViewConfigurationManager *)ret configuration] userContentController] addUserScript:resizeScript];
    [[[(MUIWKWebViewConfigurationManager *)ret configuration] userContentController] addUserScript:iframeHeightScriptBegin];

    id styleSheet = [[NSClassFromString(@"_WKUserStyleSheet") alloc] initWithSource:[(MUIWKWebViewConfigurationManager *)self effectiveUserStyle] forMainFrameOnly:NO];
    id styleSheet2 = [[NSClassFromString(@"_WKUserStyleSheet") alloc] initWithSource:@"iframe-content { display:block; max-width:100%; width: 100%; overflow-wrap: break-word; word-wrap: break-word; } html.unsafe-content, html.unsafe-content body { margin:0px;padding:0px; width:100%; max-width:100%; overflow:scroll; } html.__main__content .protected-part { margin-top: 20px; position: relative; } html.__main__content .protected-part .protected-title { position: absolute; margin-top: -5px; background-color: #fff; margin-left: 20px; font-weight: bold; } html.__main__content .protected-part .protected-content { border: 3px solid #ccc; padding: 16px; padding-left: 20px; }" forMainFrameOnly:NO];
    [[[(MUIWKWebViewConfigurationManager *)ret configuration] userContentController] _addUserStyleSheet:styleSheet];
    [[[(MUIWKWebViewConfigurationManager *)ret configuration] userContentController] _addUserStyleSheet:styleSheet2];
    return ret;
}

@end

@interface MessageViewer_GPGMail : NSObject

@end

@implementation MessageViewer_GPGMail

+ (void)MA_mailApplicationDidFinishLaunching:(id)object {
    [self MA_mailApplicationDidFinishLaunching:object];

    [GMLoaderUpdater updateLoaderIfNecessary];
    [[GPGMailBundle sharedInstance] checkSupportContractAndStartWizardIfNecessary];
}

@end

@interface MCMessageHeaders_GPGMail : NSObject

@end

@implementation MCMessageHeaders_GPGMail

- (NSArray *)MAHeadersForKey:(NSString *)key {
    NSArray *headers = [self MAHeadersForKey:key];
    if([key isEqualToString:@"subject"]) {
        // Bug #1001: Message might appear as signed even though it isn't by abusing the subject
        //
        // By using UTF-8 characters and new lines in a subject, it is possible for an attacker
        // to trick an unsuspecting user into believing that a message is signed, even though
        // it is not.
        //
        // Now macOS Mail is even particularly stupid and allows more than one Subject header
        // and concatenates them splitted by new lines...
        //
        // To fix this, GPGMail only allows a single line subject.
        NSString *subject = [headers count] ? headers[0] : nil;
        if(![subject length]) {
            return headers;
        }
        NSRange range = NSMakeRange(0, [subject length]);
        __block NSString *firstSubjectLine = nil;
        [subject enumerateSubstringsInRange:range
                                   options:NSStringEnumerationByParagraphs
                                usingBlock:^(NSString * _Nullable paragraph, NSRange paragraphRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                                    firstSubjectLine = paragraph;
                                    *stop = YES;
                                }];
        if(![firstSubjectLine length]) {
            return headers;
        }
        return @[firstSubjectLine];
    }
    return headers;
}

@end

@interface MailApp_GPGMail : NSObject

- (void)MATabView:(id)tabView didSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem;

@end

@implementation MailApp_GPGMail

- (void)MATabView:(id)tabView didSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem {
    [self MATabView:tabView didSelectTabViewItem:tabViewItem];
    if([[[tabViewItem viewController] representedObject] isKindOfClass:[GPGMailPreferences class]]) {
        [[[tabViewItem viewController] representedObject] willBeDisplayed];
    }
}

- (BOOL)MAHandleMailToURL:(NSString *)url {
    NSRange activationDataRange = [url rangeOfString:@"mailto:gmsp-activate+"];
    if(activationDataRange.location == NSNotFound) {
        return [self MAHandleMailToURL:url];
    }

    NSString *activationData = [url substringFromIndex:activationDataRange.location + activationDataRange.length];
    activationDataRange = [activationData rangeOfString:@"@support-plan.gpgtools.org"];

    if(activationDataRange.location == NSNotFound) {
        return YES;
    }

    activationData = [activationData substringWithRange:NSMakeRange(0, activationDataRange.location)];
    // Re-convert to proper base64, since normal base64 couldn contain =+/ which are not allowed
    // in email addresses.
    activationData = [activationData stringByReplacingOccurrencesOfString:@"_-_" withString:@"/"];
    activationData = [activationData stringByReplacingOccurrencesOfString:@"_" withString:@"="];
    activationData = [activationData stringByReplacingOccurrencesOfString:@"-" withString:@"+"];

    activationData = [activationData GMSP_base64Decode];

    if(![activationData length]) {
        return YES;
    }

    NSArray *activationComponents = [activationData componentsSeparatedByString:@":"];

    if([activationComponents count] != 2) {
        return YES;
    }

    [[GPGMailBundle sharedInstance] startSupportContractWizardWithActivationCode:activationComponents[0] email:activationComponents[1]];

    return YES;
}

@end

#import "GMSupportPlanAssistantWindowController.h"

@interface GPGMailBundle ()

@property GPGErrorCode gpgStatus;
@property (nonatomic, strong) GMKeyManager *keyManager;
@property (nonatomic, strong) NSDictionary *activationInfo;

@end


#pragma mark Constants and global variables

NSString *GPGMailSwizzledMethodPrefix = @"MA";
NSString *GPGMailAgent = @"GPGMail";
NSString *GPGMailKeyringUpdatedNotification = @"GPGMailKeyringUpdatedNotification";
NSString *gpgErrorIdentifier = @"^~::gpgmail-error-code::~^";
static NSString * const kExpiredCheckKey = @"__gme3__";

NSString * const kGMAllowDecryptionOfDangerousMessagesMissingMDCKey = @"GMAllowDecryptionOfDangerousMessagesMissingMDC";
NSString * const kGMShouldNotConvertPGPPartitionedMessagesKey = @"GMShouldNotConvertPGPPartitionedMessagesKey";

NSString * const kGMSupportPlanAutomaticActivationActivationCodeKey = @"SupportPlanActivationCode";
NSString * const kGMSupportPlanAutomaticActivationActivationEmailKey = @"SupportPlanActivationEmail";

NSString * const kGMSupportPlanInformationActivationCodeKey = @"ActivationCode";
NSString * const kGMSupportPlanInformationActivationEmailKey = @"ActivationEmail";

int GPGMailLoggingLevel = 0;
static BOOL gpgMailWorks = NO;

#pragma mark GPGMailBundle Implementation

@implementation GPGMailBundle
@synthesize accountExistsForSigning, gpgStatus;


#pragma mark Multiple Installations

+ (NSArray *)multipleInstallations {
    NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    NSString *bundlesPath = [@"Mail" stringByAppendingPathComponent:@"Bundles"];
    NSString *bundleName = @"GPGMail.mailbundle";
    
    NSMutableArray *installations = [NSMutableArray array];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    for(NSString *libraryPath in libraryPaths) {
        NSString *bundlePath = [libraryPath stringByAppendingPathComponent:[bundlesPath stringByAppendingPathComponent:bundleName]];
        if([fileManager fileExistsAtPath:bundlePath])
            [installations addObject:bundlePath];
    }
    
    return (NSArray *)installations;
}

+ (void)showMultipleInstallationsErrorAndExit:(NSArray *)installations {
    NSAlert *errorModal = [[NSAlert alloc] init];
    
    errorModal.messageText = GMLocalizedString(@"GPGMAIL_MULTIPLE_INSTALLATIONS_TITLE");
    errorModal.informativeText = [NSString stringWithFormat:GMLocalizedString(@"GPGMAIL_MULTIPLE_INSTALLATIONS_MESSAGE"), [installations componentsJoinedByString:@"\n\n"]];
    [errorModal addButtonWithTitle:GMLocalizedString(@"GPGMAIL_MULTIPLE_INSTALLATIONS_BUTTON")];
    [errorModal runModal];
    
    
    // It's not at all a good idea to use exit and kill the app,
    // but in this case it's alright because otherwise the user would experience a
    // crash anyway.
    exit(0);
}


#pragma mark Init, dealloc etc.

+ (void)initialize {    
    // Make sure the initializer is only run once.
    // Usually is run, for every class inheriting from
    // GPGMailBundle.
    if(self != [GPGMailBundle class])
        return;
    
    if (![GPGController class]) {
		NSRunAlertPanel([self localizedStringForKey:@"LIBMACGPG_NOT_FOUND_TITLE"], [self localizedStringForKey:@"LIBMACGPG_NOT_FOUND_MESSAGE"], nil, nil, nil);
		return;
	}
    
    /* Check the validity of the code signature.
     * Disable for the time being, since Info.plist is part of the code signature
     * and if a new version of OS X is released, and the UUID is added, this check
     * will always fail.
     * Probably not possible in the future either.
     */
//    if (![[self bundle] isValidSigned]) {
//		NSRunAlertPanel([self localizedStringForKey:@"CODE_SIGN_ERROR_TITLE"], [self localizedStringForKey:@"CODE_SIGN_ERROR_MESSAGE"], nil, nil, nil);
//        return;
//    }
    
    // If one happens to have for any reason (like for example installed GPGMail
    // from the installer, which will reside in /Library and compiled with XCode
    // which will reside in ~/Library) two GPGMail.mailbundle's,
    // display an error message to the user and shutdown Mail.app.
    NSArray *installations = [self multipleInstallations];
    if([installations count] > 1) {
        [self showMultipleInstallationsErrorAndExit:installations];
        return;
    }
    
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

    [[((MVMailBundle *)self) class] registerBundle];             // To force registering composeAccessoryView and preferences
}

- (id)init {
	if (self = [super init]) {
		NSLog(@"Loaded GPGMail %@", [self version]);
        
        NSBundle *myBundle = [GPGMailBundle bundle];
        
        // Load all necessary images.
        [self _loadImages];
        
        
        // Set domain and register the main defaults.
        GPGOptions *options = [GPGOptions sharedOptions];
        options.standardDomain = @"org.gpgtools.gpgmail";
		NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:[myBundle pathForResource:@"GPGMailBundle" ofType:@"defaults"]];
        [(id)options registerDefaults:defaultsDictionary];
        
        if (![options boolForKey:@"DefaultsLoaded"]) {
            NSRunAlertPanel([GPGMailBundle localizedStringForKey:@"NO_DEFAULTS_TITLE"], [GPGMailBundle localizedStringForKey:@"NO_DEFAULTS_MESSAGE"], nil, nil, nil);
            NSLog(@"GPGMailBundle.defaults can't be loaded!");
        }
        
        
        // Configure the logging level.
        GPGMailLoggingLevel = (int)[[GPGOptions sharedOptions] integerForKey:@"DebugLog"];
        DebugLog(@"Debug Log enabled: %@", [[GPGOptions sharedOptions] integerForKey:@"DebugLog"] > 0 ? @"YES" : @"NO");
        //GPGMailLoggingLevel = 1;
        _keyManager = [[GMKeyManager alloc] init];
        
        // Initiate the Message Rules Applier.
        _messageRulesApplier = [[GMMessageRulesApplier alloc] init];
        
        [self setAllowDecryptionOfPotentiallyDangerousMessagesWithoutMDC:[[[GPGOptions sharedOptions] valueForKey:@"AllowDecryptionOfPotentiallyDangerousMessagesWithoutMDC"] boolValue]];
        [self setShouldNotConvertPGPPartitionedMessages:[[[GPGOptions sharedOptions] valueForKey:@"ShouldNotConvertPGPPartitionedMessages"] boolValue]];
        // Start the GPG checker.
        [self startGPGChecker];
        
        // Specify that a count exists for signing.
        accountExistsForSigning = YES;
        
        _messageBodyDataLoadingQueue = [[NSOperationQueue alloc] init];
        _messageBodyDataLoadingQueue.maxConcurrentOperationCount = 1;
        _messageBodyDataLoadingQueue.name = @"org.gpgtools.gpgmail.messageBodyLoadingQueue";
        _messageBodyDataLoadingCache = [[NSCache alloc] init];

        // Inject the plugin code.
        [GMCodeInjector injectUsingMethodPrefix:GPGMailSwizzledMethodPrefix];

	}
    
	return self;
}

- (void)setAllowDecryptionOfPotentiallyDangerousMessagesWithoutMDC:(BOOL)allow {
    [self setIvar:kGMAllowDecryptionOfDangerousMessagesMissingMDCKey value:@(allow)];
}

- (BOOL)allowDecryptionOfPotentiallyDangerousMessagesWithoutMDC {
    return [[self getIvar:kGMAllowDecryptionOfDangerousMessagesMissingMDCKey] boolValue];
}

- (void)setShouldNotConvertPGPPartitionedMessages:(BOOL)shouldConvertPGPPartitionedMessages {
    [self setIvar:kGMShouldNotConvertPGPPartitionedMessagesKey value:@(shouldConvertPGPPartitionedMessages)];
}

- (BOOL)shouldNotConvertPGPPartitionedMessages {
    return [[self getIvar:kGMShouldNotConvertPGPPartitionedMessagesKey] boolValue];
}

- (void)dealloc {
    if (_checkGPGTimer) {
        //dispatch_release(_checkGPGTimer);
    }
}

- (void)_loadImages {
    /**
     * Loads all images which are used in the GPGMail User interface.
     */
    // We need to load images and name them, because all images are searched by their name; as they are not located in the main bundle,
	// +[NSImage imageNamed:] does not find them.
	NSBundle *myBundle = [GPGMailBundle bundle];
    
    NSArray *bundleImageNames = @[@"GPGMail",
                                  @"ValidBadge",
                                  @"InvalidBadge",
                                  @"GreenDot",
                                  @"YellowDot",
                                  @"RedDot",
                                  @"MenuArrowWhite",
                                  @"certificate",
                                  @"encryption",
                                  @"CertSmallStd",
                                  @"CertSmallStd_Invalid", 
                                  @"CertLargeStd",
                                  @"CertLargeNotTrusted",
                                  @"SymmetricEncryptionOn",
                                  @"SymmetricEncryptionOff"];
    NSMutableArray *bundleImages = [[NSMutableArray alloc] initWithCapacity:[bundleImageNames count]];
    
    for (NSString *name in bundleImageNames) {
        NSImage *image = [[NSImage alloc] initByReferencingFile:[myBundle pathForImageResource:name]];

        // Shoud an image not exist, log a warning, but don't crash because of inserting
        // nil!
        if(!image) {
            NSLog(@"GPGMail: Image %@ not found in bundle resources.", name);
            continue;
        }
        [image setName:name];
        [bundleImages addObject:image];
    }
    
    _bundleImages = bundleImages;
    
}

#pragma mark Check and status of GPG.

- (void)startGPGChecker {
    // Periodically check status of gpg.
    [self checkGPG];
    _checkGPGTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(_checkGPGTimer, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), 60 * NSEC_PER_SEC, 10 * NSEC_PER_SEC);
    
    __block typeof(self) __unsafe_unretained weakSelf = self;
    dispatch_source_set_event_handler(_checkGPGTimer, ^{
        [weakSelf checkGPG];
    });
    dispatch_resume(_checkGPGTimer);
}

- (BOOL)checkGPG {
    self.gpgStatus = (GPGErrorCode)[GPGController testGPG];
    switch (gpgStatus) {
        case GPGErrorNotFound:
            DebugLog(@"DEBUG: checkGPG - GPGErrorNotFound");
            break;
        case GPGErrorConfigurationError:
            DebugLog(@"DEBUG: checkGPG - GPGErrorConfigurationError");
        case GPGErrorNoError: {
            static dispatch_once_t onceToken;
            
            GMKeyManager * __weak weakKeyManager = self->_keyManager;
            
            dispatch_once(&onceToken, ^{
                [weakKeyManager scheduleInitialKeyUpdate];
            });
            
            gpgMailWorks = YES;
            return YES;
        }
        default:
            DebugLog(@"DEBUG: checkGPG - %i", gpgStatus);
            break;
    }
    gpgMailWorks = NO;
    return NO;
}

+ (BOOL)gpgMailWorks {
	return gpgMailWorks;
}

- (BOOL)gpgMailWorks {
	return gpgMailWorks;
}


#pragma mark Handling keys

- (NSSet *)allGPGKeys {
    if (!gpgMailWorks) return nil;
    
    return [_keyManager allKeys];
}

- (GPGKey *)anyPersonalPublicKeyWithPreferenceAddress:(NSString *)address {
    if(!gpgMailWorks) return nil;
    
    return [_keyManager anyPersonalPublicKeyWithPreferenceAddress:address];
}

- (GPGKey *)secretGPGKeyForKeyID:(NSString *)keyID {
    if (!gpgMailWorks) return nil;
    
    return [_keyManager secretKeyForKeyID:keyID includeDisabled:NO];
}

- (GPGKey *)secretGPGKeyForKeyID:(NSString *)keyID includeDisabled:(BOOL)includeDisabled {
    if (!gpgMailWorks) return nil;
    
    return [_keyManager secretKeyForKeyID:keyID includeDisabled:includeDisabled];
}

- (NSMutableSet *)signingKeyListForAddress:(NSString *)sender {
    if (!gpgMailWorks) return nil;
    
    return [_keyManager signingKeyListForAddress:[sender gpgNormalizedEmail]];
}

- (NSMutableSet *)publicKeyListForAddresses:(NSArray *)recipients {
    if (!gpgMailWorks) return nil;
    
    return [_keyManager publicKeyListForAddresses:recipients];
}

- (BOOL)canSignMessagesFromAddress:(NSString *)address {
    if (!gpgMailWorks) return NO;
    
    return [_keyManager secretKeyExistsForAddress:[address gpgNormalizedEmail]];
}

- (BOOL)canEncryptMessagesToAddress:(NSString *)address {
    if (!gpgMailWorks) return NO;
    
    return [_keyManager publicKeyExistsForAddress:[address gpgNormalizedEmail]];
}

- (GPGKey *)preferredGPGKeyForSigning {
    if (!gpgMailWorks) return nil;
    
    return [_keyManager findKeyByHint:[[GPGOptions sharedOptions] valueInGPGConfForKey:@"default-key"] onlySecret:YES];
}

- (GPGKey *)keyForFingerprint:(NSString *)fingerprint {
    if (!gpgMailWorks) return nil;
    
    return [_keyManager keyForFingerprint:fingerprint];
}

#pragma mark Message Rules

- (void)scheduleApplyingRulesForMessage:(Message *)message isEncrypted:(BOOL)isEncrypted {
    [_messageRulesApplier scheduleMessage:message isEncrypted:isEncrypted];
}

#pragma mark Localization Helper

+ (NSString *)localizedStringForKey:(NSString *)key {
    static dispatch_once_t onceToken;
    static NSBundle *gmBundle = nil, *englishBundle = nil;
    dispatch_once(&onceToken, ^{
        gmBundle = [GPGMailBundle bundle];
        englishBundle = [NSBundle bundleWithPath:[gmBundle pathForResource:@"en" ofType:@"lproj"]];
    });
    
    NSString *notFoundValue = @"~#*?*#~";
    NSString *localizedString = [gmBundle localizedStringForKey:key value:notFoundValue table:@"GPGMail"];
    if (localizedString == notFoundValue) {
        // No translation found. Use the english string.
        localizedString = [englishBundle localizedStringForKey:key value:nil table:@"GPGMail"];
    }

    return localizedString;
}

#pragma mark General Infos

+ (NSBundle *)bundle {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundle = [NSBundle bundleForClass:[GPGMailBundle class]];
        
        if ([bundle respondsToSelector:@selector(useGPGLocalizations)]) {
            [bundle useGPGLocalizations];
        }
    });
    return bundle;
}


- (NSString *)version {
	return [[GPGMailBundle bundle] infoDictionary][@"CFBundleShortVersionString"];
}

+ (NSString *)bundleVersion {
    /**
     Returns the version of the bundle as string.
     */
    return [[[GPGMailBundle bundle] infoDictionary] valueForKey:@"CFBundleVersion"];
}

+ (NSString *)bundleBuildNumber {
    return [[[GPGMailBundle bundle] infoDictionary] valueForKey:@"BuildNumber"];
}

+ (NSString *)agentHeader {
    NSString *header;
    if ([[GPGOptions sharedOptions] boolForKey:@"emit-version"]) {
        header = [NSString stringWithFormat:@"%@ %@", GPGMailAgent, [(GPGMailBundle *)[GPGMailBundle sharedInstance] version]];
    } else {
        header = @"GPGMail";
    }
    return header;
}

+ (Class)resolveMailClassFromName:(NSString *)name {
    NSArray *prefixes = @[@"", @"MC", @"MF"];
    
    // MessageWriter is called MessageGenerator under Mavericks.
    if([name isEqualToString:@"MessageWriter"] && !NSClassFromString(@"MessageWriter"))
        name = @"MessageGenerator";
    
    __block Class resolvedClass = nil;
    [prefixes enumerateObjectsUsingBlock:^(NSString *prefix, NSUInteger idx, BOOL *stop) {
        NSString *modifiedName = [name copy];
        if([prefixes containsObject:[modifiedName substringToIndex:2]])
            modifiedName = [modifiedName substringFromIndex:2];
        
        NSString *className = [prefix stringByAppendingString:modifiedName];
        resolvedClass = NSClassFromString(className);
        if(resolvedClass)
            *stop = YES;
    }];
    
    return resolvedClass;
}

+ (BOOL)isMountainLion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
    Class Message = [self resolveMailClassFromName:@"Message"];
    return [Message instancesRespondToSelector:@selector(dataSource)];
#pragma clang diagnostic pop
}

+ (BOOL)isLion {
    return floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6 && ![self isMountainLion] && ![self isMavericks] && ![self isYosemite] && ![self isElCapitan];
}

+ (BOOL)isMavericks {
    return floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8;
}

+ (BOOL)isYosemite {
    return floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9;
}

+ (BOOL)isElCapitan {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if(![info respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)])
        return NO;
    
    NSOperatingSystemVersion requiredVersion = {10,11,0};
    return [info isOperatingSystemAtLeastVersion:requiredVersion];
}

+ (BOOL)isSierra {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if(![info respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)])
        return NO;
    
    NSOperatingSystemVersion requiredVersion = {10,12,0};
    return [info isOperatingSystemAtLeastVersion:requiredVersion];
}

+ (BOOL)isHighSierra {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if(![info respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)])
        return NO;
    
    NSOperatingSystemVersion requiredVersion = {10,13,0};
    return [info isOperatingSystemAtLeastVersion:requiredVersion];
}

+ (BOOL)isMojave {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if(![info respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)])
        return NO;

    NSOperatingSystemVersion requiredVersion = {10,14,0};
    return [info isOperatingSystemAtLeastVersion:requiredVersion];
}

+ (BOOL)isCatalina {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if(![info respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)])
        return NO;
    
    NSOperatingSystemVersion requiredVersion = {10,15,0};
    return [info isOperatingSystemAtLeastVersion:requiredVersion];
}

+ (BOOL)hasPreferencesPanel {
    // LEOPARD Invoked on +initialize. Else, invoked from +registerBundle.
	return YES;
}

+ (NSString *)preferencesOwnerClassName {
	return NSStringFromClass([GPGMailPreferences class]);
}

+ (NSString *)preferencesPanelName {
	return GMLocalizedString(@"PGP_PREFERENCES");
}

+ (id)backEndFromObject:(id)object {
    id backEnd = nil;
    if([object isKindOfClass:[GPGMailBundle resolveMailClassFromName:@"HeadersEditor"]]) {
        if([GPGMailBundle isElCapitan])
            backEnd = [(ComposeViewController *)[object composeViewController] backEnd];
        else
            backEnd = [[object valueForKey:@"_documentEditor"] backEnd];
    }
    else if([object isKindOfClass:[GMSecurityControl class]]) {
        if([GPGMailBundle isElCapitan])
            backEnd = [[object composeViewController] backEnd];
        else
            backEnd = [[object valueForKey:@"_documentEditor"] backEnd];
    }
    
    //NSAssert(backEnd != nil, @"Couldn't find a way to access the ComposeBackEnd");
    
    return backEnd;
}

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo {
    NSString *errorDomain = [GPGMailBundle isMavericks] ? @"MCMailErrorDomain" : @"MFMessageErrorDomain";
    
    NSError *mailError = nil;
    NSMutableDictionary *extendedUserInfo = [userInfo mutableCopy];
    extendedUserInfo[@"NSLocalizedDescription"] = userInfo[@"_MFShortDescription"];
    extendedUserInfo[@"NSLocalizedRecoverySuggestion"] = userInfo[@"NSLocalizedDescription"];
    mailError = [NSError errorWithDomain:errorDomain code:code userInfo:extendedUserInfo];
    
    return mailError;
}
             
#pragma mark Active Contract Helpers

- (BOOL)hasActiveContract {
    return [[self supportPlanManager] supportPlanIsActive];
}

- (BOOL)hasActiveContractOrActiveTrial {
    return [self hasActiveContract];
}

- (NSNumber *)remainingTrialDays {
    return [[self supportPlanManager] remainingTrialDays];
}

- (void)startSupportContractWizard {
    [self startSupportContractWizardWithActivationCode:nil email:nil];
}

- (void)startSupportContractWizardWithActivationCode:(NSString *)activationCode email:(NSString *)email {
    // Check if an open SupportPlanAssistantWindowController exists and if so close
    // it
    GMSupportPlanAssistantWindowController *supportPlanAssistantWindowController = [self getIvar:@"SupportPlanAssistantWindowController"];
    if(supportPlanAssistantWindowController) {
        [self closeSupportPlanAssistant:supportPlanAssistantWindowController];
    }

    GMSupportPlanAssistantViewController *supportPlanAssistantViewController = [[GMSupportPlanAssistantViewController alloc] initWithNibName:@"GMSupportPlanAssistantView" bundle:[GPGMailBundle bundle]];
    supportPlanAssistantViewController.supportPlanManager = [self supportPlanManager];
    supportPlanAssistantViewController.delegate = self;

    supportPlanAssistantWindowController = [[GMSupportPlanAssistantWindowController alloc] initWithSupportPlanManager:[self supportPlanManager]];
    supportPlanAssistantWindowController.delegate = self;
    supportPlanAssistantWindowController.contentViewController = supportPlanAssistantViewController;
    [[supportPlanAssistantWindowController window] setTitle:@"GPG Mail Support Plan"];
    [supportPlanAssistantWindowController showWindow:nil];
    [[supportPlanAssistantWindowController window] makeKeyAndOrderFront:nil];

    [self setIvar:@"SupportPlanAssistantWindowController" value:supportPlanAssistantWindowController];
    [self setIvar:@"supportPlanAssistantWindowView" value:supportPlanAssistantViewController];

    if([self hasActivationCodeForAutomaticActivation]) {
        NSDictionary *supportPlanActivationInformation = [self supportPlanInformationForAutomaticActivation];
        email = supportPlanActivationInformation[kGMSupportPlanInformationActivationEmailKey];
        activationCode = supportPlanActivationInformation[kGMSupportPlanInformationActivationCodeKey];
    }

    if([email length] && [activationCode length]) {
        supportPlanAssistantWindowController.closeWindowAfterError = YES;
        [supportPlanAssistantWindowController performAutomaticSupportPlanActivationWithActivationCode:activationCode email:email];
    }
}

- (void)checkSupportContractAndStartWizardIfNecessary {
    BOOL shouldPresentActivationDialog = [[self supportPlanManager] shouldPresentActivationDialog];
    // If information is set for automatic activation, override shouldPresent.
    if(!shouldPresentActivationDialog && [self hasActivationCodeForAutomaticActivation]) {
        shouldPresentActivationDialog = YES;
    }
    if(shouldPresentActivationDialog) {
        [self startSupportContractWizard];
    }
}

- (BOOL)hasActivationCodeForAutomaticActivation {
    return [self supportPlanInformationForAutomaticActivation] != nil;
}

- (NSDictionary *)supportPlanInformationForAutomaticActivation {
    NSMutableDictionary *activationInformation = [NSMutableDictionary new];
    NSString *activationCode = [[GPGOptions sharedOptions] valueForKey:kGMSupportPlanAutomaticActivationActivationCodeKey];
    NSString *activationEmail = [[GPGOptions sharedOptions] valueForKey:kGMSupportPlanAutomaticActivationActivationEmailKey];
    if(![activationCode length] || ![activationEmail length]) {
        return nil;
    }

    activationInformation[kGMSupportPlanInformationActivationCodeKey] = activationCode;
    activationInformation[kGMSupportPlanInformationActivationEmailKey] = activationEmail;

    return activationInformation;
}

- (void)removeSupportPlanInformationForAutomaticActivation {
    [[GPGOptions sharedOptions] setValue:nil forKey:kGMSupportPlanAutomaticActivationActivationCodeKey];
    [[GPGOptions sharedOptions] setValue:nil forKey:kGMSupportPlanAutomaticActivationActivationCodeKey];
}

- (void)deactivateSupportContract {
    [[self supportPlanManager] deactivateWithCompletionHandler:^(GMSupportPlan * _Nonnull supportPlan, NSDictionary *result, NSError * _Nonnull error) {
        // Usually not necessary to wait for the report errors here.
        dispatch_async(dispatch_get_main_queue(), ^{
            // A new trial activation might be available, thus it is necessary to update the support plan state.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GMSupportPlanStateChangeNotification" object:self];
        });
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GMSupportPlanStateChangeNotification" object:self];
}

#pragma mark -

- (void)supportPlanAssistant:(NSWindowController *)windowController email:(NSString *)email activationCode:(NSString *)activationCode {
    [[self supportPlanManager] activateSupportPlanWithActivationCode:activationCode email:email completionHandler:^(GMSupportPlan * _Nonnull supportPlan, NSDictionary *result, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!supportPlan) {
                [(GMSupportPlanAssistantWindowController *)windowController activationDidFailWithError:error];
                return;
            }
            if(supportPlan) {
                [(GMSupportPlanAssistantWindowController *)windowController activationDidCompleteWithSuccessForSupportPlan:supportPlan];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"GMSupportPlanStateChangeNotification" object:self];

                // Remove the info for automatic activation.
                if([self hasActivationCodeForAutomaticActivation]) {
                    [self removeSupportPlanInformationForAutomaticActivation];
                }
            }
        });
    }];
}

- (void)supportPlanAssistantShouldStartTrial:(NSWindowController *)windowController {
    // Start a new trial.
    [[self supportPlanManager] startTrialWithCompletionHandler:^(GMSupportPlan * _Nullable supportPlan, NSDictionary * _Nullable result, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(!supportPlan) {
                [(GMSupportPlanAssistantWindowController *)windowController activationDidFailWithError:error];
                return;
            }
            [(GMSupportPlanAssistantWindowController *)windowController activationDidCompleteWithSuccessForSupportPlan:supportPlan];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GMSupportPlanStateChangeNotification" object:self];
        });
    }];
}

- (void)closeSupportPlanAssistant:(NSWindowController *)windowController {
    [windowController close];
}

- (GMSupportPlanManager *)supportPlanManager {
    static dispatch_once_t onceToken;
    static GMSupportPlanManager *supportPlanManager;
    dispatch_once(&onceToken, ^{
        supportPlanManager = [[GMSupportPlanManager alloc] initWithApplicationID:[[GPGMailBundle bundle] bundleIdentifier] applicationInfo:[[GPGMailBundle bundle] infoDictionary]];
    });

    return supportPlanManager;
}

@end


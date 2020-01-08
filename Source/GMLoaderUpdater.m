/* GMLoaderUpdater.m created by Mento on Monday 23-Oct-2019 */

/*
 * Copyright (c) 2019, GPGTools <team@gpgtools.org>
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
 * THIS SOFTWARE IS PROVIDED BY GPGTools ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL GPGTools BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "GMLoaderUpdater.h"
#import "MailBundle.h"
#import "MailBundleController.h"
#import "MailBundlesDirectory.h"

@interface NSApplication (MailBundleController)
@property(readonly, nonatomic) MailBundleController *mailBundleController;
@end

NSString * const kGMLoaderIdentifier = @"org.gpgtools.gpgmail.GPGMailLoader";


@implementation GMLoaderUpdater

+ (NSComparisonResult)compareVersionOfMailBundle:(MailBundle *)bundleA withMailBundle:(MailBundle *)bundleB {
    NSString *versionA = [self versionForMailBundle:bundleA];
    NSString *versionB = [self versionForMailBundle:bundleB];

    if([versionA isEqualToString:versionB]) {
        return NSOrderedSame;
    }
    if (!versionA) {
        return NSOrderedDescending;
    }
    if (!versionB) {
        return NSOrderedAscending;
    }
    // Only compare the version before the first space.
    versionA = [versionA componentsSeparatedByString:@" "][0];
    versionB = [versionB componentsSeparatedByString:@" "][0];

    NSArray *componentsA = [versionA componentsSeparatedByString:@"."];
    NSArray *componentsB = [versionB componentsSeparatedByString:@"."];
    NSUInteger countA = componentsA.count;
    NSUInteger countB = componentsB.count;
    NSUInteger count = MIN(countA, countB);
    NSUInteger i = 0;
    for (; i < count; i++) {
        NSComparisonResult result = [componentsA[i] compare:componentsB[i] options:NSNumericSearch];
        if (result == NSOrderedDescending) {
            return NSOrderedAscending;
        } else if (result == NSOrderedAscending) {
            return NSOrderedDescending;
        }
    }
    if (countA > count) {
        // versionA has mor components e.g. 1.2.1 > 1.2
        return NSOrderedAscending;
    }

    return NSOrderedDescending;
}

+ (NSString *)versionForMailBundle:(MailBundle *)mailBundle {
    if(!mailBundle) {
        return nil;
    }
    NSBundle *bundle = [self bundleForMailBundle:mailBundle];
    return [bundle infoDictionary][@"CFBundleShortVersionString"];
}

+ (void)updateLoaderIfNecessary {
    if (@available(macOS 10.14, *)) {
        // Do not enable bundles during the initialization.
        // Wait until the run-loop is ready.
        [self performSelectorOnMainThread:@selector(updateLoaderAfterInitialization) withObject:nil waitUntilDone:NO];
    }
}

+ (NSBundle *)bundleForMailBundle:(MailBundle *)mailBundle {
    NSBundle *bundle = [NSBundle bundleWithURL:mailBundle.url];
    return bundle;
}

+ (BOOL)isLoaderBundle:(MailBundle *)mailBundle {
    NSBundle *bundle = [self bundleForMailBundle:mailBundle];

    NSString *bundleIdentifier = [bundle bundleIdentifier];
    // Bug #1056: macOS Mail plugin manager doesn't open if other bundles are installed alongside GPG Mail
    //
    // If the name of a bundle was shorter than the length of our loader bundle identifier,
    // substringWithRange would raise an Exception that the length exceeds max range, which lead
    // to the the plugin manager to no longer show.
    //
    // So in order to fix that, check if length is short than the loader bundle identifier
    // and if that is the case, there's no need to do any comparison. Return early instead.
    if([bundleIdentifier length] < [kGMLoaderIdentifier length]) {
        return NO;
    }

    return [[[bundle bundleIdentifier] substringWithRange:NSMakeRange(0, [kGMLoaderIdentifier length])] isEqualToString:kGMLoaderIdentifier];
}

+ (void)updateLoaderAfterInitialization {
    NSLog(@"[GMLoaderUpdater] Updating loader...");
    MailBundleController *bundleController = [NSApp mailBundleController];
    NSURL *bundleDirURL = [NSURL fileURLWithPath:@"/Library/Mail/Bundles"];

    NSMutableArray <MailBundle *> *loaderBundles = [NSMutableArray new];

    // Loop through all bundles and find the newest active and non-active GPGMailloader.
    for (MailBundle *mailBundle in bundleController.bundles) {
        NSLog(@"[GMLoaderUpdater] Current bundle: %@", mailBundle);
        if (![mailBundle.directory.url isEqual:bundleDirURL] || ![self isLoaderBundle:mailBundle]) {
            // Ignore bundles outside of /Library/Mail/Bundles and bundles that are not loader bundles.
            continue;
        }
        [loaderBundles addObject:mailBundle];
    }

    if([loaderBundles count] <= 1) {
        return;
    }

    // Sort the loader bundles by version.
    [loaderBundles sortUsingComparator:^NSComparisonResult(MailBundle * _Nonnull mailBundleA, MailBundle * _Nonnull mailBundleB) {
        return [self compareVersionOfMailBundle:mailBundleA withMailBundle:mailBundleB];
    }];

    // Check if newest is already active.
    MailBundle *newestLoaderBundle = loaderBundles[0];
    NSLog(@"Newest loader bundle is: %@ - %@",  [self versionForMailBundle:newestLoaderBundle], newestLoaderBundle);
    if(!newestLoaderBundle.isLoaded) {
        NSLog(@"[GMLoaderUpdater] Install new loader: %@", newestLoaderBundle.displayName);
        [bundleController installBundle:newestLoaderBundle];
    }
    NSLog(@"Newest loader bundle state: %lld", newestLoaderBundle.state);

    if(newestLoaderBundle.state == 2 /* MailBundleStateInstalled */) {
        NSLog(@"Uninstalling older loader bundles...");
        for(MailBundle *mailBundle in [loaderBundles subarrayWithRange:NSMakeRange(1, [loaderBundles count] - 1)]) {
            NSLog(@"Uninstalling loader bundle: %@ - %@",  [self versionForMailBundle:mailBundle], mailBundle);
            [bundleController uninstallBundle:mailBundle];
        }
    }
}

@end

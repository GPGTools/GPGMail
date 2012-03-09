//
//  main.m
//  BundleTestRunner
//
// http://www.dribin.org/dave/blog/archives/2006/01/26/test_bundle_3/
//

#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>

static int const kBadBundle = 99;

static void loadBundle(NSString * bundlePath)
{
    NSException * exception;
    NSBundle * bundle = [NSBundle bundleWithPath: bundlePath];
    if (!bundle)
    {
        NSString * reason = [NSString stringWithFormat:
                             @"Could not find bundle: %@", bundlePath];
        exception = [NSException exceptionWithName: @"BundleLoadException"
                                            reason: reason
                                          userInfo: nil];
        @throw exception;
    }
    
    if (![bundle load])
    {
        NSString * reason = [NSString stringWithFormat:
                             @"Could not load bundle: %@", bundle];
        exception = [NSException exceptionWithName: @"BundleLoadException"
                                            reason: reason
                                          userInfo: nil];
        @throw exception;
    }
    
    NSLog(@"BundleTestRunner loaded %@", bundlePath);
}

int main(int argc, char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString * bundlePath = [[[NSProcessInfo processInfo] environment]
                             objectForKey: @"TEST_LOAD_BUNDLE"];
    
    if (bundlePath != nil)
    {
        loadBundle(bundlePath);
    }
    else {
        @throw [NSException exceptionWithName: @"ApplicationException"
                                       reason: @"No TEST_LOAD_BUNDLE!"
                                     userInfo: nil];
    }

    NSEnumerator * arguments = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
    // Skip argv[0]
    [arguments nextObject];
    NSString * lastBundlePath = nil;
    while (bundlePath = [arguments nextObject])
    {
        @try {
            if ([bundlePath length]) {
                loadBundle(bundlePath);
                lastBundlePath = bundlePath;
            }
        }
        @catch (NSException *exception) {
            NSLog(@"BundleTestRunner failed %@", exception.reason);
            return kBadBundle;
        }
    }

    if (!lastBundlePath)
        return kBadBundle;
    
    SenTestSuite * suite;
    suite = [SenTestSuite testSuiteForBundlePath: bundlePath];
    BOOL hasFailed = ![[suite run] hasSucceeded];
    
    [pool release];
    return ((int) hasFailed);
}

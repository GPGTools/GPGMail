//
//  GMSupportPlanManager.m
//  GPGMail
//
//  Created by Lukas Pitschl on 23.10.19.
//

#import <SystemConfiguration/SystemConfiguration.h>

#import "GMSPCommon.h"
#import "GMDevice.h"
#import "GMSupportPlan.h"
#import "GMSupportPlanManager.h"

#import <Libmacgpg/Libmacgpg.h>
#import <Libmacgpg/GPGTaskHelperXPC.h>


#ifdef DEBUG
NSString * const kGMSupportPlanManagerPublicCertificate = @"MIIEWjCCAsKgAwIBAgIUBpfAcF0mUJQIT4tAmfPWMYIUrP4wDQYJKoZIhvcNAQELBQAwXjELMAkGA1UEBhMCQVQxEDAOBgNVBAgMB0F1c3RyaWExDzANBgNVBAcMBlZpZW5uYTEWMBQGA1UECgwNR1BHVG9vbHMgR21iSDEUMBIGA1UEAwwLR1BHVG9vbHMgQ0EwHhcNMTkxMTEwMDEyMDQyWhcNMjQxMTA4MDEyMDQyWjBeMQswCQYDVQQGEwJBVDEQMA4GA1UECAwHQXVzdHJpYTEPMA0GA1UEBwwGVmllbm5hMRYwFAYDVQQKDA1HUEdUb29scyBHbWJIMRQwEgYDVQQDDAtHUEdUb29scyBDQTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAMA9jImqn9peLMKDJESzKvEpsDnjsiUXQdQucd7jFA7k5coSfrnpSvNVWh4n4vQy4GnEgzjnVR5nzxCOs4bMWGT6oSBHyqYhVMRV0x8WpA9fcMH0O/IYBtFGXX2BCnIXeqeIYbgaQ+3rlopjAiv78EJ3lWrTmjQNBFHqipem1qdbfPur+3ELssl6hHojz/JzW7FkS2P3/++6SHsBBMD+gHQp4R3IyGmPM6YAkFSeuxtA/Z3bK7bogtuPV8DXIT7sqK66f8P0dD8cKmEWKeaub41YxDeNR9wa0KBuTIdjzkeXFloBK7uzu54AvWM3sSJdGJ8UBdXJIf+pMV+qeY/CrPwcFiRdOwDRyia//UsPUYkthtCI9dARlMlvdmZ+OJZePI5nbfxnrqBQKWAhknCwcKG9/UYf3PeJpHM0cVvvF+LK1KQ3rZlFzN+KplLB2fL5AZEgObKbv7IAc3uqPjKqEXdgwBnHsKFCwLHX8x16KiMP4sNm9rZ5+juS3l+DJYYW/QIDAQABoxAwDjAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBgQAoebPba0MdlfAfDKbhxySSayBHY7uPG2RS7EA0JKthV77cZZQ5kl+JikubAEZ4inIj7rOkHcrk5vnGAoZpUpNKAGdUjPUKIFEibljivy7Wu4Zlq7xH7Qa8qJq5AF4sqpiLq59kY4jfXMlpO79TqL3g3jxYkEgMn9CYclTsa+7XlyteVaU+xUf3mgku1xpUj3/EYiKDJqx2nZYPyqD/yhTSIVF97CURKyJ30ErrOSJQvcCkenUkglPzr/ksMaQm8lcTVnat4NIwrkplsgN32x/5M9MonVMd5aSJEnaudEqUt4oDKhujYZsQVUF7rp/RMdhldErpodwaVcFHTiH9cpw0F15w3jLuGkyqbZmwRnwEJUZVx0HYza8qW+I4sMSw1JOkfgVKD776aBTZ96EqKx8e+zwcwcWLT0KWXv5JgEmqVyTJlfdYcns3tFzTmqqzgk7qJ/zOs4EJD0zrsPVTP+3jQjLSOlzIXdpMEDIe63qmq1KHVfyyHZdnbidN7PE/pAM=";
#else
#ifdef GMSP_PUBLIC_CERTIFICATE
// Unfortunately // in the certificate data is cutting off the macro expansion, so it has to be replaced with an alternative.
// # is used to represent //.
NSString * const kGMSupportPlanManagerPublicCertificate = GMSPStringFromPreprocessor(GMSP_PUBLIC_CERTIFICATE);
#else
#ifdef NO_SUPPORT_PLAN
NSString * const kGMSupportPlanManagerPublicCertificate = @"";
#else
#error GMSP_PUBLIC_CERTIFICATE is not defined in Release build!
#endif
#endif
#endif


#ifdef DEBUG
NSString * const kGMSupportPlanManagerFallbackTrial = @"eyJhY3RpdmF0aW9uIjp7InR5cGUiOiJmYWxsYmFja3RyaWFsIiwiZGlkIjoyMDAwMDAwMCwidWRpZCI6IiIsInVwZGF0ZWQiOjE1NzMwNTM2MjAsImlzc3VlZCI6MTU3MzA1MzYyMCwiYXBwIjoib3JnLmdwZ3Rvb2xzLmdwZ21haWw0IiwiZWxpZ2libGVfYXBwcyI6eyI0Ijoib3JnLmdwZ3Rvb2xzLmdwZ21haWw0IiwiMyI6Im9yZy5ncGd0b29scy5ncGdtYWlsIn0sInJlZnJlc2giOjE2MDQ1ODk2MjAsImV4cGlyYXRpb24iOjE1NzU2NDU2MjB9LCJtZXRhIjp7InNpZyI6ImlhMDYrWVFZbzJWVGdHYnVBblRabDZheXlmZGt5SVwva3BFd0NSWGFiWm5DSlwvRmorRTYwZ3dDYnloa2ppVU9IUXdFb2VtNUxYWVlLS1FXUkNKUk5VZER4TVM4TVZSOWtZQkgrcmJNNVBSNjRGMnpQWjVzQ3Q0SUM4QXRnQmg3SUp6UFFkRUdcLytvUTZVdVN3MnlNb3lha1U5U2JReUFoZE0xM1JUbFREOXRERWFkVVMrRklcLzFPeGRZQ2pqeTc3bjRKZlBUOXlUcStLN3NHVGFqd2hqZFNySjlcL0VvR3lVNkUzeG1PNENxcHZcLzdEVkQxeitoeWxDTGZ3K00xMWpERm0rcGtFSjRSXC9ZNHdxSHorQ2JJMnVnRFlXOVQreTFZWEVGT1RuUFZYNDBCTGhCWFBGVk5OenZjOWEwUG96UDJXT3ZcL3RuMDd0Mkp4WEgySE5Sd0xsTGlyb2RoblJ0a1ZyTkJGRjhjdTFBbDBHazZHT1wvajdyY0xQK2RFaW9RVmRDOUdNZktNd1ZucHhMMDVUNDZpbWJvSVAwMkRvUGs4OUlueW13V2pWUEhwcERvTVBzMFByM1pXWEdobXFJR0sxcmVLRUdHb1ZLVkttOW9XV3l6VHhMbDVZYWFHSFFnazJsS0NcL1lrd0tYUEZRV3cyTzA5RHhRcWlIMXhxcXZQU090MiJ9fQ==";
#else
#ifdef GMSP_FALLBACK_TRIAL
NSString * const kGMSupportPlanManagerFallbackTrial = GMSPStringFromPreprocessor(GMSP_FALLBACK_TRIAL);
#else
#ifdef NO_SUPPORT_PLAN
NSString * const kGMSupportPlanManagerFallbackTrial = @"";
#else
#error GMSP_FALLBACK_TRIAL is not defined in Release build!
#endif
#endif
#endif


#ifdef DEBUG
NSString * const kGMSupportPlanManagerAPIEndpointURL = @"http://localhost:8000/api/v1.0/support-plans";
#else
#ifdef NO_SUPPORT_PLAN
NSString * const kGMSupportPlanManagerAPIEndpointURL = @"";
#else
NSString * const kGMSupportPlanManagerAPIEndpointURL = @"https://support-plan.gpgtools.org/api/v1.0/support-plans";
#endif
#endif
NSString * const kGMSupportPlanManagerActivationDirectory = @"org.gpgtools.gmsp";
NSString * const kGMSupportPlanManagerActivationFile = @".%@.gmsp";
NSString * const kGMSupportPlanManagerNeverAskAgainForUpgradeVersionKey = @"__gmsp_naafuv";
NSString * const kGMSupportPlanManagerAlwaysLoadVersion = @"__gmsp_alv";
NSString * const kGMSupportPlanManagerAlwaysLoadVersionSharedAccessKey = @"AlwaysLoadVersion";
NSString * const kGMSupportPlanManagerEventPrefix = @"__gmsp_event";

NSString * const kGMSupportPlanManagerGMSPLegacyActivationKey = @"GMSPLegacyActivation";
NSString * const kGMSupportPlanManagerGSMPActivationForSharedAccessKey = @"GMSPActivation";

extern NSString * const GMSupportPlanRefreshTypeRegular;
extern NSString * const GMSupportPlanRefreshTypeOffline;

#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@interface GMSPLegacyActivation : NSObject {
    NSString *_productId;
    NSDate *_trialStartDate;
    NSString *_licenseCode;
    NSString *_licenseCodeHash;
    NSDate *_licenseExpiryDate;
    NSString *_activationEmail;
    NSString *_activationID;
    NSDate *_activationDate;
}

- (instancetype)initWithCoder:(id)coder;

@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSDate *trialStartDate;
@property (nonatomic, copy) NSString *licenseCode;
@property (nonatomic, copy) NSString *licenseCodeHash;
@property (nonatomic, copy) NSDate *licenseExpiryDate;
@property (nonatomic, copy) NSString *activationEmail;
@property (nonatomic, copy) NSString *activationID;
@property (nonatomic, copy) NSDate *activationDate;

@end

@implementation GMSPLegacyActivation

- (instancetype)initWithCoder:(id)coder {
    if(self = [super init]) {
        _productId = [[coder decodeObjectForKey:@"productId"] copy];
        _trialStartDate = [[coder decodeObjectForKey:@"trialStartDate"] copy];
        _licenseCode = [[coder decodeObjectForKey:@"licenseCode"] copy];
        _licenseCodeHash = [[coder decodeObjectForKey:@"licenseCodeHash"] copy];
        _licenseExpiryDate = [[coder decodeObjectForKey:@"licenseExpiryDate"] copy];
        _activationEmail = [[coder decodeObjectForKey:@"activationEmail"] copy];
        _activationID = [[coder decodeObjectForKey:@"activationId"] copy];
        _activationDate = [[coder decodeObjectForKey:@"activationDate"] copy];
    }
    return self;
}

@end

@interface GMSupportPlanManager ()

@property (nonatomic, copy) NSURL *endpointURL;
@property (nonatomic, copy) NSURL *activationURL;
@property (nonatomic, copy) NSDictionary *applicationInfo;
@property (nonatomic, retain) GMDevice *currentDevice;
@property (nonatomic, copy) NSArray *timeEvents;

@end

@implementation GMSupportPlanManager

- (instancetype)initWithApplicationID:(NSString *)applicationID applicationInfo:(NSDictionary *)applicationInfo {
    if((self = [super init])) {
        _endpointURL = [[NSURL alloc] initWithString:kGMSupportPlanManagerAPIEndpointURL];
        _applicationID = [applicationID copy];
        _applicationInfo = [applicationInfo copy];
        _currentDevice = [GMDevice currentDeviceWithApplicationInfo:applicationInfo];

        _timeEvents = @[@"sp_refresh", @"trial_expiring_warning", @"inactive_warning"];

        self.supportPlan = [self supportPlanWithActivationFilePath:[[self activationFileURL] path]];
        // On launch, synchronize the shared access data.
        if(self.supportPlan) {
            [self saveActivationForSharedAccess:self.supportPlan appName:nil];
        }
        // Install a support plan if one is passed. In case one already exists,
        // deactivate that one and install a new one.
        [self installSupportPlanFromProcessArgumentsIfNecessary];

        // Based on the params passed to Mail, delete the keep and never ask keys.
        [self resetForceVersionLoadingDefaultsIfNecessary];

        [self refreshSupportPlanIfNecessary];

    }
    return self;
}

- (instancetype)initWithApplicationID:(NSString *)applicationID applicationInfo:(NSDictionary *)applicationInfo fromSharedAccess:(BOOL)fromSharedAccess {

    if((self = [super init])) {
        _applicationID = [applicationID copy];
        _applicationInfo = [applicationInfo copy];

        self.supportPlan = [self supportPlanFromSharedAccessForAppName:applicationID];
    }
    return self;
}


- (GMSupportPlan *)supportPlanFromData:(NSData *)data {
    if([data length]) {
        NSMutableDictionary *supportPlanDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        return [self supportPlanWithDictionary:supportPlanDictionary];
    }
    return nil;
}

- (GMSupportPlan *)supportPlanWithActivationFilePath:(NSString *)path {
    NSData *activationData = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedAlways error:nil];
    return [self supportPlanFromData:activationData];
}

- (GMSupportPlan *)supportPlanForPreviousVersion {
    return [self supportPlanWithActivationFilePath:[[self activationFileURLForApplicationID:@"org.gpgtools.gpgmail"] path]];
}

- (GMSupportPlan *)supportPlanWithDictionary:(NSDictionary *)dictionary {
    GMSupportPlan *supportPlan = [[GMSupportPlan alloc] initWithDictionary:dictionary applicationID:_applicationID applicationInfo:_applicationInfo publicCertificate:kGMSupportPlanManagerPublicCertificate];
    // Reject any support plan that doesn't have a valid signature.
    if(![supportPlan isSignatureValid]) {
        return nil;
    }

    return supportPlan;
}

- (void)resetForceVersionLoadingDefaultsIfNecessary {
    if([[NSUserDefaults standardUserDefaults] valueForKey:@"gpgmail-reset-force-version"]) {
        NSLog(@"[GPGMail] Remove user defaults related to what version is being loaded.");
        [GMSupportPlanManager setAlwaysLoadVersion:nil];
        [GMSupportPlanManager setShouldNeverAskAgainForUpgradeVersion:nil];
    }
}

- (void)installSupportPlanFromProcessArgumentsIfNecessary {
    NSString *activationPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"gpgmail-install-sp"];
    NSString *activationPathForce = [[NSUserDefaults standardUserDefaults] valueForKey:@"gpgmail-install-sp-force"];

    BOOL forceInstallation = [activationPathForce length] ? YES : NO;
    if(forceInstallation) {
        activationPath = activationPathForce;
    }

    if([activationPath length]) {
        NSLog(@"[GPGMail] Attempting to install support activation from %@...", activationPath);
        GMSupportPlan *supportPlan = [self supportPlanWithActivationFilePath:activationPath];
        if(![supportPlan isSignatureValid]) {
            NSLog(@"[GPGMail] Support Plan signature is invalid.");
            return;
        }
        if([supportPlan isExpired]) {
            NSLog(@"[GPGMail] This Support Plan expired on %@", [supportPlan expirationDate]);
            return;
        }
        if(![supportPlan isDeviceValid]) {
            NSLog(@"[GPGMail] This Support Plan is not valid for this device - identifier %@ doesn't match %@", [supportPlan deviceID], [self.currentDevice deviceID]);
        }

        if(self.supportPlan && ![self.supportPlan isKindOfTrial] && !forceInstallation) {
            NSLog(@"[GPGMail] A Support Plan is already installed. Launch Mail with -gpgmail-install-sp-force to deactivate the existing support plan and install the new one.");
        }

        // Deactivate the current support plan.
        if(self.supportPlan != nil) {
            NSLog(@"[GPGMail] Deactivating current support plan: %@", [self currentActivationCode]);
            [self deactivateWithCompletionHandler:^(__unused GMSupportPlan * _Nullable supportPlan, __unused  NSDictionary * _Nullable result, __unused NSError * _Nullable error) {}];
        }

        // Activate the new one.
        NSLog(@"[GPGMail] Activating support plan…");
        [self saveActivation:supportPlan];
        NSLog(@"[GPGMail] Activation completed!");
    }
}

- (void)refreshSupportPlanIfNecessary {
    if([self.supportPlan isValid] && [self.supportPlan refreshType] == GMSupportPlanRefreshTypeOffline) {
        return;
    }

    if([self.supportPlan type] == GMSupportPlanTypeFallbackTrial) {
        // Try to exchange for a valid license.
        if([self lastDateOfEvent:@"exchange_trial" olderThan:3]) {
            [self startTrialWithCompletionHandler:NULL];
        }
        return;
    }

    NSDate *nextRefresh = [self.supportPlan refreshUntil];

    // No support plan available just yet. Make on next launch.
    if(nextRefresh == nil) {
        return;
    }

    NSDate *now = CURRENT_DATE;
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *difference = [currentCalendar components:NSCalendarUnitDay fromDate:now toDate:nextRefresh options:0];

    // Only seven more days. Try to refresh, unless a refresh has been performed in the last
    // 2 days.
    if([difference day] <= 7 && [self lastDateOfEvent:@"sp_refresh" olderThan:3]) {
        [self refresh];
    }
}

- (NSURL *)activationFileURLForApplicationID:(NSString *)applicationID {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *applicationSupportDirectories = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *directoryURL = [[applicationSupportDirectories firstObject] URLByAppendingPathComponent:kGMSupportPlanManagerActivationDirectory];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    });

    return [directoryURL URLByAppendingPathComponent:[NSString stringWithFormat:kGMSupportPlanManagerActivationFile, applicationID]];
}

- (NSURL *)activationFileURL {
    return [self activationFileURLForApplicationID:_applicationID];
}

- (void)startTrialWithCompletionHandler:(gmsp_api_handler_t __nullable)completionHandler {
    NSDictionary *payload = [self requestPayloadForTrial];

    [self runAPICallWithURL:@"/trial" data:payload completionHandler:^(NSDictionary *response, NSError *error) {
        GMSupportPlan *supportPlan = nil;
        if([response[@"success"] boolValue] && response[@"data"]) {
            supportPlan = [self supportPlanWithDictionary:response[@"data"]];
            // A support plan can be expired which would result in a
            // non valid return value. It's still fine to install however.
            if([supportPlan isSignatureValid]) {
                [self saveActivation:supportPlan];
            }
            else {
                NSLog(@"[GPGMail]: Received invalid support plan data from server");
                error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:GMSupportPlanAPIErrorServerError userInfo:nil];
                supportPlan = nil;
            }
        }
        else {
            if([[error domain] isEqualToString:NSURLErrorDomain]) {
                error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:GMSupportPlanAPIErrorNetworkError userInfo:@{@"is_trial": @(YES)}];
            }
            else {
                error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:GMSupportPlanAPIErrorServerError userInfo:@{@"is_trial": @(YES)}];
            }
            // TODO: install fallback trial activation.
        }
        if(completionHandler != NULL) {
            completionHandler(supportPlan, response, error);
        }
    }];
}

- (void)activateSupportPlanWithActivationCode:(NSString *)activationCode email:(NSString *)email completionHandler:(gmsp_api_handler_t)completionHandler {
    NSDictionary *payload = [self requestPayloadForActivationCode:activationCode email:email];

    [self runAPICallWithURL:@"/activate" data:payload completionHandler:^(NSDictionary *response, NSError *error) {
        GMSupportPlan *supportPlan = nil;
        if([response[@"success"] boolValue] && response[@"data"]) {
            supportPlan = [self supportPlanWithDictionary:response[@"data"]];
            // A support plan can be valid for other versions of GPG Mail,
            // thus the app name is not considered.
            if([supportPlan isValidExcludingAppName]) {
                [self saveActivation:supportPlan];
            }
            else {
                NSLog(@"[GPGMail]: Received invalid support plan data from server");
            }
        }
        else {
            if([[error domain] isEqualToString:NSURLErrorDomain]) {
                error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:GMSupportPlanAPIErrorNetworkError userInfo:nil];
            }
            else {
                error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:[response[@"code"] integerValue] userInfo:nil];
                //error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:GMSupportPlanAPIErrorServerError userInfo:nil];
            }
        }
        if(completionHandler) {
            completionHandler(supportPlan, response, error);
        }
    }];
}

- (void)deactivateWithCompletionHandler:(gmsp_api_handler_t)completionHandler {
    if(!self.supportPlan) {
        // Do nothing...
        return;
    }

    // Always remove the activation file, regardless of whether or not the deactivation succeeds.
    NSDictionary *payload = [self requestPayloadForSupportPlan:self.supportPlan];
    [self saveActivation:nil];

    BOOL isV3 = [_applicationID isEqualToString:@"org.gpgtools.gpgmail"];
    [self runAPICallWithURL:@"/deactivate" data:payload completionHandler:^(NSDictionary *response, NSError *error) {
        GMSupportPlan *supportPlan = nil;
        if(![response[@"success"] boolValue]) {
            error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:[response[@"code"] integerValue] userInfo:nil];
        }
        else {
            // Receive a trial activation.
            if(response[@"data"] && !isV3) {
                supportPlan = [self supportPlanWithDictionary:response[@"data"]];
                if([supportPlan isSignatureValid]) {
                    [self saveActivation:supportPlan];
                }
            }
        }
        NSLog(@"Reponse: %@", response);
        if(completionHandler) {
            completionHandler(self.supportPlan, response, error);
        }
    }];
}

- (void)refresh {
    if(!self.supportPlan) {
        // No need to refresh anything...
        return;
    }

    NSDictionary *payload = [self requestPayloadForSupportPlan:self.supportPlan];

    [self runAPICallWithURL:@"/refresh" data:payload completionHandler:^(NSDictionary *response, NSError *error) {
        // Error - don't react at the moment.
        if(![response[@"success"] boolValue] || !response[@"data"]) {
            return;
        }
        GMSupportPlan *supportPlan = [self supportPlanWithDictionary:response[@"data"]];
        if([supportPlan isSignatureValid]) {
            [self saveActivation:supportPlan];
        }
    }];
}

- (void)migratePaddleActivationWithCompletionHandler:(gmsp_api_handler_t)completionHandler {
    NSDictionary *contractInformation = [self legacySupportPlanInformation];
    NSDictionary *payload = nil;

    // The Paddle activation has already been migrated. In that case and existing support
    // plan should be available for v3.
    GMSupportPlan *olderSupportPlan = [self supportPlanForPreviousVersion];
    if([(NSString *)contractInformation[@"ActivationCode"] length]) {
        payload = @{@"meta": [self.currentDevice dictionaryRepresentationWithMAC],
                                  @"activation": @{
                                          @"email": contractInformation[@"ActivationEmail"],
                                          @"activation_code": contractInformation[@"ActivationCode"],
                                          @"activation_id":  contractInformation[@"ActivationID"]
                                          }
                                  };
    }
    else if([olderSupportPlan isValidForAppName:@"org.gpgtools.gpgmail"]) {
        payload = [self requestPayloadForSupportPlan:olderSupportPlan];
    }

    [self runAPICallWithURL:@"/migrate" data:payload completionHandler:^(NSDictionary *response, NSError *error) {
        GMSupportPlan *supportPlan = nil;
        if([response[@"success"] boolValue] && response[@"data"]) {
            supportPlan = [self supportPlanWithDictionary:response[@"data"]];
            if([supportPlan isSignatureValid]) {
                [self saveActivation:supportPlan];
                [self removeLegacySupportInformation];
            }
        }
        else {
            error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:[response[@"code"] integerValue] userInfo:nil];
        }

        if(completionHandler) {
            completionHandler(supportPlan, response, error);
        }
    }];
}

- (void)fetchUpgradeURLWithCompletionHandler:(gmsp_api_handler_t)completionHandler {
    // TODO: What to do if the activation couldn't be migrated yet?
    GMSupportPlan *olderSupportPlan = [self supportPlanForPreviousVersion];
    NSDictionary *payload = [self requestPayloadForSupportPlan:olderSupportPlan];

    [self runAPICallWithURL:@"/upgrade-url" data:payload completionHandler:^(NSDictionary *result, NSError *error) {
        if(![result[@"success"] boolValue]) {
            error = [NSError errorWithDomain:@"org.gpgtools.gpgmail" code:[result[@"code"] integerValue] userInfo:nil];
        }
        NSLog(@"Reponse: %@", result);
        if(completionHandler) {
            completionHandler(self.supportPlan, result[@"data"], error);
        }
    }];
};

- (void)runAPICallWithURL:(NSString *)url data:(NSDictionary *)data completionHandler:(void (^)(NSDictionary *result, NSError *error))completionHandler {
    NSData *json = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[_endpointURL URLByAppendingPathComponent:url]];

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = json;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *bodyData, NSURLResponse __unused *response, NSError *error) {
        id result = nil;
        if(error == nil) {
            result = [NSJSONSerialization JSONObjectWithData:bodyData options:NSJSONReadingMutableContainers error:nil];
        }
        if(completionHandler) {
            completionHandler(result, error);
        }
    }];
    [task resume];
}

- (NSDictionary *)requestPayloadForSupportPlan:(GMSupportPlan *)supportPlan {
    // TODO: Add current activation file data to each request, so the signature
    // can be verified on the server. Nice to have.
    NSMutableDictionary *meta = [NSMutableDictionary dictionaryWithDictionary:[supportPlan metadata]];
    [meta addEntriesFromDictionary:[self.currentDevice dictionaryRepresentation]];
    NSDictionary *payload = @{
                              @"activation": [supportPlan activation],
                              @"meta": meta
                              };
    return payload;
}

- (NSDictionary *)requestPayloadForActivationCode:(NSString *)activationCode email:(NSString *)email {
    NSDictionary *payload = @{
                              @"activation": @{
                                      @"email": email,
                                      @"activation_code": activationCode
                                      },
                              @"meta": [self.currentDevice dictionaryRepresentation]
                              };

    return payload;
}

- (NSDictionary *)requestPayloadForTrial {
    NSDictionary *payload = @{@"meta": [self.currentDevice dictionaryRepresentation]};

    return payload;
}

- (BOOL)saveActivation:(GMSupportPlan * __nullable)supportPlan {
    @synchronized(self) {
        BOOL setCurrent = YES;
        // Only replace the information of the current support plan, if this
        // is a valid support plan for V4. Otherwise if we have a trial, don't
        // set it. Except if the running GPG Mail is V3.
        BOOL isV3 = [_applicationID isEqualToString:@"org.gpgtools.gpgmail"];
        if(!isV3 && ![supportPlan isKindOfTrial] && [supportPlan isValidForAppName:@"org.gpgtools.gpgmail"]) {
            setCurrent = NO;
        }
        NSString *currentAppName = [[self.supportPlan appName] copy];
        if(setCurrent) {
            self.supportPlan = supportPlan;
        }
        NSError *error = nil;
        if(supportPlan) {
            NSURL *activationURL = [self activationFileURLForApplicationID:[supportPlan appName]];
            [supportPlan saveToURL:activationURL error:&error];
            [self saveActivationForSharedAccess:supportPlan appName:nil];
        }
        else {
            // Reset the keep information so next time the user launches GPG Mail,
            // GPG Mail 4 is launched.
            if([_applicationID isEqualToString:@"org.gpgtools.gpgmail"]) {
                [GMSupportPlanManager setAlwaysLoadVersion:nil];
            }
            // This is necessary to make sure that refreshes will happen again.
            [self resetLastDateOfAllEvents];
            [[NSFileManager defaultManager] removeItemAtPath:[[self activationURL] path] error:&error];
            [self saveActivationForSharedAccess:nil appName:currentAppName];
            // If an old support plan also exists, remove that one as well.
            GMSupportPlan *olderSupportPlan = [self supportPlanForPreviousVersion];
            if(olderSupportPlan != nil) {
                [[NSFileManager defaultManager] removeItemAtPath:[[self activationFileURLForApplicationID:[olderSupportPlan appName]] path] error:&error];
                [self saveActivationForSharedAccess:nil appName:[olderSupportPlan appName]];
            }
        }
        return YES;
    }
}

- (NSURL *)activationURL {
    return _activationURL;
}

- (BOOL)supportPlanIsActive {
    BOOL isActive = NO;
#ifdef DEBUG
    if([[self simulatedOptionForKey:@"SupportPlan"] boolValue] && [self simulatedOptionForKey:@"SupportPlanActive"]) {
        isActive = [[self simulatedOptionForKey:@"SupportPlanActive"] boolValue];
    }
#endif
    // Is active might be set to YES already from the debug section.
    if(!isActive) {
        isActive = self.supportPlan && [self.supportPlan isValid];
    }

    return isActive;
}

- (NSNumber *)remainingTrialDays {
    if(!self.supportPlan) {
        return nil;
    }

    if(![self.supportPlan isKindOfTrial]) {
        return nil;
    }

    NSTimeInterval remainingTimeInterval = [self.supportPlan remainingTimeInterval];
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *difference = [currentCalendar components:NSCalendarUnitDay fromDate:[NSDate date] toDate:[NSDate dateWithTimeIntervalSinceNow:remainingTimeInterval] options:0];

    return @([difference day]);
}

- (NSString *)currentActivationCode {
    NSString *activationCode = nil;
#ifdef DEBUG
    if([[self simulatedOptionForKey:@"SupportPlan"] boolValue]) {
        activationCode = [self simulatedOptionForKey:@"SupportPlanActivationCode"];
    }
#endif
    if(!activationCode) {
        activationCode = [self.supportPlan activationCode];
    }
    return activationCode;
}

- (NSString *)currentEmail {
    NSString *email = nil;
#ifdef DEBUG
    if([[self simulatedOptionForKey:@"SupportPlan"] boolValue]) {
        email = [self simulatedOptionForKey:@"SupportPlanActivationEmail"];
    }
#endif
    if(!email) {
        email = [self.supportPlan email];
    }

    return email;
}

- (BOOL)shouldPromptUserForUpgrade {
    return [self upgradeState] != GMSupportPlanManagerUpgradeStateVersionSupported;
}

- (GMSupportPlanManagerUpgradeState)upgradeState {
    // If this is version three, there's never a need to display the upgrade dialog,
    // since that only gets loaded if the user chose to keep GPG Mail 3.
    if([_applicationID isEqualToString:@"org.gpgtools.gpgmail"]) {
        return GMSupportPlanManagerUpgradeStateVersionSupported;
    }

    if([self supportPlanIsActive] && ![[self supportPlan] isKindOfTrial]) {
        return GMSupportPlanManagerUpgradeStateVersionSupported;
    }

    GMSupportPlan *olderSupportPlan = [self supportPlanForPreviousVersion];
    BOOL activationForOlderVersionAvailable = [self isLegacySupportPlanActive] || [olderSupportPlan isValidForAppName:@"org.gpgtools.gpgmail"];

    // Check if either an old paddle support plan is available for V3, or
    // if the activation has already been migrated but is only valid for V3.
    if(!activationForOlderVersionAvailable) {
        return GMSupportPlanManagerUpgradeStateVersionSupported;
    }

    BOOL supportsGPGMail4Only = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,15,0}];
#ifdef DEBUG
    if(!supportsGPGMail4Only && [[[GPGOptions sharedOptions] valueForKey:@"SimulateSupportsGPGMail4Only"] boolValue]) {
        supportsGPGMail4Only = YES;
    }
#endif
    if(supportsGPGMail4Only) {
        return GMSupportPlanManagerUpgradeStateUpgradeFromVersion3ToVersion4;
    }
    else {
        return GMSupportPlanManagerUpgradeStateUpgradeOrKeepVersion3;
    }

    return GMSupportPlanManagerUpgradeStateVersionSupported;
}

- (GMSPLegacyActivation *)legacySupportPlan {
    GPGOptions *options = [[self class] GPGOptions];

    NSString *activationData = [options valueForKey:kGMSupportPlanManagerGMSPLegacyActivationKey];
    if(![activationData length]) {
        return nil;
    }
    NSData *paddleData = [[NSData alloc] initWithBase64EncodedData:[activationData dataUsingEncoding:NSUTF8StringEncoding] options:1];
    NSDictionary *unarchiver = [NSKeyedUnarchiver unarchiveObjectWithData:paddleData];

    NSData *license = [unarchiver objectForKey:@"license_data"];

    // Key is simply md5 of product id...
    NSString *key = @"ccf88ad32ab8d844ba52691984f7a71d";

    char keyPtr[kCCKeySizeAES256+1];
    bzero( keyPtr, sizeof( keyPtr ) );

    [key getCString:keyPtr maxLength:sizeof( keyPtr ) encoding:NSUTF8StringEncoding];

    NSUInteger dataLength = [license length];

    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc( bufferSize );

    size_t numBytesDecrypted = 0;

    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [license bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);

    if(cryptStatus != kCCSuccess) {
        return nil;
    }

    NSData *decryptedData = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    [NSKeyedUnarchiver setClass:[GMSPLegacyActivation class] forClassName:@"PADLicenseFile"];
    GMSPLegacyActivation *legacyActivation = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];

    return legacyActivation;
}


- (NSDictionary *)legacySupportPlanInformation {
#ifdef DEBUG
    NSDictionary *testLegacySupportPlanFrom = [[NSUserDefaults standardUserDefaults] valueForKey:@"GPGMailSimulateLegacySupportPlan"];
    if(testLegacySupportPlanFrom) {
        return testLegacySupportPlanFrom;
    }
#endif
    GMSPLegacyActivation *legacySupportPlan = [self legacySupportPlan];
    if(!legacySupportPlan) {
        return nil;
    }
    if(![[legacySupportPlan activationID] length]) {
        return nil;
    }
    NSDictionary *activationInfo = @{@"ActivationCode": [legacySupportPlan licenseCode], @"ActivationEmail": [legacySupportPlan activationEmail], @"Active": @(YES), @"ActivationID": [legacySupportPlan activationID]};
    return activationInfo;
}

- (void)removeLegacySupportInformation {
    GPGOptions *options = [[self class] GPGOptions];
    [options setValue:nil forKey:kGMSupportPlanManagerGMSPLegacyActivationKey];
}

- (BOOL)isLegacySupportPlanActive {
    NSDictionary *contractInformation = [self legacySupportPlanInformation];
    if([(NSString *)contractInformation[@"ActivationCode"] length] != 0 && [contractInformation[@"Active"] boolValue]) {
        return YES;
    }

    return NO;
}

- (BOOL)isEligibleForApp:(NSString *)app {
    // If no support plan information is available, there's no need to perform
    // further checks.
    if(![self supportPlanIsActive]) {
        return NO;
    }

    return [[self.supportPlan appName] isEqualToString:app];
}

- (GMSupportPlanState)supportPlanState {
    GMSupportPlanType supportPlanType = self.supportPlan != nil ? [self.supportPlan type] : GMSupportPlanTypeNone;

    if(!self.supportPlan) {
        return GMSupportPlanStateInactive;
    }

    // Non-expired trial or valid activation.
    if([self supportPlanIsActive]) {
        return [self.supportPlan isKindOfTrial] ? GMSupportPlanStateTrial : GMSupportPlanStateActive;
    }

    if([self.supportPlan isKindOfTrial]) {
        return [self.supportPlan isExpired] ? GMSupportPlanStateTrialExpired : GMSupportPlanStateInactive;
    }

    if(supportPlanType == GMSupportPlanTypeTime) {
        return [self.supportPlan isExpired] ? GMSupportPlanStateTimedExpired : GMSupportPlanStateInactive;
    }

    return GMSupportPlanStateInactive;
}

- (BOOL)installFallbackTrial {
    if(self.supportPlan) {
        return NO;
    }
    NSData *trialData = [[kGMSupportPlanManagerFallbackTrial GMSP_base64Decode] dataUsingEncoding:NSUTF8StringEncoding];
    if(!trialData) {
        return NO;
    }

    id supportPlanDictionary = [NSJSONSerialization JSONObjectWithData:trialData options:NSJSONReadingMutableContainers error:nil];
    if(!supportPlanDictionary) {
        return NO;
    }
    GMSupportPlan *supportPlan = [self supportPlanWithDictionary:supportPlanDictionary];
    if([supportPlan isSignatureValid] && [supportPlan isAppNameValid]) {
        [self saveActivation:supportPlan];
        return YES;
    }
    return NO;
}

- (BOOL)shouldPresentActivationDialog {
    // Active support plan -> show never
    // Active trial -> only show if about to expire. Every 2nd day.
    if([self supportPlanIsActive]) {
        if([[self supportPlan] isAboutToExpire] && [self lastDateOfEvent:@"trial_expiring_warning" olderThan:3]) {
            return YES;
        }
        return NO;
    }

    // Support plan is not active, show the activation dialog every 7 days.
    if([self upgradeState] != GMSupportPlanManagerUpgradeStateVersionSupported) {
        return [self lastDateOfEvent:@"inactive_warning" olderThan:3];
    }

    return [self lastDateOfEvent:@"inactive_warning" olderThan:7];
}

- (BOOL)lastDateOfEvent:(NSString *)eventName olderThan:(NSInteger)days {
    NSString *defaultsName = [kGMSupportPlanManagerEventPrefix stringByAppendingFormat:@"_%@", eventName];
    NSDate *lastDate = [[NSUserDefaults standardUserDefaults] valueForKey:defaultsName];
    NSDate *now = CURRENT_DATE;
    if(!lastDate) {
        [[NSUserDefaults standardUserDefaults] setValue:now forKey:defaultsName];
        return YES;
    }

    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *difference = [currentCalendar components:NSCalendarUnitDay fromDate:lastDate toDate:now options:0];

    BOOL older = [difference day] > days;
    if(older) {
        [[NSUserDefaults standardUserDefaults] setValue:now forKey:defaultsName];
        return YES;
    }

    return NO;
}

- (void)resetLastDateOfEvent:(NSString *)eventName {
    NSString *defaultsName = [kGMSupportPlanManagerEventPrefix stringByAppendingFormat:@"_%@", eventName];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsName];
}

- (void)resetLastDateOfAllEvents {
    for(NSString *key in _timeEvents) {
        [self resetLastDateOfEvent:key];
    }
}

+ (void)setShouldNeverAskAgainForUpgradeVersion:(NSString * __nullable)version {
    if(!version) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGMSupportPlanManagerNeverAskAgainForUpgradeVersionKey];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setValue:version forKey:kGMSupportPlanManagerNeverAskAgainForUpgradeVersionKey];

    }
}

+ (NSString *)shouldNeverAskAgainForUpgradeVersion {
    return [[NSUserDefaults standardUserDefaults] valueForKey:kGMSupportPlanManagerNeverAskAgainForUpgradeVersionKey];
}

+ (NSString *)alwaysLoadVersion {
    return [[NSUserDefaults standardUserDefaults] valueForKey:kGMSupportPlanManagerAlwaysLoadVersion];
}

+ (void)setAlwaysLoadVersion:(NSString * __nullable)version {
    if(!version) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGMSupportPlanManagerAlwaysLoadVersion];
        [self setAlwaysLoadVersionForSharedAccess:version];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setValue:version forKey:kGMSupportPlanManagerAlwaysLoadVersion];
        [self setAlwaysLoadVersionForSharedAccess:version];
    }
}

+ (NSString *)alwaysLoadVersionSharedAccess {
    GPGOptions *options = [[self class] GPGOptions];

    return [options valueForKey:kGMSupportPlanManagerAlwaysLoadVersionSharedAccessKey];
}

+ (void)setAlwaysLoadVersionForSharedAccess:(NSString *)version {
    GPGOptions *options = [[self class] GPGOptions];

    [options setValue:version forKey:kGMSupportPlanManagerAlwaysLoadVersionSharedAccessKey];
}

#ifdef DEBUG
+ (NSDate *)currentDate {
    NSNumber *timeNumber = [[NSUserDefaults standardUserDefaults] valueForKey:@"GPGMailSimulateCurrentDate"];
    if(!timeNumber) {
        return [NSDate date];
    }
    return [NSDate dateWithTimeIntervalSince1970:[timeNumber integerValue]];
}
#endif

- (BOOL)isMultiUser {
    // In case of an upgrade, the current support plan will point to a trial or not be set at all.
    // The actual support plan information will be available in previousVersion.
    GMSupportPlan *supportPlan = [self supportPlanForPreviousVersion];
    if(!supportPlan) {
        return NO;
    }

    return [supportPlan isMultiUser];
}

- (BOOL)saveActivationForSharedAccess:(GMSupportPlan *)supportPlan appName:(NSString *)appName {
    NSString *supportPlanData = nil;
    if(supportPlan) {
        supportPlanData = [[supportPlan asData] base64EncodedStringWithOptions:0];
    }
    GPGOptions *options = [[self class] GPGOptions];

    NSMutableDictionary *supportPlans = [[options valueForKey:kGMSupportPlanManagerGSMPActivationForSharedAccessKey] mutableCopy];
    if(!supportPlans) {
        supportPlans = [NSMutableDictionary new];
    }
    appName = appName == nil ? [supportPlan appName] : appName;
    if(supportPlan == nil) {
        if(appName != nil) {
            [supportPlans removeObjectForKey:appName];
        }
    }
    else {
        [supportPlans setValue:supportPlanData forKey:appName];
    }

    [options setValue:supportPlans forKey:kGMSupportPlanManagerGSMPActivationForSharedAccessKey];
    return YES;
}

- (GMSupportPlan *)supportPlanFromSharedAccessForAppName:(NSString *)appName {
    GPGOptions *options = [[self class] GPGOptions];

    NSDictionary *supportPlans = [options valueForKey:kGMSupportPlanManagerGSMPActivationForSharedAccessKey];
    NSString *supportPlanData = [supportPlans valueForKey:appName];
    if(!supportPlanData) {
        return nil;
    }
    GMSupportPlan *supportPlan = [self supportPlanFromData:[[supportPlanData GMSP_base64Decode] dataUsingEncoding:NSUTF8StringEncoding]];
    if(![supportPlan isSignatureValid]) {
        return nil;
    }

    return supportPlan;
}

+ (GPGOptions *)GPGOptions {
    GPGOptions *options = [GPGOptions sharedOptions];
    options.standardDomain = @"org.gpgtools.gpgmail";

    return options;
}

- (id)simulatedOptionForKey:(NSString *)key {
    return [[[self class] GPGOptions] valueForKey:[NSString stringWithFormat:@"GPGMailSimulate%@", key]];
}

@end

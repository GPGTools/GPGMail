//
//  GMSupportPlan.m
//  GPGMail
//
//  Created by Lukas Pitschl on 23.10.19.
//

#include <CommonCrypto/CommonDigest.h>

#import "GMSupportPlanManager.h"
#import "GMSupportPlan.h"
#import "GMDevice.h"

typedef enum {
    GMSupportPlanSignatureStatusUnknown,
    GMSupportPlanSignatureStatusValid,
    GMSupportPlanSignatureStatusInvalid
} GMSupportPlanSignatureStatus;

@interface GMSupportPlan ()

@property (nonatomic, copy, readonly) NSData *publicCertificate;
@property (nonatomic, copy) NSDictionary *applicationInfo;
@property (nonatomic, retain) GMDevice *currentDevice;
@property (atomic, assign) GMSupportPlanSignatureStatus signatureStatus;

@end

NSString * const GMSupportPlanTypeValueTrial = @"trial";
NSString * const GMSupportPlanTypeValueFallbackTrial = @"fallbacktrial";
NSString * const GMSupportPlanTypeValueStatic = @"static";
NSString * const GMSupportPlanTypeValueTime = @"time";

NSString * const GMSupportPlanRefreshTypeRegular = @"regular";
NSString * const GMSupportPlanRefreshTypeOffline = @"offline";

@implementation GMSupportPlan

- (instancetype)initWithDictionary:(NSDictionary *)dictionary applicationID:(NSString *)applicationID applicationInfo:(NSDictionary *)applicationInfo publicCertificate:(NSString *)certificate {
    if((self = [super init])) {
        _activation = [[dictionary valueForKey:@"activation"] copy];

        _metadata = [[dictionary valueForKey:@"meta"] copy];
        // Certificate use # in case of // since otherwise macro expansion doesn't work properly.
        certificate = [certificate stringByReplacingOccurrencesOfString:@"#" withString:@"//"];
        _publicCertificate = [[NSData alloc] initWithBase64EncodedString:certificate options:NSDataBase64DecodingIgnoreUnknownCharacters];
        _applicationID = [applicationID copy];
        _applicationInfo = [applicationInfo copy];
        _signatureStatus = 0;
        _currentDevice = [GMDevice currentDeviceWithApplicationInfo:applicationInfo];
        _offline = [_activation[@"offline"] boolValue];

#ifdef NO_SUPPORT_PLAN
        //_activation = [[dictionary valueForKey:@"activation"] mutableCopy];
        _activation = [_activation mutableCopy];
        
        [_activation setValue:[applicationID copy] forKey:@"app"];
        
        [_activation setValue:[[self.currentDevice deviceID] copy] forKey:@"udid"];
        
        //[_activation setValue:GMSupportPlanTypeValueTime forKey:@"type"];
        [_activation setValue:GMSupportPlanTypeValueStatic forKey:@"type"];
        
        [_activation setValue:@"1577833200" forKey:@"issued"]; // 01/01/2020
        [_activation setValue:@"1577833200" forKey:@"updated"]; // 01/01/2020
        [_activation setValue:@"1577833200" forKey:@"refresh"]; // 01/01/2020
        
        [_activation setValue:@"4733506800" forKey:@"expiration"]; // 01/01/2120
        
        [_activation setValue:@"true" forKey:@"offline"];
        
        
        [_activation setValue:@"FREE USE" forKey:@"email"];
        [_activation setValue:@"NOT OFFICIAL VERSION" forKey:@"activation_code"];
        
        [_activation setValue:@"yes" forKey:@"volume"];
        
        
        _signatureStatus = GMSupportPlanSignatureStatusValid;
        _offline = true;
#endif
        
        

    }

    return self;
}

- (BOOL)saveToURL:(NSURL *)url error:(NSError __autoreleasing **)error {
    NSData *data = [self asData];
    return [data writeToFile:[url path] options:NSDataWritingAtomic error:error];
}

- (NSData *)asData {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"activation"] = _activation;
    json[@"meta"] = _metadata;

    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    return data;
}

- (nullable NSDateInterval *)validityInterval {
    if(!self.activation[@"issued"] || !self.activation[@"expiration"]) {
        return nil;
    }
    NSInteger issued = [self.activation[@"issued"] integerValue];
    NSDate *issuedDate = [NSDate dateWithTimeIntervalSince1970:issued];
    // Add approximately a day, to extend the duration for one day.
    // As a result, the remainingTrialDays will say 30 instead of 29.
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:[self.activation[@"expiration"] integerValue] + (24 * 60 * 60)];

    if(!expirationDate || !issuedDate) {
        return nil;
    }

    NSDate *referenceDate = [expirationDate laterDate:issuedDate];
    // Invalid expiration date. Expiration is later than issue date.
    if(referenceDate == issuedDate) {
        return nil;
    }

    return [[NSDateInterval alloc] initWithStartDate:issuedDate endDate:expirationDate];
}

- (NSDate *)expirationDate {
    // Expiration date shouldn't before 2019.
    if(!self.activation[@"expiration"] || [self.activation[@"expiration"] integerValue] <= 1567296000) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:[self.activation[@"expiration"] integerValue]];
}

- (NSTimeInterval)remainingTimeInterval {
    NSDateInterval *validityInterval = [self validityInterval];
    // Check validity of the license, otherwise return nil?
    return [[validityInterval endDate] timeIntervalSinceDate:CURRENT_DATE];
}

- (BOOL)isValid {
    return [self isValidExcludingAppName] && [self isAppNameValid];
}

- (BOOL)isValidExcludingAppName {
    return [self isSignatureValid] && [self isDeviceValid] && ![self isExpired];
}

- (BOOL)isValidForAppName:(NSString *)appName {
    return [self isValidExcludingAppName] && [self.appName isEqualToString:appName];
}

- (void)validateSignature {
    NSString *signature = self.metadata[@"sig"];
    if(![signature length]) {
        self.signatureStatus = GMSupportPlanSignatureStatusInvalid;
        return;
    }

    if(!_publicCertificate) {
        self.signatureStatus = GMSupportPlanSignatureStatusInvalid;
        return;
    }

    NSData *signatureData = [[NSData alloc] initWithBase64EncodedString:signature options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *digestBase = [self.activation GMSP_hashBaseWithSeparator:@"-"];
    NSData *digestBaseData = [[digestBase GMSP_SHA256] dataUsingEncoding:NSUTF8StringEncoding];

    CFDataRef dataRef = CFDataCreate(NULL, [_publicCertificate bytes], [_publicCertificate length]);
    SecCertificateRef ref = SecCertificateCreateWithData(NULL, dataRef);
    if(ref != 0) {
        SecPolicyRef x509Ref = SecPolicyCreateBasicX509();
        SecTrustRef trustRef;
        if(SecTrustCreateWithCertificates(ref, x509Ref, &trustRef) == errSecSuccess) {
            SecTrustResultType resultRef;

            if(SecTrustEvaluate(trustRef, &resultRef) == errSecSuccess) {
                SecKeyRef publicKeyRef = SecTrustCopyPublicKey(trustRef);

                CFDataRef signedDataRef = CFDataCreate(NULL, [digestBaseData bytes], [digestBaseData length]);
                CFDataRef signatureDataRef = CFDataCreate(NULL, [signatureData bytes], [signatureData length]);
                CFErrorRef error;
                if(SecKeyVerifySignature(publicKeyRef, kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256, signedDataRef, signatureDataRef, &error)) {
                    self.signatureStatus = GMSupportPlanSignatureStatusValid;
                }
                else {
                    self.signatureStatus = GMSupportPlanSignatureStatusInvalid;
                }

                CFRelease(signatureDataRef);
                CFRelease(signedDataRef);
                CFRelease(publicKeyRef);
            }

            CFRelease(trustRef);
        }

        CFRelease(x509Ref);
        CFRelease(ref);
    }

    CFRelease(dataRef);

    if(self.signatureStatus == GMSupportPlanSignatureStatusUnknown) {
        self.signatureStatus = GMSupportPlanSignatureStatusInvalid;
    }
}

- (BOOL)isSignatureValid {
    if(self.signatureStatus <= GMSupportPlanSignatureStatusUnknown) {
        @synchronized(self) {
            [self validateSignature];
        }
    }
    return self.signatureStatus == GMSupportPlanSignatureStatusValid ? YES : NO;
}

- (BOOL)isAppNameValid {
    return [_applicationID isEqualToString:self.appName];
}

- (BOOL)isEligibleForAppWithName:(NSString *)appName {
    return [[self.activation[@"eligible_apps"] allValues] containsObject:appName];
}

- (BOOL)isDeviceValid {
    if([self type] == GMSupportPlanTypeFallbackTrial) {
        return YES;
    }
    return [self.activation[@"udid"] isEqualToString:[self.currentDevice deviceID]];
}

- (NSString *)deviceID {
    return self.activation[@"udid"];
}

- (BOOL)isExpired {
    // If no expiration is set, there's no expiration.
    NSDateInterval *validityInterval = [self validityInterval];
    if(!validityInterval) {
        return NO;
    }
    return ![validityInterval containsDate:CURRENT_DATE];
}

- (NSString *)appName {
    return self.activation[@"app"];
}

- (GMSupportPlanType)type {
    if(!self.activation || !self.activation[@"did"]) {
        return GMSupportPlanTypeNone;
    }
    if([self.activation[@"type"] isEqualToString:GMSupportPlanTypeValueTrial]) {
        return GMSupportPlanTypeTrial;
    }
    if([self.activation[@"type"] isEqualToString:GMSupportPlanTypeValueTime]) {
        return GMSupportPlanTypeTime;
    }
    if([self.activation[@"type"] isEqualToString:GMSupportPlanTypeValueFallbackTrial]) {
        return GMSupportPlanTypeFallbackTrial;
    }

    return GMSupportPlanTypeStatic;
}

- (BOOL)isKindOfTrial {
    return [self type] == GMSupportPlanTypeTrial || [self type] == GMSupportPlanTypeFallbackTrial;
}

- (BOOL)isAboutToExpire {
    if(!self.expirationDate) {
        return NO;
    }
    NSTimeInterval remainingTimeInterval = [self remainingTimeInterval];
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
#ifdef DEBUG
    NSDateComponents *difference = [currentCalendar components:NSCalendarUnitDay fromDate:CURRENT_DATE toDate:[NSDate dateWithTimeInterval:remainingTimeInterval sinceDate:CURRENT_DATE] options:0];
#else
    NSDateComponents *difference = [currentCalendar components:NSCalendarUnitDay fromDate:CURRENT_DATE toDate:[NSDate dateWithTimeIntervalSinceNow:remainingTimeInterval] options:0];
#endif

    return [difference day] <= 7 ? YES : NO;
}

- (NSDate *)lastUpdate {
    if(![self.activation[@"updated"] integerValue]) {
        return nil;
    }
    NSDate *lastUpdate = [NSDate dateWithTimeIntervalSince1970:[self.activation[@"updated"] integerValue]];
    if(!lastUpdate) {
        return nil;
    }

    return lastUpdate;
}

- (NSDate *)refreshUntil {
    if(![self.activation[@"refresh"] integerValue]) {
        return nil;
    }
    NSDate *refreshUntil = [NSDate dateWithTimeIntervalSince1970:[self.activation[@"refresh"] integerValue]];
    if(!refreshUntil) {
        return nil;
    }

    return refreshUntil;
}

- (NSString *)refreshType {
    return _offline ? GMSupportPlanRefreshTypeOffline : GMSupportPlanRefreshTypeRegular;
}

- (NSString *)activationCode {
    return self.activation[@"activation_code"];
}

- (NSString *)email {
    return self.activation[@"email"];
}

- (BOOL)isMultiUser {
    id volume = self.activation[@"volume"];
    if([volume isKindOfClass:[NSNumber class]]) {
        return [volume boolValue];
    }
    else if([volume isKindOfClass:[NSString class]]) {
        return [volume isEqualToString:@"yes"] ? YES : NO;
    }

    return NO;
}

@end

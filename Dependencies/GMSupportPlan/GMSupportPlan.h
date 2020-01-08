//
//  GMSupportPlan.h
//  GPGMail
//
//  Created by Lukas Pitschl on 23.10.19.
//

#import <Foundation/Foundation.h>

#import "GMSPCommon.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define CURRENT_DATE [NSClassFromString(@"GMSupportPlanManager") currentDate]
#else
#define CURRENT_DATE [NSDate date]
#endif

typedef enum {
    GMSupportPlanTypeNone = 0, // No support plan.
    GMSupportPlanTypeTrial = 1040, // Trial type
    GMSupportPlanTypeFallbackTrial = 1041, // Trial type
    GMSupportPlanTypeStatic = 1050, // Valid
    GMSupportPlanTypeTime = 1060
} GMSupportPlanType;

@interface GMSupportPlan : NSObject {
    NSDictionary *_activation;
    NSDictionary *_metadata;

    NSData *_publicCertificate;
    NSString *_applicationID;

    BOOL _offline;
}

- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error;
- (NSData *)asData;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary applicationID:(NSString *)applicationID applicationInfo:(NSDictionary *)applicationInfo publicCertificate:(NSString *)certificate;
- (nullable NSDateInterval *)validityInterval;
- (NSTimeInterval)remainingTimeInterval;
- (NSString *)appName;
- (GMSupportPlanType)type;
- (BOOL)isValid;
- (BOOL)isExpired;
- (BOOL)isAboutToExpire;

- (BOOL)isValidForAppName:(NSString *)appName;
- (BOOL)isValidExcludingAppName;
- (BOOL)isSignatureValid;
- (BOOL)isDeviceValid;

- (NSDate *)expirationDate;
- (NSString *)deviceID;

- (NSDate *)lastUpdate;
- (NSDate *)refreshUntil;

- (NSString *)refreshType;

- (NSString *)activationCode;
- (NSString *)email;

- (BOOL)isMultiUser;

- (BOOL)isKindOfTrial;
- (BOOL)isAppNameValid;

@property (atomic, copy) NSDictionary *metadata;
@property (atomic, copy) NSDictionary *activation;


@end

NS_ASSUME_NONNULL_END

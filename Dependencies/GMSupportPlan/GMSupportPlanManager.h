//
//  GMSupportPlanManager.h
//  GPGMail
//
//  Created by Lukas Pitschl on 23.10.19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GMSupportPlan;

typedef void (^gmsp_api_handler_t)(GMSupportPlan * __nullable supportPlan, NSDictionary * __nullable result, NSError * __nullable error);

typedef enum {
    GMSupportPlanManagerUpgradeStateVersionUnknown,
    GMSupportPlanManagerUpgradeStateVersionSupported,
    GMSupportPlanManagerUpgradeStateUpgradeFromVersion3ToVersion4,
    GMSupportPlanManagerUpgradeStateUpgradeOrKeepVersion3
} GMSupportPlanManagerUpgradeState;

typedef enum {
    GMSupportPlanStateInactive = 0,
    GMSupportPlanStateTrial = 2090,
    GMSupportPlanStateTrialExpired = 3020,
    GMSupportPlanStateActive = 4000,
    GMSupportPlanStateTimedExpired = 4040
} GMSupportPlanState;

typedef enum {
    GMSupportPlanAPIErrorServerError = 10,
    GMSupportPlanAPIErrorNetworkError = 99,
    GMSupportPlanAPIErrorActivationCodeNotFound = 100,
    GMSupportPlanAPIErrorActivationCodeAlreadyUsed = 104,
    GMSupportPlanAPIErrorUpgradeURLVolume = 165
} GMSupportPlanAPIError;

@interface GMSupportPlanManager : NSObject {
    NSURL *_endpointURL;
    NSURL *_activationURL;
    NSString *_applicationID;
    NSDictionary *_applicationInfo;
}

- (instancetype)initWithApplicationID:(NSString *)applicationID applicationInfo:(NSDictionary *)applicationInfo;
- (instancetype)initWithApplicationID:(NSString *)applicationID applicationInfo:(NSDictionary *)applicationInfo fromSharedAccess:(BOOL)fromSharedAccess;
- (BOOL)supportPlanIsActive;
- (NSNumber *)remainingTrialDays;
- (NSString *)currentEmail;
- (NSString *)currentActivationCode;

- (void)startTrialWithCompletionHandler:(gmsp_api_handler_t __nullable)completionHandler;
- (void)activateSupportPlanWithActivationCode:(NSString *)activationCode email:(NSString *)email completionHandler:(gmsp_api_handler_t)completionHandler;
- (void)deactivateWithCompletionHandler:(gmsp_api_handler_t)completionHandler;
- (void)fetchUpgradeURLWithCompletionHandler:(gmsp_api_handler_t)completionHandler;
- (void)migratePaddleActivationWithCompletionHandler:(gmsp_api_handler_t)completionHandler;

- (BOOL)shouldPromptUserForUpgrade;
- (GMSupportPlanManagerUpgradeState)upgradeState;

- (NSDictionary *)legacySupportPlanInformation;

- (BOOL)isEligibleForApp:(NSString *)app;

- (BOOL)shouldPresentActivationDialog;
- (GMSupportPlanState)supportPlanState;

+ (NSString *)shouldNeverAskAgainForUpgradeVersion;
+ (void)setShouldNeverAskAgainForUpgradeVersion:(NSString * __nullable)version;;

+ (NSString *)alwaysLoadVersion;
+ (void)setAlwaysLoadVersion:(NSString * __nullable)version;
+ (NSString *)alwaysLoadVersionSharedAccess;
+ (void)setAlwaysLoadVersionForSharedAccess:(NSString *)version;

- (void)resetLastDateOfAllEvents;

- (BOOL)isMultiUser;
- (BOOL)installFallbackTrial;

#ifdef DEBUG
+ (NSDate *)currentDate;
#endif

@property (nonatomic, retain) GMSupportPlan *supportPlan;




@end

NS_ASSUME_NONNULL_END

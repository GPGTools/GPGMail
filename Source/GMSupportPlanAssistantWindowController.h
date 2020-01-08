//
//  GMSupportPlanWindowController.h
//  GPGMail
//
//  Created by Lukas Pitschl on 20.09.18.
//

#import <AppKit/AppKit.h>

@class GMSupportPlanManager, GMSupportPlan;

typedef enum : NSUInteger {
    GMSupportPlanViewControllerStateUninitialized,
    GMSupportPlanViewControllerStateBuy,
    GMSupportPlanViewControllerStateActivating,
	GMSupportPlanViewControllerStateThanks,
	GMSupportPlanViewControllerStateInfo,
    GMSupportPlanViewControllerStateCheckingSupportPlanStatus,
    GMSupportPlanViewControllerStateActivatingTrial
} GMSupportPlanAssistantViewControllerState;

typedef enum : NSUInteger {
    GMSupportPlanAssistantDialogTypeInactive,
    GMSupportPlanAssistantDialogTypeCheckingSupportPlanStatus,
    GMSupportPlanAssistantDialogTypeTrial,
    GMSupportPlanAssistantDialogTypeTrialAboutToExpire,
    GMSupportPlanAssistantDialogTypeTrialExpired,
    GMSupportPlanAssistantDialogTypeTrialActivationComplete,
    GMSupportPlanAssistantDialogTypeActivationComplete,
    GMSupportPlanAssistantDialogTypeUpgrade,
    GMSupportPlanAssistantDialogTypeUpgradeKeepPreviousVersion
} GMSupportPlanAssistantDialogType;

typedef enum : NSUInteger {
    GMSupportPlanAssistantBuyActivateButtonStateBuy,
    GMSupportPlanAssistantBuyActivateButtonStateActivate,
    GMSupportPlanAssistantBuyActivateButtonStateUpgrade,
    GMSupportPlanAssistantBuyActivateButtonStateKeepVersion3,
    GMSupportPlanAssistantBuyActivateButtonStateClose
} GMSupportPlanAssistantBuyActivateButtonState;

typedef enum : NSUInteger {
    GMSupportPlanAssistantButtonActionBuy,
    GMSupportPlanAssistantButtonActionActivate,
    GMSupportPlanAssistantButtonActionUpgrade,
    GMSupportPlanAssistantButtonActionKeepVersion3,
    GMSupportPlanAssistantButtonActionClose,
    GMSupportPlanAssistantButtonActionStartTrial,
    GMSupportPlanAssistantButtonActionContinueTrial,
    GMSupportPlanAssistantButtonActionCloseWithWarning
} GMSupportPlanAssistantButtonAction;

@protocol GMSupportPlanAssistantDelegate <NSObject>

- (void)supportPlanAssistant:(NSWindowController *)windowController email:(NSString *)email activationCode:(NSString *)activationCode;
- (void)supportPlanAssistantDidClose:(NSWindowController *)windowController;
- (void)closeSupportPlanAssistant:(NSWindowController *)windowController;
- (void)supportPlanAssistantShouldStartTrial:(NSWindowController *)windowController;
- (NSDictionary *)contractInformation;
- (NSDictionary *)supportPlanInformationForAutomaticActivationWithSupportPlanAssistant:(NSWindowController *)windowController;

@end

@interface GMSupportPlanAssistantWindowController : NSWindowController
@property (nonatomic, weak) id<GMSupportPlanAssistantDelegate> delegate;
@property (nonatomic, assign) BOOL closeWindowAfterError;

- (void)showActivationError;
- (void)activationDidCompleteWithSuccessForSupportPlan:(GMSupportPlan *)supportPlan;
- (void)activationDidFailWithError:(NSError *)error;
- (instancetype)initWithSupportPlanManager:(GMSupportPlanManager *)supportPlanManager;
- (void)performAutomaticSupportPlanActivationWithActivationCode:(NSString *)activationCode email:(NSString *)email;

@end

@interface GMSupportPlanAssistantViewController : NSViewController
@property (weak) id<GMSupportPlanAssistantDelegate> delegate;
@property (nonatomic) GMSupportPlanAssistantViewControllerState state;
@property (nonatomic) GMSupportPlanAssistantViewControllerState previousState;

@property (nonatomic) NSString *email;
@property (nonatomic) NSString *activationCode;
@property (nonatomic) BOOL showDontAskAgain;
@property (nonatomic) BOOL dontAskAgain;
@property (atomic, retain) GMSupportPlanManager *supportPlanManager;

- (void)performAutomaticSupportPlanActivationWithActivationCode:(NSString *)activationCode email:(NSString *)email;
- (void)configureTextForState:(GMSupportPlanAssistantViewControllerState)state;

- (void)hideLoadingSpinner;
- (void)setState:(GMSupportPlanAssistantViewControllerState)state forceUpdate:(BOOL)forceUpdate;
- (BOOL)windowShouldClose:(id)sender;

- (void)showGPGMail4ExplanationAndRelaunchMail;

@end


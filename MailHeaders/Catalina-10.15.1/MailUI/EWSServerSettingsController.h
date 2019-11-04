//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "ServerSettingsController.h"

@class NSURL;

@interface EWSServerSettingsController : ServerSettingsController
{
}

+ (id)keyPathsForValuesAffectingAccountExternalURL;	// IMP=0x0000000100155979
+ (id)keyPathsForValuesAffectingAccountInternalURL;	// IMP=0x000000010015586b
@property(retain, nonatomic) NSURL *accountExternalURL;
@property(retain, nonatomic) NSURL *accountInternalURL;
- (id)advancedSettingsControllerIdentifier;	// IMP=0x000000010015584c
- (id)advancedSettingsSegueIdentifier;	// IMP=0x000000010015582d

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFLibraryUpgradeStep.h>

@class NSArray;

@interface MFUpdateSpotlightIndexForCompressionCleanupUpgradeStep : MFLibraryUpgradeStep
{
    NSArray *_accounts;	// 8 = 0x8
}

+ (BOOL)needToPerformFromMinorVersion:(unsigned long long)arg1 initialLastWriteMinorVersion:(unsigned long long)arg2;	// IMP=0x000000000023701a
+ (unsigned long long)targetVersion;	// IMP=0x0000000000236f71
@property(readonly, copy, nonatomic) NSArray *accounts; // @synthesize accounts=_accounts;
- (void).cxx_destruct;	// IMP=0x00000000002373bd
- (void)runWithRowIDsNeedingConversationRecalculation:(id)arg1;	// IMP=0x000000000023702c
- (id)initWithDatabaseConnection:(id)arg1 accounts:(id)arg2;	// IMP=0x0000000000236f7c

@end


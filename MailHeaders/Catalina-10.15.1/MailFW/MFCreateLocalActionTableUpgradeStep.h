//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFLibraryUpgradeStep.h>

@interface MFCreateLocalActionTableUpgradeStep : MFLibraryUpgradeStep
{
}

+ (BOOL)needToPerformFromMinorVersion:(unsigned long long)arg1 initialLastWriteMinorVersion:(unsigned long long)arg2;	// IMP=0x000000000003e0e2
+ (unsigned long long)targetVersion;	// IMP=0x000000000003e0d7
- (void)_addFlagEntriesForActionID:(id)arg1 flags:(long long)arg2 mask:(long long)arg3 connection:(id)arg4;	// IMP=0x000000000003e68a
- (void)runWithRowIDsNeedingConversationRecalculation:(id)arg1;	// IMP=0x000000000003e127

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFLibraryUpgradeStep.h>

@class NSArray, NSDictionary, NSProgress;

@interface MFAddMessageListIDColumnUpgradeStep : MFLibraryUpgradeStep
{
    NSArray *_accounts;	// 8 = 0x8
    NSDictionary *_mailboxPathsByMailboxURL;	// 16 = 0x10
    NSProgress *_messageProgress;	// 24 = 0x18
}

+ (unsigned long long)targetVersion;	// IMP=0x000000000001e4fa
@property(retain, nonatomic) NSProgress *messageProgress; // @synthesize messageProgress=_messageProgress;
@property(retain, nonatomic) NSDictionary *mailboxPathsByMailboxURL; // @synthesize mailboxPathsByMailboxURL=_mailboxPathsByMailboxURL;
@property(readonly, copy, nonatomic) NSArray *accounts; // @synthesize accounts=_accounts;
- (void).cxx_destruct;	// IMP=0x000000000001f08b
- (id)_listIDHashForMessageLibraryID:(long long)arg1 mailboxURL:(id)arg2;	// IMP=0x000000000001ee0a
- (void)_gatherListIDsSinceDate:(id)arg1;	// IMP=0x000000000001ea1d
- (void)runWithRowIDsNeedingConversationRecalculation:(id)arg1;	// IMP=0x000000000001e672
- (id)initWithDatabaseConnection:(id)arg1;	// IMP=0x000000000001e5a3
- (id)initWithDatabaseConnection:(id)arg1 accounts:(id)arg2;	// IMP=0x000000000001e505

@end


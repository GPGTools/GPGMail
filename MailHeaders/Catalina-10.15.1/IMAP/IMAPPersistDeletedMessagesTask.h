//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPPersistenceTask.h>

#import <IMAP/IMAPPersistDeletedMessagesOperationDelegate-Protocol.h>

@class NSMutableIndexSet, NSString;

@interface IMAPPersistDeletedMessagesTask : IMAPPersistenceTask <IMAPPersistDeletedMessagesOperationDelegate>
{
    NSMutableIndexSet *_uids;	// 8 = 0x8
}

- (void).cxx_destruct;	// IMP=0x000000000004cafc
- (void)persistDeletedMessagesOperation:(id)arg1 deletedUIDs:(id)arg2;	// IMP=0x000000000004c9fc
- (void)operationFinished:(id)arg1;	// IMP=0x000000000004c8ec
- (void)recalculatePriorities;	// IMP=0x000000000004c895
- (id)nextPersistenceOperation;	// IMP=0x000000000004c717
- (id)initWithDataSource:(id)arg1;	// IMP=0x000000000004c648
- (id)initWithUIDs:(id)arg1 dataSource:(id)arg2;	// IMP=0x000000000004c46b

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


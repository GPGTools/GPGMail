//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPPersistenceTaskOperation.h>

@class NSIndexSet;
@protocol IMAPPersistDeletedMessagesOperationDelegate;

@interface IMAPPersistDeletedMessagesOperation : IMAPPersistenceTaskOperation
{
    NSIndexSet *_uids;	// 8 = 0x8
    id <IMAPPersistDeletedMessagesOperationDelegate> _delegate;	// 16 = 0x10
}

@property(readonly, nonatomic) __weak id <IMAPPersistDeletedMessagesOperationDelegate> delegate; // @synthesize delegate=_delegate;
@property(readonly, copy, nonatomic) NSIndexSet *uids; // @synthesize uids=_uids;
- (void).cxx_destruct;	// IMP=0x000000000004c43c
- (void)main;	// IMP=0x000000000004c126
- (id)description;	// IMP=0x000000000004c055
- (id)initWithDataSource:(id)arg1;	// IMP=0x000000000004bf86
- (id)initWithDataSource:(id)arg1 uids:(id)arg2 delegate:(id)arg3;	// IMP=0x000000000004beef
- (id)initWithDataSource:(id)arg1 delegate:(id)arg2;	// IMP=0x000000000004be64

@end


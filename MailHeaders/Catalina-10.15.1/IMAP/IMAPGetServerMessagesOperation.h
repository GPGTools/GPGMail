//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPPersistenceTaskOperation.h>

@class NSIndexSet;
@protocol IMAPGetServerMessagesOperationDelegate;

@interface IMAPGetServerMessagesOperation : IMAPPersistenceTaskOperation
{
    id <IMAPGetServerMessagesOperationDelegate> _delegate;	// 8 = 0x8
    NSIndexSet *_uids;	// 16 = 0x10
}

@property(readonly, copy, nonatomic) NSIndexSet *uids; // @synthesize uids=_uids;
@property(readonly, nonatomic) __weak id <IMAPGetServerMessagesOperationDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;	// IMP=0x0000000000032c80
- (void)main;	// IMP=0x0000000000032901
- (id)initWithDataSource:(id)arg1;	// IMP=0x0000000000032832
- (id)initWithUIDs:(id)arg1 dataSource:(id)arg2 delegate:(id)arg3;	// IMP=0x0000000000032763

@end


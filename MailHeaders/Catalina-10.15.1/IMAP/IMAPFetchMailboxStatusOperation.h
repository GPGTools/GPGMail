//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPNetworkTaskOperation.h>

@class NSArray;
@protocol IMAPFetchMailboxStatusOperationDelegate;

@interface IMAPFetchMailboxStatusOperation : IMAPNetworkTaskOperation
{
    id <IMAPFetchMailboxStatusOperationDelegate> _delegate;	// 8 = 0x8
    NSArray *_mailboxNames;	// 16 = 0x10
    unsigned long long _dataItems;	// 24 = 0x18
}

@property(readonly, nonatomic) unsigned long long dataItems; // @synthesize dataItems=_dataItems;
@property(readonly, copy, nonatomic) NSArray *mailboxNames; // @synthesize mailboxNames=_mailboxNames;
@property(readonly, nonatomic) __weak id <IMAPFetchMailboxStatusOperationDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;	// IMP=0x0000000000031057
- (void)main;	// IMP=0x0000000000030292
- (id)_descriptionHidingPII:(BOOL)arg1;	// IMP=0x000000000002febc
- (id)description;	// IMP=0x000000000002fea5
- (id)debugDescription;	// IMP=0x000000000002fe91
- (id)initWithMailboxName:(id)arg1;	// IMP=0x000000000002fdc2
- (id)initWithMailboxNames:(id)arg1 dataItems:(unsigned long long)arg2 delegate:(id)arg3;	// IMP=0x000000000002fd00

@end


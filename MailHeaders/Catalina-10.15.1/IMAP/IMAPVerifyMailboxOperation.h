//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPPersistenceTaskOperation.h>

@protocol IMAPVerifyMailboxOperationDelegate;

@interface IMAPVerifyMailboxOperation : IMAPPersistenceTaskOperation
{
    id <IMAPVerifyMailboxOperationDelegate> _delegate;	// 8 = 0x8
}

@property(readonly, nonatomic) __weak id <IMAPVerifyMailboxOperationDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;	// IMP=0x000000000006ad86
- (void)main;	// IMP=0x000000000006acbb
- (id)initWithDataSource:(id)arg1;	// IMP=0x000000000006abec
- (id)initWithDataSource:(id)arg1 delegate:(id)arg2;	// IMP=0x000000000006ab61

@end


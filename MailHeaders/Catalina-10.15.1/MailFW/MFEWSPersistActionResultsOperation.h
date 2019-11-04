//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFEWSPersistenceTaskOperation.h>

@class ECLocalMessageAction, ECLocalMessageActionResults;
@protocol MFEWSPersistActionResultsOperationDelegate;

@interface MFEWSPersistActionResultsOperation : MFEWSPersistenceTaskOperation
{
    ECLocalMessageAction *_messageAction;	// 8 = 0x8
    ECLocalMessageActionResults *_results;	// 16 = 0x10
    id <MFEWSPersistActionResultsOperationDelegate> _delegate;	// 24 = 0x18
}

@property(nonatomic) __weak id <MFEWSPersistActionResultsOperationDelegate> delegate; // @synthesize delegate=_delegate;
@property(readonly, nonatomic) ECLocalMessageActionResults *results; // @synthesize results=_results;
@property(readonly, nonatomic) ECLocalMessageAction *messageAction; // @synthesize messageAction=_messageAction;
- (void).cxx_destruct;	// IMP=0x000000000009a726
- (void)main;	// IMP=0x000000000009a5c2
- (id)init;	// IMP=0x000000000009a4f3
- (id)initWithMessageAction:(id)arg1 results:(id)arg2;	// IMP=0x000000000009a451

@end


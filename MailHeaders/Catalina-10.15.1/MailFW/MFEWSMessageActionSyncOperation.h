//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFEWSNetworkTaskOperation.h>

@class ECLocalMessageAction, NSProgress;
@protocol MFEWSMessageActionSyncOperationDelegate;

@interface MFEWSMessageActionSyncOperation : MFEWSNetworkTaskOperation
{
    ECLocalMessageAction *_messageAction;	// 8 = 0x8
    NSProgress *_progress;	// 16 = 0x10
    id <MFEWSMessageActionSyncOperationDelegate> _delegate;	// 24 = 0x18
}

@property(nonatomic) __weak id <MFEWSMessageActionSyncOperationDelegate> delegate; // @synthesize delegate=_delegate;
@property(retain, nonatomic) NSProgress *progress; // @synthesize progress=_progress;
@property(readonly, nonatomic) ECLocalMessageAction *messageAction; // @synthesize messageAction=_messageAction;
- (void).cxx_destruct;	// IMP=0x0000000000096490
- (id)folderIDStringForMailboxURLString:(id)arg1;	// IMP=0x00000000000963c2
- (id)folderIDStringForMailbox:(id)arg1;	// IMP=0x0000000000096235
- (BOOL)isRecoverableError:(id)arg1;	// IMP=0x000000000009617c
- (id)init;	// IMP=0x00000000000960ad
- (id)initWithMessageAction:(id)arg1;	// IMP=0x000000000009603f

@end


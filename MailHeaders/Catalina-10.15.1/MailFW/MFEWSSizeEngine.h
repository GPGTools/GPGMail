//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFRemoteStoreSizeEngine.h>

@class MFEWSAccount;

@interface MFEWSSizeEngine : MFRemoteStoreSizeEngine
{
}

- (void)_getSizeForMailbox:(id)arg1;	// IMP=0x00000000000a1563
- (void)_runWorkerThread;	// IMP=0x00000000000a1262
- (id)initWithAccount:(id)arg1;	// IMP=0x00000000000a111d

// Remaining properties
@property(readonly, nonatomic) MFEWSAccount *account; // @dynamic account;

@end


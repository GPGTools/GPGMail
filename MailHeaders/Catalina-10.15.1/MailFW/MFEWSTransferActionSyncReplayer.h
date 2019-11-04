//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <EmailCore/ECTransferActionReplayer.h>

#import <Mail/ECTransferActionReplayerSubclassMethods-Protocol.h>

@class MFEWSConnection, NSString;

@interface MFEWSTransferActionSyncReplayer : ECTransferActionReplayer <ECTransferActionReplayerSubclassMethods>
{
    MFEWSConnection *_connection;	// 8 = 0x8
}

@property(retain, nonatomic) MFEWSConnection *connection; // @synthesize connection=_connection;
- (void).cxx_destruct;	// IMP=0x00000000000a90a7
- (id)_folderIDStringForMailboxURLString:(id)arg1;	// IMP=0x00000000000a9017
- (id)_folderIDStringForMailbox:(id)arg1;	// IMP=0x00000000000a8e8a
- (id)_bodyRequestShape;	// IMP=0x00000000000a8d95
- (id)appendItem:(id)arg1 mailboxURL:(id)arg2;	// IMP=0x00000000000a82c0
- (BOOL)isRecoverableError:(id)arg1;	// IMP=0x00000000000a8207
- (BOOL)downloadFailed;	// IMP=0x00000000000a81b0
- (id)fetchBodyDataForRemoteID:(id)arg1 mailboxURL:(id)arg2;	// IMP=0x00000000000a7b91
- (BOOL)deleteSourceMessagesFromTransferItems:(id)arg1;	// IMP=0x00000000000a77b2
- (id)moveItems:(id)arg1 destinationMailboxURL:(id)arg2;	// IMP=0x00000000000a7659
- (id)copyItems:(id)arg1 destinationMailboxURL:(id)arg2;	// IMP=0x00000000000a6728
- (id)replayActionUsingEWSConnection:(id)arg1;	// IMP=0x00000000000a66fa

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


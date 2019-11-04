//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <IMAP/ECIMAPServerInterface-Protocol.h>

@class IMAPConnection, IMAPMailbox, IMAPNetworkTaskHandler, NSArray, NSString;

@interface IMAPServerInterface : NSObject <ECIMAPServerInterface>
{
    IMAPNetworkTaskHandler *_networkTaskHandler;	// 8 = 0x8
    IMAPConnection *_connection;	// 16 = 0x10
    NSString *_mailboxName;	// 24 = 0x18
}

@property(retain, nonatomic) NSString *mailboxName; // @synthesize mailboxName=_mailboxName;
@property(readonly, nonatomic) IMAPConnection *connection; // @synthesize connection=_connection;
@property(readonly) IMAPNetworkTaskHandler *networkTaskHandler; // @synthesize networkTaskHandler=_networkTaskHandler;
- (void).cxx_destruct;	// IMP=0x00000000000550ed
- (void)_setErrorFromCommand:(id)arg1 overwriteExistingError:(BOOL)arg2;	// IMP=0x0000000000054ff8
- (BOOL)_setError:(id *)arg1 fromCommand:(id)arg2;	// IMP=0x0000000000054fa4
- (BOOL)executeClientCommand:(id)arg1;	// IMP=0x00000000000549d3
- (void)startIdle;	// IMP=0x0000000000054996
- (unsigned int)searchedUidNextForMessageNumber:(unsigned long long)arg1;	// IMP=0x000000000005452f
- (id)searchUidRange:(CDStruct_f792af56)arg1 forNewMessageIDs:(id)arg2;	// IMP=0x0000000000054012
- (id)searchUidRange:(CDStruct_f792af56)arg1 forTerms:(id)arg2;	// IMP=0x0000000000053f23
- (BOOL)appendData:(id)arg1 toMailboxNamed:(id)arg2 flags:(id)arg3 dateReceived:(id)arg4 appendInfo:(id *)arg5 error:(id *)arg6;	// IMP=0x0000000000053b93
- (BOOL)_transferUIDs:(id)arg1 toMailboxNamed:(id)arg2 isMove:(BOOL)arg3 copyInfo:(id *)arg4 error:(id *)arg5;	// IMP=0x0000000000053869
- (id)_sourceUIDsToDestinationUIDsFromMessageInfo:(id)arg1;	// IMP=0x0000000000053406
- (BOOL)moveUIDs:(id)arg1 toMailboxNamed:(id)arg2 copyInfo:(id *)arg3 error:(id *)arg4;	// IMP=0x00000000000532ea
- (BOOL)copyUIDs:(id)arg1 toMailboxNamed:(id)arg2 copyInfo:(id *)arg3 error:(id *)arg4;	// IMP=0x0000000000053285
- (BOOL)_batchUIDs:(id)arg1 block:(CDUnknownBlockType)arg2;	// IMP=0x0000000000053117
- (BOOL)storeGmailLabels:(id)arg1 state:(BOOL)arg2 forUIDs:(id)arg3;	// IMP=0x0000000000052f97
- (BOOL)storeFlagChange:(id)arg1 forUIDs:(id)arg2;	// IMP=0x0000000000052c94
- (void)fetchTotalSizeAndMessageCount;	// IMP=0x0000000000052bfe
- (void)unselect;	// IMP=0x0000000000052b52
- (void)closeAndLogout;	// IMP=0x0000000000052ad1
- (void)logout;	// IMP=0x0000000000052a86
- (void)close;	// IMP=0x0000000000052a27
- (BOOL)expungeUIDs:(id)arg1;	// IMP=0x00000000000528a4
- (BOOL)expunge;	// IMP=0x0000000000052828
- (BOOL)check:(id *)arg1;	// IMP=0x00000000000527ac
- (BOOL)getQuotaForRootName:(id)arg1;	// IMP=0x000000000005265e
- (void)fetchQuotaRootNamesForMailboxes:(id)arg1;	// IMP=0x0000000000052332
- (BOOL)unsubscribeMailbox:(id)arg1;	// IMP=0x0000000000052297
- (BOOL)subscribeMailbox:(id)arg1;	// IMP=0x00000000000521fc
- (BOOL)renameMailbox:(id)arg1 toMailbox:(id)arg2;	// IMP=0x000000000005209b
- (BOOL)deleteMailbox:(id)arg1;	// IMP=0x0000000000051fbf
- (BOOL)createMailbox:(id)arg1;	// IMP=0x0000000000051edd
@property(readonly) IMAPMailbox *selectedIMAPMailbox;
- (id)mailboxNameIfSelected:(BOOL)arg1;	// IMP=0x0000000000051e2e
- (BOOL)selectMailbox:(id)arg1 error:(id *)arg2;	// IMP=0x0000000000051c21
- (BOOL)selectMailboxIfNeededWithError:(id *)arg1;	// IMP=0x0000000000051aeb
- (BOOL)subscribedListingForMailbox:(id)arg1 options:(long long)arg2 listingInfo:(id)arg3;	// IMP=0x00000000000519e0
- (BOOL)listingForMailbox:(id)arg1 options:(long long)arg2 listingInfo:(id)arg3;	// IMP=0x00000000000518d5
@property(readonly, copy, nonatomic) NSString *separatorChar;
@property(readonly, copy) NSArray *capabilities;
- (BOOL)capabilityIsEnabled:(unsigned long long)arg1;	// IMP=0x00000000000517e1
- (BOOL)supportsCapability:(unsigned long long)arg1;	// IMP=0x000000000005178d
@property(readonly, nonatomic) BOOL hasValidConnection;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;	// IMP=0x000000000005156e
- (void)dealloc;	// IMP=0x0000000000051522
- (id)init;	// IMP=0x0000000000051453
- (id)initWithConnection:(id)arg1 mailboxName:(id)arg2;	// IMP=0x0000000000051392
- (id)initWithNetworkTaskHandler:(id)arg1 mailboxName:(id)arg2;	// IMP=0x00000000000512eb

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "EFSignpostable-Protocol.h"
#import "ThreadedMessageListDelegate-Protocol.h"

@class MCMessage, MFMessageThread, MessageListContentProviderOptions, NSMutableArray, NSMutableDictionary, NSMutableSet, NSNumber, NSOperationQueue, NSPredicate, NSString;
@protocol MessageList, MessageListContentProviderDelegate;

@interface MessageListContentProvider : NSObject <ThreadedMessageListDelegate, EFSignpostable>
{
    int _taskCounter;	// 8 = 0x8
    NSMutableArray *_allStores;	// 16 = 0x10
    NSMutableSet *_storesWaitingToLoad;	// 24 = 0x18
    NSMutableSet *_primaryMessages;	// 32 = 0x20
    NSMutableSet *_secondaryMessages;	// 40 = 0x28
    NSMutableSet *_nonDeletedMessages;	// 48 = 0x30
    NSMutableSet *_hiddenMessages;	// 56 = 0x38
    NSMutableSet *_shownMessages;	// 64 = 0x40
    NSMutableDictionary *_conversationIDByMessage;	// 72 = 0x48
    NSMutableDictionary *_threadsByConversationID;	// 80 = 0x50
    NSMutableDictionary *_originalMessageByMessageID;	// 88 = 0x58
    NSMutableDictionary *_messageCopiesByMessageID;	// 96 = 0x60
    NSMutableSet *_pendingSelectedMessageIdentifiers;	// 104 = 0x68
    NSMutableSet *_pendingSelectedThreadIdentifiers;	// 112 = 0x70
    NSMutableSet *_pendingOpenThreadIdentifiers;	// 120 = 0x78
    NSMutableDictionary *_foundSelectedMessagesByIdentifier;	// 128 = 0x80
    NSMutableDictionary *_foundSelectedThreadsByIdentifier;	// 136 = 0x88
    MFMessageThread *_foundPinnedThread;	// 144 = 0x90
    MCMessage *_foundPinnedMessage;	// 152 = 0x98
    NSMutableSet *_changedMessages;	// 160 = 0xa0
    NSMutableSet *_changedThreads;	// 168 = 0xa8
    NSMutableArray *_contentChanges;	// 176 = 0xb0
    BOOL _animateFoundSelection;	// 184 = 0xb8
    BOOL _taskRequiresReload;	// 185 = 0xb9
    BOOL _taskChangedOriginalsOrCopies;	// 186 = 0xba
    id <MessageListContentProviderDelegate> _delegate;	// 192 = 0xc0
    MessageListContentProviderOptions *_options;	// 200 = 0xc8
    id <MessageList> _messageList;	// 208 = 0xd0
    NSOperationQueue *_taskQueue;	// 216 = 0xd8
    id _pendingPinnedMessageIdentifier;	// 224 = 0xe0
    NSNumber *_pendingPinnedThreadIdentifier;	// 232 = 0xe8
    double _pendingPinningOffset;	// 240 = 0xf0
    CDUnknownBlockType _taskCompletionBlock;	// 248 = 0xf8
}

+ (id)signpostLog;	// IMP=0x00000001001e713b
+ (id)log;	// IMP=0x00000001001e70c4
@property(nonatomic) BOOL taskChangedOriginalsOrCopies; // @synthesize taskChangedOriginalsOrCopies=_taskChangedOriginalsOrCopies;
@property(nonatomic) BOOL taskRequiresReload; // @synthesize taskRequiresReload=_taskRequiresReload;
@property(copy, nonatomic) CDUnknownBlockType taskCompletionBlock; // @synthesize taskCompletionBlock=_taskCompletionBlock;
@property(nonatomic) BOOL animateFoundSelection; // @synthesize animateFoundSelection=_animateFoundSelection;
@property(nonatomic) double pendingPinningOffset; // @synthesize pendingPinningOffset=_pendingPinningOffset;
@property(retain, nonatomic) NSNumber *pendingPinnedThreadIdentifier; // @synthesize pendingPinnedThreadIdentifier=_pendingPinnedThreadIdentifier;
@property(copy, nonatomic) id pendingPinnedMessageIdentifier; // @synthesize pendingPinnedMessageIdentifier=_pendingPinnedMessageIdentifier;
@property(readonly, nonatomic) NSOperationQueue *taskQueue; // @synthesize taskQueue=_taskQueue;
@property(retain, nonatomic) id <MessageList> messageList; // @synthesize messageList=_messageList;
@property(readonly, copy, nonatomic) MessageListContentProviderOptions *options; // @synthesize options=_options;
@property __weak id <MessageListContentProviderDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;	// IMP=0x00000001001f039f
- (void)threadedMessageList:(id)arg1 messageWillChange:(id)arg2;	// IMP=0x00000001001f01db
- (void)threadedMessageList:(id)arg1 willRemoveThread:(id)arg2 withConversationID:(id)arg3;	// IMP=0x00000001001f01c2
- (void)threadedMessageList:(id)arg1 willAddThread:(id)arg2 withConversationID:(id)arg3;	// IMP=0x00000001001f00fb
- (void)threadedMessageList:(id)arg1 willRemoveMessage:(id)arg2;	// IMP=0x00000001001f00e2
- (void)threadedMessageList:(id)arg1 willAddMessage:(id)arg2 withConversationID:(id)arg3;	// IMP=0x00000001001f009a
- (void)messageList:(id)arg1 didUpdateWithContentChange:(id)arg2;	// IMP=0x00000001001f007e
- (id)threadForMessage:(id)arg1;	// IMP=0x00000001001f0012
- (id)conversationIDForMessage:(id)arg1;	// IMP=0x00000001001efffc
- (id)threadForConversationID:(id)arg1;	// IMP=0x00000001001effe6
- (long long)sortingUniqueIdentifierForMessageThread:(id)arg1;	// IMP=0x00000001001eff26
- (id)_messagesIncludingHiddenCopies:(id)arg1;	// IMP=0x00000001001eff02
- (long long)sortingMessageFlagsForMessage:(id)arg1 appliedFlagColors:(id *)arg2 conversationFlags:(unsigned long long *)arg3;	// IMP=0x00000001001efee8
- (long long)messageFlagsForMessage:(id)arg1 size:(unsigned long long *)arg2 appliedFlagColors:(id *)arg3 conversationFlags:(unsigned long long *)arg4;	// IMP=0x00000001001efec1
- (unsigned long long)sortingSizeForMessage:(id)arg1;	// IMP=0x00000001001efeaf
- (unsigned long long)sizeForMessage:(id)arg1;	// IMP=0x00000001001efe8b
@property(readonly, nonatomic) NSPredicate *filterPredicate;
- (id)arrayOfSortOrders;	// IMP=0x00000001001efd23
- (unsigned int)_loadOptions;	// IMP=0x00000001001efb15
- (id)_updateCopiesInfoForMessages:(id)arg1;	// IMP=0x00000001001ef68d
- (void)_extractMessages:(id)arg1 animate:(BOOL)arg2;	// IMP=0x00000001001eef7c
- (void)_checkForPendingMessages:(id)arg1;	// IMP=0x00000001001eed07
- (void)_insertPrimaryMessages:(id)arg1 secondaryMessages:(id)arg2;	// IMP=0x00000001001eebba
- (void)_performTask:(CDUnknownBlockType)arg1;	// IMP=0x00000001001ee7ed
- (id)_collectTaskInfo;	// IMP=0x00000001001ee259
- (void)_clearTaskSpecificInfo;	// IMP=0x00000001001ee18a
- (id)_originalForMessage:(id)arg1;	// IMP=0x00000001001ee0fa
- (BOOL)_shouldAlwaysShowDuplicates;	// IMP=0x00000001001ee07d
- (BOOL)_shouldDisplayMessage:(id)arg1;	// IMP=0x00000001001edfff
- (void)_componentStoreMessagesWereAdded:(id)arg1;	// IMP=0x00000001001ede17
- (void)_componentStoreFinishedLoading:(id)arg1;	// IMP=0x00000001001edb17
- (void)_removeMessages:(id)arg1;	// IMP=0x00000001001ed8f9
- (void)_addMessages:(id)arg1 secondaryMessages:(id)arg2;	// IMP=0x00000001001ed32e
- (void)_libraryConversationsWereChanged:(id)arg1;	// IMP=0x00000001001ec637
- (void)_libraryMessagesGmailLabelsChanged:(id)arg1;	// IMP=0x00000001001ebef1
- (void)_libraryMessagesCompacted:(id)arg1;	// IMP=0x00000001001ebd8b
- (void)_libraryMessagesUpdated:(id)arg1;	// IMP=0x00000001001eb774
- (BOOL)_isKnownMessage:(id)arg1;	// IMP=0x00000001001eb713
- (id)_knownAndUnknownMessages:(id)arg1 fromMessages:(id)arg2;	// IMP=0x00000001001eb53c
- (id)messagesForConversationID:(long long)arg1;	// IMP=0x00000001001eb277
- (void)_libraryConversationFlagsWereChanged:(id)arg1;	// IMP=0x00000001001ead58
- (void)_libraryMessagesFlagsChangedForMessages:(id)arg1 flags:(id)arg2;	// IMP=0x00000001001ea67c
- (void)_libraryMessagesFlagsChanged:(id)arg1;	// IMP=0x00000001001ea4e0
- (void)getIndexesOfMessages:(id)arg1 options:(unsigned long long)arg2 completionBlock:(CDUnknownBlockType)arg3;	// IMP=0x00000001001ea179
- (void)closeAllThreads;	// IMP=0x00000001001ea0d1
- (void)closeThreads:(id)arg1 selectingThread:(id)arg2;	// IMP=0x00000001001e9f05
- (void)openAllThreads;	// IMP=0x00000001001e9e5d
- (void)openThreads:(id)arg1;	// IMP=0x00000001001e9d5f
- (void)unhideMessages:(id)arg1;	// IMP=0x00000001001e9622
- (void)hideMessages:(id)arg1 selectingNextMessage:(id)arg2 withAnimationOptions:(unsigned long long)arg3 completionHandler:(CDUnknownBlockType)arg4;	// IMP=0x00000001001e8f8b
- (void)changeFilterPredicate:(id)arg1;	// IMP=0x00000001001e8e74
- (void)_rebuild;	// IMP=0x00000001001e8d5d
- (void)ungroupMessages;	// IMP=0x00000001001e8cb2
- (void)groupMessages;	// IMP=0x00000001001e8c04
- (void)_findPendingObjectsInList;	// IMP=0x00000001001e8875
- (void)invertWithViewingState:(id)arg1;	// IMP=0x00000001001e8696
- (void)resortWithSortOrder:(id)arg1 isOrderedAscending:(BOOL)arg2 viewingState:(id)arg3;	// IMP=0x00000001001e84b4
- (id)_newMessageList;	// IMP=0x00000001001e8438
- (void)_clearAllMessageInfo;	// IMP=0x00000001001e83c3
- (void)_unrollViewingState:(id)arg1;	// IMP=0x00000001001e7e8c
- (void)loadWithViewingState:(id)arg1;	// IMP=0x00000001001e78f4
- (void)_dumpDiagnosticInfo;	// IMP=0x00000001001e7797
- (void)unregisterForNotifications;	// IMP=0x00000001001e7717
- (id)init;	// IMP=0x00000001001e7648
- (id)initWithStores:(id)arg1 options:(id)arg2;	// IMP=0x00000001001e7254
@property(readonly) unsigned long long signpostID;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


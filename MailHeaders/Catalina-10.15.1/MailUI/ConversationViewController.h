//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSViewController.h>

#import "MUICollectionViewDelegate-Protocol.h"
#import "NSUserInterfaceValidations-Protocol.h"

@class ConversationMember, ConversationMemberArrayController, ConversationViewFindController, MUICollectionView, MessageSelection, MessageViewController, NSArray, NSHashTable, NSMutableDictionary, NSMutableIndexSet, NSMutableOrderedSet, NSMutableSet, NSScrollView, NSString, NSUUID;
@protocol NSTextFinderBarContainer;

@interface ConversationViewController : NSViewController <MUICollectionViewDelegate, NSUserInterfaceValidations>
{
    NSMutableOrderedSet *_conversationMembers;	// 16 = 0x10
    NSMutableSet *_viewControllers;	// 24 = 0x18
    NSMutableIndexSet *_loadIndexes;	// 32 = 0x20
    NSMutableIndexSet *_primaryIndexes;	// 40 = 0x28
    NSMutableIndexSet *_unreadIndexes;	// 48 = 0x30
    NSMutableIndexSet *_visibleIndexes;	// 56 = 0x38
    NSMutableDictionary *_defaultMessageViewingState;	// 64 = 0x40
    NSMutableDictionary *_messageViewingStateByLibraryID;	// 72 = 0x48
    ConversationMember *_conversationMemberObservedForActivity;	// 80 = 0x50
    NSHashTable *_observedConversations;	// 88 = 0x58
    BOOL _scrollViewIsInLiveScroll;	// 96 = 0x60
    BOOL _loaded;	// 97 = 0x61
    BOOL _needsBackdrop;	// 98 = 0x62
    BOOL _suppressesContentUpdates;	// 99 = 0x63
    MUICollectionView *_conversationView;	// 104 = 0x68
    ConversationMemberArrayController *_arrayController;	// 112 = 0x70
    ConversationViewFindController *_findController;	// 120 = 0x78
    double _pageZoom;	// 128 = 0x80
    NSUUID *_updateUUID;	// 136 = 0x88
    NSScrollView *_scrollView;	// 144 = 0x90
    NSString *_urlStringToContinue;	// 152 = 0x98
    NSString *_persistentIdToContinue;	// 160 = 0xa0
}

+ (BOOL)automaticallyNotifiesObserversOfRepresentedObject;	// IMP=0x000000010011556f
@property(nonatomic) BOOL suppressesContentUpdates; // @synthesize suppressesContentUpdates=_suppressesContentUpdates;
@property(copy, nonatomic) NSString *persistentIdToContinue; // @synthesize persistentIdToContinue=_persistentIdToContinue;
@property(copy, nonatomic) NSString *urlStringToContinue; // @synthesize urlStringToContinue=_urlStringToContinue;
@property(nonatomic) __weak NSScrollView *scrollView; // @synthesize scrollView=_scrollView;
@property(copy, nonatomic) NSUUID *updateUUID; // @synthesize updateUUID=_updateUUID;
@property(nonatomic) double pageZoom; // @synthesize pageZoom=_pageZoom;
@property(nonatomic) BOOL needsBackdrop; // @synthesize needsBackdrop=_needsBackdrop;
@property(nonatomic) BOOL loaded; // @synthesize loaded=_loaded;
@property(readonly, nonatomic) ConversationViewFindController *findController; // @synthesize findController=_findController;
@property(readonly, nonatomic) ConversationMemberArrayController *arrayController; // @synthesize arrayController=_arrayController;
@property(readonly, nonatomic) MUICollectionView *conversationView; // @synthesize conversationView=_conversationView;
- (void).cxx_destruct;	// IMP=0x00000001001180d9
- (void)updateUserActivityState:(id)arg1;	// IMP=0x0000000100117e41
@property(readonly, nonatomic) BOOL conversationMemberHasRelatedMessages;
- (BOOL)validateToolbarItem:(id)arg1;	// IMP=0x00000001000264fb
- (BOOL)validateMenuItem:(id)arg1;	// IMP=0x00000001000751eb
- (BOOL)validateUserInterfaceItem:(id)arg1;	// IMP=0x00000001000266ef
- (void)makeFontSmaller:(id)arg1;	// IMP=0x0000000100077076
- (void)makeFontBigger:(id)arg1;	// IMP=0x000000010007603b
- (void)toggleViewRelatedMessages:(id)arg1;	// IMP=0x0000000100117dab
- (void)performTextFinderAction:(id)arg1;	// IMP=0x0000000100117d39
@property(readonly, nonatomic) MessageViewController *actionViewController;
@property(readonly, copy, nonatomic) NSArray *actionConversationMembers;
- (id)actionMessagesIncludingDuplicates:(BOOL)arg1;	// IMP=0x0000000100025cf1
- (id)_actionConversationMemberIndices;	// IMP=0x0000000100025852
- (void)_updateLastViewedDateAndMarkRead:(id)arg1;	// IMP=0x0000000100117b21
- (void)_prepareToUpdateLastViewedDateAndMarkReadIfNeeded:(id)arg1 index:(unsigned long long)arg2;	// IMP=0x00000001001178d3
- (void)_cellViewFrameDidChange:(id)arg1;	// IMP=0x000000010003cb54
- (void)collectionView:(id)arg1 didSelectIndex:(unsigned long long)arg2;	// IMP=0x00000001001177f8
- (void)collectionView:(id)arg1 didEndScrollInScrollView:(id)arg2;	// IMP=0x00000001001176f7
- (void)collectionView:(id)arg1 didScrollInScrollView:(id)arg2;	// IMP=0x000000010011762b
- (void)collectionView:(id)arg1 didEndDisplayingCellView:(id)arg2 forItemAtIndex:(unsigned long long)arg3;	// IMP=0x0000000100117451
- (void)collectionView:(id)arg1 didBeginDisplayingCellView:(id)arg2 forItemAtIndex:(unsigned long long)arg3;	// IMP=0x000000010011722c
- (void)collectionView:(id)arg1 willEvictCellView:(id)arg2;	// IMP=0x000000010011717f
- (id)collectionView:(id)arg1 makeCellViewForItemAtIndex:(unsigned long long)arg2;	// IMP=0x00000001001170b4
- (double)collectionView:(id)arg1 initialHeightOfCellAtIndex:(unsigned long long)arg2;	// IMP=0x0000000100116fd4
- (void)_restoreMessageViewingState:(id)arg1;	// IMP=0x000000010003c98c
- (void)_saveMessageViewingState:(id)arg1;	// IMP=0x00000001000476bb
- (void)_viewControllerDidFinishLoading:(id)arg1;	// IMP=0x0000000100116d63
- (void)_markViewControllerLoaded;	// IMP=0x0000000100116c62
- (void)_loadCellAtNextIndex;	// IMP=0x0000000100116b5c
- (void)_performInitialPinning;	// IMP=0x000000010003636e
- (void)_updateConversationMembers:(id)arg1;	// IMP=0x00000001000355dc
- (void)_resetConversationDisplayState;	// IMP=0x0000000100116328
- (void)_resetConversationState;	// IMP=0x000000010001b96a
- (void)_updateActivityFromConversationMember:(id)arg1;	// IMP=0x0000000100116154
@property(retain, nonatomic) ConversationMember *conversationMemberObservedForActivity;
- (void)_updateFirstResponderIfNeeded;	// IMP=0x000000010001bec4
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;	// IMP=0x000000010001bc11
- (void)_updateNeedsBackdrop;	// IMP=0x000000010011605a
- (void)_scrollViewDidEndLiveScroll:(id)arg1;	// IMP=0x0000000100115fcc
- (void)_scrollViewWillStartLiveScroll:(id)arg1;	// IMP=0x0000000100115f34
- (void)viewDidLoad;	// IMP=0x0000000100115c5b
- (BOOL)_isSingleton;	// IMP=0x0000000100115bb8
- (void)_updateContent;	// IMP=0x000000010011597f
@property(retain) MessageSelection *representedObject;
@property(readonly, nonatomic) __weak id <NSTextFinderBarContainer> textFinderBarContainer;
@property(readonly, copy) NSString *description;
- (void)_performDiagnostics:(id)arg1;	// IMP=0x00000001001150c7
- (void)tearDown;	// IMP=0x0000000100114f57
- (void)dealloc;	// IMP=0x0000000100095478
- (void)_conversationViewControllerCommonInit;	// IMP=0x0000000100019b48
- (id)initWithNibName:(id)arg1 bundle:(id)arg2;	// IMP=0x0000000100019ad7
- (id)initWithCoder:(id)arg1;	// IMP=0x0000000100114f10

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


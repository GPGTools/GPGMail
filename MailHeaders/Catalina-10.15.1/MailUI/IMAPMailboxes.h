//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "AccountInfoTabOwner-Protocol.h"
#import "MCActivityTarget-Protocol.h"
#import "NSOutlineViewDataSource-Protocol.h"
#import "NSOutlineViewDelegate-Protocol.h"

@class MCActivityMonitor, MCInvocationQueue, MFIMAPAccount, NSArray, NSButton, NSImageView, NSOutlineView, NSPredicate, NSProgressIndicator, NSSearchField, NSString, NSTextField, NSView, NSWindow;

@interface IMAPMailboxes : NSObject <AccountInfoTabOwner, MCActivityTarget, NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    MCActivityMonitor *_mailboxListMonitor;	// 8 = 0x8
    NSWindow *_window;	// 16 = 0x10
    NSView *_mailboxesView;	// 24 = 0x18
    NSSearchField *_searchField;	// 32 = 0x20
    NSOutlineView *_mailboxesOutline;	// 40 = 0x28
    NSButton *_subscribeButton;	// 48 = 0x30
    NSButton *_unsubscribeButton;	// 56 = 0x38
    NSProgressIndicator *_fetchProgressIndicator;	// 64 = 0x40
    NSTextField *_fetchStatusField;	// 72 = 0x48
    NSImageView *_statusImageView;	// 80 = 0x50
    MFIMAPAccount *_account;	// 88 = 0x58
    NSPredicate *_predicate;	// 96 = 0x60
    NSArray *_mailboxes;	// 104 = 0x68
    NSArray *_filteredMailboxes;	// 112 = 0x70
    MCInvocationQueue *_subscribeQueue;	// 120 = 0x78
}

@property(retain, nonatomic) MCInvocationQueue *subscribeQueue; // @synthesize subscribeQueue=_subscribeQueue;
@property(copy, nonatomic) NSArray *filteredMailboxes; // @synthesize filteredMailboxes=_filteredMailboxes;
@property(copy, nonatomic) NSArray *mailboxes; // @synthesize mailboxes=_mailboxes;
@property(retain, nonatomic) NSPredicate *predicate; // @synthesize predicate=_predicate;
@property(retain, nonatomic) MFIMAPAccount *account; // @synthesize account=_account;
@property(nonatomic) __weak NSImageView *statusImageView; // @synthesize statusImageView=_statusImageView;
@property(nonatomic) __weak NSTextField *fetchStatusField; // @synthesize fetchStatusField=_fetchStatusField;
@property(nonatomic) __weak NSProgressIndicator *fetchProgressIndicator; // @synthesize fetchProgressIndicator=_fetchProgressIndicator;
@property(nonatomic) __weak NSButton *unsubscribeButton; // @synthesize unsubscribeButton=_unsubscribeButton;
@property(nonatomic) __weak NSButton *subscribeButton; // @synthesize subscribeButton=_subscribeButton;
@property(nonatomic) __weak NSOutlineView *mailboxesOutline; // @synthesize mailboxesOutline=_mailboxesOutline;
@property(nonatomic) __weak NSSearchField *searchField; // @synthesize searchField=_searchField;
@property(nonatomic) __weak NSView *mailboxesView; // @synthesize mailboxesView=_mailboxesView;
@property(retain, nonatomic) NSWindow *window; // @synthesize window=_window;
- (void).cxx_destruct;	// IMP=0x0000000100182d9b
- (void)accountInfoWillShowView:(id)arg1;	// IMP=0x0000000100182b87
- (void)accountInfoWillHideView:(id)arg1;	// IMP=0x0000000100182b34
- (void)outlineView:(id)arg1 setObjectValue:(id)arg2 forTableColumn:(id)arg3 byItem:(id)arg4;	// IMP=0x0000000100182a6d
- (BOOL)outlineView:(id)arg1 shouldSelectItem:(id)arg2;	// IMP=0x0000000100182a62
- (void)outlineView:(id)arg1 willDisplayCell:(id)arg2 forTableColumn:(id)arg3 item:(id)arg4;	// IMP=0x00000001001827e0
- (id)outlineView:(id)arg1 objectValueForTableColumn:(id)arg2 byItem:(id)arg3;	// IMP=0x00000001001827c1
- (long long)outlineView:(id)arg1 numberOfChildrenOfItem:(id)arg2;	// IMP=0x0000000100182759
- (BOOL)outlineView:(id)arg1 isItemExpandable:(id)arg2;	// IMP=0x0000000100182710
- (id)outlineView:(id)arg1 child:(long long)arg2 ofItem:(id)arg3;	// IMP=0x0000000100182699
- (void)_handleError:(id)arg1 settingSubscribedState:(id)arg2 forMailboxPath:(id)arg3 account:(id)arg4;	// IMP=0x0000000100182453
- (void)_setSubscribedState:(BOOL)arg1 forMailboxPath:(id)arg2 parentUid:(id)arg3;	// IMP=0x0000000100182295
- (void)_reallySetSubscribedState:(BOOL)arg1 forMailboxPath:(id)arg2 parentMailbox:(id)arg3 account:(id)arg4 refreshListing:(BOOL)arg5;	// IMP=0x0000000100181e69
- (void)_updateEntryTreeForChangedEntry:(id)arg1 oldValue:(BOOL)arg2;	// IMP=0x00000001001819ef
- (id)_mailboxEntryForMailbox:(id)arg1;	// IMP=0x0000000100181814
- (id)_mailboxEntryForPath:(id)arg1;	// IMP=0x000000010018139e
- (void)_clearFilteredMailboxes:(id)arg1;	// IMP=0x00000001001811fa
- (void)_clearFilteredMailboxes;	// IMP=0x0000000100181197
- (void)filterMailboxList:(id)arg1;	// IMP=0x0000000100180de9
- (void)unsubscribeButtonClicked:(id)arg1;	// IMP=0x0000000100180dd5
- (void)subscribeButtonClicked:(id)arg1;	// IMP=0x0000000100180dbe
- (void)_handleSubscriptionRequest:(BOOL)arg1;	// IMP=0x0000000100180bd4
- (void)_handleSubscriptionRequest:(BOOL)arg1 forItem:(id)arg2 refreshSet:(id)arg3 recursive:(BOOL)arg4;	// IMP=0x00000001001807b5
- (void)_reallyStopSubscriptionRequest:(id)arg1 refreshList:(id)arg2;	// IMP=0x0000000100180676
- (void)_stopSubscriptionRequest:(id)arg1;	// IMP=0x0000000100180595
@property(readonly, nonatomic) NSView *view;
- (void)_fetchMailboxListingForAccount:(id)arg1;	// IMP=0x0000000100180048
- (id)_recursivelyCreateMailboxEntriesForList:(id)arg1 subscribedList:(id)arg2 inLocalPath:(id)arg3 remotePath:(id)arg4 forAccount:(id)arg5;	// IMP=0x000000010017f659
- (void)_mailboxFetchCompleted:(id)arg1 forAccount:(id)arg2;	// IMP=0x000000010017f49e
- (void)setupUIWithAccount:(id)arg1;	// IMP=0x000000010017f387
- (void)_setupNotifications;	// IMP=0x000000010017f2d1
- (void)setUIEnabled:(BOOL)arg1;	// IMP=0x000000010017f1ed
- (void)_updateUIForOnlineState:(id)arg1;	// IMP=0x000000010017ed32
- (id)_alertIcon;	// IMP=0x000000010017ec6d
- (void)dealloc;	// IMP=0x000000010017ec2b
- (id)init;	// IMP=0x000000010017eb4b

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly, copy, nonatomic) NSString *displayName;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


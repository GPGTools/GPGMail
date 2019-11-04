//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "MailBarContainerButton.h"

#import "FavoritesMenuDelegateProtocol-Protocol.h"
#import "NSCopying-Protocol.h"
#import "NSDraggingSource-Protocol.h"
#import "NSPasteboardItemDataProvider-Protocol.h"

@class FavoriteButtonMailboxProperties, FavoritesMenuController, MFMailbox, NSString, NSTimer;
@protocol MFUIMailbox;

@interface FavoriteButton : MailBarContainerButton <FavoritesMenuDelegateProtocol, NSCopying, NSDraggingSource, NSPasteboardItemDataProvider>
{
    BOOL _menuIsOpen;	// 108 = 0x6c
    id <MFUIMailbox> _mailbox;	// 112 = 0x70
    MFMailbox *_selectedSubMailbox;	// 120 = 0x78
    FavoriteButtonMailboxProperties *_mailboxProperties;	// 128 = 0x80
    FavoritesMenuController *_menuController;	// 136 = 0x88
    NSTimer *_showMenuTimer;	// 144 = 0x90
    NSTimer *_flashButtonTimer;	// 152 = 0x98
    long long _flashCount;	// 160 = 0xa0
}

+ (BOOL)enabledStateforMailbox:(id)arg1;	// IMP=0x000000010001113d
+ (Class)cellClass;	// IMP=0x0000000100010405
+ (id)titleForMailbox:(id)arg1 selectedSubMailbox:(id)arg2 shouldUseExtendedName:(BOOL)arg3 countsChildren:(BOOL)arg4;	// IMP=0x00000001000106e5
+ (unsigned long long)_unreadCountForMailbox:(id)arg1 countsChildren:(BOOL)arg2;	// IMP=0x0000000100010998
+ (void)setDraggedButton:(id)arg1;	// IMP=0x0000000100155f22
+ (id)draggedButton;	// IMP=0x000000010001149f
@property(nonatomic) BOOL menuIsOpen; // @synthesize menuIsOpen=_menuIsOpen;
@property(nonatomic) long long flashCount; // @synthesize flashCount=_flashCount;
@property(retain, nonatomic) NSTimer *flashButtonTimer; // @synthesize flashButtonTimer=_flashButtonTimer;
@property(retain, nonatomic) NSTimer *showMenuTimer; // @synthesize showMenuTimer=_showMenuTimer;
@property(retain, nonatomic) FavoritesMenuController *menuController; // @synthesize menuController=_menuController;
@property(retain, nonatomic) FavoriteButtonMailboxProperties *mailboxProperties; // @synthesize mailboxProperties=_mailboxProperties;
@property(retain, nonatomic) MFMailbox *selectedSubMailbox; // @synthesize selectedSubMailbox=_selectedSubMailbox;
@property(readonly, nonatomic) id <MFUIMailbox> mailbox; // @synthesize mailbox=_mailbox;
- (void).cxx_destruct;	// IMP=0x0000000100158419
@property(readonly, nonatomic) id <MFUIMailbox> selectedMailbox;
- (void)menuDidSelectMailbox:(id)arg1;	// IMP=0x0000000100158098
- (void)menuDidClose;	// IMP=0x0000000100158066
- (void)menuDidPresent;	// IMP=0x000000010015804f
- (void)showMenu;	// IMP=0x0000000100157fc1
- (void)_showMenuTimerFired:(id)arg1;	// IMP=0x0000000100157fad
- (void)_toggleFlashState:(id)arg1;	// IMP=0x0000000100157e0f
- (void)_stopShowMenuTimer;	// IMP=0x0000000100157db5
- (void)_startShowMenuTimer;	// IMP=0x0000000100157c28
@property(readonly, copy) NSString *description;
- (BOOL)_canAcceptMailboxAtPoint:(struct CGPoint)arg1;	// IMP=0x0000000100157acc
- (BOOL)performDragOperation:(id)arg1;	// IMP=0x00000001001577b6
- (void)draggingExited:(id)arg1;	// IMP=0x0000000100157701
- (unsigned long long)draggingUpdated:(id)arg1;	// IMP=0x0000000100157546
- (unsigned long long)draggingEntered:(id)arg1;	// IMP=0x000000010015736c
- (unsigned long long)_dragOperationForCurrentEvent;	// IMP=0x00000001001572e8
- (BOOL)_canDragMessageIntoSubMailboxesOrMailbox:(id)arg1;	// IMP=0x0000000100157261
- (BOOL)_canDragMessageIntoMailbox:(id)arg1;	// IMP=0x00000001001571f9
- (void)flash;	// IMP=0x00000001001571a4
- (void)_finishFlash:(id)arg1;	// IMP=0x0000000100157190
- (void)draggingSession:(id)arg1 endedAtPoint:(struct CGPoint)arg2 operation:(unsigned long long)arg3;	// IMP=0x0000000100156f61
- (id)copyWithZone:(struct _NSZone *)arg1;	// IMP=0x0000000100156f56
- (unsigned long long)draggingSession:(id)arg1 sourceOperationMaskForDraggingContext:(long long)arg2;	// IMP=0x0000000100156f3f
- (void)mouseUp:(id)arg1;	// IMP=0x0000000100156f06
- (void)mouseDown:(id)arg1;	// IMP=0x000000010007da6a
- (void)_presentContextualPopupForEvent:(id)arg1;	// IMP=0x0000000100156dc6
- (BOOL)_shouldDispayMenuForEvent:(id)arg1;	// IMP=0x000000010007dd66
- (void)pasteboard:(id)arg1 item:(id)arg2 provideDataForType:(id)arg3;	// IMP=0x0000000100156dc0
- (void)draggingSession:(id)arg1 movedToPoint:(struct CGPoint)arg2;	// IMP=0x0000000100156c03
- (void)_performDragFromMouseDown:(id)arg1 withViewFrameOrigin:(struct CGPoint)arg2;	// IMP=0x0000000100156950
- (struct CGSize)_currentEventOffsetFromEvent:(id)arg1;	// IMP=0x000000010007de91
- (BOOL)_canDragHorizontally:(BOOL)arg1 fromMouseDown:(id)arg2;	// IMP=0x00000001001568f7
- (id)_draggingImage;	// IMP=0x000000010015674d
- (void)dealloc;	// IMP=0x000000010003fe5c
- (BOOL)_hasIndicator;	// IMP=0x0000000100156718
- (void)_setIndicator:(BOOL)arg1;	// IMP=0x00000001000110e2
@property(readonly, nonatomic) id <MFUIMailbox> activeMailbox;
- (void)_fullScreenStateChanged:(id)arg1;	// IMP=0x00000001001566b6
- (void)_mailboxSectionListingDidChange:(id)arg1;	// IMP=0x000000010002ca58
- (void)_flagMailboxVisibilityChanged:(id)arg1;	// IMP=0x0000000100156613
- (void)_unreadCountDidChange:(id)arg1;	// IMP=0x000000010006a78b
- (void)_mailboxInfoDidChange:(id)arg1;	// IMP=0x000000010007cc11
- (void)_mailboxWillBecomeInvalid:(id)arg1;	// IMP=0x00000001001564fd
- (void)viewWillMoveToWindow:(id)arg1;	// IMP=0x0000000100012881
- (id)initWithFrame:(struct CGRect)arg1;	// IMP=0x000000010015642e
- (void)_favoriteButtonCommonInit;	// IMP=0x0000000100155fe6
- (id)initWithCoder:(id)arg1;	// IMP=0x0000000100155f9f
- (id)initWithMailbox:(id)arg1 selectedSubMailbox:(id)arg2;	// IMP=0x00000001000102ba
- (void)_registerChildrenForUnreadCountChangesForMailbox:(id)arg1;	// IMP=0x0000000100010e3f
- (void)registerForDraggedTypes;	// IMP=0x0000000100010d93

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


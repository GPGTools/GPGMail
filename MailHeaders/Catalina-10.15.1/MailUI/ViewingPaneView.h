//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSView.h>

@class NSHashTable;

@interface ViewingPaneView : NSView
{
    NSHashTable *_topAlignedSubviews;	// 112 = 0x70
    NSHashTable *_managedConstraints;	// 120 = 0x78
    NSView *_contentView;	// 128 = 0x80
    BOOL _isVertical;	// 136 = 0x88
}

+ (BOOL)automaticallyNotifiesObserversOfContentView;	// IMP=0x00000001002b52d4
@property(nonatomic) BOOL isVertical; // @synthesize isVertical=_isVertical;
- (void).cxx_destruct;	// IMP=0x00000001002b5abc
- (void)viewDidMoveToWindow;	// IMP=0x00000001002b5a58
- (void)updateConstraints;	// IMP=0x00000001002b53fa
- (void)setContentView:(id)arg1 titlebarAligned:(BOOL)arg2;	// IMP=0x00000001002b52dc
@property(readonly, nonatomic) NSView *contentView;
- (void)_viewingPaneViewCommonInit;	// IMP=0x000000010001ac8d
- (id)initWithCoder:(id)arg1;	// IMP=0x00000001002b528d
- (id)initWithFrame:(struct CGRect)arg1;	// IMP=0x000000010001ac2e

@end


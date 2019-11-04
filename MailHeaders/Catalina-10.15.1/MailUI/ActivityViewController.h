//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "NSAnimationDelegate-Protocol.h"

@class NSLayoutConstraint, NSString, NSView, NSViewController;

@interface ActivityViewController : NSObject <NSAnimationDelegate>
{
    NSView *_contentView;	// 8 = 0x8
    NSViewController *_progressViewController;	// 16 = 0x10
    NSLayoutConstraint *_activityViewHeightConstraint;	// 24 = 0x18
}

@property(retain, nonatomic) NSLayoutConstraint *activityViewHeightConstraint; // @synthesize activityViewHeightConstraint=_activityViewHeightConstraint;
@property(retain, nonatomic) NSViewController *progressViewController; // @synthesize progressViewController=_progressViewController;
@property(retain, nonatomic) NSView *contentView; // @synthesize contentView=_contentView;
- (void).cxx_destruct;	// IMP=0x00000001000a6ef9
- (void)_setVisible:(BOOL)arg1;	// IMP=0x0000000100019361
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;	// IMP=0x00000001000683f4
- (void)dealloc;	// IMP=0x0000000100095425
- (void)awakeFromNib;	// IMP=0x0000000100019243

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSOutlineView.h>

@class MTMFullWindowController;

@interface MTMOutlineView : NSOutlineView
{
    MTMFullWindowController *_windowController;	// 136 = 0x88
}

@property(nonatomic) __weak MTMFullWindowController *windowController; // @synthesize windowController=_windowController;
- (void).cxx_destruct;	// IMP=0x000000010023a6ce
- (BOOL)becomeFirstResponder;	// IMP=0x000000010023a62f
- (void)selectAll:(id)arg1;	// IMP=0x000000010023a629
- (struct CGRect)frameOfOutlineCellAtRow:(long long)arg1;	// IMP=0x000000010023a51b

@end


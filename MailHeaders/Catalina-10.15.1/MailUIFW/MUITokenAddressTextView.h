//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSTokenTextView.h>

@class MUIAddressField;

@interface MUITokenAddressTextView : NSTokenTextView
{
    MUIAddressField *_addressField;	// 112 = 0x70
}

@property(nonatomic) __weak MUIAddressField *addressField; // @synthesize addressField=_addressField;
- (void).cxx_destruct;	// IMP=0x0000000000010ebb
- (void)mouseUp:(id)arg1;	// IMP=0x0000000000024124
- (void)mouseDown:(id)arg1;	// IMP=0x0000000000024078
- (void)noteFocusRingMaskChanged;	// IMP=0x000000000002401d
- (id)designatedFocusRingView;	// IMP=0x000000000000e006
- (BOOL)performDragOperation:(id)arg1;	// IMP=0x0000000000023f70
- (void)_muiTokenAddressTextViewCommonInit;	// IMP=0x0000000000023f07
- (id)initWithCoder:(id)arg1;	// IMP=0x0000000000023ec0
- (id)initWithFrame:(struct CGRect)arg1;	// IMP=0x000000000000ca94

@end


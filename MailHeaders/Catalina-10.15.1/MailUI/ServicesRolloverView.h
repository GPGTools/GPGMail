//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSView.h>

@class NSTrackingArea;
@protocol ServicesRolloverViewDelegate;

@interface ServicesRolloverView : NSView
{
    id <ServicesRolloverViewDelegate> _delegate;	// 112 = 0x70
    long long _style;	// 120 = 0x78
    NSTrackingArea *_rolloverTrackingArea;	// 128 = 0x80
}

@property(retain) NSTrackingArea *rolloverTrackingArea; // @synthesize rolloverTrackingArea=_rolloverTrackingArea;
@property(nonatomic) long long style; // @synthesize style=_style;
@property(nonatomic) __weak id <ServicesRolloverViewDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;	// IMP=0x00000001002735f4
- (void)_scrollViewDidChangeBounds:(id)arg1;	// IMP=0x0000000100273536
- (void)_hideServicePickerWithoutAnimation;	// IMP=0x000000010027348c
- (void)_showServicePicker;	// IMP=0x0000000100273326
- (double)_showServicesPickerDelay;	// IMP=0x00000001002731bc
- (void)viewDidMoveToWindow;	// IMP=0x000000010027308c
- (void)viewWillMoveToWindow:(id)arg1;	// IMP=0x0000000100273026
- (void)mouseDown:(id)arg1;	// IMP=0x0000000100272ea4
- (id)hitTest:(struct CGPoint)arg1;	// IMP=0x0000000100272cdd
- (void)mouseExited:(id)arg1;	// IMP=0x0000000100272bb0
- (void)mouseEntered:(id)arg1;	// IMP=0x0000000100272ab9
- (void)updateTrackingAreas;	// IMP=0x00000001002729af
- (void)setFrame:(struct CGRect)arg1;	// IMP=0x000000010027295d
- (BOOL)isFlipped;	// IMP=0x0000000100272952
- (void)dealloc;	// IMP=0x00000001002728ac
- (void)_servicesRolloverViewCommonInit;	// IMP=0x000000010027280b
- (id)initWithFrame:(struct CGRect)arg1;	// IMP=0x00000001002727a7
- (id)initWithCoder:(id)arg1;	// IMP=0x000000010027275b

@end


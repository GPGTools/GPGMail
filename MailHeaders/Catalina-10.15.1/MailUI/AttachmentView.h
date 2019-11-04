//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <AppKit/NSView.h>

#import "NSAccessibilityImage-Protocol.h"
#import "NSDraggingSource-Protocol.h"
#import "NSSharingServiceDelegate-Protocol.h"
#import "NSSharingServicePickerDelegate-Protocol.h"
#import "ServicesRolloverViewDelegate-Protocol.h"

@class AttachmentViewController, NSImageView, NSSharingServicePicker, NSString, NSURL, ServicesRolloverView;
@protocol AttachmentView;

@interface AttachmentView : NSView <NSSharingServicePickerDelegate, ServicesRolloverViewDelegate, NSAccessibilityImage, NSDraggingSource, NSSharingServiceDelegate>
{
    AttachmentViewController *_controller;	// 112 = 0x70
    NSView<AttachmentView> *_registeredViewer;	// 120 = 0x78
    NSSharingServicePicker *_servicesPicker;	// 128 = 0x80
    long long _fixedWidth;	// 136 = 0x88
    NSString *_elementID;	// 144 = 0x90
    BOOL _invisible;	// 152 = 0x98
    BOOL _isSelected;	// 153 = 0x99
    BOOL _webViewIsEditable;	// 154 = 0x9a
    BOOL _needsToAdjustWebFrame;	// 155 = 0x9b
    BOOL _drawWithBorder;	// 156 = 0x9c
    BOOL _initializedImage;	// 157 = 0x9d
    NSURL *_URL;	// 160 = 0xa0
    double _documentMargin;	// 168 = 0xa8
    long long _fixedHeight;	// 176 = 0xb0
    NSString *_firstLineLabel;	// 184 = 0xb8
    NSString *_secondLineLabel;	// 192 = 0xc0
    NSString *_sizeLabel;	// 200 = 0xc8
    NSImageView *_imageView;	// 208 = 0xd0
    double _timeOfFirstDisplay;	// 216 = 0xd8
    ServicesRolloverView *_servicesRolloverView;	// 224 = 0xe0
    struct CGRect _downloadImageRect;	// 232 = 0xe8
}

@property(readonly, nonatomic) ServicesRolloverView *servicesRolloverView; // @synthesize servicesRolloverView=_servicesRolloverView;
@property(nonatomic) double timeOfFirstDisplay; // @synthesize timeOfFirstDisplay=_timeOfFirstDisplay;
@property(nonatomic) BOOL initializedImage; // @synthesize initializedImage=_initializedImage;
@property(retain, nonatomic) NSImageView *imageView; // @synthesize imageView=_imageView;
@property(nonatomic) struct CGRect downloadImageRect; // @synthesize downloadImageRect=_downloadImageRect;
@property(nonatomic) BOOL drawWithBorder; // @synthesize drawWithBorder=_drawWithBorder;
@property(nonatomic) BOOL needsToAdjustWebFrame; // @synthesize needsToAdjustWebFrame=_needsToAdjustWebFrame;
@property(nonatomic) BOOL webViewIsEditable; // @synthesize webViewIsEditable=_webViewIsEditable;
@property(nonatomic) BOOL isSelected; // @synthesize isSelected=_isSelected;
@property(copy, nonatomic) NSString *sizeLabel; // @synthesize sizeLabel=_sizeLabel;
@property(copy, nonatomic) NSString *secondLineLabel; // @synthesize secondLineLabel=_secondLineLabel;
@property(copy, nonatomic) NSString *firstLineLabel; // @synthesize firstLineLabel=_firstLineLabel;
@property(nonatomic) long long fixedHeight; // @synthesize fixedHeight=_fixedHeight;
@property(nonatomic) double documentMargin; // @synthesize documentMargin=_documentMargin;
@property(retain, nonatomic) NSURL *URL; // @synthesize URL=_URL;
- (void).cxx_destruct;	// IMP=0x00000001000c0a61
- (BOOL)_accessibilityIsTableViewDescendant;	// IMP=0x00000001000c0821
- (BOOL)accessibilityShouldUseUniqueId;	// IMP=0x00000001000c0816
- (void)_accessibilityShowMenu;	// IMP=0x00000001000c060b
- (BOOL)accessibilityPerformShowMenu;	// IMP=0x00000001000c05e7
- (id)accessibilityLabel;	// IMP=0x00000001000c056d
- (id)accessibilityTitle;	// IMP=0x00000001000c04f3
- (id)accessibilitySubrole;	// IMP=0x00000001000c04df
- (void)sharingService:(id)arg1 didShareItems:(id)arg2;	// IMP=0x00000001000bfb89
- (id)sharingService:(id)arg1 sourceWindowForShareItems:(id)arg2 sharingContentScope:(long long *)arg3;	// IMP=0x00000001000bfb6b
- (id)sharingService:(id)arg1 transitionImageForShareItem:(id)arg2 contentRect:(struct CGRect *)arg3;	// IMP=0x00000001000bfb59
- (struct CGRect)sharingService:(id)arg1 sourceFrameOnScreenForShareItem:(id)arg2;	// IMP=0x00000001000bfa42
- (id)sharingServicePicker:(id)arg1 sharingServicesForItems:(id)arg2 mask:(unsigned long long)arg3 proposedSharingServices:(id)arg4;	// IMP=0x00000001000bfa2c
- (id)sharingServicePicker:(id)arg1 delegateForSharingService:(id)arg2;	// IMP=0x00000001000bfa23
- (id)pickerForRolloverCalloutView:(id)arg1;	// IMP=0x00000001000bfa11
@property(readonly, nonatomic) NSSharingServicePicker *servicesPicker;
- (void)_retrieveAttachmentFromSharedItem:(id)arg1 attachmentFilename:(id)arg2 handler:(CDUnknownBlockType)arg3;	// IMP=0x00000001000bf6e6
- (void)_updateServicesRolloverBounds;	// IMP=0x00000001000bf623
- (id)quickLookTransitionImage;	// IMP=0x00000001000bf611
- (struct CGRect)quickLookRectForFrame:(struct CGRect)arg1;	// IMP=0x00000001000bf585
- (struct CGRect)_rectForImage;	// IMP=0x00000001000bf448
- (struct CGSize)_sizeInViewCoordinatesOfImage:(id)arg1;	// IMP=0x00000001000bf233
- (void)_drawIcon:(id)arg1;	// IMP=0x00000001000bdf0a
- (id)sizeLabelAttributes;	// IMP=0x00000001000bddb9
- (id)labelAttributes;	// IMP=0x00000001000bdc5a
- (id)_image;	// IMP=0x00000001000bdb91
- (id)_labelColor;	// IMP=0x00000001000bdadd
- (id)sizeLabelColor;	// IMP=0x00000001000bdac4
- (id)sizeLabelFont;	// IMP=0x00000001000bdaa3
- (id)_labelFont;	// IMP=0x00000001000bda82
@property(nonatomic) BOOL invisible;
- (void)_updateElementVisbility;	// IMP=0x00000001000bd8ec
- (void)viewDidMoveToWindow;	// IMP=0x00000001000bd857
- (void)viewDidMoveToSuperview;	// IMP=0x00000001000bd6c6
- (id)menuForEvent:(id)arg1;	// IMP=0x00000001000bd523
- (void)viewWillMoveToSuperview:(id)arg1;	// IMP=0x00000001000bd3f6
- (void)viewWillMoveToWindow:(id)arg1;	// IMP=0x00000001000bd2cf
- (BOOL)shouldDelayWindowOrderingForEvent:(id)arg1;	// IMP=0x00000001000bd2c4
- (BOOL)acceptsFirstMouse:(id)arg1;	// IMP=0x00000001000bd2b9
- (void)webPlugInSetIsSelected:(BOOL)arg1;	// IMP=0x00000001000bd286
- (void)webPlugInDestroy;	// IMP=0x00000001000bd280
- (void)webPlugInStop;	// IMP=0x00000001000bd27a
- (void)webPlugInStart;	// IMP=0x00000001000bd23a
- (void)webPlugInInitialize;	// IMP=0x00000001000bd234
- (void)mouseDragged:(id)arg1;	// IMP=0x00000001000bc84c
- (unsigned long long)draggingSession:(id)arg1 sourceOperationMaskForDraggingContext:(long long)arg2;	// IMP=0x00000001000bc841
- (id)_imageForDrag;	// IMP=0x00000001000bc662
- (id)view:(id)arg1 stringForToolTip:(long long)arg2 point:(struct CGPoint)arg3 userData:(void *)arg4;	// IMP=0x00000001000bc415
- (void)resetCursorRects;	// IMP=0x00000001000bc382
- (void)_backingScaleFactorChanged:(id)arg1;	// IMP=0x00000001000bc354
- (void)windowDidResize:(id)arg1;	// IMP=0x00000001000bc342
- (void)mouseDown:(id)arg1;	// IMP=0x00000001000bbab1
- (void)mouseUp:(id)arg1;	// IMP=0x00000001000bb8b1
@property(copy, nonatomic) NSString *elementID;
@property(nonatomic) __weak AttachmentViewController *controller;
- (struct CGSize)_sizeOfContentsRespectingMaxWidth:(double)arg1;	// IMP=0x00000001000bb513
@property(nonatomic) long long fixedWidth;
- (void)sizeToFit;	// IMP=0x00000001000bae8c
@property(readonly, nonatomic) BOOL displaying2PixelPerPointImage;
- (void)refreshView;	// IMP=0x00000001000bac6b
- (void)downloadDidFinish;	// IMP=0x00000001000babdc
- (void)didChangeViewingMode;	// IMP=0x00000001000babae
- (void)drawRect:(struct CGRect)arg1;	// IMP=0x00000001000baaba
- (void)_refreshImage;	// IMP=0x00000001000ba59f
@property(retain, nonatomic) NSView<AttachmentView> *registeredViewer;
@property(readonly, nonatomic) BOOL hasRegisteredViewer;
- (id)makeBackingLayer;	// IMP=0x00000001000ba411
- (BOOL)isFlipped;	// IMP=0x00000001000ba406
- (BOOL)isOpaque;	// IMP=0x00000001000ba3fe
- (void)dealloc;	// IMP=0x00000001000ba36f
- (void)_attachmentViewCommonInitForEditing:(BOOL)arg1;	// IMP=0x00000001000ba218
- (id)initWithFrame:(struct CGRect)arg1;	// IMP=0x00000001000ba204
- (id)initWithCoder:(id)arg1;	// IMP=0x00000001000ba1bb
- (id)initWithFrame:(struct CGRect)arg1 isForEditing:(BOOL)arg2;	// IMP=0x00000001000ba152
- (struct CGSize)_computeSizeAndLabels;	// IMP=0x00000001000b9be9

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


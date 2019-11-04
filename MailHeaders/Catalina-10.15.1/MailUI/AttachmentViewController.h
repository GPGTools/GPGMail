//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "ImageConverterDelegate-Protocol.h"
#import "MCCIDURLProtocolDataProvider-Protocol.h"
#import "NSCopying-Protocol.h"

@class DOMHTMLObjectElement, ImageConverter, MCAttachment, NSArray, NSImage, NSItemProvider, NSMutableArray, NSString, NSURL;

@interface AttachmentViewController : NSObject <ImageConverterDelegate, MCCIDURLProtocolDataProvider, NSCopying>
{
    NSMutableArray *_attachmentViews;	// 8 = 0x8
    BOOL _canBeDisplayedInline;	// 16 = 0x10
    BOOL _canBeDisplayedInRegisteredViewer;	// 17 = 0x11
    NSImage *_inlineImage;	// 24 = 0x18
    BOOL _isBeingDisplayedInline;	// 32 = 0x20
    BOOL _isInvisible;	// 33 = 0x21
    struct CGSize _targetImageSize;	// 40 = 0x28
    struct CGSize _previousTargetImageSize;	// 56 = 0x38
    struct CGSize _currentImageSize;	// 72 = 0x48
    BOOL _isImageOriginal;	// 88 = 0x58
    ImageConverter *_imageConverter;	// 96 = 0x60
    BOOL _imageConversionOptionsComputed;	// 104 = 0x68
    unsigned long long _imageConversionOptions;	// 112 = 0x70
    BOOL _needsForcedJPEGConversion;	// 120 = 0x78
    BOOL _originalImageSizeHasBeenComputed;	// 121 = 0x79
    struct CGSize _originalImageSize;	// 128 = 0x80
    BOOL _isImageBeingConverted;	// 144 = 0x90
    MCAttachment *_attachment;	// 152 = 0x98
    DOMHTMLObjectElement *_objectElement;	// 160 = 0xa0
    long long _domNodeWidth;	// 168 = 0xa8
    long long _domNodeHeight;	// 176 = 0xb0
}

+ (Class)_viewProviderClassForMimeType:(id)arg1;	// IMP=0x00000001000c140b
+ (void)registerViewingClass:(Class)arg1 forMimeTypes:(id)arg2;	// IMP=0x00000001000c102c
@property(nonatomic) BOOL isImageBeingConverted; // @synthesize isImageBeingConverted=_isImageBeingConverted;
@property(readonly, nonatomic) struct CGSize targetImageSize; // @synthesize targetImageSize=_targetImageSize;
@property(nonatomic) long long domNodeHeight; // @synthesize domNodeHeight=_domNodeHeight;
@property(nonatomic) long long domNodeWidth; // @synthesize domNodeWidth=_domNodeWidth;
@property(retain, nonatomic) DOMHTMLObjectElement *objectElement; // @synthesize objectElement=_objectElement;
@property(readonly, nonatomic) MCAttachment *attachment; // @synthesize attachment=_attachment;
- (void).cxx_destruct;	// IMP=0x00000001000c3a04
@property(readonly, nonatomic) struct CGSize originalImageSize;
- (BOOL)convertAttachmentForSelectedImageConversionOption:(long long)arg1;	// IMP=0x00000001000c34d9
- (void)_revertImageToOriginal;	// IMP=0x00000001000c3427
@property(readonly, nonatomic) unsigned long long imageConversionOptions;
- (void)_computeImagePropertiesIfNecessary;	// IMP=0x00000001000c3118
- (struct CGSize)_imageSizeForTag:(long long)arg1;	// IMP=0x00000001000c30d7
- (void)_updateInlineImage;	// IMP=0x00000001000c2eb9
- (void)imageConverter:(id)arg1 didFinishConversionWithResultCode:(long long)arg2;	// IMP=0x00000001000c2a09
@property(readonly, copy) NSString *mimeType;
@property(readonly) NSURL *cidURL;
- (void)dataWithCompletionBlock:(CDUnknownBlockType)arg1;	// IMP=0x00000001000c2889
@property(readonly, nonatomic) NSItemProvider *itemProvider;
@property(readonly, copy) NSString *description;
- (void)_attachmentDidFinishReading:(id)arg1;	// IMP=0x00000001000c24a5
@property(readonly, copy, nonatomic) NSImage *iconImage;
@property(readonly, copy, nonatomic) NSImage *inlineImage;
- (void)setInvisible:(BOOL)arg1;	// IMP=0x00000001000c1f5a
@property(readonly, nonatomic) BOOL shouldBeDisplayedInlineByDefault;
@property(nonatomic) BOOL canBeDisplayedInline;
@property(nonatomic) BOOL isBeingDisplayedInline;
- (void)addAttachmentView:(id)arg1;	// IMP=0x00000001000c0eba
@property(readonly, copy, nonatomic) NSArray *attachmentViews;
- (id)copyWithZone:(struct _NSZone *)arg1;	// IMP=0x00000001000c0ea1
- (void)dealloc;	// IMP=0x00000001000c0e01
- (id)initWithAttachment:(id)arg1;	// IMP=0x00000001000c0be7
- (id)init;	// IMP=0x00000001000c0b18

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly) long long fileSize;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


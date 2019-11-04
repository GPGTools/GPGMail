//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <MailUI/MCCIDURLProtocolDataProvider-Protocol.h>
#import <MailUI/QLPreviewItem-Protocol.h>

@class MUIWKWebViewController, MUIWebAttachment, NSImage, NSProgress, NSString, NSURL;

@interface MUIWebAttachmentController : NSObject <MCCIDURLProtocolDataProvider, QLPreviewItem>
{
    long long _displayState;	// 8 = 0x8
    MUIWebAttachment *_webAttachment;	// 16 = 0x10
    MUIWKWebViewController *_controller;	// 24 = 0x18
    NSString *_markup;	// 32 = 0x20
    NSImage *_cachedSnapshot;	// 40 = 0x28
    long long _downloadedState;	// 48 = 0x30
    NSProgress *_downloadProgress;	// 56 = 0x38
    struct CGRect _cachedFrame;	// 64 = 0x40
}

@property(retain, nonatomic) NSProgress *downloadProgress; // @synthesize downloadProgress=_downloadProgress;
@property(nonatomic) long long downloadedState; // @synthesize downloadedState=_downloadedState;
@property(retain, nonatomic) NSImage *cachedSnapshot; // @synthesize cachedSnapshot=_cachedSnapshot;
@property(nonatomic) struct CGRect cachedFrame; // @synthesize cachedFrame=_cachedFrame;
@property(readonly, nonatomic) NSString *markup; // @synthesize markup=_markup;
@property(nonatomic) __weak MUIWKWebViewController *controller; // @synthesize controller=_controller;
@property(readonly, nonatomic) MUIWebAttachment *webAttachment; // @synthesize webAttachment=_webAttachment;
- (void).cxx_destruct;	// IMP=0x000000000000b395
- (void)startDownloadingIfNeededWithProgress:(id)arg1 completionBlock:(CDUnknownBlockType)arg2;	// IMP=0x000000000000abbb
@property(readonly, copy) NSString *mimeType;
@property(readonly) NSURL *cidURL;
- (void)dataWithCompletionBlock:(CDUnknownBlockType)arg1;	// IMP=0x0000000000026013
- (void)setImageScale:(long long)arg1;	// IMP=0x0000000000025d81
@property(readonly, nonatomic) struct CGRect frameForPreview;
@property(readonly, copy, nonatomic) NSImage *transitionImageForPreview;
@property(readonly) NSString *previewItemTitle;
@property(readonly) NSURL *previewItemURL;
@property(readonly, copy, nonatomic) NSString *registrationScriptString;
@property(readonly, nonatomic) BOOL canDisplayInline;
@property(nonatomic) long long displayState;
- (void)_handleDownloadProgress:(id)arg1 changedFractionCompleted:(double)arg2;	// IMP=0x00000000000258c5
- (void)_handleDownloadErrorChange:(id)arg1;	// IMP=0x0000000000025550
- (void)_handleDownloadFinished;	// IMP=0x000000000000f0a4
- (void)_handleUpdateForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3;	// IMP=0x000000000002530e
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;	// IMP=0x000000000000ef01
- (void)dealloc;	// IMP=0x000000000000b2ea
- (id)init;	// IMP=0x000000000002521a
- (id)initWithWebAttachment:(id)arg1 controller:(id)arg2;	// IMP=0x000000000000a78a

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) long long fileSize;
@property(readonly) unsigned long long hash;
@property(readonly) id previewItemDisplayState;
@property(readonly) Class superclass;

@end


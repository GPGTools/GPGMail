//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "WebViewEditor.h"

#import "ComposeWebViewDelegate-Protocol.h"
#import "WKUIDelegatePrivate-Protocol.h"

@class ComposeBackEndWK2, ComposeWebView, NSString;

@interface WebViewEditorWK2 : WebViewEditor <ComposeWebViewDelegate, WKUIDelegatePrivate>
{
    ComposeWebView *_webView;	// 64 = 0x40
}

- (void).cxx_destruct;	// IMP=0x00000001002bcf91
- (void)_webView:(id)arg1 getContextMenuFromProposedMenu:(id)arg2 forElement:(id)arg3 userInfo:(id)arg4 completionHandler:(CDUnknownBlockType)arg5;	// IMP=0x00000001002bcb27
- (void)_webView:(id)arg1 didRemoveAttachment:(id)arg2;	// IMP=0x00000001002bca66
- (void)_webView:(id)arg1 didInsertAttachment:(id)arg2 withSource:(id)arg3;	// IMP=0x00000001002bc928
- (void)composeWebView:(id)arg1 attachment:(id)arg2 changedIdentifierTo:(id)arg3;	// IMP=0x00000001002bc80f
- (void)composeWebViewDidModifySignature:(id)arg1;	// IMP=0x00000001002bc785
- (void)composeWebViewDidChange:(id)arg1;	// IMP=0x00000001002bc771
- (void)_addAttachments:(id)arg1;	// IMP=0x00000001002bc5bb
- (long long)_webViewSpellCheckerDocumentTag;	// IMP=0x00000001002bc5b3
- (void)_changeComposeModeInViewTo:(long long)arg1;	// IMP=0x00000001002bc5ad
- (void)restoreOriginalAttachments:(CDUnknownBlockType)arg1;	// IMP=0x00000001002bc283
- (void)removeAttachmentsLeavingPlaceholder:(BOOL)arg1 completionHandler:(CDUnknownBlockType)arg2;	// IMP=0x00000001002bc162
- (void)replaceOldSignatureWithNewSignature:(id)arg1;	// IMP=0x00000001002bbdcc
- (void)replaceRiskyAttachmentsWithLinks;	// IMP=0x00000001002bbdc6
- (void)prepareToGoAway;	// IMP=0x00000001002bbd97
- (void)setCheckGrammarWithSpelling:(BOOL)arg1;	// IMP=0x00000001002bbd91
- (void)setInlineSpellCheckingEnabled:(BOOL)arg1;	// IMP=0x00000001002bbd8b
- (void)earlySetUp;	// IMP=0x00000001002bbd3d
- (void)setUp;	// IMP=0x00000001002bbcef
@property(retain, nonatomic) ComposeWebView *webView;

// Remaining properties
@property(readonly, nonatomic) ComposeBackEndWK2 *composeBackEnd; // @dynamic composeBackEnd;
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "NSObject-Protocol.h"

@class DOMCSSStyleDeclaration, DOMNode, DOMRange, NSNotification, NSString, NSUndoManager, WebView;

@protocol WebEditingDelegate <NSObject>

@optional
- (NSUndoManager *)undoManagerForWebView:(WebView *)arg1;
- (void)webViewDidChangeSelection:(NSNotification *)arg1;
- (void)webViewDidChangeTypingStyle:(NSNotification *)arg1;
- (void)webViewDidEndEditing:(NSNotification *)arg1;
- (void)webViewDidChange:(NSNotification *)arg1;
- (void)webViewDidBeginEditing:(NSNotification *)arg1;
- (BOOL)webView:(WebView *)arg1 doCommandBySelector:(SEL)arg2;
- (BOOL)webView:(WebView *)arg1 shouldChangeTypingStyle:(DOMCSSStyleDeclaration *)arg2 toStyle:(DOMCSSStyleDeclaration *)arg3;
- (BOOL)webView:(WebView *)arg1 shouldApplyStyle:(DOMCSSStyleDeclaration *)arg2 toElementsInDOMRange:(DOMRange *)arg3;
- (BOOL)webView:(WebView *)arg1 shouldChangeSelectedDOMRange:(DOMRange *)arg2 toDOMRange:(DOMRange *)arg3 affinity:(unsigned long long)arg4 stillSelecting:(BOOL)arg5;
- (BOOL)webView:(WebView *)arg1 shouldDeleteDOMRange:(DOMRange *)arg2;
- (BOOL)webView:(WebView *)arg1 shouldInsertText:(NSString *)arg2 replacingDOMRange:(DOMRange *)arg3 givenAction:(long long)arg4;
- (BOOL)webView:(WebView *)arg1 shouldInsertNode:(DOMNode *)arg2 replacingDOMRange:(DOMRange *)arg3 givenAction:(long long)arg4;
- (BOOL)webView:(WebView *)arg1 shouldEndEditingInDOMRange:(DOMRange *)arg2;
- (BOOL)webView:(WebView *)arg1 shouldBeginEditingInDOMRange:(DOMRange *)arg2;
@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/NSObject-Protocol.h>

@class NSError, NSURLAuthenticationChallenge, NSURLRequest, NSURLResponse, WebDataSource, WebView;

@protocol WebResourceLoadDelegate <NSObject>

@optional
- (void)webView:(WebView *)arg1 plugInFailedWithError:(NSError *)arg2 dataSource:(WebDataSource *)arg3;
- (void)webView:(WebView *)arg1 resource:(id)arg2 didFailLoadingWithError:(NSError *)arg3 fromDataSource:(WebDataSource *)arg4;
- (void)webView:(WebView *)arg1 resource:(id)arg2 didFinishLoadingFromDataSource:(WebDataSource *)arg3;
- (void)webView:(WebView *)arg1 resource:(id)arg2 didReceiveContentLength:(long long)arg3 fromDataSource:(WebDataSource *)arg4;
- (void)webView:(WebView *)arg1 resource:(id)arg2 didReceiveResponse:(NSURLResponse *)arg3 fromDataSource:(WebDataSource *)arg4;
- (void)webView:(WebView *)arg1 resource:(id)arg2 didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)arg3 fromDataSource:(WebDataSource *)arg4;
- (void)webView:(WebView *)arg1 resource:(id)arg2 didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)arg3 fromDataSource:(WebDataSource *)arg4;
- (NSURLRequest *)webView:(WebView *)arg1 resource:(id)arg2 willSendRequest:(NSURLRequest *)arg3 redirectResponse:(NSURLResponse *)arg4 fromDataSource:(WebDataSource *)arg5;
- (id)webView:(WebView *)arg1 identifierForInitialRequest:(NSURLRequest *)arg2 fromDataSource:(WebDataSource *)arg3;
@end


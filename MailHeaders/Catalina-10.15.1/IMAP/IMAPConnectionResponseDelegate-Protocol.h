//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/NSObject-Protocol.h>

@class IMAPConnection, IMAPFetchResponse, IMAPResponse, IMAPSingleCommand, NSString;

@protocol IMAPConnectionResponseDelegate <NSObject>
- (void)connection:(IMAPConnection *)arg1 receivedUnhandledUntaggedResponse:(IMAPResponse *)arg2 forMailbox:(NSString *)arg3 forCommand:(IMAPSingleCommand *)arg4;
- (void)connection:(IMAPConnection *)arg1 receivedFetchResponse:(IMAPFetchResponse *)arg2 forMailbox:(NSString *)arg3;
- (void)connection:(IMAPConnection *)arg1 receivedExists:(unsigned long long)arg2 forMailbox:(NSString *)arg3;
- (BOOL)connection:(IMAPConnection *)arg1 shouldProcessUnsolicitedResponse:(IMAPResponse *)arg2;
@end


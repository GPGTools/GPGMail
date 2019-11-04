//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/NSObject-Protocol.h>

@class EWSSubscription, NSArray, NSError;

@protocol EWSSubscriptionDelegate <NSObject>

@optional
- (void)subscription:(EWSSubscription *)arg1 failedWithError:(NSError *)arg2;
- (void)subscription:(EWSSubscription *)arg1 receivedEvents:(NSArray *)arg2;
- (void)subscriptionDidUnsubscribe:(EWSSubscription *)arg1;
- (void)subscriptionDidSubscribe:(EWSSubscription *)arg1;
@end


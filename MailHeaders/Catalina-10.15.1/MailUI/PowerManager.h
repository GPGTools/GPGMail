//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class NSBackgroundActivityScheduler;
@protocol OS_dispatch_source;

@interface PowerManager : NSObject
{
    NSBackgroundActivityScheduler *_applicationRefreshActivity;	// 8 = 0x8
    NSObject<OS_dispatch_source> *_fetchCheckPointTimer;	// 16 = 0x10
    CDUnknownBlockType _applicationRefreshCompletionHandler;	// 24 = 0x18
}

+ (id)sharedInstance;	// IMP=0x000000010000616c
+ (id)allocWithZone:(struct _NSZone *)arg1;	// IMP=0x0000000100254b92
+ (id)log;	// IMP=0x0000000100254b35
@property(copy) CDUnknownBlockType applicationRefreshCompletionHandler; // @synthesize applicationRefreshCompletionHandler=_applicationRefreshCompletionHandler;
@property(readonly, nonatomic) NSObject<OS_dispatch_source> *fetchCheckPointTimer; // @synthesize fetchCheckPointTimer=_fetchCheckPointTimer;
@property(readonly, nonatomic) NSBackgroundActivityScheduler *applicationRefreshActivity; // @synthesize applicationRefreshActivity=_applicationRefreshActivity;
- (void).cxx_destruct;	// IMP=0x0000000100255761
- (void)_applicationRefreshDidEnd;	// IMP=0x0000000100255639
- (CDUnknownBlockType)_applicationRefreshShouldBegin;	// IMP=0x0000000100255050
- (void)_systemDidWake:(id)arg1;	// IMP=0x0000000100254eff
- (void)_systemWillSleep:(id)arg1;	// IMP=0x0000000100254da8
- (void)registerForPowerEvents;	// IMP=0x000000010000631a
- (void)dealloc;	// IMP=0x0000000100254c4b
- (id)init;	// IMP=0x0000000100006225

@end


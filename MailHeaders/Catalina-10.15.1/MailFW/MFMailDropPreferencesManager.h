//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@interface MFMailDropPreferencesManager : NSObject
{
}

+ (id)sharedInstance;	// IMP=0x00000000001710f0
+ (id)allocWithZone:(struct _NSZone *)arg1;	// IMP=0x0000000000171037
- (BOOL)validateURL:(id)arg1;	// IMP=0x000000000017192a
@property(readonly, nonatomic) float minMessageSize;
@property(readonly, nonatomic) float maxMessageSize;
@property(readonly, nonatomic) long long attachmentTTL;
- (void)dealloc;	// IMP=0x00000000001716e9
- (id)init;	// IMP=0x00000000001711a9

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Foundation/NSInvocation.h>

@class NSNumber;

@interface NSInvocation (MailCoreAdditions)
+ (id)invocationWithSelector:(SEL)arg1 target:(id)arg2 object1:(id)arg3 object2:(id)arg4 object3:(id)arg5 object4:(id)arg6;	// IMP=0x0000000000011d42
+ (id)invocationWithSelector:(SEL)arg1 target:(id)arg2 object1:(id)arg3 object2:(id)arg4 object3:(id)arg5;	// IMP=0x00000000000321aa
+ (id)invocationWithSelector:(SEL)arg1 target:(id)arg2 object1:(id)arg3 object2:(id)arg4;	// IMP=0x000000000002c206
+ (id)invocationWithSelector:(SEL)arg1 target:(id)arg2 object:(id)arg3;	// IMP=0x0000000000002ba6
+ (id)invocationWithSelector:(SEL)arg1 target:(id)arg2;	// IMP=0x0000000000004b5c
@property(readonly) NSNumber *requestedQualityOfService;
@property(readonly) unsigned char priority;
@end


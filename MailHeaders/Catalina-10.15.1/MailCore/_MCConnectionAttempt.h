//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@interface _MCConnectionAttempt : NSObject
{
    long long _securityLayer;	// 8 = 0x8
    long long _port;	// 16 = 0x10
    double _connectTimeout;	// 24 = 0x18
}

@property(nonatomic) double connectTimeout; // @synthesize connectTimeout=_connectTimeout;
@property(nonatomic) long long port; // @synthesize port=_port;
@property(nonatomic) long long securityLayer; // @synthesize securityLayer=_securityLayer;
- (id)description;	// IMP=0x00000000000475e5

@end


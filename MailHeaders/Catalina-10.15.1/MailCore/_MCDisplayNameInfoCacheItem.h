//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class MCDisplayNameInfo, NSString;

@interface _MCDisplayNameInfoCacheItem : NSObject
{
    MCDisplayNameInfo *_info;	// 8 = 0x8
    NSString *_rawAddress;	// 16 = 0x10
}

@property(readonly, copy, nonatomic) NSString *rawAddress; // @synthesize rawAddress=_rawAddress;
@property(readonly, nonatomic) MCDisplayNameInfo *info; // @synthesize info=_info;
- (void).cxx_destruct;	// IMP=0x000000000004a10f
- (id)init;	// IMP=0x000000000004a040
- (id)initWithInfo:(id)arg1 address:(id)arg2;	// IMP=0x0000000000008438

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class ECAuthScheme, NSString;

@interface AuthSchemeBindingProxy : NSObject
{
    BOOL _isSeparator;	// 8 = 0x8
    ECAuthScheme *_authScheme;	// 16 = 0x10
}

+ (id)separatorProxy;	// IMP=0x00000001000971a3
+ (id)noneProxy;	// IMP=0x0000000100097158
@property(nonatomic) BOOL isSeparator; // @synthesize isSeparator=_isSeparator;
@property(retain, nonatomic) ECAuthScheme *authScheme; // @synthesize authScheme=_authScheme;
- (void).cxx_destruct;	// IMP=0x000000010009757a
- (unsigned long long)hash;	// IMP=0x0000000100097508
- (BOOL)isEqual:(id)arg1;	// IMP=0x0000000100097476
@property(readonly, copy, nonatomic) NSString *name;
@property(readonly, copy, nonatomic) NSString *humanReadableName;
- (id)initWithAuthScheme:(id)arg1;	// IMP=0x000000010009725a
- (id)init;	// IMP=0x000000010009720c

@end


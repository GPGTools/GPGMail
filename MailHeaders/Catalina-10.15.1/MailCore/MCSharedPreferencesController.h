//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class NSArray, NSString, NSUserDefaults;

@interface MCSharedPreferencesController : NSObject
{
    NSUserDefaults *_sharedMailUserDefaults;	// 8 = 0x8
}

+ (id)sharedInstance;	// IMP=0x000000000001f05c
+ (id)allocWithZone:(struct _NSZone *)arg1;	// IMP=0x00000000000965c7
@property(retain, nonatomic) NSUserDefaults *sharedMailUserDefaults; // @synthesize sharedMailUserDefaults=_sharedMailUserDefaults;
- (void).cxx_destruct;	// IMP=0x0000000000096d2a
- (void)_preferencesChangedExternally:(id)arg1;	// IMP=0x0000000000096bf9
- (void)_postPreferencesDidChangeNotifications;	// IMP=0x0000000000096ae8
@property(readonly) BOOL intranetDomainsManagedByProfile;
@property BOOL shouldCheckIntranetDomains;
@property(retain) NSArray *intranetDomains;
@property long long addressDisplayMode;
@property BOOL disableRemoteContent;
@property BOOL shouldExpandGroups;
@property(retain) NSString *defaultFromAddress;
- (void)dealloc;	// IMP=0x0000000000096680
- (id)init;	// IMP=0x000000000001f115

@end


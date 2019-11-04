//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <Mail/MCActivityTarget-Protocol.h>

@class NSMapTable, NSMutableArray, NSMutableDictionary, NSMutableSet, NSString, NSTimer;

@interface MFAccountStatus : NSObject <MCActivityTarget>
{
    NSMutableDictionary *_states;	// 8 = 0x8
    NSMutableDictionary *_stateDetails;	// 16 = 0x10
    NSMapTable *_clients;	// 24 = 0x18
    NSMutableSet *_allRegisteredAccounts;	// 32 = 0x20
    unsigned long long _allRegisteredTypes;	// 40 = 0x28
    NSMutableArray *_accountRefreshQueue;	// 48 = 0x30
    NSTimer *_refreshTimer;	// 56 = 0x38
}

+ (id)sharedStatus;	// IMP=0x000000000001aca4
@property(readonly, nonatomic) NSTimer *refreshTimer; // @synthesize refreshTimer=_refreshTimer;
- (void).cxx_destruct;	// IMP=0x000000000001da02
- (void)_accountStatusUpdatedWithInfo:(id)arg1;	// IMP=0x000000000001d8c9
- (void)_refreshAccountStatus:(id)arg1;	// IMP=0x000000000001cb27
- (void)_refreshAccounts:(id)arg1 clearingStatus:(BOOL)arg2;	// IMP=0x000000000001c72a
- (void)refreshStatusForClient:(id)arg1 forceRefresh:(BOOL)arg2;	// IMP=0x000000000001c6d0
- (void)refreshAndClearStatus:(BOOL)arg1;	// IMP=0x000000000001c5fa
- (void)_accountInfoChanged:(id)arg1;	// IMP=0x000000000001c53b
- (void)_networkChanged:(id)arg1;	// IMP=0x000000000001c524
- (void)_timedRefresh:(id)arg1;	// IMP=0x000000000001c3d6
- (void)_setStatusDetails:(id)arg1 forAccount:(id)arg2;	// IMP=0x000000000001c318
- (id)accountStatusDetails:(id)arg1;	// IMP=0x000000000001c25f
- (void)_setStatus:(long long)arg1 forAccount:(id)arg2;	// IMP=0x000000000001c188
- (long long)knownAccountStatus:(id)arg1;	// IMP=0x000000000001bf9a
- (long long)accountStatus:(id)arg1;	// IMP=0x000000000001bef2
- (id)_accountsForTypes:(unsigned long long)arg1;	// IMP=0x000000000001b9f4
- (id)_allRegisteredAccounts;	// IMP=0x000000000001b93b
- (id)_registeredAccountsForClient:(id)arg1 onlyWithUnknownStatus:(BOOL)arg2;	// IMP=0x000000000001b6ff
- (id)registeredAccountsForClient:(id)arg1;	// IMP=0x000000000001b6ad
- (void)unregisterClient:(id)arg1;	// IMP=0x000000000001b3d8
- (void)registerAccounts:(id)arg1 forClient:(id)arg2;	// IMP=0x000000000001b391
- (void)registerAccountTypes:(unsigned long long)arg1 forClient:(id)arg2;	// IMP=0x000000000001b37a
- (void)registerAccountTypes:(unsigned long long)arg1 accounts:(id)arg2 forClient:(id)arg3;	// IMP=0x000000000001b0eb
- (void)invalidate;	// IMP=0x000000000001b055
- (void)dealloc;	// IMP=0x000000000001af65
- (id)init;	// IMP=0x000000000001ad3d

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly, copy, nonatomic) NSString *displayName;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


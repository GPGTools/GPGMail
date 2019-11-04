//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/ECMailAccount-Protocol.h>

@class ACAccount, NSString;

@protocol EDAccount <ECMailAccount>
@property(readonly) BOOL primaryiCloudAccount;
@property(readonly, copy, nonatomic) NSString *statisticsKind;
@property(readonly, copy) ACAccount *systemAccount;
@property(readonly, copy) NSString *identifier;
- (void)savePersistentAccount;
- (BOOL)hasPasswordCredential;
- (BOOL)canAuthenticateWithCurrentCredentials;
- (NSString *)username;
- (NSString *)hostname;
- (NSString *)displayName;
@end


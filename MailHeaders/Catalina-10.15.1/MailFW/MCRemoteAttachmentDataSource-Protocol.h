//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/NSObject-Protocol.h>

@class NSString;

@protocol MCRemoteAttachmentDataSource <NSObject>
- (void)fetchAttachmentForAccessLevel:(long long)arg1 mimePartNumber:(NSString *)arg2 withCompletionBlock:(void (^)(NSError *))arg3;
@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/NSObject-Protocol.h>

@class MFEWSGetMessagesNeedingBodiesOperation, MFMailbox, NSArray;

@protocol MFEWSGetMessagesNeedingBodiesOperationDelegate <NSObject>
- (void)getMessagesNeedingBodiesOperation:(MFEWSGetMessagesNeedingBodiesOperation *)arg1 didGetMessagesNeedingBodies:(NSArray *)arg2 forMailbox:(MFMailbox *)arg3;
@end


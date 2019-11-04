//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <IMAP/IMAPAggregateCommand.h>

@interface IMAPAggregateFetchUIDCommand : IMAPAggregateCommand
{
    unsigned int _expectedSize;	// 8 = 0x8
}

@property unsigned int expectedSize; // @synthesize expectedSize=_expectedSize;
- (long long)maxAllowedConnectionState;	// IMP=0x000000000002ef21
- (long long)minRequiredConnectionState;	// IMP=0x000000000002ef16
- (void)cleanupAfterCompletion;	// IMP=0x000000000002ef10
- (id)activityString;	// IMP=0x000000000002eea3
- (id)commandTypeString;	// IMP=0x000000000002ee84
- (id)initWithCommands:(id)arg1;	// IMP=0x000000000002ee70
- (id)initWithCommands:(id)arg1 expectedSize:(unsigned int)arg2;	// IMP=0x000000000002ee2e

@end


//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <Mail/MFEWSCreateItemRequestOperation.h>

@class MFEWSCreateEventReplyResponseOperation, MFEWSGetItemsResponseOperation, NSString;

@interface MFEWSCreateEventReplyRequestOperation : MFEWSCreateItemRequestOperation
{
    BOOL _messageResponseType;	// 8 = 0x8
    NSString *_messageMeetingItemIdString;	// 16 = 0x10
    MFEWSGetItemsResponseOperation *_getItemsResponse;	// 24 = 0x18
}

@property(readonly, nonatomic) BOOL messageResponseType; // @synthesize messageResponseType=_messageResponseType;
@property(readonly, nonatomic) MFEWSGetItemsResponseOperation *getItemsResponse; // @synthesize getItemsResponse=_getItemsResponse;
@property(readonly, copy, nonatomic) NSString *messageMeetingItemIdString; // @synthesize messageMeetingItemIdString=_messageMeetingItemIdString;
- (void).cxx_destruct;	// IMP=0x000000000006f8e9
- (id)newResponseOperationWithGateway:(id)arg1 errorHandler:(id)arg2;	// IMP=0x000000000006f848
@property(retain, nonatomic) MFEWSCreateEventReplyResponseOperation *responseOperation;
- (id)prepareRequest;	// IMP=0x000000000006f3bd
- (void)encodeWithCoder:(id)arg1;	// IMP=0x000000000006f2f8
- (id)initWithCoder:(id)arg1;	// IMP=0x000000000006f206
- (id)initWithFolderIdString:(id)arg1 messageType:(BOOL)arg2 disposition:(long long)arg3 gateway:(id)arg4 errorHandler:(id)arg5;	// IMP=0x000000000006f137
- (void)_ewsCreateEventReplyRequestOperationCommonInitWithItemIdString:(id)arg1 responseType:(BOOL)arg2;	// IMP=0x000000000006eea5
- (id)initWithItemIdString:(id)arg1 folderIdString:(id)arg2 messageType:(BOOL)arg3 responseType:(BOOL)arg4 disposition:(long long)arg5 gateway:(id)arg6 errorHandler:(id)arg7;	// IMP=0x000000000006edec

@end


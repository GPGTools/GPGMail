/*
 *     Generated by class-dump 3.4 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2012 by Steve Nygard.
 */

#import "NSObject.h"

#import "MCActivityTarget.h"

@class MCInvocationQueue, NSDate, NSMutableArray, NSMutableSet;

@interface MFParentalControlManager : NSObject <MCActivityTarget>
{
    NSMutableSet *_pcStores;
    MCInvocationQueue *_tasks;
    NSDate *_lastCleanupDate;
    NSMutableArray *_recentRequests;
    BOOL _isDirty;
    BOOL _recentRequestsDirty;
    NSMutableSet *_pendingRequests;
}

+ (id)sharedManager;
+ (id)allocWithZone:(struct _NSZone *)arg1;
- (void)_saveChangesWithDelay;
@property BOOL isDirty;
- (void)_approveEmailListChanged:(id)arg1;
- (BOOL)isEmail:(id)arg1 inEmailList:(id)arg2;
- (BOOL)rejectRequest:(id)arg1;
- (BOOL)approveRequest:(id)arg1;
- (BOOL)_respondToRequest:(id)arg1 approve:(BOOL)arg2;
- (void)_deliverResponseMessage:(id)arg1 requestMessage:(id)arg2;
- (id)_makeResponseMessageToRequest:(id)arg1 approve:(BOOL)arg2;
- (void)saveChanges;
- (BOOL)requestApprovalForOutgoingMessage:(id)arg1;
- (void)_requestApprovalForOutgoingMessage:(id)arg1 srcStore:(id)arg2;
- (void)_deliverApprovalRequestMessage:(id)arg1 forOutgoingMessage:(id)arg2;
- (BOOL)haveEmailsBeenApproved:(id)arg1 unapprovedOnes:(id)arg2;
- (BOOL)processIncomingMessage:(id)arg1 messageIsParentResponse:(char *)arg2;
- (void)_cleanupPCStores;
- (void)_reallyCleanupPCStores;
- (void)_cleanupPCStore:(id)arg1;
- (void)_rejectAddresses:(id)arg1 responseFromAccount:(id)arg2;
- (void)_approveAddresses:(id)arg1 responseFromAccount:(id)arg2;
- (void)_reallyRequestApprovalForIncomingMessage:(id)arg1 srcStore:(id)arg2 pcStore:(id)arg3 messageInPCStore:(id)arg4;
- (void)_requestApprovalForIncomingMessage:(id)arg1 srcStore:(id)arg2 pcStore:(id)arg3 messageInPCStore:(id)arg4;
- (BOOL)_hasPendingRequestForSender:(id)arg1;
- (void)_removeSendersFromRecentRequests:(id)arg1;
- (BOOL)_hasRecentlySentPermissionRequestForSender:(id)arg1;
- (id)_recentRequestsNoLock;
- (id)_recentRequestsFilePath;
- (id)_deliverMessage:(id)arg1;
- (id)_makeRequestMessageForMessage:(id)arg1 isOutgoingMessage:(BOOL)arg2;
- (id)_openPCStoreForAccount:(id)arg1;
- (id)_openStoreForPCMailbox:(id)arg1;
- (id)_openStoreForPCMailbox:(id)arg1 keepOpen:(BOOL)arg2;
- (void)_rejectSenders:(id)arg1 sourcePCMailbox:(id)arg2;
- (void)_approveSenders:(id)arg1 sourcePCMailbox:(id)arg2 destinationAccount:(id)arg3;
- (void)_cleanupPCStoresAfterDelay:(id)arg1;
- (void)deleteAccount:(id)arg1;
- (id)headersRequiredForParentalControl;
- (BOOL)isParentEmailAvailable;
- (id)parentalControlDirectory;
- (id)autorelease;
- (oneway void)release;
- (unsigned long long)retainCount;
- (id)retain;
- (void)dealloc;
- (id)init;

@end


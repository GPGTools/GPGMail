/* MFLibraryStore+GPGMail.m created by Lukas Pitschl (@lukele) on Thursday 21-Sep-2017 */

/*
 * Copyright (c) 2017, GPGTools <team@gpgtools.org>
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of GPGTools nor the names of GPGMail
 *       contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY GPGTools ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL GPGTools BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#import "MFLibraryStore+GPGMail.h"

#import "NSObject+LPDynamicIvars.h"
#import "CCLog.h"

#import "MCMessage.h"
#import "Library+GPGMail.h"
#import "MFLibraryStore.h"
#import "MCMessageBody.h"
#import "MFLibrary.h"
#import "MimePart+GPGMail.h"

extern NSString * const kLibraryMimeBodyReturnCompleteBodyDataForComposeBackendKey;
extern NSString * const kLibraryMimeBodyReturnCompleteBodyDataForMessageKey;
extern NSString * const kLibraryMimeBodyReturnCompleteBodyDataKey;
extern NSString * const kLibraryMessageDataIsBeingForceFetched;

NSString * const kMFLibraryStoreMessageBodyContainsPGPData = @"MFLibraryStoreMessageBodyContainsPGPData";
NSString * const kMFLibraryStoreMessageDataFetchLockMap = @"MFLibraryStoreMessageDataFetchLockMap";
NSString * const kMFLibraryStoreMessageWaitForData = @"MFLibraryStoreMessageWaitForData";
NSString * const kMFLibraryStoreMessageFetchLockMap = @"MFLibraryStoreMessageFetchLockMap";

// This class is responsible for fetching message data on High Sierra.

@implementation MFLibraryStore_GPGMail

- (id)MAInitWithCriterion:(id)criterion mailbox:(id)mailbox readOnly:(BOOL)readOnly {
    id object = [self MAInitWithCriterion:criterion mailbox:mailbox readOnly:readOnly];
    [object setIvar:kMFLibraryStoreMessageFetchLockMap value:[NSMutableDictionary new]];
    return object;
}

- (void)MAGetTopLevelMimePart:(id *)topLevelMimePart headers:(id *)headers body:(id *)body forMessage:(MCMessage *)currentMessage fetchIfNotAvailable:(BOOL)fetchIfNotAvailable updateFlags:(BOOL)updateFlags allowPartial:(BOOL)allowPartial {
    // In macOS High Sierra, Mail has introduced a new caching technique, in order to cache
    // headers, body and mime structure in memory.
    // When a message is first fetched from a mail server, the mime tree is parsed and a representing html body
    // is created, which is then cached for every further display until a user restarts Mail.
    // While this is a very welcome change for normal messages, since it speeds message loading
    // up immensely, it's not suitable for PGP messages.
    // If GPGMail tries to handle PGP data in messages when their mime tree is first parsed, users would be
    // bothered by passphrase requests even though they might not be viewing the message at the time and might
    // not be interested in its content at the time. In addition, if they were to cancel the passphrase request,
    // the body would be cached in encrypted manner and would never be decrypted again, unless the user restarts
    // Mail.
    // In order to fix this usability nuisance, GPGMail tries to figure out if a message contains PGP data
    // and if it does, will disable the caching mechanism for that particular message.
    // Since the complete body data is no longer available in most cases, a best guess has to be performed
    // based on the mime structure of a message.

    // Since macOS Sierra, the body data of a message is stripped of data belonging to individual attachments.
    // This information is however highly necessary in order to correctly detect and process PGP data when the mime
    // structure is parsed internally to prepare the message for display.
    // In order to fix that, the wantsCompleteBodyData signals if a user actively selected a message, and in that
    // case, GPGMail will try to re-construct the entire body data (including attachment data) by either injecting
    // the attachment data from already downloaded attachments, or by re-downloading the complete message.
    BOOL wantsCompleteBodyData = ([[[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMimeBodyReturnCompleteBodyDataKey] boolValue] &&
                                  [[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMimeBodyReturnCompleteBodyDataForMessageKey] == currentMessage) || [[[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMimeBodyReturnCompleteBodyDataForComposeBackendKey] boolValue];
    BOOL messageIsBeingForceFetched = [[[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMessageDataIsBeingForceFetched] boolValue] && [[currentMessage getIvar:kLibraryMessageDataIsBeingForceFetched] boolValue];
    // If either wantsCompleteBodyData is not set, or body is NULL, so the Mail call is not interested in
    // the message body data, call the original Mail method.
    // Bug #977: Crash due to endless loop when fetching the raw message from server.
    //
    // This bug has only been observed with MS Exchange servers, but could affect
    // other messages as well. In order to prevent the endless loop, check if the
    // message is already being force fetched and if so, don't process further, but
    // call into Mail's original method.
    //
    // The endless loop is caused when +[MFLibrary setData:forMessage:isPartial:hasCompleteText:]
    // is called after receiving message data for a new message, and that method internally
    // calls this method. Since no data is available yet, the message is force fetched and that
    // in turn causes the endless loop.
    if(!wantsCompleteBodyData || body == NULL || messageIsBeingForceFetched) {
        return [self MAGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial];
    }
    // If a message body is cached and it is not flagged as containing PGP data, the cached version is returned.
    MCMessageBody *cachedMessageBody = [(MFLibraryStore *)self _cachedBodyForMessage:currentMessage valueIfNotPresent:NULL];
    if([cachedMessageBody ivarExists:kMFLibraryStoreMessageBodyContainsPGPData] && [[cachedMessageBody getIvar:kMFLibraryStoreMessageBodyContainsPGPData] boolValue] == NO) {
        return [self MAGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial];
    }

    void (^cleanUp)(id, MCMessage *, NSRecursiveLock *) = ^void(id object, MCMessage *currentMessage, NSRecursiveLock *messageLock) {
        // Unset wait for data, so method calls not controlled by GPGMail don't use
        // the locks. (ref. Bug #952)
        [[[NSThread currentThread] threadDictionary] setValue:@(NO) forKey:kMFLibraryStoreMessageWaitForData];

        if(messageLock) {
            NSMutableDictionary *messageLockMap = [object getIvar:kMFLibraryStoreMessageFetchLockMap];
            @synchronized(messageLockMap) {
                NSRecursiveLock *endLock = messageLockMap[currentMessage];
                if(messageLock == endLock) {
                    @try {
                        [messageLockMap removeObjectForKey:currentMessage];
                    }
                    @catch(NSException *exception) {}
                }
            }
        }
    };

    // Bug #952: Messages containing PGP data are not always processed properly
    //
    // Under some circumstances a call to +[MFLibrary _messageDataAtPath:] returns nil
    // even though the file exists on disk.
    // It's not yet entirely clear why that happens, but it might help, if the data is only
    // read when the mime part is created for display instead of twice, once for the check
    // if the message contains PGP data and once for display.
    // Call into the original Mail method in order to get the top level mime part based
    // on the partial data available.
    MCMimePart *temporaryMimePart = nil;
    // It appears that for display, topLevelMimePart is always NULL.
    [[[NSThread currentThread] threadDictionary] setValue:@(YES) forKey:kMFLibraryStoreMessageWaitForData];
    [self MAGetTopLevelMimePart:&temporaryMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial];
    if(![(MimePart_GPGMail *)temporaryMimePart mightContainPGPData]) {
        cleanUp(self, currentMessage, nil);
        return;
    }

    // Now all the best cases are covered, down to the nitty gritty.
    // Bug #967: Deadlock preventing messages from loading
    //
    // In order to prevent the same message from being loaded and processed from
    // multiple threads, we have been using Mail's internal lock `_libraryFetchLockMap`
    // Unfortunately this lock map is also used in some methods which are called when
    // data is fetched from the server, which in turn calls this method again. Under special
    // circumstances that behavior can trigger a deadlock.
    // To have better control over the locking behavior, we use our own lock map instead.
    NSMutableDictionary *messageLockMap = [self getIvar:kMFLibraryStoreMessageFetchLockMap];
    NSRecursiveLock *messageLock = nil;
    @synchronized(messageLockMap) {
        messageLock = messageLockMap[currentMessage];
        if(!messageLock) {
            messageLock = [NSRecursiveLock new];
            messageLockMap[currentMessage] = messageLock;
        }
    }
    [messageLock lock];

    // The message contains PGP data, so the first step is to try to re-create the complete body data
    // from locally available message data. If the message hasn't been downloaded yet in its entirety,
    // the message data is fetched from the mail server.
    // By passing nil as topLevelPart, -[MFLibrary GMRawDataForMessage:topLevelPart:fetchIfNotAvailable] will
    // create one based on the always available partial message.
    NSData *messageData = [Library_GPGMail GMRawDataForMessage:currentMessage topLevelPart:nil fetchIfNotAvailable:NO];
    if(!messageData) {
        @try {
            messageData = [Library_GPGMail GMRawDataForMessage:currentMessage topLevelPart:nil fetchIfNotAvailable:YES];
        }
        @catch(NSException *exception) {
            cleanUp(self, currentMessage, nil);
        }
        @finally {
            cleanUp(self, currentMessage, nil);
        }
    }
    if(!messageData) {
        // Something is going really wrong. It should never be possible to come here.
        [messageLock unlock];
        cleanUp(self, currentMessage, messageLock);
        DebugLog(@"Failed to fetch data for message! %@", currentMessage);
        return;
    }
    @try {
        if(topLevelMimePart != NULL) {
            *topLevelMimePart = nil;
        }
        if(body != NULL) {
            *body = nil;
        }
        BOOL success = [Library_GPGMail GMGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage messageData:messageData shouldProcessPGPData:YES];
    }
    @catch (NSException *exception) {
        [self MAGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial];
        cleanUp(self, currentMessage, nil);
    }
    @finally {
        [messageLock unlock];
        cleanUp(self, currentMessage, messageLock);
    }
}

- (void)MAGetTopLevelMimePart:(id *)topLevelMimePart headers:(id *)headers body:(id *)body forMessage:(MCMessage *)currentMessage fetchIfNotAvailable:(BOOL)fetchIfNotAvailable updateFlags:(BOOL)updateFlags allowPartial:(BOOL)allowPartial skipSignatureVerification:(BOOL)skipSignatureVerification {
    // In macOS High Sierra, Mail has introduced a new caching technique, in order to cache
    // headers, body and mime structure in memory.
    // When a message is first fetched from a mail server, the mime tree is parsed and a representing html body
    // is created, which is then cached for every further display until a user restarts Mail.
    // While this is a very welcome change for normal messages, since it speeds message loading
    // up immensely, it's not suitable for PGP messages.
    // If GPGMail tries to handle PGP data in messages when their mime tree is first parsed, users would be
    // bothered by passphrase requests even though they might not be viewing the message at the time and might
    // not be interested in its content at the time. In addition, if they were to cancel the passphrase request,
    // the body would be cached in encrypted manner and would never be decrypted again, unless the user restarts
    // Mail.
    // In order to fix this usability nuisance, GPGMail tries to figure out if a message contains PGP data
    // and if it does, will disable the caching mechanism for that particular message.
    // Since the complete body data is no longer available in most cases, a best guess has to be performed
    // based on the mime structure of a message.
    
    // Since macOS Sierra, the body data of a message is stripped of data belonging to individual attachments.
    // This information is however highly necessary in order to correctly detect and process PGP data when the mime
    // structure is parsed internally to prepare the message for display.
    // In order to fix that, the wantsCompleteBodyData signals if a user actively selected a message, and in that
    // case, GPGMail will try to re-construct the entire body data (including attachment data) by either injecting
    // the attachment data from already downloaded attachments, or by re-downloading the complete message.
    BOOL wantsCompleteBodyData = ([[[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMimeBodyReturnCompleteBodyDataKey] boolValue] &&
                                  [[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMimeBodyReturnCompleteBodyDataForMessageKey] == currentMessage) || [[[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMimeBodyReturnCompleteBodyDataForComposeBackendKey] boolValue];
    BOOL messageIsBeingForceFetched = [[[[NSThread currentThread] threadDictionary] valueForKey:kLibraryMessageDataIsBeingForceFetched] boolValue] && [[currentMessage getIvar:kLibraryMessageDataIsBeingForceFetched] boolValue];
    // If either wantsCompleteBodyData is not set, or body is NULL, so the Mail call is not interested in
    // the message body data, call the original Mail method.
    // Bug #977: Crash due to endless loop when fetching the raw message from server.
    //
    // This bug has only been observed with MS Exchange servers, but could affect
    // other messages as well. In order to prevent the endless loop, check if the
    // message is already being force fetched and if so, don't process further, but
    // call into Mail's original method.
    //
    // The endless loop is caused when +[MFLibrary setData:forMessage:isPartial:hasCompleteText:]
    // is called after receiving message data for a new message, and that method internally
    // calls this method. Since no data is available yet, the message is force fetched and that
    // in turn causes the endless loop.
    if(!wantsCompleteBodyData || body == NULL || messageIsBeingForceFetched) {
        return [self MAGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial skipSignatureVerification:skipSignatureVerification];
    }
    // If a message body is cached and it is not flagged as containing PGP data, the cached version is returned.
    MCMessageBody *cachedMessageBody = [(MFLibraryStore *)self _cachedBodyForMessage:currentMessage valueIfNotPresent:NULL];
    if([cachedMessageBody ivarExists:kMFLibraryStoreMessageBodyContainsPGPData] && [[cachedMessageBody getIvar:kMFLibraryStoreMessageBodyContainsPGPData] boolValue] == NO) {
        return [self MAGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial skipSignatureVerification:skipSignatureVerification];
    }
    
    void (^cleanUp)(id, MCMessage *, NSRecursiveLock *) = ^void(id object, MCMessage *currentMessage, NSRecursiveLock *messageLock) {
        // Unset wait for data, so method calls not controlled by GPGMail don't use
        // the locks. (ref. Bug #952)
        [[[NSThread currentThread] threadDictionary] setValue:@(NO) forKey:kMFLibraryStoreMessageWaitForData];

        if(messageLock) {
            NSMutableDictionary *messageLockMap = [object getIvar:kMFLibraryStoreMessageFetchLockMap];
            @synchronized(messageLockMap) {
                NSRecursiveLock *endLock = messageLockMap[currentMessage];
                if(messageLock == endLock) {
                    @try {
                        [messageLockMap removeObjectForKey:currentMessage];
                    }
                    @catch(NSException *exception) {}
                }
            }
        }
    };

    // Bug #952: Messages containing PGP data are not always processed properly
    //
    // Under some circumstances a call to +[MFLibrary _messageDataAtPath:] returns nil
    // even though the file exists on disk.
    // It's not yet entirely clear why that happens, but it might help, if the data is only
    // read when the mime part is created for display instead of twice, once for the check
    // if the message contains PGP data and once for display.
    // Call into the original Mail method in order to get the top level mime part based
    // on the partial data available.
    MCMimePart *temporaryMimePart = nil;
    // It appears that for display, topLevelMimePart is always NULL.
    [[[NSThread currentThread] threadDictionary] setValue:@(YES) forKey:kMFLibraryStoreMessageWaitForData];
    [self MAGetTopLevelMimePart:&temporaryMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial skipSignatureVerification:skipSignatureVerification];
    if(![(MimePart_GPGMail *)temporaryMimePart mightContainPGPData]) {
        cleanUp(self, currentMessage, nil);
        return;
    }

    // Now all the best cases are covered, down to the nitty gritty.
    // Bug #967: Deadlock preventing messages from loading
    //
    // In order to prevent the same message from being loaded and processed from
    // multiple threads, we have been using Mail's internal lock `_libraryFetchLockMap`
    // Unfortunately this lock map is also used in some methods which are called when
    // data is fetched from the server, which in turn calls this method again. Under special
    // circumstances that behavior can trigger a deadlock.
    // To have better control over the locking behavior, we use our own lock map instead.
    NSMutableDictionary *messageLockMap = [self getIvar:kMFLibraryStoreMessageFetchLockMap];
    NSRecursiveLock *messageLock = nil;
    @synchronized(messageLockMap) {
        messageLock = messageLockMap[currentMessage];
        if(!messageLock) {
            messageLock = [NSRecursiveLock new];
            messageLockMap[currentMessage] = messageLock;
        }
    }
    [messageLock lock];

    // The message contains PGP data, so the first step is to try to re-create the complete body data
    // from locally available message data. If the message hasn't been downloaded yet in its entirety,
    // the message data is fetched from the mail server.
    // By passing nil as topLevelPart, -[MFLibrary GMRawDataForMessage:topLevelPart:fetchIfNotAvailable] will
    // create one based on the always available partial message.
    NSData *messageData = [Library_GPGMail GMRawDataForMessage:currentMessage topLevelPart:nil fetchIfNotAvailable:NO];
    if(!messageData) {
        @try {
            messageData = [Library_GPGMail GMRawDataForMessage:currentMessage topLevelPart:nil fetchIfNotAvailable:YES];
        }
        @catch(NSException *exception) {
            cleanUp(self, currentMessage, nil);
        }
        @finally {
            cleanUp(self, currentMessage, nil);
        }
    }
    if(!messageData) {
        // Something is going really wrong. It should never be possible to come here.
        [messageLock unlock];
        cleanUp(self, currentMessage, messageLock);
        DebugLog(@"Failed to fetch data for message! %@", currentMessage);
        return;
    }
    @try {
        if(topLevelMimePart != NULL) {
            *topLevelMimePart = nil;
        }
        if(body != NULL) {
            *body = nil;
        }
        BOOL success = [Library_GPGMail GMGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage messageData:messageData shouldProcessPGPData:YES];
    }
    @catch (NSException *exception) {
        [self MAGetTopLevelMimePart:topLevelMimePart headers:headers body:body forMessage:currentMessage fetchIfNotAvailable:fetchIfNotAvailable updateFlags:updateFlags allowPartial:allowPartial skipSignatureVerification:skipSignatureVerification];
        cleanUp(self, currentMessage, nil);
    }
    @finally {
        [messageLock unlock];
        cleanUp(self, currentMessage, messageLock);
    }
}

@end


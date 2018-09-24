/* Library+GPGMail.m created by Lukas Pitschl (@lukele) on Wed 13-Jun-2013 */

/*
 * Copyright (c) 2000-2013, GPGTools Team <team@gpgtools.org>
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
 * THIS SOFTWARE IS PROVIDED BY THE GPGTools Team ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE GPGTools Team BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CCLog.h"

#import "Library+GPGMail.h"
#import "NSObject+LPDynamicIvars.h"
#import "GPGFlaggedString.h"

#import "MFLibrary.h"
#import "MCMessage.h"
#import "MCMimeBody.h"
#import "MCMimePart.h"

#import "MCAttachment.h"
#import "MFLibraryAttachmentDataSource.h"
#import "MFLibraryMessage.h"

#import "MimePart+GPGMail.h"

#import "MCMessageGenerator.h"
#import "MCMutableMessageHeaders.h"
#import "MCOutgoingMessage.h"

#import "MimeBody+GPGMail.h"

#import "MFEWSStore.h"
#import "IMAPMessageDataSource-Protocol.h"
#import "MCParsedMessage.h"
#import "MFRemoteURLAttachmentDataSource.h"
#import "MFLibraryAttachmentDataSource.h"
#import "MFRemoteAttachmentDataSource.h"
#import "MCDataAttachmentDataSource.h"
#import "MCFileWrapperAttachmentDataSource.h"
#import "MCFileURLAttachmentDataSource.h"
#import "MCStationeryCompositeImage.h"

#import "GPGMailBundle.h"

// 10.13
#import "NSData-MailCoreAdditions.h"

#import <sys/stat.h>

#define MAIL_SELF(self) ((MFLibrary *)(self))

extern NSString *MCDescriptionForMessageFlags(int arg0);
extern const NSString *kMimeBodyMessageKey;
extern NSString * const kMimePartAllowPGPProcessingKey;

NSString * const kLibraryMimeBodyReturnCompleteBodyDataKey = @"LibraryMimeBodyReturnCompleteBodyDataKey";
NSString * const kLibraryMimeBodyReturnCompleteBodyDataForMessageKey = @"LibraryMimeBodyReturnCompleteBodyDataForMessageKey";
extern NSString * const kLibraryMimeBodyReturnCompleteBodyDataForComposeBackendKey;

NSString * const kLibraryMessagePreventSnippingAttachmentDataKey = @"LibraryMessagePreventSnippingAttachmentDataKey";
NSString * const kLibraryMessageDataIsBeingForceFetched = @"LibraryMessageDataIsBeingForceFetched";


extern NSString * const kMessageSecurityFeaturesKey;
extern NSString * const kMFLibraryStoreMessageWaitForData;

static NSMutableDictionary *messageDataAccessMap;

@implementation Library_GPGMail

/** ONLY FOR Mavericks and then on MFLibrary. */
+ (id)MAPlistDataForMessage:(id)message subject:(id)subject sender:(id)sender to:(id)to dateSent:(id)dateSent dateReceived:(id)dateReceived dateLastViewed:(id)dateLastViewed remoteID:(id)remoteID originalMailboxURLString:(id)originalMailboxURLString gmailLabels:(id)gmailLabels flags:(long long)flags mergeWithDictionary:(id)mergeWithDictionary {
    if([sender isKindOfClass:[GPGFlaggedString class]])
        sender = [(GPGFlaggedString *)sender description];
    if([to isKindOfClass:[GPGFlaggedString class]])
        to = [(GPGFlaggedString *)to description];
    
    return [self MAPlistDataForMessage:message subject:subject sender:sender to:to dateSent:dateSent dateReceived:dateReceived dateLastViewed:dateLastViewed remoteID:remoteID originalMailboxURLString:originalMailboxURLString gmailLabels:gmailLabels flags:flags mergeWithDictionary:mergeWithDictionary];
}

+ (id)MAPlistDataForMessage:(id)message subject:(id)subject sender:(id)sender to:(id)to dateSent:(id)dateSent remoteID:(id)remoteID originalMailbox:(id)originalMailbox flags:(long long)flags mergeWithDictionary:(id)mergeWithDictionary {
    if([sender isKindOfClass:[GPGFlaggedString class]])
        sender = [(GPGFlaggedString *)sender description];
    if([to isKindOfClass:[GPGFlaggedString class]])
        to = [(GPGFlaggedString *)to description];
    
    return [self MAPlistDataForMessage:message subject:subject sender:sender to:to dateSent:dateSent remoteID:remoteID originalMailbox:originalMailbox flags:flags mergeWithDictionary:mergeWithDictionary];
}

+ (NSData *)GMDataForMessage:(MCMessage *)message mimePart:(MCMimePart *)mimePart fetchIfNotAvailable:(BOOL)fetchIfNotAvailable {
    MCAttachment *attachment = [[MCAttachment alloc] initWithMimePart:mimePart];
    MFLibraryAttachmentDataSource *dataSource = [[MFLibraryAttachmentDataSource alloc] initWithMessage:message mimePartNumber:[mimePart partNumber] attachment:attachment remoteDataSource:nil];
    
    // Not available and should not be fetched, out of here.
    if(![dataSource dataIsLocallyAvailable] && !fetchIfNotAvailable) {
        return nil;
    }

    __block dispatch_semaphore_t waiter = dispatch_semaphore_create(0);
    __block NSData *attachmentData = nil;
    [dataSource dataForAccessLevel:1 completionBlock:^(NSData *data, NSError *error){
        attachmentData = data;
        dispatch_semaphore_signal(waiter);
    }];
    dispatch_semaphore_wait(waiter, DISPATCH_TIME_FOREVER);
    
    return attachmentData;
}

+ (NSData *)GMLocalMessageDataForMessage:(MCMessage *)message topLevelPart:(MCMimePart *)topLevelPart error:(__autoreleasing NSError **)error {
    // MCMessageGenerator is usually used for building Outgoing Messages so it should
    // be very suitable for this task.

    // The mime tree is already available, so basically the only thing left to do, is
    // build the NSMapTable with the partData for the mime tree.
    __block NSMapTable *partData = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    __block NSError *partError = nil;
    
    [(MimePart_GPGMail *)topLevelPart enumerateSubpartsWithBlock:^(MCMimePart *mimePart) {
        NSData *partBodyData = nil;
        if([mimePart isAttachment]) {
            partBodyData = [[self class] GMDataForMessage:message mimePart:mimePart fetchIfNotAvailable:NO];
            if(!partBodyData) {
                // If the data of an attachment is missing, abort. This means that the attachment
                // or for now the entire message has to be re-fetched.
                partError = [NSError errorWithDomain:@"GMAttachmentMissingError" code:201000 userInfo:nil];
                return;
            }
            if([[mimePart.contentTransferEncoding lowercaseString] isEqualToString:@"base64"]) {
                partBodyData = [partBodyData base64EncodedDataWithOptions:NSDataBase64Encoding76CharacterLineLength];
            }
        }
        else {
            // For partial emlx files, the top level part encodedBodyDay returns the entire
            // mime tree. Using decodedData, it's possible to check, if the part really contains data.
            // Only in that case, the encodedBodyData is added to the message data.
            partBodyData = [mimePart decodedData];
            if(partBodyData) {
                partBodyData = [mimePart encodedBodyData];
            }
        }
        if(partBodyData) {
            [partData setObject:partBodyData forKey:mimePart];
        }
    }];
    
    if(partError) {
        *error = partError;
        return nil;
    }
    
    MCMessageGenerator *messageGenerator = [[MCMessageGenerator alloc] init];
    MCMutableMessageHeaders *messageHeaders = [[MCMutableMessageHeaders alloc] initWithHeaderData:[topLevelPart headerData] encodingHint:NSUTF8StringEncoding];
    MCOutgoingMessage *outgoingMessage = [messageGenerator _newOutgoingMessageFromTopLevelMimePart:topLevelPart topLevelHeaders:messageHeaders withPartData:partData];

    return [outgoingMessage rawData];
}

+ (NSData *)GMForceFetchMessageDataForMessage:(MCMessage *)message {
    [message setIvar:kLibraryMessageDataIsBeingForceFetched value:@(YES)];
    [[[NSThread currentThread] threadDictionary] setValue:@(YES) forKey:kLibraryMessageDataIsBeingForceFetched];

    NSData *messageData = [message messageDataFetchIfNotAvailable:YES newDocumentID:nil];

    [messageData removeIvar:kLibraryMessageDataIsBeingForceFetched];
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:kLibraryMessageDataIsBeingForceFetched];

    return messageData;
}

+ (NSData *)GMRawDataForMessage:(MCMessage *)currentMessage topLevelPart:(MCMimePart *)topLevelPart fetchIfNotAvailable:(BOOL)fetchIfNotAvailable {
    // This method tries to load the complete message data from different sources.
    // 1.) Local .emlx file
    //     Mail caches the message data it fetches from the mail server in a local .emlx file
    //     In most cases however, only a partial.emlx file is available, which contains the message
    //     but the attachment data has been stripped out.
    //     Whenever there is a .emlx file with the complete message data available, GPGMail
    //     will always prefer and use that, since it's the most pure representation of the message
    //     as it is stored on the server.
    //
    // 2.) Local partial .emlx file with re-added attachment data
    //     If no local .emlx file is available, GPGMail tries to re-create the entire message data
    //     based on the mime tree of the partial .emlx file and the already downloaded attachment data.
    //     This approach is however not ideal when the message is PGP/MIME signed, since the re-created message
    //     data might differ from the data as stored on the server as Mail reformats headers in the partial.emlx file
    //
    // 3.) Original data from the server
    //     If approach nr. 2 fails, since not all attachments have been downloaded yet, or the message
    //     is PGP/MIME signed, GPGMail will attempt to force fetch the data from the server.
    BOOL isCompleteMessageAvailable = NO;
    NSData *messageData = [self GMMessageDataForMessage:currentMessage isCompleteMessageAvailable:&isCompleteMessageAvailable];
    if(isCompleteMessageAvailable) {
        return messageData;
    }
    if(!messageData) {
        DebugLog(@"Oh noes, can't fetch message data for message: %@", currentMessage);
    }
    
    if(!topLevelPart) {
        topLevelPart = [[MCMimePart alloc] initWithEncodedData:messageData];
        [topLevelPart parse];
    }
    BOOL mightContainPGPData = [(MimePart_GPGMail *)topLevelPart mightContainPGPMIMESignedData];
    // If the message is PGP/MIME signed but fetch is not allowed, no message data is returned.
    // The calling method might then release a lock and call this method again with fetchIfNotAvailable
    // enabled. Otherwise trying to fetch the data from the server might result in a deadlock.
    if(mightContainPGPData && !fetchIfNotAvailable) {
        return nil;
    }
    if(mightContainPGPData && fetchIfNotAvailable) {
        NSData *messageDataFromServer = [self GMForceFetchMessageDataForMessage:currentMessage];
        if(messageDataFromServer) {
            messageData = messageDataFromServer;
        }
        return messageData;
    }
    
    NSError *error = nil;
    NSData *localMessageData = [self GMLocalMessageDataForMessage:currentMessage topLevelPart:topLevelPart error:&error];
    if(!localMessageData && error) {
        if(fetchIfNotAvailable) {
            NSData *messageDataFromServer = [self GMForceFetchMessageDataForMessage:currentMessage];
            if(messageDataFromServer) {
                messageData = messageDataFromServer;
            }
            return messageData;
        }
        return nil;
    }
    
    messageData = localMessageData;
    return messageData;
}

+ (BOOL)GMGetTopLevelMimePart:(__autoreleasing id *)topLevelMimePart headers:(__autoreleasing id *)headers body:(__autoreleasing id *)body forMessage:(MCMessage *)currentMessage messageData:(NSData *)messageData shouldProcessPGPData:(BOOL)shouldProcessPGPData {
    // If for some reason no message data is available, something has gone terribly wrong.
    // Out of here!
    if(!messageData) {
        if(topLevelMimePart != NULL) {
            *topLevelMimePart = nil;
        }
        if(headers != NULL) {
            *headers = nil;
        }
        if(body != NULL) {
            *body = nil;
        }
        return NO;
    }

    // Create the mime part, headers and message body.
    NSRange headerDataRange = [messageData rangeOfRFC822HeaderData];
    NSData *headerData = [messageData subdataWithRange:headerDataRange];
    if(headers != NULL) {
        *headers = [[MCMessageHeaders alloc] initWithHeaderData:headerData encodingHint:0x0];
    }
    MCMimePart *mimePart = nil;
    if(topLevelMimePart != NULL || body != NULL) {
        NSData *bodyData = nil;
        if([messageData length] - (headerDataRange.location + headerDataRange.length) > 0) {
            NSRange bodyDataRange = NSMakeRange(headerDataRange.location + headerDataRange.length, [messageData length] - (headerDataRange.location + headerDataRange.length));
            bodyData = [messageData subdataWithRange:bodyDataRange];
        }
        mimePart = [[MCMimePart alloc] initWithEncodedHeaderData:headerData encodedBodyData:bodyData];
        if(![mimePart parse]) {
            mimePart = nil;
        }
        if(([currentMessage type] & 0xfe) == 0x6) {
            [mimePart setHideCalendarMimePart:YES];
        }
    }
    if(topLevelMimePart != NULL) {
        *topLevelMimePart = mimePart;
    }
    if(body != NULL && mimePart != NULL) {
        if(shouldProcessPGPData) {
            [mimePart setIvar:kMimePartAllowPGPProcessingKey value:@(YES)];
        }
        MCMessageBody *messageBody = [mimePart messageBody];
        // Set the security features collected on topLevelMimePart on the message.
        [currentMessage setIvar:kMessageSecurityFeaturesKey value:[(MimePart_GPGMail *)mimePart securityFeatures]];
        [self GMSetupDataSourcesForParsedMessage:messageBody ofMessage:currentMessage];
        *body = messageBody;
    }
    
    return YES;
}

+ (NSData *)GMMessageDataForMessage:(MCMessage *)currentMessage isCompleteMessageAvailable:(BOOL *)isCompleteMessageAvailable {
    // Bug #952: Messages containing PGP data are not always processed properly
    //
    // Under certain circumstances -[MFLibrary _dataForMessageAtPath:] does not always
    // return the message data contained in the local .emlx file.
    // It appears that this is happening, if -[MFLibrary _updateMessageForFile:] is
    // updating the last access date of a message, while -[MFLibrary _dataForMessageAtPath:]
    // is trying to access the data within the same message.
    //
    // In order to work around that issue, a lock is introduced which makes sure, that
    // the read waits for the write to complete or vice versa.
    // As a last resort, a change to -[MFLibrary _dataForMessageAtPath:] has been added
    // which polls for the data to be available again and returning it once it is.
    __block NSData *messageData = nil;
    __block BOOL complete = YES;

    @try {
        [self exclusiveAccessToMessage:currentMessage withBlock:^{
            messageData = [MFLibrary fullMessageDataForMessage:currentMessage];
            if(!messageData) {
                complete = NO;
                messageData = [MFLibrary _messageDataAtPath:[MFLibrary _dataPathForMessage:currentMessage type:1]];
            }
        }];
    }
    @catch(NSException *exception) {}

    if(isCompleteMessageAvailable != NULL) {
        *isCompleteMessageAvailable = complete;
    }

    return messageData;
}

+ (void)GMSetupDataSourcesForParsedMessage:(id)parsedMessage ofMessage:(MCMessage *)message {
    // Setup the data source for attachments as Mail does.
    id <IMAPMessageDataSource> messageDataSource = [message dataSource];
    BOOL needRemoteDataSource = YES;
    if(![messageDataSource conformsToProtocol:@protocol(IMAPMessageDataSource)]) {
        needRemoteDataSource = [messageDataSource isKindOfClass:[MFEWSStore class]] ? YES : NO;
    }
    
    // Check if complete message eml is available. This is necessary in order to figure
    // out whether to skip the attachment data source setup or not.
    BOOL isCompleteMessageAvailable = NO;
    NSData *messageData = [self GMMessageDataForMessage:message isCompleteMessageAvailable:&isCompleteMessageAvailable];

    for(id key in [parsedMessage attachmentsByURL]) {
        MCAttachment *attachment = [[parsedMessage attachmentsByURL] objectForKey:key];
        // In some cases the data source for the attachment is already setup, for example
        // if a pgp encrypted attachment was decrypted.
        // In that case the data source *must no* be setup again.
        // Passing 0 to -[MCAttachment dataForAccessLevel:] guarantees that data is only returned,
        // if it's available locally.

        // Bug #974: Don't reset attachment data source if the message is locally available in full and
        //           the attachment is not remotely accessed
        // This is a bug in my re-implementation of the data source setup part. If the complete eml file for
        // a message is available (not only partial eml) and [attachment isRemotelyAccessed] returns NO
        // the setup for the data source of the attachment must be skipped.
        if([attachment dataForAccessLevel:0] || (![attachment isRemotelyAccessed] && isCompleteMessageAvailable)) {
            continue;
        }
        id <MCRemoteAttachmentDataSource> remoteDataSource = nil;
        MFLibraryAttachmentDataSource *dataSource = nil;
        NSString *partNumber = [attachment mimePartNumber];
        if([attachment isRemotelyAccessed]) {
            NSString *attachmentsDirectory = [MFLibrary attachmentsDirectoryForMessage:message partNumber:partNumber];
            remoteDataSource = [[MFRemoteURLAttachmentDataSource alloc] initWithAttachment:attachment attachmentsDirectory:attachmentsDirectory];
        }
        else {
            if(needRemoteDataSource) {
                remoteDataSource = [MFRemoteAttachmentDataSource remoteAttachmentDataSourceForMessage:message];
            }
        }
        dataSource = [[MFLibraryAttachmentDataSource alloc] initWithMessage:message mimePartNumber:partNumber attachment:attachment remoteDataSource:remoteDataSource];
        [attachment setDataSource:dataSource];
        if(![attachment isRemotelyAccessed]) {
            [attachment setDownloadProgress:[(MFRemoteAttachmentDataSource *)remoteDataSource downloadProgress]];
        }
    }
}

+ (void)MASetData:(id)data forMessage:(id)message isPartial:(BOOL)isPartial hasCompleteText:(BOOL)hasCompleteText {
    // Since 10.12.4 it seems possible to force Mail to fetch the entire message body again for multipart/signed messages,
    // by returning NO from -[MFLibraryMessage shouldSnipAttachmentData].
    // In -[MFLibraryMessage shouldSnipAttachmentData] the data is however not available, which is the reason
    // why it's necessary to instruct -[MFLibraryMessage shouldSnipAttachmentData] to return NO, if a multipart/signed message
    // was found by setting an ivar on the message itself.
    MCMimePart *mimePart = [[MCMimePart alloc] initWithEncodedData:data];
    [mimePart parse];
    // Check if the message contains a PGP/MIME signature.
    BOOL mightContainPGPData = [(MimePart_GPGMail *)mimePart mightContainPGPMIMESignedData];
    if(mightContainPGPData) {
        [message setIvar:kLibraryMessagePreventSnippingAttachmentDataKey value:@(YES)];
    }
    [self MASetData:data forMessage:message isPartial:isPartial hasCompleteText:hasCompleteText];
}

+ (NSMutableDictionary *)messageDataAccessMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        messageDataAccessMap = [[NSMutableDictionary alloc] init];
    });
    return messageDataAccessMap;
}

+ (void)exclusiveAccessToMessage:(MCMessage *)message withBlock:(void (^)(void))block {
    NSMutableDictionary *accessMap = [self messageDataAccessMap];

    NSException *exception = nil;
    NSRecursiveLock *messageLock = nil;
    @synchronized(accessMap) {
        messageLock = accessMap[message];
        if(!messageLock) {
            messageLock = [NSRecursiveLock new];
            accessMap[message] = messageLock;
        }
    }
    [messageLock lock];
    @try {
        if(block) {
            block();
        }
    }
    @catch(NSException *e) {
        exception = e;
    }
    @finally {
        [messageLock unlock];
    }

    @synchronized(accessMap) {
        NSRecursiveLock *currentLock = accessMap[message];
        if(currentLock == messageLock) {
            @try {
                [accessMap removeObjectForKey:message];
            }
            @catch(NSException *e) {}
        }
    }

    if(exception != nil) {
        @throw exception;
    }
}

+ (void)MAUpdateFileForMessage:(MCMessage *)message {
    // Bug #952: Messages containing PGP data are not always processed properly
    //
    // See -[Library_GPGMail GMMessageDataForMessage:isCompleteMessageAvailable:] for
    // a more detailed explanation.
    @try {
        [self exclusiveAccessToMessage:message withBlock:^{
            [self MAUpdateFileForMessage:message];
        }];
    }
    @catch(NSException *exception) {}
}

+ (NSData *)MA_messageDataAtPath:(NSString *)path {
    // Bug #952: Messages containing PGP data are not always processed properly
    //
    // While the locks added to +[MFLibrary updateFileForMessage:] and
    // +[Library_GPGMail GMMessageDataForMessage:isCompleteMessageAvailable:] should
    // make sure that Mail always returns the message data from a local emlx file,
    // an additional workaround should guarantee it.
    // If still no data is available, GPGMail will poll the size of the file via stat
    // and return its content once size is greater 0 again.
    BOOL waitForData = [[[[NSThread currentThread] threadDictionary] valueForKey:kMFLibraryStoreMessageWaitForData] boolValue] && [[NSFileManager  defaultManager] fileExistsAtPath:path];
    __block NSData *messageData = [self MA_messageDataAtPath:path];
    // Check stat, if size is already > 0 the meta data update performed in +[MFLibrary updateFileForMessage:]
    // should be completed and repeating the previous +[MFLibrary _messageDataAtPath:] should
    // return the message data.
    if(!messageData || [messageData length]) {
        struct stat fileInfo;
        int error = stat([path fileSystemRepresentation], &fileInfo);
        if(!error && fileInfo.st_size > 0) {
            messageData = [self MA_messageDataAtPath:path];
        }
        // If there's still no message data available and waitForData
        // is set, poll the size until it's greater zero and try one last time.
        if(!messageData && waitForData) {
            __block int maxRetries = 30;
            __block dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            dispatch_queue_t fileSizeCheckQueue = dispatch_queue_create("org.gpgtools.GPGMail.messageDataAvailableCheck", DISPATCH_QUEUE_SERIAL);
            dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, fileSizeCheckQueue);
            dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
            dispatch_source_set_event_handler(timer, ^{
                struct stat _fileInfo;
                int _error = stat([path fileSystemRepresentation], &_fileInfo);
                if(_error) {
                    return;
                }
                if(_fileInfo.st_size > 0) {
                    messageData = [self MA_messageDataAtPath:path];
                    dispatch_semaphore_signal(sem);
                }
                else {
                    maxRetries -= 1;
                }
                if(maxRetries <= 0) {
                    dispatch_semaphore_signal(sem);
                }
            });
            dispatch_resume(timer);
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            dispatch_cancel(timer);

//            dispatch_release(timer);
//            dispatch_release(fileSizeCheckQueue);
//            dispatch_release(sem);
        }
    }
    return messageData;
}

@end

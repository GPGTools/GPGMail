//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "MCActivityTarget-Protocol.h"
#import "NSSharingServiceDelegate-Protocol.h"
#import "NSSharingServicePickerDelegate-Protocol.h"
#import "QLPreviewPanelDataSource-Protocol.h"
#import "QLPreviewPanelDelegate-Protocol.h"
#import "QLSeamlessOpenerDelegate-Protocol.h"
#import "TerminationHandler-Protocol.h"

@class AttachmentViewController, MCInvocationQueue, NSMutableArray, NSMutableDictionary, NSString, NSTimer;

@interface AttachmentManager : NSObject <MCActivityTarget, NSSharingServiceDelegate, NSSharingServicePickerDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, QLSeamlessOpenerDelegate, TerminationHandler>
{
    NSMutableArray *_openedAttachmentPaths;	// 8 = 0x8
    NSMutableDictionary *_openedAttachmentMessageIDs;	// 16 = 0x10
    NSMutableArray *_messageIDPurgeQueue;	// 24 = 0x18
    long long _purgeBehavior;	// 32 = 0x20
    NSMutableDictionary *_quickLookAttachmentViewControllersByURL;	// 40 = 0x28
    BOOL _isDirty;	// 48 = 0x30
    AttachmentViewController *_controllerForImageToShare;	// 56 = 0x38
    NSTimer *_purgeTimer;	// 64 = 0x40
    MCInvocationQueue *_deletionHandlerQueue;	// 72 = 0x48
}

+ (BOOL)attachmentPurgingIsEnabled;	// IMP=0x0000000100043186
+ (id)_openedAttachmentListURL;	// IMP=0x00000001000b0281
+ (id)sharedInstance;	// IMP=0x00000001000431d9
+ (id)allocWithZone:(struct _NSZone *)arg1;	// IMP=0x00000001000b00c3
+ (void)initialize;	// IMP=0x0000000100043046
@property(readonly, nonatomic) MCInvocationQueue *deletionHandlerQueue; // @synthesize deletionHandlerQueue=_deletionHandlerQueue;
@property(retain, nonatomic) NSTimer *purgeTimer; // @synthesize purgeTimer=_purgeTimer;
@property(retain, nonatomic) AttachmentViewController *controllerForImageToShare; // @synthesize controllerForImageToShare=_controllerForImageToShare;
- (void).cxx_destruct;	// IMP=0x00000001000b9aa0
- (void)_noteFileSystemChanged:(id)arg1;	// IMP=0x00000001000b99ba
- (id)_fileForSavedFileWrapper:(id)arg1 directory:(id)arg2 makePathUnique:(BOOL)arg3;	// IMP=0x00000001000b96b1
- (BOOL)_immediatelyOpenAttachment:(id)arg1 withApplicationURL:(id)arg2 window:(id)arg3 attachmentDirectory:(id)arg4 reason:(unsigned long long)arg5;	// IMP=0x00000001000b942d
- (void)nowWouldBeAGoodTimeToTerminate:(id)arg1;	// IMP=0x0000000100093fd1
- (void)_handleMessageDeleted:(id)arg1;	// IMP=0x0000000100048019
- (void)_messageDeleted:(id)arg1;	// IMP=0x0000000100047f75
- (void)_schedulePurgeOfMessageIDs:(id)arg1;	// IMP=0x00000001000b939f
- (void)_scheduleMessageIDPurge;	// IMP=0x00000001000b9306
- (void)_purgeMessageIDs;	// IMP=0x00000001000b8c7a
- (void)_purgeAttachments:(id)arg1;	// IMP=0x000000010004a5a3
- (void)_reallyPurgeAttachments;	// IMP=0x000000010004a5ef
- (void)_finishTerminatingAttachmentPurge;	// IMP=0x0000000100093fe3
- (void)_synchronouslyPurgeAttachments;	// IMP=0x000000010004a799
- (BOOL)_allMessagesWithMessageIDAreDeletedOrTrashed:(id)arg1;	// IMP=0x000000010004ae76
- (void)_saveOpenedAttachmentsList;	// IMP=0x000000010005f020
- (void)_scheduleAttachmentListSave;	// IMP=0x000000010004b132
- (void)_setDirty:(BOOL)arg1;	// IMP=0x000000010004b095
- (void)_addPurgeEntryForAttachmentAtPath:(id)arg1 modDate:(id)arg2 messageIDHeader:(id)arg3 partNumber:(id)arg4;	// IMP=0x00000001000b8943
- (void)_addOrReplaceEntry:(id)arg1 inAttachmentList:(id)arg2;	// IMP=0x00000001000b87cd
- (void)_setupOpenedAttachmentsMessageIDMap;	// IMP=0x0000000100043603
- (id)seamlessOpener:(id)arg1 transitionImageForPreviewItem:(id)arg2 contentRect:(struct CGRect *)arg3;	// IMP=0x00000001000b87b9
- (struct CGRect)seamlessOpener:(id)arg1 sourceFrameOnScreenForPreviewItem:(id)arg2;	// IMP=0x00000001000b8798
- (BOOL)_immediatelyOpenAttachment:(id)arg1 path:(id)arg2 window:(id)arg3 application:(id)arg4 reason:(unsigned long long)arg5 exists:(BOOL)arg6;	// IMP=0x00000001000b823d
- (BOOL)_sameAttachmentAsBefore:(id)arg1 proposedPath:(id)arg2 withProposedAttachmentWrapper:(id)arg3;	// IMP=0x00000001000b7da0
- (BOOL)_saveAttachmentsFromMessages:(id)arg1 toDirectory:(id)arg2 error:(id *)arg3;	// IMP=0x00000001000b77b0
- (void)_saveAttachmentsFromMessages:(id)arg1 toDirectory:(id)arg2;	// IMP=0x00000001000b7658
- (BOOL)_saveAttachments:(id)arg1 toDirectory:(id)arg2 makePathsUnique:(BOOL)arg3 error:(id *)arg4;	// IMP=0x00000001000b6f2c
- (void)_saveAttachments:(id)arg1 toDirectory:(id)arg2 makePathsUnique:(BOOL)arg3;	// IMP=0x00000001000b6dcf
- (void)_saveAttachment:(id)arg1 toPath:(id)arg2 window:(id)arg3;	// IMP=0x00000001000b6991
- (void)_immediatelySaveFileWrapper:(id)arg1 path:(id)arg2 window:(id)arg3;	// IMP=0x00000001000b6556
- (int)_openFullPath:(id)arg1 withAppURL:(struct __CFURL *)arg2 options:(unsigned int)arg3;	// IMP=0x00000001000b64ae
- (id)previewPanel:(id)arg1 previewItemAtIndex:(long long)arg2;	// IMP=0x00000001000b6442
- (long long)numberOfPreviewItemsInPreviewPanel:(id)arg1;	// IMP=0x00000001000b641a
- (id)sharingService:(id)arg1 sourceWindowForShareItems:(id)arg2 sharingContentScope:(long long *)arg3;	// IMP=0x00000001000b6316
- (id)sharingService:(id)arg1 transitionImageForShareItem:(id)arg2 contentRect:(struct CGRect *)arg3;	// IMP=0x00000001000b62ac
- (struct CGRect)sharingService:(id)arg1 sourceFrameOnScreenForShareItem:(id)arg2;	// IMP=0x00000001000b615f
- (id)sharingServicePicker:(id)arg1 delegateForSharingService:(id)arg2;	// IMP=0x00000001000b6156
- (void)sharingService:(id)arg1 didShareItems:(id)arg2;	// IMP=0x00000001000b6142
- (id)sharingServicePicker:(id)arg1 sharingServicesForItems:(id)arg2 proposedSharingServices:(id)arg3;	// IMP=0x00000001000b5f3c
- (void)writeImageAttachmentToPasteboard:(id)arg1;	// IMP=0x00000001000b5cf3
- (void)saveAttachments:(id)arg1 toDirectory:(id)arg2 makePathsUnique:(BOOL)arg3 window:(id)arg4;	// IMP=0x00000001000b5a10
- (id)contextualMenuForAttachments:(id)arg1 clickedAttachment:(id)arg2 forEditing:(BOOL)arg3;	// IMP=0x00000001000b4f76
- (void)_configureOpenWithMenu:(id)arg1 forAttachments:(id)arg2;	// IMP=0x00000001000b4aba
- (BOOL)openFileAtPath:(id)arg1 withApplication:(id)arg2 stayInBackground:(BOOL)arg3;	// IMP=0x00000001000b49f9
- (void)chooseApplicationToOpenAttachments:(id)arg1 window:(id)arg2;	// IMP=0x00000001000b4554
- (BOOL)openInvitationAttachments:(id)arg1 openImmediately:(BOOL)arg2;	// IMP=0x00000001000b44d5
- (BOOL)openTemporaryAttachments:(id)arg1 applicationBundle:(id)arg2 window:(id)arg3;	// IMP=0x00000001000b43e6
- (void)saveAttachmentsToDownloadDirectory:(id)arg1 window:(id)arg2;	// IMP=0x00000001000b40d4
- (void)_runSavePanelForAttachments:(id)arg1 messages:(id)arg2 window:(id)arg3;	// IMP=0x00000001000b3857
- (void)runSavePanelForAttachments:(id)arg1 window:(id)arg2;	// IMP=0x00000001000b3810
- (void)saveAttachmentsFromMessages:(id)arg1 window:(id)arg2;	// IMP=0x00000001000b37c9
- (void)_openAttachmentsWithDictionary:(id)arg1;	// IMP=0x00000001000b36cf
- (void)openAttachments:(id)arg1 applicationURL:(id)arg2 window:(id)arg3 delegate:(id)arg4;	// IMP=0x00000001000b3454
- (void)downloadAttachments:(id)arg1 window:(id)arg2;	// IMP=0x00000001000b3214
- (void)quickLookAttachmentsFromMessages:(id)arg1 window:(id)arg2;	// IMP=0x00000001000b2cbb
- (void)quickLookAttachments:(id)arg1 window:(id)arg2;	// IMP=0x00000001000b26ce
- (void)windowWillClose:(id)arg1;	// IMP=0x00000001000b25f4
- (BOOL)previewPanel:(id)arg1 shouldOpenURL:(id)arg2 forPreviewItem:(id)arg3;	// IMP=0x00000001000b24fa
- (id)previewPanel:(id)arg1 transitionImageForPreviewItem:(id)arg2 contentRect:(struct CGRect *)arg3;	// IMP=0x00000001000b2431
- (struct CGRect)previewPanel:(id)arg1 sourceFrameOnScreenForPreviewItem:(id)arg2;	// IMP=0x00000001000b2113
- (void)_addAttachmentToQuickLookPanel:(id)arg1 attachmentDirectory:(id)arg2 window:(id)arg3;	// IMP=0x00000001000b2025
- (BOOL)addAttachmentForQuickLook:(id)arg1 attachmentDirectory:(id)arg2;	// IMP=0x00000001000b1bb6
- (void)_tellControllerAttachmentIsDownloaded:(id)arg1;	// IMP=0x00000001000b1a52
- (void)_downloadCompleted:(id)arg1;	// IMP=0x00000001000b1555
- (void)_openFromDownloadedNotification:(id)arg1;	// IMP=0x00000001000b13e8
- (id)urlsForDraggedAttachments:(id)arg1 fromView:(id)arg2;	// IMP=0x00000001000b0e7d
- (BOOL)dragAttachments:(id)arg1 startPoint:(struct CGPoint)arg2 view:(id)arg3 event:(id)arg4 image:(id)arg5;	// IMP=0x00000001000b0848
@property(nonatomic) long long attachmentPurgingBehavior;
- (void)disableAttachmentPurging;	// IMP=0x00000001000b04a2
- (void)enableAttachmentPurging;	// IMP=0x00000001000b033a
- (void)initializeAttachmentPurging;	// IMP=0x00000001000438fc
- (void)dealloc;	// IMP=0x00000001000b017c
- (id)init;	// IMP=0x0000000100043292

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly, copy, nonatomic) NSString *displayName;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


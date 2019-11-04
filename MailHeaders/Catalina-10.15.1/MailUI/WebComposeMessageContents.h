//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class ECHTMLStringAndMIMECharset, NSAttributedString, NSDictionary, NSMutableArray, NSURL;

@interface WebComposeMessageContents : NSObject
{
    BOOL _isMailDropPlaceholderMessage;	// 8 = 0x8
    BOOL _isSignificant;	// 9 = 0x9
    NSAttributedString *_plainText;	// 16 = 0x10
    ECHTMLStringAndMIMECharset *_topLevelHtmlString;	// 24 = 0x18
    NSMutableArray *_attachmentsAndHtmlStrings;	// 32 = 0x20
    NSMutableArray *_urlsForAttachmentsAndHtmlStrings;	// 40 = 0x28
    NSDictionary *_remoteAttachments;	// 48 = 0x30
    NSURL *_imageArchiveURL;	// 56 = 0x38
}

@property(nonatomic) BOOL isSignificant; // @synthesize isSignificant=_isSignificant;
@property(nonatomic) BOOL isMailDropPlaceholderMessage; // @synthesize isMailDropPlaceholderMessage=_isMailDropPlaceholderMessage;
@property(retain, nonatomic) NSURL *imageArchiveURL; // @synthesize imageArchiveURL=_imageArchiveURL;
@property(copy, nonatomic) NSDictionary *remoteAttachments; // @synthesize remoteAttachments=_remoteAttachments;
@property(retain, nonatomic) NSMutableArray *urlsForAttachmentsAndHtmlStrings; // @synthesize urlsForAttachmentsAndHtmlStrings=_urlsForAttachmentsAndHtmlStrings;
@property(retain, nonatomic) NSMutableArray *attachmentsAndHtmlStrings; // @synthesize attachmentsAndHtmlStrings=_attachmentsAndHtmlStrings;
@property(retain, nonatomic) ECHTMLStringAndMIMECharset *topLevelHtmlString; // @synthesize topLevelHtmlString=_topLevelHtmlString;
@property(retain, nonatomic) NSAttributedString *plainText; // @synthesize plainText=_plainText;
- (void).cxx_destruct;	// IMP=0x00000001000df213
- (id)debugDescription;	// IMP=0x00000001000df0a0
- (void)addAttachmentOrHtmlString:(id)arg1 withURL:(id)arg2;	// IMP=0x00000001000def39

@end


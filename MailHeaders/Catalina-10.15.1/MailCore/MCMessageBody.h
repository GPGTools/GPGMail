//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import <MailCore/NSXMLParserDelegate-Protocol.h>
#import <MailCore/WebResourceLoadDelegate-Protocol.h>

@class NSArray, NSAttributedString, NSDictionary, NSError, NSMutableDictionary, NSString, NSURL;

@interface MCMessageBody : NSObject <WebResourceLoadDelegate, NSXMLParserDelegate>
{
    NSMutableDictionary *_attachmentsByURL;	// 8 = 0x8
    BOOL _isPlainText;	// 16 = 0x10
    BOOL _isEncrypted;	// 17 = 0x11
    BOOL _hasEncryptedDescendantPart;	// 18 = 0x12
    NSString *_html;	// 24 = 0x18
    unsigned long long _originalEncoding;	// 32 = 0x20
    NSString *_mimeType;	// 40 = 0x28
    NSURL *_baseURL;	// 48 = 0x30
    NSArray *_signers;	// 56 = 0x38
    NSError *_smimeError;	// 64 = 0x40
}

+ (void)setRichTextWebPreferences:(id)arg1;	// IMP=0x000000000005d141
+ (void)setPlainTextWebPreferences:(id)arg1;	// IMP=0x000000000005d0ff
@property(retain, nonatomic) NSError *smimeError; // @synthesize smimeError=_smimeError;
@property(nonatomic) BOOL hasEncryptedDescendantPart; // @synthesize hasEncryptedDescendantPart=_hasEncryptedDescendantPart;
@property(nonatomic) BOOL isEncrypted; // @synthesize isEncrypted=_isEncrypted;
@property(copy, nonatomic) NSArray *signers; // @synthesize signers=_signers;
@property(nonatomic) BOOL isPlainText; // @synthesize isPlainText=_isPlainText;
@property(retain, nonatomic) NSURL *baseURL; // @synthesize baseURL=_baseURL;
@property(copy, nonatomic) NSString *mimeType; // @synthesize mimeType=_mimeType;
@property(nonatomic) unsigned long long originalEncoding; // @synthesize originalEncoding=_originalEncoding;
@property(copy, nonatomic) NSString *html; // @synthesize html=_html;
- (void).cxx_destruct;	// IMP=0x0000000000012a74
- (id)webView:(id)arg1 resource:(id)arg2 willSendRequest:(id)arg3 redirectResponse:(id)arg4 fromDataSource:(id)arg5;	// IMP=0x000000000005e3d0
@property(readonly, copy, nonatomic) NSArray *signerLabels;
- (void)setBaseURLFromHtml;	// IMP=0x000000000005dda2
- (void)_addWebArchiveDataToArray:(id)arg1;	// IMP=0x000000000005d943
- (id)attributedStringBlockingRemoteContent:(BOOL)arg1 attachmentAccessLevel:(long long)arg2;	// IMP=0x000000000005d60d
@property(readonly, copy, nonatomic) NSAttributedString *attributedString;
@property(readonly, copy) NSString *description;
@property(readonly, copy) NSString *debugDescription;
- (void)addAttachment:(id)arg1 forURL:(id)arg2;	// IMP=0x000000000005d26e
@property(copy) NSDictionary *attachmentsByURL;
- (void)_mcMessageBodyCommonInit;	// IMP=0x000000000005d09f
- (id)init;	// IMP=0x0000000000008f5e
- (id)initWithWebArchive:(id)arg1 archiveIsMailInternal:(BOOL)arg2;	// IMP=0x000000000005ca75
- (id)initWithWebArchive:(id)arg1;	// IMP=0x000000000005c78a

// Remaining properties
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


/* GMCodeInjector.m created by Lukas Pitschl (@lukele) on Fri 14-Jun-2013 */

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
#import "GPGMail_Prefix.pch"
#import "JRLPSwizzle.h"
#import "GPGMailBundle.h"
#import "GMCodeInjector.h"

@implementation GMCodeInjector

+ (NSDictionary *)commonHooks {
	return @{
			 @"MessageHeaderDisplay": @[
					 @"_attributedStringForSecurityHeader",
					 @"textView:clickedOnLink:atIndex:"
			 ],
			 @"ComposeBackEnd": @[
					 @"_makeMessageWithContents:isDraft:shouldSign:shouldEncrypt:shouldSkipSignature:shouldBePlainText:",
//					 @"canEncryptForRecipients:sender:",
//					 @"canSignFromAddress:",
					 @"recipientsThatHaveNoKeyForEncryption",
//					 @"setEncryptIfPossible:",
//					 @"setSignIfPossible:",
//					 @"_saveThreadShouldCancel",
					 @"_configureLastDraftInformationFromHeaders:overwrite:",
//					 @"sender",
//					 @"outgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:",
//					 @"initCreatingDocumentEditor:"
			 ],
			 @"HeadersEditor": @[
//					 @"securityControlChanged:",
//					 @"_updateFromAndSignatureControls:",
					 @"changeFromHeader:",
//					 @"dealloc",
					 @"awakeFromNib",
//					 @"_updateSignButtonTooltip",
//					 @"_updateEncryptButtonTooltip",
					 @"updateSecurityControls",
//					 @"_updateSecurityStateInBackgroundForRecipients:sender:"
			 ],
             @"MailDocumentEditor": @[
					 @"backEndDidLoadInitialContent:",
					 @"dealloc",
					 @"backEnd:didCancelMessageDeliveryForEncryptionError:",
					 @"backEnd:didCancelMessageDeliveryForError:",
                     @"initWithBackEnd:",
					 @"sendMessageAfterChecking:"
             ],
//			 @"NSWindow": @[
//					 @"toggleFullScreen:"
//			 ],
			 @"MessageContentController": @[
					 @"setMessageToDisplay:"
			 ],
//			 @"BannerController": @[
//					 @"updateBannerForViewingState:"
//			 ],
			 @"Message": @[],
			 @"MimePart": @[
					 @"isEncrypted",
					 @"newEncryptedPartWithData:recipients:encryptedData:",
					 @"newSignedPartWithData:sender:signatureData:",
					 @"verifySignature",
					 @"decodeWithContext:",
					 @"decodeTextPlainWithContext:",
					 @"decodeTextHtmlWithContext:",
					 @"decodeApplicationOctet_streamWithContext:",
					 @"isSigned",
					 @"isMimeSigned",
					 @"isMimeEncrypted",
					 @"usesKnownSignatureProtocol",
					 @"clearCachedDecryptedMessageBody"
			 ],
			 @"MimeBody": @[
					 @"isSignedByMe",
					 @"_isPossiblySignedOrEncrypted"
			 ],
			 @"MessageCriterion": @[
					 @"_evaluateIsDigitallySignedCriterion:",
					 @"_evaluateIsEncryptedCriterion:"
			 ],
			 @"Library": @[
					 @"plistDataForMessage:subject:sender:to:dateSent:remoteID:originalMailbox:flags:mergeWithDictionary:",
			 ],
			 @"MailAccount": @[
					 @"accountExistsForSigning",
                     @"completeDeferredAccountInitialization"
			 ],
			 @"OptionalView": @[
					 @"widthIncludingOptionSwitch:"
			 ],
			 @"NSPreferences": @[
					 @"sharedPreferences",
					 @"windowWillResize:toSize:",
					 @"toolbarItemClicked:",
					 @"showPreferencesPanelForOwner:"
			 ]
	};
}

+ (NSDictionary *)hookChangesForMavericks {
	return @{
			 @"Library": @{
					 @"status": @"renamed",
					 @"name": @"MFLibrary",
					 @"selectors": @{
							 @"replaced": @[
									 @[
										 @"plistDataForMessage:subject:sender:to:dateSent:remoteID:originalMailbox:flags:mergeWithDictionary:",
										 @"plistDataForMessage:subject:sender:to:dateSent:dateReceived:dateLastViewed:remoteID:originalMailboxURLString:gmailLabels:flags:mergeWithDictionary:"
								     ]
							 ]
					 },
			 },
//             @"HeadersEditor": @{
//                     @"selectors": @{
//                             @"renamed": @[
//                                @[
//                                    @"_updateSignButtonTooltip",
//                                    @"_updateSignButtonToolTip"
//                                 ],
//                                @[
//                                    @"_updateEncryptButtonTooltip",
//                                    @"_updateEncryptButtonToolTip"
//                                 ]
//                             ]
//                     }
//             },
			 @"EAEmailAddressParser": @{
					 @"selectors": @[
							 @"rawAddressFromFullAddress:"
					 ]
			 },
			 @"MimePart": @{
					 @"status": @"renamed",
					 @"name": @"MCMimePart"
			 },
			 @"MimeBody": @{
					 @"status": @"renamed",
					 @"name": @"MCMimeBody"
			 },
			 @"Message": @{
					 @"status": @"renamed",
					 @"name": @"MCMessage",
					 @"selectors": @{
							 @"added": @[
									 @"setMessageInfo:subjectPrefixLength:to:sender:type:dateReceivedTimeIntervalSince1970:dateSentTimeIntervalSince1970:messageIDHeaderDigest:inReplyToHeaderDigest:dateLastViewedTimeIntervalSince1970:"
							 ]
					 }
			 },
			 @"ComposeBackEnd": @{
					 @"selectors": @{
							 @"renamed": @[
									 @[
										 @"outgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:",
										 @"newOutgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:"
									 ]
							 ]
					 }
			 },
			 @"MessageCriterion": @{
					 @"status": @"renamed",
					 @"name": @"MFMessageCriterion"
			 },
			 @"MailAccount": @{
					 @"status": @"renamed",
					 @"name": @"MFMailAccount"
			 },
             @"MailDocumentEditor": @{
                     @"status": @"renamed",
                     @"name": @"DocumentEditor"
             },
             @"MessageRouter": @{
                     @"status": @"renamed",
                     @"name": @"MFMessageRouter"
            },
             @"MessageContentController": @{
                     @"status": @"renamed",
                     @"name": @"MessageViewController",
                     @"selectors": @{
                        @"replaced": @[
                           @[
                               @"setMessageToDisplay:",
                               @"setRepresentedObject:"
                            ]
                        ]
                     }
             },
             @"MessageHeaderDisplay": @{
                     @"status": @"renamed",
                     @"name": @"HeaderViewController",
                     @"selectors": @{
                             @"added": @[
                                     @"_displayStringForSecurityKey",
                                     @"textView:clickedOnCell:inRect:atIndex:",
                                     @"_updateTextStorageWithHardInvalidation:",
                                     @"toggleDetails:"
                             ],
                             @"removed": @[
                                     @"_attributedStringForSecurityHeader",
                                     @"textView:clickedOnLink:atIndex:"
                             ]
                                             
                     }
             },
//             @"BannerController": @{
//                     @"status": @"removed"
//             },
//             @"ConversationMember": @{
//                     @"selectors": @[
//                             @"_reloadSecurityProperties"
//                     ]
//             },
			 @"WebDocumentGenerator": @{
					 @"selectors": @[
							 @"setWebDocument:"
					]
			},
			 @"MCMessageGenerator": @{
					 @"selectors": @[
							 @"_newDataForMimePart:withPartData:",
                             @"_newOutgoingMessageFromTopLevelMimePart:topLevelHeaders:withPartData:",
                             @"setSigningIdentity:",
                             @"_appendHeadersForMimePart:toHeaders:"
					 ]
			}
	};
}

+ (NSDictionary *)hookChangesForYosemite {
    return @{
             @"HeadersEditor": @{
                     @"selectors": @{
//                             @"renamed": @[
//                                     @[@"updateSecurityControls",
//                                       @"_updateSecurityControls"
//                                     ]
//                                    
//                             ],
//                             @"removed": @[
//                                     @"_updateSignButtonToolTip",
//                                     @"_updateEncryptButtonToolTip",
//                                     @"toggleDetails",
//                                     @"_updateFromAndSignatureControls:"
//                            ],
                            @"added": @[
                                     @"_updateFromControl",
//                                     @"setMessageIsToBeEncrypted:",
//                                     @"setMessageIsToBeSigned:",
//                                     @"setCanSign:",
//                                     @"setCanEncrypt:"
                            ]
                     }
             },
//             @"ComposeBackEnd": @{
//                     @"selectors": @{
//                            @"added": @[
//                                    @"setKnowsCanSign:"
//                            ]
//                     }
//             },
//             @"HeaderViewController": @{
//                     @"selectors": @{
//                            @"removed": @[
//                                @"_displayStringForSecurityKey",
//                                @"toggleDetails:" // TODO: Implement again?
//                            ]
//                     }
//             },
//             @"ConversationMember": @{
//                     @"selectors": @{
//                            @"removed": @[
//                                @"_reloadSecurityProperties"
//                            ]
//                     }
//             }
    };
}

+ (NSDictionary *)hookChangesForElCapitan {
	return @{
			 // Insert the security method switcher into the toolbar as a toolbar item.
			 @"MailToolbar": @{
					 @"selectors": @[
							 @"_plistForToolbarWithIdentifier:"
							 ]
					 },
			 @"ComposeWindowController": @{
                     @"selectors": @[
                             @"toolbarDefaultItemIdentifiers:",
                             @"toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:",
                             @"_performSendAnimation",
                             @"_tabBarView:performSendAnimationOfTabBarViewItem:"
                                 ]
					 },
			 @"ComposeBackEnd": @{
					 @"selectors": @{
							 @"added": @[
									 @"init"
									 ],
							 @"removed": @[
									 @"initCreatingDocumentEditor:",
									 ]
							 }
					 },
			 @"DocumentEditor": @{
					 @"status": @"renamed",
					 @"name": @"ComposeViewController",
					 @"selectors": @{
							 @"removed": @[
									 @"initWithBackEnd:"
									 ],
							 @"added": @[
								 @"setDelegate:",
								 @"backEndDidAppendMessageToOutbox:result:"
								 ]
							 }
					 }
			 };
}

+ (NSDictionary *)hookChangesForSierra {
    return @{
             @"MCMimeBody": @{
                     @"selectors": @{
                             @"added": @[
                                     @"message",
                                     @"parsedMessage"
                                     ]
                             }
                     },
             @"MCMimePart": @{
                     @"selectors": @{
                             @"added": @[
                                     @"mimeBody",
                                     @"decode",
                                     @"isAttachment",
                                     @"newEncryptedPartWithData:certificates:encryptedData:"
                                     ]
                             }
                     },
             @"MCMessage": @{
                     @"selectors": @{
                             @"added": @[
                                     @"parsedMessage"
                                     ]
                             }
                     },
             @"MFMessageStore": @{
                     @"selectors": @[
                             @"bodyDataForMessage:fetchIfNotAvailable:allowPartial:"
                                     ]
                     },
             
             
             
             @"MFLibrary": @{
                     @"selectors": @{
                             @"added": @[
                                     @"mimeBodyForMessage:",
                                     @"setData:forMessage:isPartial:hasCompleteText:",
                                     @"parsedMessageForMessage:",
//                                     @"isMessageContentLocallyAvailable:",
                                     ]}
                     },
             @"MCKeychainManager": @{
                     @"selectors": @[
                             @"copySigningIdentityForAddress:"
                             ]
                     },
             @"HeadersEditor": @{
                     @"selectors": @{
                            @"added": @[
                                    @"_toggleEncryption",
                                    @"securityControlChanged:",
                                    @"_changeHeaderField:"
                            ],
                             @"renamed": @[
                                     @[@"updateSecurityControls",
                                       @"_updateSecurityControls"
                                       ]
                                     
                                     ],
                             }
                     },

             @"ComposeBackEnd": @{
                     @"selectors": @{
                             @"added": @[
                                     @"updateSMIMEStatus:",
                                     @"_generateParsedMessageFromOriginalMessages",
                                     @"setIsUndeliverable:"
                                     ]
                             }
                     },
             @"IMAPMessageDownload": @{
                     @"selectors": @[
                             @"setAllowsPartialDownloads:",
                             @"collectDataAndWriteToDisk:"
                             ]
                     },
             @"CertificateBannerViewController": @{
                     @"selectors": @[
                             @"updateWantsDisplay"
                             ]
                     },
             @"MCDataAttachmentDataSource": @{
                     @"selectors": @[
                             @"initWithData:",
                             @"data"
                             ]
                     },
             @"MCAttachment": @{
                     @"selectors": @[
                             @"iconImage"
                             ]
                     },
             @"MailWebAttachment": @{
                     @"selectors": @[
                             @"iconImage",
                             @"filename"
                            ]
                     },
             @"MFLibraryAttachmentDataSource": @{
                     @"selectors": @[
                             @"initWithMessage:mimePartNumber:attachment:remoteDataSource:"
                             ]
                     },
             @"MCMutableMessageHeaders": @{
                     @"selectors": @[
                             @"encodedHeadersIncludingFromSpace:"
                             ]
                     },
             @"ComposeWindowController": @{
                     @"selectors": @{
                             @"replaced": @[
                                     @[@"_performSendAnimation",
                                       @"_performSendAnimationWithCompletion:",
                                      ]],
                             @"added": @[
                                     @"composeViewControllerDidSend:"
                                     ]
                             }
                     },
             @"FullScreenWindowController": @{
                     @"selectors": @[
                             @"_closeModalWindow:"]
                     },
             @"RedundantContentIdentificationManager": @{
                     @"selectors": @[
                             @"redundantContentMarkupForMessage:inConversation:"]
                     },
             @"MFLibraryMessage": @{
                     @"selectors": @[
                             @"shouldSnipAttachmentData"]
                     },
             @"ComposeViewController": @{
                     @"selectors": @{
                             @"added": @[
                                     @"saveDocument:",
                                     @"setIsBeingPreparedForSending:",
                                     @"setHasUserMadeChanges:",
                                     @"setRepresentedObject:"
                                     ]
                             }
                     }
             };
}

+ (NSDictionary *)hookChangesForHighSierra {
    return @{
             @"MFLibrary": @{
                     @"selectors": @{
                             @"added": @[
                                     @"getTopLevelMimePart:headers:body:forMessage:",
                                     @"updateFileForMessage:",
                                     @"_messageDataAtPath:"
                                     ]
                             }
                     },
             @"MCMessage": @{
                     @"selectors": @{
                             @"added": @[
                                     @"bodyFetchIfNotAvailable:updateFlags:allowPartial:"
                                     ]
                             }
                     },
             @"MFLibraryStore": @{
                     @"selectors": @[
                             @"getTopLevelMimePart:headers:body:forMessage:fetchIfNotAvailable:updateFlags:allowPartial:",
                             @"initWithCriterion:mailbox:readOnly:"]
             },
             @"MCMimePart": @{
                     @"selectors": @{
                             @"added": @[
                                     @"_decode",
                                     @"messageBody",
                                     @"htmlStringForMimePart:attachment:",
                                     @"decodeApplicationPkcs7",
                                     @"_decodeTextHtml"]
                             }
                     },
//             @"MailApp": @{
//                     @"selectors": @[
//                             @"setPreferencesController:"]
//                     },
//             @"MailTabViewController": @{
//                     @"selectors": @[
//                             @"toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:",
//                             @"toolbarAllowedItemIdentifiers:",
//                             @"toolbarSelectableItemIdentifiers:",
//                             @"toolbarDefaultItemIdentifiers:"
//                             ]
//                     }
             @"HeaderViewController": @{
                     @"selectors": @{
                             @"added": @[@"securityHeaderString"]
                             }
                     },
             @"MCMemoryDataSource": @{
                     @"selectors": @[@"getTopLevelMimePart:headers:body:forMessage:fetchIfNotAvailable:updateFlags:allowPartial:"]
                     },
             @"ComposeBackEnd": @{
                     @"selectors": @{
                             @"renamed": @[
                                     @[
                                         @"_generateParsedMessageFromOriginalMessages",
                                         @"_generateMessageBodiesFromOriginalMessages"]
                                     ]
                             }
                     },
             @"MailPreferences": @{
                     @"selectors": @[
                             @"makePreferenceTabViewItems"
                             ]
                     },
             @"MCMessageBody": @{
                     @"selectors": @[
                             @"isEncrypted",
                             @"setIsEncrypted:"]
                     },
             @"ConversationMember": @{
                    @"selectors": @[
                            @"setWebDocument:",
                            @"hasBlockedRemoteContent",
                            @"remoteContentBlockingReason"
                      ]
                     },
             @"MUIWebDocument": @{
                     @"selectors":
                     @[
                     @"setBlockRemoteContent:",
                     @"setHasBlockedRemoteContent:",
                     @"hasBlockedRemoteContent",
                     @"setIsEncrypted:"
                     ]
                     },
             @"MUIWKWebViewController": @{
                     @"selectors": @[
                             @"setMessageHasBlockedRemoteContent",
                             @"reloadDocument",
                             @"webView:decidePolicyForNavigationAction:decisionHandler:",
                             @"logInjectedWebBundleMessage:",
                             @"logWebConsoleMessage:"
                             ]
                     },
             @"MUIWKWebViewConfigurationManager": @{
                     @"selectors": @[
                             @"init"]
                     },
             @"LoadRemoteContentBannerViewController": @{
                     @"selectors": @[
                             @"wantsDisplay",
                             @"setWantsDisplay:",
                             @"updateBannerContents",
                             @"_hasBlockedRemoteContentDidChange:",
                             @"hasBlockedRemoteContent"]
                     },
             @"JunkMailBannerViewController": @{
                     @"selectors": @[
                             @"updateBannerContents"
                             ]
                     },
             @"CertificateBannerViewController": @{
                     @"selectors": @{
                             @"added": @[
                                     @"updateBannerContents"
                                     ]
                             }
                     },
             @"MessageViewer": @{
                     @"selectors": @[
                         @"_mailApplicationDidFinishLaunching:"
                             ]
                     },
             @"MCMessageHeaders": @{
                     @"selectors": @[
                             @"headersForKey:"]
                     },
             @"MailApp": @{
                     @"selectors": @[
                             @"tabView:didSelectTabViewItem:",
                             @"handleMailToURL:"
                             ]
                     }
     };
}

+ (NSDictionary *)hookChangesForMojave {
    return @{
             @"ConversationMember": @{
                     @"selectors": @{
                             @"added": @[
                                     @"messageContentBlockingReason",
                                     @"hasBlockedMessageContent"
                                     ]
                             }
                     },
             @"PlugInsViewController": @{
                     @"selectors": @[
                             @"viewWillAppear"]
                     }
             };
}

+ (NSDictionary *)hookChangesForCatalina {
    return @{
             @"ComposeBackEnd": @{
                     @"selectors": @{
                             @"replaced": @[
                                     @[@"_makeMessageWithContents:isDraft:shouldSign:shouldEncrypt:shouldSkipSignature:shouldBePlainText:",
                                       @"_makeMessageWithContents:isDraft:shouldSign:shouldEncrypt:shouldSkipSignature:"],
                                     @[@"newOutgoingMessageUsingWriter:contents:headers:isDraft:shouldBePlainText:",
                                       @"_newOutgoingMessageUsingWriter:contents:headers:isDraft:"]
                                     ]
                             }
                     },
             @"MFLibraryStore": @{
                     @"selectors": @{
                             @"replaced": @[
                                 @[@"getTopLevelMimePart:headers:body:forMessage:fetchIfNotAvailable:updateFlags:allowPartial:",
                                   @"getTopLevelMimePart:headers:body:forMessage:fetchIfNotAvailable:updateFlags:allowPartial:skipSignatureVerification:"]
                                 ]
                             }
                     },
             @"MCMemoryDataSource": @{
                     @"selectors": @{
                             @"replaced": @[
                                     @[@"getTopLevelMimePart:headers:body:forMessage:fetchIfNotAvailable:updateFlags:allowPartial:",
                                       @"getTopLevelMimePart:headers:body:forMessage:fetchIfNotAvailable:updateFlags:allowPartial:skipSignatureVerification:"]
                                     ]
                             }
                     },
             @"ComposeViewController": @{
                     @"selectors": @{
                             @"replaced": @[
                                     @[@"backEndDidLoadInitialContent:",
                                       @"backEndDidLoadInitialContent:mayUseDarkAppearance:"
                                         ]
                                     ]
                             }
                     }
             };
}

+ (NSDictionary *)hooks {
	static dispatch_once_t onceToken;
	static NSDictionary *_hooks;
    
    dispatch_once(&onceToken, ^{
		NSMutableDictionary *hooks = [[NSMutableDictionary alloc] init];
		NSDictionary *commonHooks = [self commonHooks];
		
		// Make a mutable version of all the dictionary.
		for(NSString *class in commonHooks)
			hooks[class] = [NSMutableArray arrayWithArray:commonHooks[class]];
		
		/* Fix, once we can compile with stable Xcode including 10.9 SDK. */
		if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8)
			[self applyHookChangesForVersion:@"10.9" toHooks:hooks];
		if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
            [self applyHookChangesForVersion:@"10.10" toHooks:hooks];
		if([GPGMailBundle isElCapitan])
			[self applyHookChangesForVersion:@"10.11" toHooks:hooks];
        if([GPGMailBundle isSierra]) {
            [self applyHookChangesForVersion:@"10.12" toHooks:hooks];
        }
        if([GPGMailBundle isHighSierra]) {
            [self applyHookChangesForVersion:@"10.13" toHooks:hooks];
        }
        if([GPGMailBundle isMojave]) {
            [self applyHookChangesForVersion:@"10.14" toHooks:hooks];
        }
        if([GPGMailBundle isCatalina]) {
            [self applyHookChangesForVersion:@"10.15" toHooks:hooks];
        }
        
		_hooks = [NSDictionary dictionaryWithDictionary:hooks];
	});
	
	return _hooks;
}

+ (void)applyHookChangesForVersion:(NSString *)osxVersion toHooks:(NSMutableDictionary *)hooks {
	NSDictionary *hookChanges;
	if([osxVersion isEqualToString:@"10.9"])
		hookChanges = [self hookChangesForMavericks];
	else if([osxVersion isEqualToString:@"10.10"])
        hookChanges = [self hookChangesForYosemite];
	else if([osxVersion isEqualToString:@"10.11"])
		hookChanges = [self hookChangesForElCapitan];
    else if([osxVersion isEqualToString:@"10.12"])
        hookChanges = [self hookChangesForSierra];
	else if([osxVersion isEqualToString:@"10.13"])
        hookChanges = [self hookChangesForHighSierra];
    else if([osxVersion isEqualToString:@"10.14"]) {
        hookChanges = [self hookChangesForMojave];
    }
    else if([osxVersion isEqualToString:@"10.15"]) {
        hookChanges = [self hookChangesForCatalina];
    }
    
	for(NSString *class in hookChanges) {
		NSDictionary *hook = hookChanges[class];
        // class seems to be a protected identifier in lldb.
        NSString *klass = class;
		// Class was added.
		if(!hooks[class]) {
			// This check is necessary on older systems. 10.10+ has an additional check for nil value.
			// If hook[selectors] is nil, it would call removeObjectForKey instead of setObject:forKey.
			// Interestingly enough, this is done in the arclite implementation of the sdk this code is compiled on.
			// Setting hook[class] to hook[selectors] would crash on previous version if the code was compiled on 10.9 or lower
			// since no nil check was added in the arclite implementation of setObject:forKeyedSubscript:
			if(hook[@"selectors"]) {
				hooks[class] = hook[@"selectors"];
			}
			continue;
		}
		// Class was removed.
		if([hook[@"status"] isEqualToString:@"removed"]) {
			[hooks removeObjectForKey:class];
			continue;
		}
		// Selectors were updated
		if(hook[@"selectors"]) {
			for(NSString *action in hook[@"selectors"]) {
				for(id selector in hook[@"selectors"][action]) {
                    if([action isEqualToString:@"added"]) {
                        hooks[class] = [[hooks[class] arrayByAddingObject:selector] mutableCopy];
                    }
                    else if([action isEqualToString:@"removed"]) {
                        NSMutableArray *tempHooks = [hooks[class] mutableCopy];
                        [tempHooks removeObject:selector];
                        hooks[class] = tempHooks;
                    }
					else if([action isEqualToString:@"replaced"]) {
                        NSMutableArray *tempHooks = [hooks[class] mutableCopy];
                        [(NSMutableArray *)tempHooks removeObject:selector[0]];
						[(NSMutableArray *)tempHooks addObject:selector[1]];
                        hooks[class] = tempHooks;
                    }
                    else if([action isEqualToString:@"renamed"]) {
                        [(NSMutableArray *)hooks[class] removeObject:selector[0]];
                        [(NSMutableArray *)hooks[class] addObject:selector];
                    }
				}
			}
		}
		
		// Class was renamed.
		if([hook[@"status"] isEqualToString:@"renamed"]) {
			hooks[hook[@"name"]] = hooks[class];
			[hooks removeObjectForKey:class];
		}
	}
    
    
}

+ (NSString *)legacyClassNameForName:(NSString *)className {
    // Some classes have been renamed in Mavericks.
    // This methods converts known classes to their counterparts in Mavericks.
    if([@[@"MC", @"MF"] containsObject:[className substringToIndex:2]])
        return [className substringFromIndex:2];
    
    if([className isEqualToString:@"DocumentEditor"])
        return @"MailDocumentEditor";
    
    if([className isEqualToString:@"MessageViewController"])
        return @"MessageContentController";
    
    if([className isEqualToString:@"HeaderViewController"])
        return @"MessageHeaderDisplay";
	
	if([GPGMailBundle isElCapitan] && [className isEqualToString:@"ComposeViewController"])
		return @"MailDocumentEditor";
	
    return className;
}


+ (void)injectUsingMethodPrefix:(NSString *)prefix hooks:(NSDictionary*)hooks{
    /**
     This method replaces all of Mail's methods which are necessary for GPGMail
     to work correctly.
     
     For each class of Mail that must be extended, a class with the same name
     and suffix _GPGMail (<ClassName>_GPGMail) exists which implements the methods
     to be relaced.
     On runtime, these methods are first added to the original Mail class and
     after that, the original Mail methods are swizzled with the ones of the
     <ClassName>_GPGMail class.
     
     swizzleMap contains all classes and methods which need to be swizzled.
     */
    
    NSString *extensionClassSuffix = @"GPGMail";
    
    NSError * __autoreleasing error = nil;
    for(NSString *class in hooks) {
        NSString *klass = class;
        NSString *oldClass = [[self class] legacyClassNameForName:class];
        error = nil;
        
        NSArray *selectors = hooks[class];
        
        Class mailClass = NSClassFromString(class);
        if(!mailClass) {
            DebugLog(@"WARNING: Class %@ doesn't exist. This leads to unexpected behaviour!", class);
            continue;
        }
        
        // Check if a class exists with <class>_GPGMail. If that's
        // the case, all the methods of that class, have to be added
        // to the original Mail or Messages class.
        Class extensionClass = NSClassFromString([oldClass stringByAppendingFormat:@"_%@", extensionClassSuffix]);
        if(!extensionClass) {
            // In order to correctly hook classes on older versions of OS X than 10.9, the MC and MF prefix
            // is removed. There are however some cases, where classes where added to 10.9 which didn't exist
            // on < 10.9. In those cases, let's try to find the class with the appropriate prefix.
            
            // Try to find extensions to the original classname.
            extensionClass = NSClassFromString([class stringByAppendingFormat:@"_%@", extensionClassSuffix]);
        }
        BOOL extend = extensionClass != nil ? YES : NO;
        if(extend) {
            if(![mailClass jrlp_addMethodsFromClass:extensionClass error:&error])
                DebugLog(@"WARNING: methods of class %@ couldn't be added to %@ - %@", extensionClass,
                         mailClass, error);
        }
        
        // And on to swizzling methods and class methods.
        for(id selectorNames in selectors) {
            // If the selector changed from one OS X version to the other, selectorNames is an NSArray and
            // the selector name of the GPGMail implementation is item 0 and the Mail implementation name is
            // item 1.
            NSString *gmSelectorName = [selectorNames isKindOfClass:[NSArray class]] ? selectorNames[0] : selectorNames;
            NSString *mailSelectorName = [selectorNames isKindOfClass:[NSArray class]] ? selectorNames[1] : selectorNames;
            
            error = nil;
            NSString *extensionSelectorName = [NSString stringWithFormat:@"%@%@%@", prefix, [[gmSelectorName substringToIndex:1] uppercaseString],
                                               [gmSelectorName substringFromIndex:1]];
            SEL selector = NSSelectorFromString(mailSelectorName);
            SEL extensionSelector = NSSelectorFromString(extensionSelectorName);
            // First try to add as instance method.
            if(![mailClass jrlp_swizzleMethod:selector withMethod:extensionSelector error:&error]) {
                // If that didn't work, try to add as class method.
                if(![mailClass jrlp_swizzleClassMethod:selector withClassMethod:extensionSelector error:&error])
                    DebugLog(@"WARNING: %@ doesn't respond to selector %@", NSStringFromClass(mailClass),
                             NSStringFromSelector(selector));
            }
        }
    }
}

+ (void)injectUsingMethodPrefix:(NSString *)prefix {
    [self injectUsingMethodPrefix:prefix hooks:[self hooks]];
}

@end

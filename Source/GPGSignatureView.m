#import "GPGSignatureView.h"

#define localized(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:(key) table:@"SignatureView"]


@implementation GPGSignatureView
@synthesize keyList, signatures, gpgKey;
GPGSignatureView *_sharedInstance;

- (NSString *)unlocalizedValidityKey {
	NSString *text = nil;

	switch (signature.status) {
		case GPGErrorNoError:
			if (signature.trust > 1) {
				text = @"VALIDITY_OK";
			} else {
				text = @"VALIDITY_NO_TRUST";
			}
			break;
		case GPGErrorBadSignature:
			text = @"VALIDITY_BAD_SIGNATURE";
			break;
		case GPGErrorSignatureExpired:
			text = @"VALIDITY_SIGNATURE_EXPIRED";
			break;
		case GPGErrorKeyExpired:
			text = @"VALIDITY_KEY_EXPIRED";
			break;
		case GPGErrorCertificateRevoked:
			text = @"VALIDITY_KEY_REVOKED";
			break;
		case GPGErrorUnknownAlgorithm:
			text = @"VALIDITY_UNKNOWN_ALGORITHM";
			break;
		case GPGErrorNoPublicKey:
			text = @"VALIDITY_NO_PUBLIC_KEY";
			break;
		default:
			text = @"VALIDITY_UNKNOWN_ERROR";
			break;
	}
	return text;
}



- (NSImage *)validityImage {
	if (!signature) return nil;

	static NSArray *images = nil;
	if (!images) {
		images = [[NSArray alloc] initWithObjects:
				  [[[NSImage alloc] initWithContentsOfFile:@"/System/Library/Frameworks/SecurityInterface.framework/Resources/ValidBadge.tif"] autorelease],
				  [[[NSImage alloc] initWithContentsOfFile:@"/System/Library/Frameworks/SecurityInterface.framework/Resources/InvalidBadge.tif"] autorelease],
				  nil];
	}
	if (signature.status != 0 || signature.trust <= 1) {
		return [images objectAtIndex:1];
	} else {
		return [images objectAtIndex:0];
	}
}

- (NSString *)emailAndID {

    NSString *value = [NSString stringWithFormat:@"%@", gpgKey.email];
    NSString *keyID = [self keyID];
    if(keyID) {
        value = [value stringByAppendingFormat:@" (%@)", keyID];
    }
    return value;
}

- (NSString *)validityDescription {
	if (!signature) return nil;

	NSString *text = [self unlocalizedValidityKey];
	if (text) {
		return localized(text);
	} else {
		return @"";
	}
}

- (NSString *)validityToolTip {
	if (!signature) return nil;

	NSString *text = [self unlocalizedValidityKey];
	text = [text stringByAppendingString:@"_TOOLTIP"];
	if (text) {
		return localized(text);
	} else {
		return @"";
	}
}

- (NSString *)keyID {
	NSString *keyID = gpgKey.keyID;
	if (!keyID) {
		keyID = signature.fingerprint;
	}
	return [keyID shortKeyID];
}

- (NSImage *)signatureImage {
	static NSArray *images = nil;
	if (!images) {
		images = [[NSArray alloc] initWithObjects:
				  [[[NSImage alloc] initWithContentsOfFile:@"/System/Library/Frameworks/SecurityInterface.framework/Resources/CertLargeStd.tif"] autorelease],
				  [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"GPGCertLargeNotTrusted"]] autorelease],
				  nil];
	}

	if ([signature isKindOfClass:[GPGSignature class]]) {
		if (signature.status != 0 || signature.trust <= 1) {
			return [images objectAtIndex:1];
		} else {
			return [images objectAtIndex:0];
		}
	}
	return nil;
}




- (void)setGpgKey:(GPGKey *)value {
	if (value != gpgKey) {
		[gpgKey release];
		gpgKey = [value retain];
	}
}

- (void)setSignature:(GPGSignature *)value {
	if (value != signature) {
		[signature release];
		signature = [value retain];

		GPGKey *key = nil;
		if (signature) {
			NSString *fingerprint = signature.primaryFingerprint;
			if ((key = [keyList member:fingerprint])) {
				goto found;
			}
			fingerprint = signature.fingerprint;
			if ([fingerprint length] >= 8) {
				if ((key = [keyList member:fingerprint])) {
					goto found;
				}
				fingerprint = [fingerprint stringByAppendingString:@"\n"];
				for (key in keyList) {
					if ([[key allFingerprints] rangeOfString:fingerprint].length > 0) {
						goto found;
					}
				}
			}
		}
	found:
		[self setGpgKey:key];
	}
}

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:@"signature."]) {
		if (signature == nil) {
			return nil;
		}
		keyPath = [keyPath substringFromIndex:10];
        if ([signature respondsToSelector:NSSelectorFromString(keyPath)]) {
			return [signature valueForKey:keyPath];
		}
	}
	return [super valueForKeyPath:keyPath];
}

- (NSInteger)runModal {
	if (!running) {
		running = 1;
		[self willChangeValueForKey:@"signatureDescriptions"];
		[self didChangeValueForKey:@"signatureDescriptions"];
		[NSApp runModalForWindow:window];
		return NSOKButton;
	} else {
		return NSCancelButton;
	}
}
- (void)beginSheetModalForWindow:(NSWindow *)modalWindow completionHandler:(void (^)(NSInteger result))handler {
	if (!running) {
		running = 1;
		[self willChangeValueForKey:@"signatureDescriptions"];
		[self didChangeValueForKey:@"signatureDescriptions"];
		[NSApp beginSheet:window modalForWindow:modalWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:handler];
	} else {
		handler(NSCancelButton);
	}
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	((void (^)(NSInteger result))contextInfo)(NSOKButton);
}



- (IBAction)close:(id)sender {
	[window orderOut:self];
	[NSApp stopModal];
	[NSApp endSheet:window];
	running = 0;
}

- (void)windowWillClose:(NSNotification *)notification {
	[NSApp stopModal];
	[NSApp endSheet:window];
	running = 0;
}

- (NSIndexSet *)signatureIndexes {
	return [[signatureIndexes retain] autorelease];
}
- (void)setSignatureIndexes:(NSIndexSet *)value {
	if (value != signatureIndexes) {
		[signatureIndexes release];
		signatureIndexes = [value retain];
		NSUInteger index;
		if ([value count] > 0 && (index = [value firstIndex]) < [signatures count]) {
			self.signature = [signatures objectAtIndex:index];
		} else {
			self.signature = nil;
		}

	}
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
	return proposedMinimumPosition + 20;
}
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
	return proposedMaximumPosition - 90;
}
- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSArray *subviews = [splitView subviews];
	NSView *view1 = [subviews objectAtIndex:0];
	NSView *view2 = [subviews objectAtIndex:1];
	NSSize splitViewSize = [splitView frame].size;
	NSSize size1 = [view1 frame].size;
	NSRect frame2 = [view2 frame];
	CGFloat dividerThickness = [splitView dividerThickness];

	size1.width = splitViewSize.width;
	frame2.size.width = splitViewSize.width;

	frame2.size.height = splitViewSize.height - dividerThickness - size1.height;
	if (frame2.size.height < 60) {
		frame2.size.height = 60;
		size1.height = splitViewSize.height - 60 - dividerThickness;
	}
	frame2.origin.y = splitViewSize.height - frame2.size.height;

	[view1 setFrameSize:size1];
	[view2 setFrame:frame2];
}

- (void)awakeFromNib {
	[detailView setFrameOrigin:NSMakePoint(0, [scrollContentView frame].size.height)];
}



- (IBAction)switchDetailView:(NSButton *)sender {
	static CGFloat minHeight = 0;
	static CGFloat maxHeight = 450;
	NSRect windowFrame = [window frame];
	NSSize windowSize = windowFrame.size;
	NSSize scrollContentSize = [scrollContentView frame].size;
	NSSize detailSize = [detailView frame].size;

	if ([detailView superview]) {
		if (minHeight > 0 && minHeight < windowSize.height) {
			maxHeight = windowSize.height;
			windowSize.height = minHeight;
		} else {
			maxHeight = 0;
		}

		scrollContentSize.height -= detailSize.height;
		//infoSize.width = [infoView frame].size.width;

		[detailView removeFromSuperview];
	} else {
		if (maxHeight > 0 && windowSize.height < maxHeight) {
			minHeight = windowSize.height;
			windowSize.height = maxHeight;
		} else {
			minHeight = 0;
		}

		scrollContentSize.height += detailSize.height;
		[detailView setFrameSize:NSMakeSize(scrollContentSize.width, [detailView frame].size.height)];
		//infoSize.width = [detailView frame].size.width;

		[scrollContentView addSubview:detailView];
	}
	[scrollContentView setFrameSize:scrollContentSize];


	windowFrame.origin.x = windowFrame.origin.x + (windowSize.width - windowFrame.size.width) / 2;
	windowFrame.origin.y = windowFrame.origin.y + windowFrame.size.height - windowSize.height;
	windowFrame.size = windowSize;

	[window setFrame:windowFrame display:YES animate:YES];
}

+ (id)signatureView {
    static dispatch_once_t pred;
    static GPGSignatureView *_sharedInstance;
    dispatch_once(&pred, ^{
        _sharedInstance = [[GPGSignatureView alloc] init];
        [NSBundle loadNibNamed:@"GPGSignatureView" owner:_sharedInstance];
    });
    return _sharedInstance;
}

- (id)init {
	return [super init];
}

@end



@implementation GPGSignatureCertImageTransformer
NSArray *images;
+ (void)initialize {
	images = [[NSArray alloc] initWithObjects:
			  [[[NSImage alloc] initWithContentsOfFile:@"/System/Library/Frameworks/SecurityInterface.framework/Resources/CertSmallStd.tif"] autorelease],
			  [[[NSImage alloc] initWithContentsOfFile:@"/System/Library/Frameworks/SecurityInterface.framework/Resources/CertSmallStd_Invalid.tif"] autorelease],
			  nil];
}
+ (Class)transformedValueClass { return [NSImage class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(GPGSignature *)signature {
	NSImage *image = nil;
	if ([signature isKindOfClass:[GPGSignature class]]) {
		if (signature.status != 0 || signature.trust <= 1) {
			image = [images objectAtIndex:1];
		} else {
			image = [images objectAtIndex:0];
		}
	}
	return image;
}
@end



@implementation FlippedView
- (BOOL)isFlipped {
	return YES;
}
@end

@implementation TopScrollView
- (void)setFrameSize:(NSSize)newSize {
	NSClipView *clipView = [self contentView];
	NSRect bounds = [clipView bounds];
	[super setFrameSize:newSize];
	bounds.origin.y = bounds.origin.y - (bounds.size.height - [clipView bounds].size.height);
	[clipView setBoundsOrigin:bounds.origin];
}
@end



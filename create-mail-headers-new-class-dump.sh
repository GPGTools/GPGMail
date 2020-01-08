if [ -z "$1" ]; then
	echo "Output directory has to be specified!"
	exit 1
fi

ROOT="/"
OUTDIR="$1"

if [[ -n "$2" && -d "$2" ]]; then
	ROOT="$2"
fi

ADDRESS_FLAGS="-a -A"
if [[ -n "$3" ]]; then
	#ADDRESS_FLAGS="-r"
	ADDRESS_FLAGS=""
fi

class-dump $ADDRESS_FLAGS -I -H -o "$OUTDIR/MailUI" \
           -R "- \\(void\\)\\./// - (void)." \
           -R "\\(CDUnknownBlockType\\)/(id)" \
           -R "CDUnknownBlockType /id " \
           "$ROOT/Applications/Mail.app/Contents/MacOS/Mail"

class-dump $ADDRESS_FLAGS -I -H -o "$OUTDIR/EmailAddressing" \
           "$ROOT/System/Library/PrivateFrameworks/EmailAddressing.framework/EmailAddressing" 

class-dump $ADDRESS_FLAGS -I -H -o "$OUTDIR/MailCore" \
           -R "- \\(void\\)\\./// - (void)." \
           -R "\\(CDUnknownBlockType\\)/(id)" \
           -R "CDUnknownBlockType /id " \
           -R "\\CDStruct_7ad7028e/id" \
           -R "@protocol MCAttachmentDataSource/#import <MailCore/MCFileWrapper.h>
@protocol MCAttachmentDataSource" \
           "$ROOT/System/Library/PrivateFrameworks/MailCore.framework/MailCore"

class-dump $ADDRESS_FLAGS -I -H -o "$OUTDIR/MailUIFW" \
           -R "#import <MailUI\\//#import <MailUIFW/" \
           -R "- \\(void\\)\\./// - (void)." \
           -R "CDUnknownBlockType /id " \
           "$ROOT/System/Library/PrivateFrameworks/MailUI.framework"

class-dump $ADDRESS_FLAGS -I -H -o "$OUTDIR/MailFW" \
           -R "#import <Mail\\//#import <MailFW/" \
           -R "- \\(void\\)\\./// - (void)." \
           -R "\\(CDStruct_c53ccb4e \\*\\)/(id)" \
           -R "\\(CDStruct_33dcf794 \\*\\)/(id)" \
           -R "\\CDStruct_f4b747e6/id" \
           -R "\\(CDUnknownBlockType\\)/(id)" \
           "$ROOT/System/Library/PrivateFrameworks/Mail.framework"

class-dump $ADDRESS_FLAGS -I -H -o "$OUTDIR/IMAP" \
           "$ROOT/System/Library/PrivateFrameworks/IMAP.framework"

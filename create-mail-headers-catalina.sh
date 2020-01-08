#!/bin/bash

#############################
# FUNCTION Patch
#############################
Patch()
{
  FILE_SRC=$1
  SEARCH=$2
  REPLACE=$3

  #echo "$(date '+%Y-%m-%d %H:%M:%S')  ****** START (Patch) ******"
  echo "SRC:${FILE_SRC}"
  #echo "SEARCH:${SEARCH}"
  #echo "REPLACE:${REPLACE}"
  #echo ""

  sed -i -e "s/${SEARCH}/${REPLACE}/g" "${FILE_SRC}"

  #cat  ${FILE_SRC}

  #echo "$(date '+%Y-%m-%d %H:%M:%S')  ****** END (Patch) ******"
  #echo ""
}

./create-mail-headers-new-class-dump.sh MailHeaders/Catalina-10.15.1
#create-mail-headers-new-class-dump.sh MailHeaders/Catalina-10.15.1 /System "release" 
./create-mail-headers-new-class-dump.sh MailHeaders/Catalina-10.15.1 /System 

# PATCH .H

# Remove unknow include in MailUIFW
# //#import <AppKit/NSTokenAttachmentCell.h>
# @interface MUIAddressTokenAttachmentCell //: NSTokenAttachmentCell
Patch "MailHeaders/Catalina-10.15.1/MailUIFW/MUIAddressTokenAttachmentCell.h" "^#import" "\/\/#import" 
Patch "MailHeaders/Catalina-10.15.1/MailUIFW/MUIAddressTokenAttachmentCell.h" "Cell : NSTokenAttachmentCell" "Cell \/\/: NSTokenAttachmentCell" 

# Remove 2 var in a struct 4 Static Functions to MailCore/MCMessage.h
# id <MCMessageDataSource> _dataSource;
# long long _conversationID;
Patch "MailHeaders/Catalina-10.15.1/MailCore/MCMessage.h" "id <MCMessageDataSource> _dataSource;" "\/\/ id <MCMessageDataSource> _dataSource;" 
Patch "MailHeaders/Catalina-10.15.1/MailCore/MCMessage.h" "long long _conversationID;" "\/\/ long long _conversationID;" 

# Add 4 Static Functions to MailFW/MFLibrary.h
# + (id)fullMessageDataForMessage:(id)arg1;
# + (id)_dataPathForMessage:(id)arg1 type:(long long)arg2;
# + (id)_messageDataAtPath:(id)arg1;
# + (id)attachmentsDirectoryForMessage:(id)arg1 partNumber:(id)arg2;

Patch "MailHeaders/Catalina-10.15.1/MailFW/MFLibrary.h" "^@end" $'+ (id)fullMessageDataForMessage:(id)arg1;\\\n@end'
Patch "MailHeaders/Catalina-10.15.1/MailFW/MFLibrary.h" "^@end" $'+ (id)_dataPathForMessage:(id)arg1 type:(long long)arg2;\\\n@end'
Patch "MailHeaders/Catalina-10.15.1/MailFW/MFLibrary.h" "^@end" $'+ (id)_messageDataAtPath:(id)arg1;\\\n@end'
Patch "MailHeaders/Catalina-10.15.1/MailFW/MFLibrary.h" "^@end" $'+ (id)attachmentsDirectoryForMessage:(id)arg1 partNumber:(id)arg2;\\\n@end'
Patch "MailHeaders/Catalina-10.15.1/MailFW/MFLibrary.h" "^@end" $'\\\n@end'

ln -shF Catalina-10.15.1 MailHeaders/Catalina



//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

#import "NSTableViewDataSource-Protocol.h"

@class CriterionView, NSButton, NSLayoutConstraint, NSMutableArray, NSPanel, NSPopUpButton, NSScrollView, NSString, NSTableView, NSTextField, NSWindow;

@interface CriteriaUIHelper : NSObject <NSTableViewDataSource>
{
    NSMutableArray *_criteriaViews;	// 8 = 0x8
    BOOL _criteriaWillBeUsedForMailboxes;	// 16 = 0x10
    BOOL _isEditingHeader;	// 17 = 0x11
    NSString *_previousTitle;	// 24 = 0x18
    NSWindow *_parentWindow;	// 32 = 0x20
    CriterionView *_criterionView;	// 40 = 0x28
    NSTextField *_nameField;	// 48 = 0x30
    NSScrollView *_criteriaContainer;	// 56 = 0x38
    NSPopUpButton *_allCriteriaMustBeMetPopUp;	// 64 = 0x40
    NSButton *_includeTrashCheckbox;	// 72 = 0x48
    NSButton *_includeSentCheckbox;	// 80 = 0x50
    NSTextField *_performActionLabel;	// 88 = 0x58
    NSScrollView *_actionContainer;	// 96 = 0x60
    NSPanel *_headerListPanel;	// 104 = 0x68
    NSTableView *_headerListTable;	// 112 = 0x70
    NSButton *_addHeaderButton;	// 120 = 0x78
    NSLayoutConstraint *_criteriaHeightConstraint;	// 128 = 0x80
    NSLayoutConstraint *_criteriaContentHeightConstraint;	// 136 = 0x88
    NSLayoutConstraint *_actionHeightConstraint;	// 144 = 0x90
    NSLayoutConstraint *_actionContentHeightConstraint;	// 152 = 0x98
    id _objectWithCriteria;	// 160 = 0xa0
}

+ (id)headerList;	// IMP=0x000000010011c9c2
+ (void)unpackUserCriteria:(id *)arg1 noJunkCriterion:(id *)arg2 noTrashCriterion:(id *)arg3 noSentCriterion:(id *)arg4 allCriteriaMustBeSatisfield:(char *)arg5 fromCriteria:(id)arg6;	// IMP=0x000000010011c696
+ (id)packageUserCriteria:(id)arg1 withNoJunk:(BOOL)arg2 noTrash:(BOOL)arg3 noSent:(BOOL)arg4 allUserCriteriaMustBeSatisfied:(BOOL)arg5;	// IMP=0x000000010011c4a1
@property(nonatomic) __weak id objectWithCriteria; // @synthesize objectWithCriteria=_objectWithCriteria;
@property(nonatomic) BOOL isEditingHeader; // @synthesize isEditingHeader=_isEditingHeader;
@property(retain, nonatomic) NSLayoutConstraint *actionContentHeightConstraint; // @synthesize actionContentHeightConstraint=_actionContentHeightConstraint;
@property(retain, nonatomic) NSLayoutConstraint *actionHeightConstraint; // @synthesize actionHeightConstraint=_actionHeightConstraint;
@property(retain, nonatomic) NSLayoutConstraint *criteriaContentHeightConstraint; // @synthesize criteriaContentHeightConstraint=_criteriaContentHeightConstraint;
@property(retain, nonatomic) NSLayoutConstraint *criteriaHeightConstraint; // @synthesize criteriaHeightConstraint=_criteriaHeightConstraint;
@property(retain, nonatomic) NSButton *addHeaderButton; // @synthesize addHeaderButton=_addHeaderButton;
@property(retain, nonatomic) NSTableView *headerListTable; // @synthesize headerListTable=_headerListTable;
@property(retain, nonatomic) NSPanel *headerListPanel; // @synthesize headerListPanel=_headerListPanel;
@property(retain, nonatomic) NSScrollView *actionContainer; // @synthesize actionContainer=_actionContainer;
@property(retain, nonatomic) NSTextField *performActionLabel; // @synthesize performActionLabel=_performActionLabel;
@property(retain, nonatomic) NSButton *includeSentCheckbox; // @synthesize includeSentCheckbox=_includeSentCheckbox;
@property(retain, nonatomic) NSButton *includeTrashCheckbox; // @synthesize includeTrashCheckbox=_includeTrashCheckbox;
@property(retain, nonatomic) NSPopUpButton *allCriteriaMustBeMetPopUp; // @synthesize allCriteriaMustBeMetPopUp=_allCriteriaMustBeMetPopUp;
@property(retain, nonatomic) NSScrollView *criteriaContainer; // @synthesize criteriaContainer=_criteriaContainer;
@property(retain, nonatomic) NSTextField *nameField; // @synthesize nameField=_nameField;
@property(retain, nonatomic) CriterionView *criterionView; // @synthesize criterionView=_criterionView;
@property(nonatomic) __weak NSWindow *parentWindow; // @synthesize parentWindow=_parentWindow;
@property(retain, nonatomic) NSString *previousTitle; // @synthesize previousTitle=_previousTitle;
@property(nonatomic) BOOL criteriaWillBeUsedForMailboxes; // @synthesize criteriaWillBeUsedForMailboxes=_criteriaWillBeUsedForMailboxes;
- (void).cxx_destruct;	// IMP=0x000000010011f5fb
- (void)connectNextKeyViewChain;	// IMP=0x000000010011f2d5
- (void)tileViews:(id)arg1 inContainer:(id)arg2 withChangeAtRow:(unsigned long long)arg3 removeIsEnabled:(BOOL)arg4;	// IMP=0x000000010011e9ac
- (void)tableView:(id)arg1 setObjectValue:(id)arg2 forTableColumn:(id)arg3 row:(long long)arg4;	// IMP=0x000000010011e810
- (void)_removeInvalidHeaders;	// IMP=0x000000010011e24f
- (id)tableView:(id)arg1 objectValueForTableColumn:(id)arg2 row:(long long)arg3;	// IMP=0x000000010011e1c0
- (long long)numberOfRowsInTableView:(id)arg1;	// IMP=0x000000010011e195
- (void)addHeaderClicked:(id)arg1;	// IMP=0x000000010011e048
- (void)_headerTableEndedEditing:(id)arg1;	// IMP=0x000000010011e018
- (void)_headerTableBeganEditing:(id)arg1;	// IMP=0x000000010011dfe5
- (void)_updateHeaderListUI;	// IMP=0x000000010011df86
- (void)headerListCancelClicked:(id)arg1;	// IMP=0x000000010011df36
- (void)headerListOkClicked:(id)arg1;	// IMP=0x000000010011dee3
- (void)_endEditingHeader;	// IMP=0x000000010011de90
- (void)resetHeaderListForObjectsWithCriteria:(id)arg1;	// IMP=0x000000010011d7cb
- (void)_configureAllCriterionMenus;	// IMP=0x000000010011d6a2
- (void)editHeaderList;	// IMP=0x000000010011d57c
- (void)userHasSelectedSenderInContacts:(char *)arg1 senderInPreviousRecipients:(char *)arg2;	// IMP=0x000000010011d3d6
- (void)removeView:(id)arg1 fromViews:(id)arg2 inContainer:(id)arg3;	// IMP=0x000000010011d270
- (void)removeCriterion:(id)arg1;	// IMP=0x000000010011d1dd
- (id)_createNewCriterionViewForSender:(id)arg1;	// IMP=0x000000010011cf40
- (void)addCriterion:(id)arg1;	// IMP=0x000000010011cf01
- (void)configureCriteriaForObject:(id)arg1;	// IMP=0x000000010011c9d3
- (void)trashMailboxCriterionAdded;	// IMP=0x000000010011c45a
- (void)sentMessagesMailboxCriterionAdded;	// IMP=0x000000010011c413
- (void)putCriteriaFromUIIntoObject:(id)arg1;	// IMP=0x000000010011bf45
- (id)newCriterion;	// IMP=0x000000010011bf2c
- (void)awakeFromNib;	// IMP=0x000000010011bd44
- (void)dealloc;	// IMP=0x000000010011bccf

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end


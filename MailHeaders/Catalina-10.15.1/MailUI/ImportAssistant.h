//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import "Assistant.h"

@class EmailImporter, NSArray, NSDictionary, NSMatrix, NSMutableArray, NSProgressIndicator, NSTabView, NSTableView, NSTextField, NSView;

@interface ImportAssistant : Assistant
{
    NSMutableArray *_importers;	// 8 = 0x8
    NSMutableArray *_startingImporters;	// 16 = 0x10
    double _currentTime;	// 24 = 0x18
    double _referenceTime;	// 32 = 0x20
    NSView *_topView;	// 40 = 0x28
    NSTabView *_tabView;	// 48 = 0x30
    NSMatrix *_importClients;	// 56 = 0x38
    NSTextField *_explanatoryTextInImportClientTab;	// 64 = 0x40
    NSProgressIndicator *_progressWheelInImportClientTab;	// 72 = 0x48
    NSTextField *_statusLineInImportClientTab;	// 80 = 0x50
    NSMatrix *_importTypes;	// 88 = 0x58
    NSTextField *_explanatoryTextField;	// 96 = 0x60
    NSProgressIndicator *_progressWheel;	// 104 = 0x68
    NSTextField *_statusLineField;	// 112 = 0x70
    NSTableView *_tableView;	// 120 = 0x78
    NSProgressIndicator *_progressBar;	// 128 = 0x80
    NSTextField *_textFieldAboveField;	// 136 = 0x88
    NSTextField *_textFieldBelowField;	// 144 = 0x90
    NSTextField *_importFinishedField;	// 152 = 0x98
    NSArray *_clients;	// 160 = 0xa0
    NSDictionary *_client;	// 168 = 0xa8
    long long _currentTab;	// 176 = 0xb0
    EmailImporter *_importer;	// 184 = 0xb8
}

@property(retain, nonatomic) EmailImporter *importer; // @synthesize importer=_importer;
@property(nonatomic) long long currentTab; // @synthesize currentTab=_currentTab;
@property(retain, nonatomic) NSDictionary *client; // @synthesize client=_client;
@property(readonly, nonatomic) NSArray *clients; // @synthesize clients=_clients;
@property(nonatomic) __weak NSTextField *importFinishedField; // @synthesize importFinishedField=_importFinishedField;
@property(nonatomic) __weak NSTextField *textFieldBelowField; // @synthesize textFieldBelowField=_textFieldBelowField;
@property(nonatomic) __weak NSTextField *textFieldAboveField; // @synthesize textFieldAboveField=_textFieldAboveField;
@property(nonatomic) __weak NSProgressIndicator *progressBar; // @synthesize progressBar=_progressBar;
@property(nonatomic) __weak NSTableView *tableView; // @synthesize tableView=_tableView;
@property(nonatomic) __weak NSTextField *statusLineField; // @synthesize statusLineField=_statusLineField;
@property(nonatomic) __weak NSProgressIndicator *progressWheel; // @synthesize progressWheel=_progressWheel;
@property(nonatomic) __weak NSTextField *explanatoryTextField; // @synthesize explanatoryTextField=_explanatoryTextField;
@property(nonatomic) __weak NSMatrix *importTypes; // @synthesize importTypes=_importTypes;
@property(nonatomic) __weak NSTextField *statusLineInImportClientTab; // @synthesize statusLineInImportClientTab=_statusLineInImportClientTab;
@property(nonatomic) __weak NSProgressIndicator *progressWheelInImportClientTab; // @synthesize progressWheelInImportClientTab=_progressWheelInImportClientTab;
@property(nonatomic) __weak NSTextField *explanatoryTextInImportClientTab; // @synthesize explanatoryTextInImportClientTab=_explanatoryTextInImportClientTab;
@property(nonatomic) __weak NSMatrix *importClients; // @synthesize importClients=_importClients;
@property(nonatomic) __weak NSTabView *tabView; // @synthesize tabView=_tabView;
@property(retain, nonatomic) NSView *topView; // @synthesize topView=_topView;
- (void).cxx_destruct;	// IMP=0x000000010018b853
- (void)tableView:(id)arg1 didClickTableColumn:(id)arg2;	// IMP=0x000000010018b333
- (id)tableView:(id)arg1 toolTipForCell:(id)arg2 rect:(struct CGRect *)arg3 tableColumn:(id)arg4 row:(long long)arg5 mouseLocation:(struct CGPoint)arg6;	// IMP=0x000000010018b1e2
- (void)tableView:(id)arg1 setObjectValue:(id)arg2 forTableColumn:(id)arg3 row:(long long)arg4;	// IMP=0x000000010018b0cc
- (id)tableView:(id)arg1 objectValueForTableColumn:(id)arg2 row:(long long)arg3;	// IMP=0x000000010018afce
- (long long)numberOfRowsInTableView:(id)arg1;	// IMP=0x000000010018af52
@property(readonly, nonatomic) BOOL shouldUpdateTextFields;
- (void)updateProgressIndicatorByValue:(double)arg1;	// IMP=0x000000010018ae82
- (void)updateProgressIndicatorWithItem:(id)arg1;	// IMP=0x000000010018ae51
- (void)updateProgressIndicatorWithFraction:(double)arg1 ofItem:(id)arg2;	// IMP=0x000000010018ad40
- (void)_setProgressStartOnItem:(id)arg1;	// IMP=0x000000010018acc1
- (void)_updateProgressIndicatorToValue:(id)arg1;	// IMP=0x000000010018ac5f
- (void)_updateProgressIndicatorByValue:(id)arg1;	// IMP=0x000000010018abd6
- (void)initializeProgressIndicator;	// IMP=0x000000010018a8ae
- (void)reloadTableView;	// IMP=0x000000010018a871
- (void)setExplanatoryText:(id)arg1;	// IMP=0x000000010018a734
- (void)setTextFieldBelow:(id)arg1;	// IMP=0x000000010018a6b2
- (void)setTextFieldAbove:(id)arg1;	// IMP=0x000000010018a630
- (void)clearStatusLine;	// IMP=0x000000010018a521
- (void)setStatusLine:(id)arg1;	// IMP=0x000000010018a423
- (void)askForMailboxLocationAllowedFileTypes:(id)arg1 allowsMultipleSelection:(BOOL)arg2;	// IMP=0x0000000100189912
- (void)importFinished;	// IMP=0x000000010018954c
- (void)moveToTab:(long long)arg1;	// IMP=0x0000000100188ad5
- (void)presentAlertSheetWithString:(id)arg1;	// IMP=0x00000001001889a5
- (void)runImporter;	// IMP=0x000000010018885f
- (void)createNewImporter;	// IMP=0x0000000100188547
- (void)_importClientSelected:(id)arg1;	// IMP=0x00000001001881bc
- (void)goBackward;	// IMP=0x00000001001880e8
- (void)goForward;	// IMP=0x0000000100187b6d
- (void)stop;	// IMP=0x0000000100187981
- (BOOL)shouldStop;	// IMP=0x00000001001877be
- (void)start;	// IMP=0x0000000100187645
- (id)windowTitle;	// IMP=0x00000001001875d8
- (id)initWithAssistantManager:(id)arg1;	// IMP=0x000000010018720c

@end


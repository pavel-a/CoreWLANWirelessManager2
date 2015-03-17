//
//  CoreWLANController.h
//  CoreWLANWirelessManager example app
//

// File: CoreWLANController.h
// Abstract: Controller class for the CoreWLANWirelessManager application.
// Version: 2.0
// 

@class CWInterface, CWConfiguration, CWNetwork, SFAuthorizationView;

@interface CoreWLANController : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource>
{
    CWWiFiClient *wifiClient;
    CWInterface *currentInterface;
	NSMutableArray *scanResults;
	CWConfiguration *configurationSession;
	BOOL joinDialogContext;
	
	// main window
	IBOutlet NSPopUpButton *supportedInterfacesPopup;
	IBOutlet NSButton *refreshButton;
	IBOutlet NSProgressIndicator *refreshSpinner;
	IBOutlet NSTabView *tabView;
	IBOutlet NSWindow *mainWindow;
	
	// interface info tab
	IBOutlet NSTextField *supportedChannelsField;
	IBOutlet NSTextField *supportedPHYModesField;
	IBOutlet NSTextField *countryCodeField;
	IBOutlet NSSegmentedControl *powerStateControl;
	IBOutlet NSPopUpButton *channelPopup;
	IBOutlet NSTextField *opModeField;
	IBOutlet NSTextField *txPowerField;
	IBOutlet NSTextField *rssiField;
	IBOutlet NSTextField *noiseField;
	IBOutlet NSTextField *ssidField;
	IBOutlet NSTextField *securityModeField;
	IBOutlet NSTextField *bssidField;
	IBOutlet NSTextField *phyModeField;
	IBOutlet NSTextField *txRateField;
	IBOutlet NSButton *disconnectButton;
	
	// scan tab
	IBOutlet NSTableView *scanResultsTable;
	IBOutlet NSButton *joinButton;
	IBOutlet NSButton *mergeScanResultsCheckbox;
	NSTableColumn *ssidColumn;
	NSTableColumn *bssidColumn;
	NSTableColumn *channelColumn;
	NSTableColumn *phyModeColumn;
	NSTableColumn *securityModeColumn;
	NSTableColumn *ibssColumn;
	NSTableColumn *rssiColumn;
	
	// join dialog
	CWNetwork *selectedNetwork;
	IBOutlet NSWindow *joinDialogWindow;
	IBOutlet NSButton *joinOKButton;
	IBOutlet NSButton *joinCancelButton;
	IBOutlet NSPopUpButton *joinSecurityPopupButton;
	IBOutlet NSPopUpButton *joinUser8021XProfilePopupButton;
	IBOutlet NSProgressIndicator *joinSpinner;
	IBOutlet NSTextField *joinNetworkNameField;
	IBOutlet NSTextField *joinUsernameField;
	IBOutlet NSSecureTextField *joinPassphraseField;
	
	// ibss dialog
	IBOutlet NSWindow *ibssDialogWindow;
	IBOutlet NSButton *ibssOKButton;
	IBOutlet NSButton *ibssCancelButton;
	IBOutlet NSTextField *ibssNetworkNameField;
	IBOutlet NSTextField *ibssPassphraseField;
	IBOutlet NSPopUpButton *ibssChannelPopupButton;
	IBOutlet NSProgressIndicator *ibssSpinner;
}

@property(readwrite, retain) CWWiFiClient   *wifiClient;
@property(readwrite, retain) CWInterface    *currentInterface;
@property(readwrite, retain) NSMutableArray *scanResults;
@property(readwrite, retain) CWNetwork      *selectedNetwork;
@property(readwrite, assign) BOOL           joinDialogContext;

#pragma mark -
#pragma mark IBAction Methods
// application window
- (IBAction)interfaceSelected:(id)sender; 
- (IBAction)refreshPressed:(id)sender;

// interface info tab
- (IBAction)changePower:(id)sender;
- (IBAction)changeChannel:(id)sender;
- (IBAction)disconnect:(id)sender;

// scan tab
- (IBAction)joinButtonPressed:(id)sender;
- (IBAction)createIBSSButtonPressed:(id)sender;

// join dialog
- (IBAction)changeSecurityMode:(id)sender;
- (IBAction)change8021XProfile:(id)sender;
- (IBAction)joinOKButtonPressed:(id)sender;
- (IBAction)joinCancelButtonPressed:(id)sender;

// ibss dialog
- (IBAction)ibssOKButtonPressed:(id)sender;
- (IBAction)ibssCancelButtonPressed:(id)sender;
@end

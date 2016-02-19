//
// File: CoreWLANController.m
// Abstract: Controller class for the CoreWLANWirelessManager application.
// Version: 2.0 pa02 10-mar-2015
//

#import <CoreWLAN/CoreWLAN.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import "CoreWLANController.h"

@implementation CoreWLANController

@synthesize currentInterface;
@synthesize scanResults;
@synthesize selectedNetwork;
@synthesize joinDialogContext;
@synthesize wifiClient;

- (void)dealloc
{
	self.currentInterface = nil;
	self.scanResults = nil;
	self.selectedNetwork = nil;
	self.joinDialogContext = NO;
	[super dealloc];
}

#pragma mark -
#pragma mark Utility Methods
- (NSString*)stringForPHYMode:(NSNumber*)phyMode
{
	NSString *phyModeStr = nil;
	switch( [phyMode longValue] )
	{
		case kCWPHYMode11a:
			phyModeStr = @"802.11a";
			break;
		case kCWPHYMode11b:
			phyModeStr = @"802.11b";
			break;
		case kCWPHYMode11g:
			phyModeStr = @"802.11g";
			break;
		case kCWPHYMode11n:
			phyModeStr = @"802.11n";
			break;
		case kCWPHYMode11ac:
			phyModeStr = "802.11ac";
			break;
		default:
			phyModeStr = "?unknown mode?";
			break;
	}
	return phyModeStr;
}

- (NSString*)stringForSecurityMode:(NSNumber*)securityMode
{
	NSString *securityModeStr = nil;
	switch( [securityMode longValue] )
	{
		case kCWSecurityNone:
			securityModeStr = @"None";
			break;
		case kCWSecurityWEP:
			securityModeStr = @"WEP";
			break;
		case kCWSecurityWPAPersonal:
			securityModeStr = @"WPA Personal";
			break;
		case kCWSecurityWPAEnterprise:
			securityModeStr = @"WPA Enterprise";
			break;
		case kCWSecurityWPA2Personal:
			securityModeStr = @"WPA2 Personal";
			break;
		case kCWSecurityWPA2Enterprise:
			securityModeStr = @"WPA2 Enterprise";
			break;
		case kCWSecurityDynamicWEP:
			securityModeStr = @"802.1X WEP";
			break;
        case kCWSecurityUnknown:
            securityModeStr = @"Unknown";
            break;
        default:
            securityModeStr = @"?Other?";
	}
	return securityModeStr;
}

- (CWSecurity)securityModeForString:(NSString*)securityMode
{
	if( [securityMode isEqualToString:@"WEP"] )
		return kCWSecurityWEP;
	else if( [securityMode isEqualToString:@"WPA Personal"] )
		return kCWSecurityWPAPersonal;
	else if( [securityMode isEqualToString:@"WPA2 Personal"] )
		return kCWSecurityWPA2Personal;
	else if( [securityMode isEqualToString:@"WPA Enterprise"] )
		return kCWSecurityWPAEnterprise;
	else if( [securityMode isEqualToString:@"WPA2 Enterprise"] )
		return kCWSecurityWPA2Enterprise;
	else if( [securityMode isEqualToString:@"802.1X WEP"] )
		return kCWSecurityDynamicWEP;
	else
		return kCWSecurityNone;
}

- (NSString*)stringForOpMode:(NSNumber*)opMode
{
	NSString *opModeStr = nil;
	switch( [opMode intValue] )
	{
		case kCWInterfaceModeIBSS:
			opModeStr = @"IBSS";
			break;
		case kCWInterfaceModeStation:
			opModeStr = @"Infrastructure";
			break;
		case kCWInterfaceModeHostAP:
			opModeStr = @"Host Access Point";
			break;
	}
	return opModeStr;
}

// From neighbor's CWNetwork, figure out what security it supports:
static NSString *stringForNeigbSecurity(CWNetwork *neigb)
{
    if ([neigb supportsSecurity: kCWSecurityWPA2Personal])
        return @"WPA2/PSK";
    if ([neigb supportsSecurity: kCWSecurityNone])
        return @"Open";
    if ([neigb supportsSecurity: kCWSecurityWPA2Enterprise])
        return @"WPA2";
    if ([neigb supportsSecurity: kCWSecurityWEP])
        return @"WEP";
    if ([neigb supportsSecurity: kCWSecurityWPAPersonal])
        return @"WPA/PSK";
    if ([neigb supportsSecurity: kCWSecurityWPAEnterprise])
        return @"WPA/TKIP";
    if ([neigb supportsSecurity: kCWSecurityWPAPersonalMixed])
        return @"WPA mixed";
    //......
    return @"Other/unknown";
}

// From neighbor's CWNetwork, figure out its PHY
static NSString *stringForNeigbPhy(CWNetwork *neigb)
{
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:16];
    if ([neigb supportsPHYMode: kCWPHYMode11n])
        [s appendString: @".n"];
    if ([neigb supportsPHYMode: kCWPHYMode11g])
        [s appendString: @".g"];
    if ([neigb supportsPHYMode: kCWPHYMode11ac])
        [s appendString: @".ac"];
    if ([neigb supportsPHYMode: kCWPHYMode11a])
        [s appendString: @".a"];
    if ([neigb supportsPHYMode: kCWPHYMode11b])
        [s appendString: @".b"];

    return s;
}


#pragma mark -
#pragma mark Info display

- (void)updateInterfaceInfoTab
{
	NSNumber *num = nil;
	NSString *str = nil;

    if( !wifiClient ) {
        return; //self.wifiClient = CWWiFiClient.sharedWiFiClient;
    }

    if ( !currentInterface) {
        return; //self.currentInterface = self.wifiClient.interface;
    }

    // Note: most numeric properties of CWInterface return 0 in case of error;

	BOOL powerState = currentInterface.powerOn; /* whether the adapter is powered on */
	[powerStateControl setSelectedSegment:(powerState ? 0 : 1)];
	
	if( currentInterface.serviceActive )
		[disconnectButton setEnabled:YES];
	else
		[disconnectButton setEnabled:NO];

    num = currentInterface.interfaceMode;
	[opModeField setStringValue:((num && powerState) ? [self stringForOpMode:num] : @"")];
	
    num = [NSNumber numberWithLong: [currentInterface security]];
	[securityModeField setStringValue:((num && powerState) ? [self stringForSecurityMode:num] : @"")];
	
    num = [NSNumber numberWithLong:[currentInterface activePHYMode]];
	[phyModeField setStringValue:((num && powerState) ? [self stringForPHYMode:num] : @"")];
	
	str = [currentInterface ssid];
	[ssidField setStringValue:((str && powerState) ? str : @"")];
	
	str = [currentInterface bssid];
	[bssidField setStringValue:((str && powerState) ? str : @"")];
	
    str = currentInterface.countryCode;
    [countryCodeField setStringValue:((str && powerState) ? str : @"n/a")];

    num = [NSNumber numberWithDouble: [currentInterface transmitRate]];
	[txRateField setStringValue:((num && powerState) ? [NSString stringWithFormat:@"%@ Mbps", num] : @"n/a")];
	
    num = [NSNumber numberWithLong: [currentInterface rssiValue]];
	[rssiField setStringValue:((num.integerValue && powerState) ? [NSString stringWithFormat:@"%@ dBm",num] : @"n/a")];
	
    num = [NSNumber numberWithInteger: [currentInterface noiseMeasurement]];
	[noiseField setStringValue:((num && powerState) ? [NSString stringWithFormat:@"%@ dBm", num] : @"n/a")];

    num = [NSNumber numberWithUnsignedInteger: currentInterface.transmitPower];
	[txPowerField setStringValue:((num.integerValue && powerState) ? [NSString stringWithFormat:@"%@ mW", num] : @"n/a")];
	// *** pa01 This is always 0 on my Mini, 10.10 Does it mean error?

    NSArray *supportedChannelsArray = [[currentInterface supportedWLANChannels] allObjects];
	NSMutableString *supportedChannelsString = [NSMutableString stringWithCapacity:0];
	[channelPopup removeAllItems];
	for( id eachChannel in supportedChannelsArray )
	{
//		if( [eachChannel isEqualToNumber:[supportedChannelsArray lastObject]] )
//			[supportedChannelsString appendFormat:@"%@",[eachChannel stringValue]];
//		else
        // **** sort channels by band, some channels duplicate in several bands??
			[supportedChannelsString appendFormat:@"%lu ", (long)[eachChannel channelNumber] ];
		
		if( powerState )
			[channelPopup addItemWithTitle:[NSNumber numberWithLong:[eachChannel channelNumber]].stringValue ];
	}
	[supportedChannelsField setStringValue:supportedChannelsString];

#if 0 // supportedPHYModes removed, =>  CWNetwork supportsPHYMode?
    NSArray *supportedPHYModesArray = [self.currentInterface supportedPHYModes];
	NSMutableString *supportedPHYModesString = [NSMutableString stringWithString:@"802.11"];
	for( id eachPHYMode in supportedPHYModesArray )
	{
		switch( [eachPHYMode intValue] )
		{
			case kCWPHYMode11a:
				[supportedPHYModesString appendString:@"a/"];
				break;
			case kCWPHYMode11b:
				[supportedPHYModesString appendString:@"b/"];
				break;
			case kCWPHYMode11g:
				[supportedPHYModesString appendString:@"g/"];
				break;
			case kCWPHYMode11n:
				[supportedPHYModesString appendString:@"n/"];
				break;
            case kCWPHYMode11ac:
                [supportedPHYModesString appendString:@"ac/"];
                break;
            default:
                [supportedPHYModesString appendString:@"(other)/"];
		}
	}
	if( [supportedPHYModesString hasSuffix:@"/"] )
		[supportedPHYModesString deleteCharactersInRange:NSMakeRange([supportedPHYModesString length] - 1, 1)];
	if( [supportedPHYModesString hasSuffix:@"802.11"] )
		supportedPHYModesString = [NSMutableString stringWithString:@"None"];
#endif //----------------------------------------------
    NSString *supportedPHYModesString = @"[N/A]"; // don't know how to get
	[supportedPHYModesField setStringValue:supportedPHYModesString];

    num = [NSNumber numberWithUnsignedInteger:[[currentInterface wlanChannel] channelNumber]];
	[channelPopup selectItemWithTitle: num.stringValue];

    //NsLog( @"BAND: %d", (int)[[currentInterface wlanChannel] channelBand]);

	if( !powerState )
		[channelPopup setEnabled:NO];
	else
		[channelPopup setEnabled:YES];
}

- (void)updateScanTab
{
    @autoreleasepool {
    bool m = ([mergeScanResultsCheckbox state] == NSOnState);
    NSSet *scanset = [currentInterface cachedScanResults];

    if (m) {
        scanset = CWMergeNetworks(scanset);
    }
    NSArray *x = scanset.allObjects;
    self.scanResults = [x mutableCopy];
	[self.scanResults sortUsingDescriptors:[NSArray arrayWithObject:[
                          [[NSSortDescriptor alloc] initWithKey:@"ssid" ascending:YES
                          selector:@selector(caseInsensitiveCompare:)]
                          autorelease ]]];

    [scanResultsTable reloadData];
    }
}

- (void)resetDialog
{
	[joinNetworkNameField setStringValue:@""];
	[joinNetworkNameField setEnabled:YES];
	[joinUsernameField setStringValue:@""];
	[joinUsernameField setEnabled:YES];
	[joinPassphraseField setStringValue:@""];
	[joinPassphraseField setEnabled:YES];
	
	[joinSecurityPopupButton removeAllItems];
	[joinSecurityPopupButton addItemsWithTitles:[NSArray arrayWithObjects:@"Open", @"WEP", @"WPA Personal", @"WPA2 Personal", @"WPA Enterprise", @"WPA2 Enterprise", @"802.1X WEP", nil]];
	[joinSecurityPopupButton selectItemAtIndex:0];
	[joinSecurityPopupButton setEnabled:YES];
	[joinUser8021XProfilePopupButton removeAllItems];
	[self changeSecurityMode:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	self.joinDialogContext = NO;
}

#pragma mark -
#pragma mark NSNibAwaking Protocol
- (void) awakeFromNib
{
    if( !wifiClient ) {
        wifiClient = CWWiFiClient.sharedWiFiClient;
    }

    if ( !currentInterface) {
        currentInterface = wifiClient.interface;
    }

	// populate interfaces popup with all supported interfaces
	[supportedInterfacesPopup removeAllItems];
    NSArray *aintf = [wifiClient interfaces];
    for (CWInterface *intf in aintf) {
        [supportedInterfacesPopup addItemWithTitle: intf.interfaceName];
    }

	// setup scan results table
	[scanResultsTable setDataSource:self];
	[scanResultsTable setDelegate:self];
	ssidColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"NETWORK_NAME"];
	bssidColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"BSSID"];
	channelColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"CHANNEL"];
	phyModeColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"PHY_MODE"];
	ibssColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"NETWORK_MODE"];
	rssiColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"RSSI"];
	securityModeColumn = [scanResultsTable tableColumnWithIdentifier:(NSString *)@"SECURITY_MODE"];
	
	// hide progress indicators 
	[refreshSpinner setHidden:YES];
	[joinSpinner setHidden:YES];
	[ibssSpinner setHidden:YES];
	
#if 1 //*** TODO notifications using client::startMonitoringEventsWithType...
    // register for notifcations
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification::) name:CWModeDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:CWSSIDDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:CWBSSIDDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:CWCountryCodeDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:CWLinkDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:CWPowerDidChangeNotification object:nil];
#endif //***
}

#pragma mark -
#pragma mark NSApplicationDelegate Protocol
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[supportedInterfacesPopup selectItemAtIndex:0];
	[self interfaceSelected:nil];
}

#pragma mark -
#pragma mark IBAction Methods
- (IBAction)interfaceSelected:(id)sender
{
    if( !wifiClient ) {
        wifiClient = CWWiFiClient.sharedWiFiClient;
    }
    if( !currentInterface ) {
        currentInterface = [wifiClient interface];
    }
	[self updateInterfaceInfoTab];
}

- (IBAction)refreshPressed:(id)sender
{
	[refreshSpinner setHidden:NO];
	[refreshSpinner startAnimation:self];
	
	if( [[[tabView selectedTabViewItem] label] isEqualToString:@"Interface Info"] )
		[self updateInterfaceInfoTab];
    else if( [[[tabView selectedTabViewItem] label] isEqualToString:@"Scan"] ) {
        NSError *err = nil;
        [currentInterface scanForNetworksWithSSID:Nil error:&err];
        if( (err != nil) && (err.code != 0)) {
            [[NSAlert alertWithError:err] runModal];
        }
		[self updateScanTab];
    }

	[refreshSpinner stopAnimation:self];
	[refreshSpinner setHidden:YES];
}

- (IBAction)changePower:(id)sender
{
	NSError *err = nil;
	BOOL result = [currentInterface setPower:([powerStateControl selectedSegment] ? NO : YES) error:&err];
	if( !result )
		[[NSAlert alertWithError:err] runModal];
	[self updateInterfaceInfoTab];
}

- (IBAction)changeChannel:(id)sender
{
	NSError *err = nil;
    BOOL result = 0;//$$$[currentInterface setChannel:[[NSNumber numberWithInt:[[[channelPopup selectedItem] title] intValue]] unsignedIntegerValue] error:&err];
	if( !result )
		[[NSAlert alertWithError:err] runModal];
	[self updateInterfaceInfoTab];
}

- (IBAction)disconnect:(id)sender
{
	[self.currentInterface disassociate];
	[self updateInterfaceInfoTab];
}

- (IBAction)changeSecurityMode:(id)sender
{	
	if( [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA Enterprise"] ||
	   [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA2 Enterprise"] ||
	   [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"802.1X WEP"] )
	{
		[joinUsernameField setEnabled:YES];
		[joinUser8021XProfilePopupButton setEnabled:YES];
		[joinPassphraseField setEnabled:YES];
		
		[joinUser8021XProfilePopupButton addItemWithTitle:@"Default"];
#if 0
		for( CW8021XProfile *each8021XProfile in [CW8021XProfile allUser8021XProfiles] )
		{
			[joinUser8021XProfilePopupButton addItemWithTitle:[each8021XProfile userDefinedName]];
		}
#endif
		[joinUser8021XProfilePopupButton selectItemAtIndex:0];
	}
	else if( [[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA Personal"] ||
			[[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WPA2 Personal"] || 
			[[[joinSecurityPopupButton selectedItem] title] isEqualToString:@"WEP"] )
	{
		[joinUser8021XProfilePopupButton removeAllItems];
		[joinUser8021XProfilePopupButton setEnabled:NO];
		[joinUsernameField setEnabled:NO];
		[joinPassphraseField setEnabled:YES];
	}
	else
	{
		[joinUser8021XProfilePopupButton removeAllItems];
		[joinPassphraseField setEnabled:NO];
		[joinUsernameField setEnabled:NO];
		[joinUser8021XProfilePopupButton setEnabled:NO];
	}
}

- (IBAction)change8021XProfile:(id)sender
{
#if 0
	CW8021XProfile *tmp = [[CW8021XProfile allUser8021XProfiles] objectAtIndex:[joinUser8021XProfilePopupButton indexOfSelectedItem] -1];
	if( tmp )
	{
		if( [[[joinUser8021XProfilePopupButton selectedItem] title] isEqualToString:@"Default"] )
		{
			[joinUsernameField setStringValue:@""];
			[joinUsernameField setEnabled:YES];
			[joinPassphraseField setStringValue:@""];
			[joinPassphraseField setEnabled:YES];
		}
		else
		{
			[joinUsernameField setStringValue:tmp.username];
			[joinUsernameField setEnabled:NO];
			[joinPassphraseField setStringValue:tmp.password];
			[joinPassphraseField setEnabled:NO];
		}

    }
#endif
}

- (IBAction)joinOKButtonPressed:(id)sender
{
#if 0 //$$$ todo
	CW8021XProfile *user8021XProfile = nil;
	
	[joinSpinner setHidden:NO];
	[joinSpinner startAnimation:self];
	
	if( [joinUser8021XProfilePopupButton isEnabled] )
	{
		if( [[[joinUser8021XProfilePopupButton selectedItem] title] isEqualToString:@"Default"] )
		{
			user8021XProfile = [CW8021XProfile profile];
			user8021XProfile.ssid = [joinNetworkNameField stringValue];
			user8021XProfile.userDefinedName = [joinNetworkNameField stringValue];
			user8021XProfile.username = ([[joinUsernameField stringValue] length] ? [joinUsernameField stringValue] : nil);
			user8021XProfile.password = ([[joinPassphraseField stringValue] length] ? [joinPassphraseField stringValue] : nil);
		}
		else
		{
			user8021XProfile = [[CW8021XProfile allUser8021XProfiles] objectAtIndex:[joinUser8021XProfilePopupButton indexOfSelectedItem]-1];
		}
	}
	
	if( self.joinDialogContext )
	{
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
		if( user8021XProfile )
			[params setValue:user8021XProfile forKey:kCWAssocKey8021XProfile];
		else
			[params setValue:([[joinPassphraseField stringValue] length] ? [joinPassphraseField stringValue] : nil) forKey:kCWAssocKeyPassphrase];
		NSError *err = nil;
		BOOL result = [self.currentInterface associateToNetwork:self.selectedNetwork parameters:[NSDictionary dictionaryWithDictionary:params] error:&err];
		
		[joinSpinner stopAnimation:self];
		[joinSpinner setHidden:YES];
		
		if( !result )
			[[NSAlert alertWithError:err] runModal];
		else
			[self joinCancelButtonPressed:nil];
	}
#endif //$$$
}

- (IBAction)joinCancelButtonPressed:(id)sender
{
	[(NSApplication*)NSApp endSheet:joinDialogWindow];
	[joinDialogWindow orderOut:sender];
}

- (IBAction)joinButtonPressed:(id)sender
{
	NSInteger index = [scanResultsTable selectedRow];
	if( index >= 0 )
	{
		[self resetDialog];
		self.selectedNetwork = [self.scanResults objectAtIndex:index];
		
		[joinNetworkNameField setStringValue:self.selectedNetwork.ssid];
		[joinNetworkNameField setEnabled:NO];
#if 0 //$$$ todo
		[joinSecurityPopupButton selectItemWithTitle:[self stringForSecurityMode:self.selectedNetwork.securityMode]];
		[joinSecurityPopupButton setEnabled:NO];
		[self changeSecurityMode:nil];
		
		CWWirelessProfile *wp = self.selectedNetwork.wirelessProfile;
		CW8021XProfile *xp = wp.user8021XProfile;
		switch( [self.selectedNetwork.securityMode intValue] )
		{
			case kCWSecurityModeWPA_PSK:
			case kCWSecurityModeWPA2_PSK:
			case kCWSecurityModeWEP:
				if( wp.passphrase )
				{
					[joinPassphraseField setStringValue:wp.passphrase];
				}
				break;
			case kCWSecurityModeOpen:
				break;
			case kCWSecurityModeWPA_Enterprise:
			case kCWSecurityModeWPA2_Enterprise:
				if( xp )
				{
					[joinUser8021XProfilePopupButton selectItemWithTitle:xp.userDefinedName];
					[joinUsernameField setStringValue:xp.username];
					[joinUsernameField setEnabled:NO];
					[joinPassphraseField setStringValue:xp.password];
					[joinPassphraseField setEnabled:NO];
				}
				break;
		}
#endif //$$$
		// reset first repsponder
		[joinDialogWindow makeFirstResponder:joinNetworkNameField];
		
		self.joinDialogContext = YES;
		[NSApp beginSheet:joinDialogWindow modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (IBAction)ibssOKButtonPressed:(id)sender
{
	[ibssSpinner setHidden:NO];
	[ibssSpinner startAnimation:self];
	
	NSString *networkName = [ibssNetworkNameField stringValue];
	NSNumber *channel = [NSNumber numberWithInt:[[[ibssChannelPopupButton selectedItem] title] intValue]];
	NSString *passphrase = [ibssPassphraseField stringValue];
	
	NSMutableDictionary *ibssParams = [NSMutableDictionary dictionaryWithCapacity:0];
#if 0//$$$ todo
	if( networkName && [networkName length] )
		[ibssParams setValue:networkName forKey:kCWIBSSKeySSID];
	if( channel && [channel intValue] > 0 )
		[ibssParams setValue:channel forKey:kCWIBSSKeyChannel];
	if( passphrase && [passphrase length] )
		[ibssParams setValue:passphrase forKey:kCWIBSSKeyPassphrase];
	NSError *error = nil;
	BOOL created = [self.currentInterface enableIBSSWithParameters:[NSDictionary dictionaryWithDictionary:ibssParams] error:&error];
#else
    NSError *error = nil;
    BOOL created = 0;
#endif //$$$
	
	[ibssSpinner stopAnimation:self];
	[ibssSpinner setHidden:YES];
	
	if( !created )
	{
		[[NSAlert alertWithError:error] runModal];
	}
	else
	{
		[self ibssCancelButtonPressed:nil];
	}
}

- (IBAction)ibssCancelButtonPressed:(id)sender
{
	[(NSApplication*)NSApp endSheet:ibssDialogWindow];
	[ibssDialogWindow orderOut:sender];
}

- (IBAction)createIBSSButtonPressed:(id)sender
{
	// add machine name as default SSID
	CFStringRef machineName = CSCopyMachineName();
	if( machineName )
	{
		[ibssNetworkNameField setStringValue:(id)machineName];
		CFRelease(machineName);
	}

	// hard code IBSS channel for now
	[ibssChannelPopupButton addItemWithTitle:@"11"];
	[ibssChannelPopupButton setEnabled:NO];
	
	// select channel 11 as default channel
	[ibssChannelPopupButton selectItemWithTitle:@"11"];
	
	// reset passphrase
	[ibssPassphraseField setStringValue:@""];
	
	// reset first responder
	[ibssDialogWindow makeFirstResponder:ibssNetworkNameField];
	
	[NSApp beginSheet:ibssDialogWindow modalForWindow:mainWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}


#pragma mark -
#pragma mark NSTableDataSource Protocol

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
	if( tableView == scanResultsTable )
	{
		if( row < [self.scanResults count] )
		{
			CWNetwork *network = [self.scanResults objectAtIndex:row];
			if( tableColumn == ssidColumn )
				return [network ssid];
			if( tableColumn == bssidColumn )
				return [network bssid];
			if( tableColumn == channelColumn )
                return [NSNumber numberWithInt: [[network wlanChannel] channelNumber]].stringValue;
			if( tableColumn == phyModeColumn )
                return stringForNeigbPhy(network);
			if( tableColumn == securityModeColumn )
                return stringForNeigbSecurity(network);
			if( tableColumn == rssiColumn )
				return [NSNumber numberWithLong:[network rssiValue]].stringValue;
			if( tableColumn == ibssColumn )
                return ([network ibss] ? @"Yes" : @"No");
		}
	}
	return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{	
	return (self.scanResults ? [self.scanResults count] : 0);
}

#pragma mark -
#pragma mark Notification Handler
- (void)handleNotification:(NSNotification*)note
{
	[self updateInterfaceInfoTab];
}
@end

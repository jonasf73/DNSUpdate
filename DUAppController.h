#import <Cocoa/Cocoa.h>
#import "DUProtocols.h"

@interface DUAppController : NSObject <DUDaemonDelegate>
{
    IBOutlet id monitorController;
    IBOutlet id usersController;
    IBOutlet id launchPanel;
    IBOutlet id launchProgressIndicator;
    
    IBOutlet id usersWindow;
    IBOutlet id monitorWindow;
    IBOutlet id helpWindow;
    IBOutlet id helpTextView;
    IBOutlet id pauseMenuItem;
    
    IBOutlet id preferencesWindow;
    IBOutlet id startOptionRadioButtons;
    
    IBOutlet id supportWindow;
}

+ (id <DUProxy>) daemon;

- (void)daemonIsLaunched:(NSNotification *)theNotification;

- (IBAction)uninstallDNSUpdate:sender;
- (IBAction)openHelp:sender;
- (IBAction)pauseDaemon:sender;
- (IBAction)openLogFile:sender;

- (void)updateDockMenu:(NSNotification *)theNotification;

- (IBAction)supportOpen:sender;
- (IBAction)supportPay:sender;
- (IBAction)supportContact:sender;
- (IBAction)supportLater:sender;

- (IBAction)openPreferencesWindow:sender;
- (IBAction)setStartOption:sender;

@end

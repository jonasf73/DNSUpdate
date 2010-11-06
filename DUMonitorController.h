#import <Cocoa/Cocoa.h>
#import "DUHost.h"

@interface DUMonitorController : NSObject
{
    IBOutlet id monitorWindow;
    IBOutlet id tableView;
    IBOutlet id activeColumn;
    IBOutlet id hostnameColumn;
    IBOutlet id userColumn;
    IBOutlet id ipColumn;
    IBOutlet id lastUpdateColumn;
    IBOutlet id statusColumn;
    IBOutlet id pauseButton;
    IBOutlet id statusField;
    NSMutableArray *keys;
    NSMutableDictionary *data;
}

- (void)initTable;
- (void)loadData;
- (void)updateData;

- (void)duDataUpdated:(NSNotification *)theNotification;

- (IBAction)openMonitorWindow:(id)sender;
- (IBAction)pauseDaemon:(id)sender;

- (void)updateHost:(DUHost *)host;

@end

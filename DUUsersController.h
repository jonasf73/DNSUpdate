#import <Cocoa/Cocoa.h>
#import "DUServiceInterface.h"

@interface DUUsersController : NSObject
{
    IBOutlet id activeColumn;
    IBOutlet id nameColumn;
    IBOutlet id statusColumn;
    IBOutlet id usersOutlineView;
    IBOutlet id usersWindow;
    IBOutlet id userEditWindow;
    IBOutlet id userEditSaveButton;
    IBOutlet id userEditName;
    IBOutlet id userEditPassword;
    IBOutlet id userEditService;
    IBOutlet NSBox *userEditBox;
    IBOutlet id hostEditWindow;
    IBOutlet id hostEditSaveButton;
    IBOutlet id hostEditName;
    IBOutlet id hostEditInterface;
    IBOutlet NSBox *hostEditBox;
    NSView *hostContentView;
    NSView *userContentView;
    NSToolbar *userToolbar;
    NSMutableDictionary *userToolbarItems;
}

- (void)duDataUpdated:(NSNotification *)theNotification;

- (IBAction)addHost:(id)sender;
- (IBAction)addUser:(id)sender;
- (IBAction)editAction:(id)sender;
- (IBAction)openUsersWindow:(id)sender;
- (IBAction)removeAction:(id)sender;

- (IBAction)userSave:(id)sender;
- (IBAction)userCancel:(id)sender;
- (IBAction)userChangeService:(id)sender;
- (void)hostChangeServiceTo:(DUServiceInterface *)theService;

- (IBAction)hostSave:(id)sender;
- (IBAction)hostCancel:(id)sender;

@end

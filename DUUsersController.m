#import "DUUsersController.h"
#import "DUProtocols.h"
#import "DUUser.h"
#import "DUHost.h"
#import "DUAppController.h"
#import "DUServiceUpdater.h"
#import "DUInterface.h"
#import "DUCommon.h"

#import "DUServiceInterface.h"
#import "DUDynDNSInterface.h"
#import "DUZoneEditInterface.h"
#import "DUEasyDNSInterface.h"

BOOL _firstLaunch=YES;
NSArray *_usersArray=nil;
NSMutableDictionary *_usersHosts=nil;

BOOL _duEditing=NO;

NSDictionary *_duServices=nil;
NSDictionary *_duInterfaces=nil;

@implementation DUUsersController

- (void)initOutlineView {
    NSButtonCell *dataCell=[[NSButtonCell alloc] init];

    _usersArray=[[[[DUAppController daemon] users] allValues] copy];
    _usersHosts=[[NSMutableDictionary alloc] initWithCapacity:1];
    
    [usersOutlineView setAutosaveName:@"DUUsersList"];
    [usersOutlineView setAutosaveTableColumns:YES];
    [usersOutlineView setDoubleAction:@selector(editAction:)];
    [usersOutlineView setTarget:self];
    
    [dataCell setButtonType:NSSwitchButton];
    [dataCell setImagePosition:NSImageOnly];

    [activeColumn setDataCell:[dataCell autorelease]];
    
    [[nameColumn dataCell] setEditable:NO];
    [[statusColumn dataCell] setEditable:NO];
    
    [usersOutlineView setDataSource:self];
    [usersOutlineView setDelegate:self];
}

- (void)initServicesAndInterfaces {
    id <DUProxy> daemon=[DUAppController daemon];
    
    _duServices=[[daemon services] retain];
    [userEditService removeAllItems];
    [userEditService addItemsWithTitles:[_duServices allKeys]];

    [DUDynDNSInterface registerService];
    [DUZoneEditInterface registerService];
    [DUEasyDNSInterface registerService];
    
    hostContentView=[[hostEditBox contentView] retain];
    userContentView=[[userEditBox contentView] retain];
    
    _duInterfaces=[[daemon interfaces] retain];
    [hostEditInterface removeAllItems];
    [hostEditInterface addItemsWithTitles:[[_duInterfaces allKeys] sortedArrayUsingSelector:@selector(compare:)]];
}

- outlineView:(NSOutlineView *)theView child:(int)index ofItem:item {
    id obj;
    if(!item) {
        obj=[_usersArray objectAtIndex:index];
    } else {
        id hosts=[item hosts];
        obj=[hosts objectAtIndex:index];
        [_usersHosts setObject:hosts forKey:[item description]];
    }
    return obj;
}

- (BOOL)outlineView:(NSOutlineView *)theView isItemExpandable:item {    
    if([item isUser])
        return YES;
    else
        return NO;
}

- (int)outlineView:(NSOutlineView *)theView numberOfChildrenOfItem:item {
    int co;
    if(!item)
        co=[_usersArray count];
    else
        co=[[item hosts] count];
    return co;
}

- outlineView:(NSOutlineView *)theView objectValueForTableColumn:(NSTableColumn *)col byItem:item {
    id obj=nil;
    if([item isUser]) {
        if(col==nameColumn) {
            obj=[item description];
        } else if(col==statusColumn) {
            obj=NSLocalizedString([item getUserStatus],@"");
        } else if(col==activeColumn) {
            obj=[NSNumber numberWithBool:[item isActive]];
        }
    } else {
        if(col==nameColumn) {
            obj=[item getName];
        } else if(col==statusColumn) {
            NSString *hostStatus = [item realStatus];
            if([hostStatus isEqualToString: @"Waiting"]) {
                // XXX refactoring -> see DUMonitorController
                NSString *_shortDateFormat=[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString];
                NSString *_longDateFormat=[NSString stringWithFormat:@"%@, %@",_shortDateFormat, [[NSUserDefaults standardUserDefaults] stringForKey:NSTimeFormatString]];
                
                hostStatus = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(hostStatus, @""), [[item hostPropertyForKey: @"DUDateForUpdate"] descriptionWithCalendarFormat:_longDateFormat timeZone:nil locale:nil]];
            } else {
                hostStatus = NSLocalizedString(hostStatus, @"");
            }
            obj=hostStatus;
        } else if(col==activeColumn) {
            obj=[NSNumber numberWithBool:[item isActive]];
        }
    }
    return obj;
}

- (void)outlineView:(NSOutlineView *)theView setObjectValue:(id)object forTableColumn:(NSTableColumn *)col byItem:(id)item {
    id <DUProxy> daemon=[DUAppController daemon];
    
    [item setActive:![item isActive]];
    if([item isUser])
        [item saveUser];
    else
        [[(DUHost *)item user] saveUser];
    
    if(![daemon isPaused])
        [daemon daemonStart];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    int row=[usersOutlineView selectedRow];
    id item=nil;
        
    if(row>=0) {
        item=[usersOutlineView itemAtRow:row];
    }

    if((row<0)||[item isUser]) {
        [[userToolbarItems objectForKey:@"Edit"] setLabel:NSLocalizedString(@"Edit User",@"")];
        [[userToolbarItems objectForKey:@"Remove"] setLabel:NSLocalizedString(@"Remove User",@"")];        
    }
    else {
        [[userToolbarItems objectForKey:@"Edit"] setLabel:NSLocalizedString(@"Edit Host",@"")];
        [[userToolbarItems objectForKey:@"Remove"] setLabel:NSLocalizedString(@"Remove Host",@"")];        
    }

    [userToolbar validateVisibleItems];
}

- (IBAction)addHost:(id)sender
{
    DUServiceInterface *theServiceInterface;
    id item=[usersOutlineView itemAtRow:[usersOutlineView selectedRow]];
    DUUser *theUser;
    
    if([item isUser])
        theUser=item;
    else
        theUser=[(DUHost *)item user];

    theServiceInterface=[DUServiceInterface getServiceInterfaceFor:[[theUser getService] getServiceName]];

    [self hostChangeServiceTo:theServiceInterface];
    [theServiceInterface clearHostView];
    
    [hostEditSaveButton setTitle:NSLocalizedString(@"Add",@"")];
    [hostEditName setStringValue:@""];


    [hostEditInterface selectItemWithTitle:@"Default Interface"];
    
    _duEditing=NO;

    [[NSApplication sharedApplication] beginSheet:hostEditWindow
                                        modalForWindow:usersWindow
                                        modalDelegate:nil
                                        didEndSelector:NULL
                                        contextInfo:NULL];
}

- (IBAction)addUser:(id)sender
{
    [userEditSaveButton setTitle:NSLocalizedString(@"Add",@"")];
    [userEditName setStringValue:@""];
    [userEditPassword setStringValue:@""];
    [userEditName setEnabled:YES];
    [userEditService setEnabled:YES];

    _duEditing=NO;

    [self userChangeService:self];
    [[DUServiceInterface getServiceInterfaceFor:[userEditService titleOfSelectedItem]] clearUserView];

    [[NSApplication sharedApplication] beginSheet:userEditWindow
                                        modalForWindow:usersWindow
                                        modalDelegate:nil
                                        didEndSelector:NULL
                                        contextInfo:NULL];
}

- (IBAction)userSave:(id)sender {
    id <DUProxy> daemon=[DUAppController daemon];
    DUUser *theUser;
    DUServiceInterface *theServiceInterface=[DUServiceInterface getServiceInterfaceFor:[userEditService titleOfSelectedItem]];
    
    [[NSApplication sharedApplication] endSheet:userEditWindow];
    [userEditWindow orderOut:nil];
    
    if(_duEditing) {
        id item=[usersOutlineView itemAtRow:[usersOutlineView selectedRow]];
        
        [item setPassword:[userEditPassword stringValue]];
        [item saveUser];
        theUser=item;
    } else {
        theUser=[daemon addUserWithName:[userEditName stringValue] andPassword:[userEditPassword stringValue] andService:[_duServices objectForKey:[userEditService titleOfSelectedItem]]];
        [daemon saveUsers];
        [usersOutlineView reloadData];
    }

    [theServiceInterface validateUser:theUser];
    
    if(_duEditing&&(![daemon isPaused])) {
        [daemon daemonStart];
    }    
}

- (IBAction)userCancel:(id)sender {
    [[NSApplication sharedApplication] endSheet:userEditWindow];
    [userEditWindow orderOut:nil];
}

- (IBAction)userChangeService:(id)sender {
    NSRect newWinFrame, oldFrame, newFrame;
    float diffHeight, oldHeight, newHeight;
    NSView *newServiceView=[[DUServiceInterface getServiceInterfaceFor:[userEditService titleOfSelectedItem]] serviceUserView];

    
    oldFrame=[[userEditBox contentView] frame];
    newFrame=[userContentView frame];
    newFrame.size.height=oldFrame.size.height;
    [userContentView setFrame:newFrame];
    [userEditBox setContentView:userContentView];

    newHeight=NSHeight([newServiceView frame]);
    oldHeight=NSHeight([userContentView frame]);
    diffHeight=newHeight-oldHeight;

    if(diffHeight!=0.0) {        
        newWinFrame=[userEditWindow frame];
        newWinFrame.size.height+=diffHeight;
        newWinFrame.origin.y-=diffHeight;
        [userEditWindow setFrame:newWinFrame display:YES animate:[userEditWindow isVisible]];
    }
    [userEditBox setContentView:newServiceView];
}

- (void)hostChangeServiceTo:(DUServiceInterface *)theService {
    NSRect newWinFrame;
    float diffHeight, oldHeight, newHeight;
    NSView *newServiceView=[theService serviceHostView];
    NSView *oldServiceView;

    oldServiceView=[hostEditBox contentView];
    [oldServiceView removeFromSuperview];

    newHeight=NSHeight([newServiceView frame]);
    oldHeight=NSHeight([oldServiceView frame]);
    diffHeight=newHeight-oldHeight;

    if(diffHeight!=0.0) {
        newWinFrame=[hostEditWindow frame];
        newWinFrame.size.height+=diffHeight;
        newWinFrame.origin.y-=diffHeight;
        [hostEditWindow setFrame:newWinFrame display:YES];
    }

    [hostEditBox setContentView:newServiceView];
}

- (IBAction)editAction:(id)sender
{
    id item;

    if(usersOutlineView==sender) {
        if([usersOutlineView clickedRow]<0) {
            return;
        }
    }

    item=[usersOutlineView itemAtRow:[usersOutlineView selectedRow]];


    _duEditing=YES;
    
    if([item isUser]) {
        [userEditSaveButton setTitle:NSLocalizedString(@"Save",@"")];
        [userEditName setEnabled:NO];
        [userEditService setEnabled:NO];
        [userEditName setStringValue:[item getName]];
        [userEditPassword setStringValue:[item getPassword]];
        [userEditService selectItemWithTitle:[[item getService] getServiceName]];
        [self userChangeService:self];
        [[DUServiceInterface getServiceInterfaceFor:[[item getService] getServiceName]] prepareUserViewForUser:item];
        [[NSApplication sharedApplication] beginSheet:userEditWindow
                                            modalForWindow:usersWindow
                                            modalDelegate:nil
                                            didEndSelector:NULL
                                            contextInfo:NULL];
    
    } else {
        DUServiceInterface *theServiceInterface=[DUServiceInterface getServiceInterfaceFor:[[[(DUHost *)item user] getService] getServiceName]];

        [self hostChangeServiceTo:theServiceInterface];
        
        [theServiceInterface prepareHostViewForHost:item];
        
        [hostEditSaveButton setTitle:NSLocalizedString(@"Save",@"")];
        [hostEditName setStringValue:[item getName]];
        [hostEditInterface selectItemWithTitle:[[item interface] getName]];
    
        [[NSApplication sharedApplication] beginSheet:hostEditWindow
                                            modalForWindow:usersWindow
                                            modalDelegate:nil
                                            didEndSelector:NULL
                                            contextInfo:NULL];
    }
}

- (IBAction)openUsersWindow:(id)sender
{
    if(_firstLaunch) {
        [self initOutlineView];
        [self initServicesAndInterfaces];
        userToolbarItems=[[NSMutableDictionary dictionaryWithCapacity:5] retain];
        userToolbar=[[NSToolbar alloc] initWithIdentifier:@"DUUsersToolbar"];

        [userToolbar setDelegate:self];
        
        [usersWindow setToolbar:userToolbar];
        [self outlineViewSelectionDidChange:nil];
        //[self performSelector:@selector(outlineViewSelectionDidChange:) withObject:nil afterDelay:0];

        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(duDataUpdated:) name:DUDataUpdated object:nil];
        _firstLaunch=NO;
    }
    
    [usersWindow makeKeyAndOrderFront:self];
}

// Toolbar delegate methods
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    int row;
    if([[theItem itemIdentifier] isEqualToString:@"Add User"])
        return YES;

    row=[usersOutlineView selectedRow];
    if(row<0) {
        return NO;
    } else {
        return YES;
    }
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:@"Add User",@"Add Host",@"Remove",@"Edit",NSToolbarFlexibleSpaceItemIdentifier,NULL];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:@"Add User",@"Add Host",@"Edit",@"Remove",NULL];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *theItem;

    if(!(theItem=[userToolbarItems objectForKey:itemIdentifier])) {
        NSImage *itemImage=[NSImage imageNamed:itemIdentifier];
        theItem=[[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
        [userToolbarItems setObject:theItem forKey:itemIdentifier];
        [theItem setLabel:NSLocalizedString(itemIdentifier,@"")];
        [theItem setTarget:self];
        if(itemImage)
            [theItem setImage:itemImage];
        if([itemIdentifier isEqualToString:@"Add User"]) {
            [theItem setAction:@selector(addUser:)];
        } else if ([itemIdentifier isEqualToString:@"Add Host"]) {
            [theItem setAction:@selector(addHost:)];
        } else if ([itemIdentifier isEqualToString:@"Edit"]) {
            [theItem setAction:@selector(editAction:)];
        } else if ([itemIdentifier isEqualToString:@"Remove"]) {
            [theItem setAction:@selector(removeAction:)];
        }
    }
    return theItem;
}

- (void)duDataUpdated:(NSNotification *)theNotification {
    [_usersArray release];
    [_usersHosts release];
    _usersArray=[[[[DUAppController daemon] users] allValues] copy];
    _usersHosts=[[NSMutableDictionary alloc] initWithCapacity:1];
    [usersOutlineView reloadData];
}

- (void)removeUser:(NSWindow *)sheet returnCode:(int)returnCode 
contextInfo:(void *)contextInfo {
    if(returnCode != 0) {
        id item=[usersOutlineView itemAtRow:[usersOutlineView selectedRow]];

        [usersOutlineView collapseItem:item];
        
        [item removeUser];
    }
}

- (void)removeHost:(NSWindow *)sheet returnCode:(int)returnCode 
contextInfo:(void *)contextInfo {
    if(returnCode != 0) {
        id item=[usersOutlineView itemAtRow:[usersOutlineView selectedRow]];
        id <DUProxy> daemon=[DUAppController daemon];
        
        [daemon removeHost:item];
    }
}

- (IBAction)removeAction:(id)sender
{
    id item=[usersOutlineView itemAtRow:[usersOutlineView selectedRow]];

    if([item isUser]) {
        NSBeginAlertSheet(NSLocalizedString(@"Do you really want to remove this User?",@""), NSLocalizedString(@"Yes",@""),NSLocalizedString(@"No",@""), NULL, usersWindow, self, @selector(removeUser:returnCode:contextInfo:), NULL, NULL, NSLocalizedString(@"Removing is unrecoverable.",@""));
    } else {
        NSBeginAlertSheet(NSLocalizedString(@"Do you really want to remove this Host?",@""), NSLocalizedString(@"Yes",@""),NSLocalizedString(@"No",@""), NULL, usersWindow, self, @selector(removeHost:returnCode:contextInfo:), NULL, NULL, NSLocalizedString(@"Removing is unrecoverable.",@""));
    }
}

- (IBAction)hostSave:(id)sender {
    id item=[usersOutlineView itemAtRow:[usersOutlineView selectedRow]];
    id <DUProxy> daemon=[DUAppController daemon];

    [[NSApplication sharedApplication] endSheet:hostEditWindow];
    [hostEditWindow orderOut:nil];
    
    
    if(_duEditing) {
        [(DUHost *)item setName:[hostEditName stringValue]];
        [item setInterface:[_duInterfaces objectForKey:[hostEditInterface titleOfSelectedItem]]];

        [[DUServiceInterface getServiceInterfaceFor:[[[(DUHost *)item user] getService] getServiceName]] validateHost:item];
        
        [[(DUHost *)item user] saveUser];
        [usersOutlineView reloadData];

        if(![daemon isPaused]) {
            [daemon daemonStart];
        }
    } else {
        DUUser *theUser;
        DUHost *theHost;
        if(![item isUser]) {
            theUser=[(DUHost *)item user];
        } else {
            [usersOutlineView expandItem:item];
            theUser=item;
        }
        
        theHost=[daemon newHostWithName:[hostEditName stringValue] andInterface:[_duInterfaces objectForKey:[hostEditInterface titleOfSelectedItem]] forUser:theUser];

        [[DUServiceInterface getServiceInterfaceFor:[[theUser getService] getServiceName]] validateHost:theHost];

        [usersOutlineView reloadData];

        if(![daemon isPaused]) {
            [daemon daemonStart];
        }
    }
}

- (IBAction)hostCancel:(id)sender {
    [[NSApplication sharedApplication] endSheet:hostEditWindow];
    [hostEditWindow orderOut:nil];
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

    [_duServices release];
    [_duInterfaces release];
    
    [_usersArray release];
    [_usersHosts release];

    [hostContentView release];
    [userContentView release];
    
    [usersWindow release];
    [userEditWindow release];
    [hostEditWindow release];
    [userToolbarItems release];

    [super dealloc];
    
}

@end

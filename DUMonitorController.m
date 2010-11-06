#import "DUMonitorController.h"
#import "DUAppController.h"
#import "DUProtocols.h"
#import "DUUser.h"
#import "DUCommon.h"

NSDictionary *_textFieldAttributes=nil;
NSString *_longDateFormat=nil;
NSString *_shortDateFormat=nil;
NSTimer *_timer=nil;

@implementation DUMonitorController

- (void)initTable {
    NSButtonCell *dataCell=[[NSButtonCell alloc] init];
    
    [tableView setAutosaveName:@"DUMonitorTable"];
    [tableView setAutosaveTableColumns:YES];
    
    _shortDateFormat=[[[NSUserDefaults standardUserDefaults] stringForKey:NSShortDateFormatString] retain];
    _longDateFormat=[[NSString stringWithFormat:@"%@, %@",_shortDateFormat,
                                            [[NSUserDefaults standardUserDefaults]
                                                                    stringForKey:NSTimeFormatString]] retain];
    
    [dataCell setButtonType:NSSwitchButton];
    [dataCell setImagePosition:NSImageOnly];
    
    [activeColumn setDataCell:[dataCell autorelease]];
    [[hostnameColumn dataCell] setEditable:NO];
    _textFieldAttributes=[[[[hostnameColumn dataCell] attributedStringValue] fontAttributesInRange:NSMakeRange(0,0)] retain];
    [[userColumn dataCell] setEditable:NO];
    [[ipColumn dataCell] setEditable:NO];
    [[lastUpdateColumn dataCell] setEditable:NO];
    [[statusColumn dataCell] setEditable:NO];
    [tableView setDataSource:self];
}

- (void)updateData {
    id <DUProxy> daemon=[DUAppController daemon];
    NSEnumerator *userEnumerator=[[daemon users] objectEnumerator];
    DUUser *user;

    if(data) {
        [data release];
        [keys release];
    }
    
    data=[[NSMutableDictionary alloc] initWithCapacity:1];
    keys=[[NSMutableArray alloc] initWithCapacity:1];

    while(user=[userEnumerator nextObject]) {
        NSEnumerator *hostEnumerator=[[user hosts] objectEnumerator];
        DUHost *host;
        
        while(host=[hostEnumerator nextObject]) {
            [self updateHost:host];
        }
    }
    [tableView reloadData];
    if([daemon isPaused]) {
        [pauseButton setTitle:NSLocalizedString(@"Start DNSUpdate daemon",@"")];
        [statusField setStringValue:NSLocalizedString(@"Daemon is paused.",@"")];
    } else {
        [pauseButton setTitle:NSLocalizedString(@"Pause DNSUpdate daemon",@"")];
        [statusField setStringValue:NSLocalizedString(@"Daemon is running.",@"")];
    }
}

- (void)loadData {
    [self initTable];
    
    [self updateData];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(duDataUpdated:) name:DUDataUpdated object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(duUpdating:) name:DUUpdating object:nil];
}

- (void)duDataUpdated:(NSNotification *)theNotification {
    [self updateData];
}

- (void)duUpdating:(NSNotification *)theNotification {
    [statusField setStringValue:NSLocalizedString(@"Updating...",@"")];
}

- (IBAction)openMonitorWindow:(id)sender {
    if(!data)
        [self loadData];
    [monitorWindow makeKeyAndOrderFront:self];
}

- (IBAction)pauseDaemon:(id)sender {
    id <DUProxy> daemon=[DUAppController daemon];
    
    if([daemon isPaused])
        [daemon daemonStart];
    else
        [daemon pause];
    [self updateData];
}

- init {
    data=nil;
    return self;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [keys count];
}

- tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row {
    if(col==activeColumn) {
        return [[data objectForKey:[keys objectAtIndex:row]] objectForKey:@"Active"];
    } else if(col==hostnameColumn) {
        return [[data objectForKey:[keys objectAtIndex:row]] objectForKey:@"Hostname"];
    } else if(col==userColumn) {
        NSDictionary *theLine=[data objectForKey:[keys objectAtIndex:row]];
        
        if([col width]>[[theLine objectForKey:@"UserLength"] floatValue])
            return [theLine objectForKey:@"User"];
        else
            return [theLine objectForKey:@"ShortUser"];
    } else if(col==ipColumn) {
        return NSLocalizedString([[data objectForKey:[keys objectAtIndex:row]] objectForKey:@"IP"],@"");
    } else if(col==lastUpdateColumn) {
        NSDictionary *theLine=[data objectForKey:[keys objectAtIndex:row]];
        
        if([col width]>[[theLine objectForKey:@"DateLength"] floatValue])
            return [theLine objectForKey:@"LastUpdate"];
        else
            return [theLine objectForKey:@"ShortLastUpdate"];
    } else if(col==statusColumn) {
        return NSLocalizedString([[data objectForKey:[keys objectAtIndex:row]] objectForKey:@"Status"],@"");
    } else
        return @"-- Error --";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)col row:(int)row {
    NSMutableDictionary *hostDict=[data objectForKey:[keys objectAtIndex:row]];
    DUHost *host=[hostDict objectForKey:@"Host"];
    id <DUProxy> daemon=[DUAppController daemon];
    
    [host setActive:![host isActive]];
    [hostDict setObject:[NSNumber numberWithBool:[host isActive]] forKey:@"Active"];
    [[host user] saveUser];
    
    if(![daemon isPaused])
        [daemon daemonStart];
}

- (void)updateHost:(DUHost *)host {
    DUUser *user=[host user];
    NSString *key=[NSString stringWithFormat:@"%@//%@",host,user];
    NSMutableDictionary *hostStatus=[data objectForKey:key];
    NSDate *lastUpdate;
    NSString *hostAddress=[host getAddress];
    
    if(!hostStatus) {
        hostStatus=[[[NSMutableDictionary alloc] initWithCapacity:8] autorelease];
        [data setObject:hostStatus forKey:key];
        [keys addObject:key];
    } 
    [hostStatus setObject:[host getName] forKey:@"Hostname"];

    if([hostAddress isEqualToString: @"111.111.111.111"]) {
        [hostStatus setObject:@"Offline" forKey:@"IP"];
    } else {
        [hostStatus setObject:[host getAddress] forKey:@"IP"];
    }
    
    lastUpdate=[host lastUpdate];
    if([lastUpdate isEqualToDate:[NSDate distantPast]]) {
        [hostStatus setObject:NSLocalizedString(@"N/A",@"") forKey:@"ShortLastUpdate"];
        [hostStatus setObject:NSLocalizedString(@"Never registered",@"") forKey:@"LastUpdate"];
    } else {
        [hostStatus setObject:[lastUpdate descriptionWithCalendarFormat:_shortDateFormat timeZone:nil locale:nil]
                    forKey:@"ShortLastUpdate"];
        [hostStatus setObject:[lastUpdate descriptionWithCalendarFormat:_longDateFormat timeZone:nil locale:nil]
                    forKey:@"LastUpdate"];
    }
    [hostStatus setObject:[NSNumber numberWithFloat:
                                [[hostStatus objectForKey:@"LastUpdate"] sizeWithAttributes:_textFieldAttributes].width]
                forKey:@"DateLength"];
                
    [hostStatus setObject:[user description] forKey:@"User"];
    [hostStatus setObject:[NSNumber numberWithFloat:[[user description] sizeWithAttributes:_textFieldAttributes].width] 
                forKey:@"UserLength"];
    [hostStatus setObject:[user getName] forKey:@"ShortUser"];
    
    [hostStatus setObject:[NSNumber numberWithBool:[host isActive]] forKey:@"Active"];
    
    [hostStatus setObject:[host hostStatus] forKey:@"Status"];
    
    [hostStatus setObject:host forKey:@"Host"];
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

    [keys release];
    [data release];
    [monitorWindow release];
    
    [super dealloc];
}

@end

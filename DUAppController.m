#import "DUAppController.h"
#import "DUMonitorController.h"
#import "DUUsersController.h"
#import "DUClient.h"
#import "DUCommon.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#include <sys/types.h>
#include <unistd.h>
#include <grp.h>
#include <pwd.h>

#define USERDEBUG 1

NSConnection *duConnection=nil;
NSObject <DUProxy> *duDaemon=nil;

#define DAEMONPATH @"/usr/local/sbin/dnsupdate"

BOOL duIsHelpLoaded=NO;
BOOL duHasInstalled=NO;

BOOL isAdmin()
{
    struct group *adminGroup;
    BOOL returnValue=NO;
    int uid=getuid();
    
    if(uid==0) {
        return YES;
    }
    else {
    
    adminGroup=getgrnam("admin");
    if(adminGroup) {
        char **user=adminGroup->gr_mem;
        while((*user)&&(!returnValue)) {
            struct passwd *userPwd;
                
            userPwd=getpwnam(*user);

            if(userPwd) {
                if(userPwd->pw_uid==uid) returnValue=YES;
            }
                        
            user++;
        }
    }
    
    }
    return returnValue;
}

@implementation DUAppController

- (void)setConnection:(NSConnection *)theConnection {
    NSLog(@"Setting connection");
    duConnection=[theConnection retain];
}

+ (id <DUProxy>) daemon {
    return duDaemon;
}

- (void)launchDaemon {
    AuthorizationRef authorizationRef=NULL;
    AuthorizationRights rights;
    AuthorizationRights *authorizedRights;
    AuthorizationFlags flags;
    AuthorizationItem items[1];
    char *launchDaemonPath = (char *)[[[NSBundle mainBundle] pathForResource:@"startDaemon" ofType:@"py"] UTF8String];
    OSStatus err = 0;
    char *args[1];
    FILE *communicationsPipe=NULL;
    
    // Using security framework
    
    rights.count=0;
    rights.items = NULL;
    
    flags = kAuthorizationFlagDefaults;

    err = AuthorizationCreate(&rights,
                            kAuthorizationEmptyEnvironment, flags,
                            &authorizationRef);
    
    items[0].name = kAuthorizationRightExecute;
    items[0].value = "/usr/bin/python";
    items[0].valueLength = strlen(items[0].value);
    items[0].flags = 0;
    
    rights.count=1;
    rights.items = items;
    
    flags = kAuthorizationFlagInteractionAllowed 
                | kAuthorizationFlagExtendRights;

    // Get the root rights
    err = AuthorizationCopyRights(authorizationRef,&rights,
                        kAuthorizationEmptyEnvironment,
                        flags,&authorizedRights);

    if(err != errAuthorizationSuccess) {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Can't start daemon",@""),NSLocalizedString(@"DNSUpdate needs administrator privileges to start the daemon.",@""),NSLocalizedString(@"Quit",@""),nil,nil);
        [NSApp terminate:self];
    }
    
    AuthorizationFreeItemSet(authorizedRights);

    args[0]=launchDaemonPath;
    args[1]=NULL;
    
    // Launch the daemon

    NSLog(@"Launching daemon");
    [launchProgressIndicator startAnimation:self];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(daemonIsLaunched:) name:DUDaemonLaunched object:nil];
    
    NSLog(@"Executing %s %s %s", items[0].value, args[0], args[1]);
    err = AuthorizationExecuteWithPrivileges(authorizationRef,
                                            "/usr/bin/python",
                                            0,
                                            args,
                                            &communicationsPipe);

#ifdef USERDEBUG
    NSLog(@"Launching debug:");
    for(;;) {
        char s[30];
        int i;
        i = fread(s, sizeof(char), 20, communicationsPipe);
        if(i<=0) break;
        fwrite(s, sizeof(char), i, stdout);
    }
#endif
    
    [NSApp runModalForWindow:launchPanel];
    
    [launchProgressIndicator stopAnimation:self];
    [launchPanel orderOut:self];
}

- (void)daemonIsLaunched:(NSNotification *)theNotification {
    NSLog(@"Daemon is launched");
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [NSApp abortModal];
    //[launchPanel orderOut:self];
}

- (BOOL)installDaemon {
    NSFileManager *fm=[NSFileManager defaultManager];
    NSString *daemonInBundle=[[NSBundle mainBundle] pathForResource:@"dnsupdate" ofType:nil];
    BOOL installDaemon=NO;
    
    // test if the daemon is installed or
    // if the version of the bundled daemon is the same as the installed one
    NSLog(@"Testing the installed daemon");
    
    if(![fm fileExistsAtPath:DAEMONPATH])
        installDaemon=YES;
    else {
        NSTask *testDaemon=[[NSTask alloc] init];
        NSPipe *testOutput=[NSPipe pipe];
        NSFileHandle *outputHandle=[testOutput fileHandleForReading];
        NSString *daemonMagic;
        
        [testDaemon setLaunchPath:DAEMONPATH];
        [testDaemon setArguments:[NSArray arrayWithObject:@"magic"]];
        [testDaemon setStandardOutput:testOutput];

        NSLog(@"Testing magic with <%@ %@>",[testDaemon launchPath],[testDaemon arguments]);
        
        [testDaemon launch];
        
        daemonMagic=[[NSString alloc] initWithData:[outputHandle readDataToEndOfFile]
                                        encoding:NSASCIIStringEncoding];

        NSLog(@"Installed daemon : %@",daemonMagic);
        if([daemonMagic isEqualToString:UserAgent]) {
            NSLog(@"Installed daemon is the good one");
        } else {
            NSLog(@"Installed daemon will be updated. Will install daemon with version %@",UserAgent);
            installDaemon=YES;
        }
        
        [daemonMagic release];
        [testDaemon release];
    }
    
    if(installDaemon) {
        AuthorizationRef authorizationRef=NULL;
        AuthorizationRights rights;
        AuthorizationRights *authorizedRights;
        AuthorizationFlags flags;
        AuthorizationItem items[1];
        char *installToolPath = (char *)[[[NSBundle mainBundle] pathForResource:@"duInstallDaemon" ofType:@"py"] UTF8String];
        OSStatus err = 0;
        char *args[3];
        FILE *communicationsPipe=NULL;
        
        // Using security framework

        rights.count=0;
        rights.items = NULL;
        
        flags = kAuthorizationFlagDefaults;
    
        err = AuthorizationCreate(&rights,
                                kAuthorizationEmptyEnvironment, flags,
                                &authorizationRef);

        NSLog(@"Installing daemon in %@",DAEMONPATH);
        NSRunAlertPanel(NSLocalizedString(@"DNSUpdate needs to install the daemon.",@""),NSLocalizedString(@"DNSUpdate will install the daemon and a Startup item in order to be launched at boot time.",@""),NSLocalizedString(@"Install",@""),nil,nil);
        
        items[0].name = kAuthorizationRightExecute;
        items[0].value = "/usr/bin/python";
        items[0].valueLength = strlen(items[0].value);
        items[0].flags = 0;
        
        rights.count=1;
        rights.items = items;
        
        flags = kAuthorizationFlagInteractionAllowed 
                    | kAuthorizationFlagExtendRights;

        // Quit the daemon if running
        system([[NSString stringWithFormat:@"\"%@\" quit",daemonInBundle] UTF8String]);

        // Get the root rights
        err = AuthorizationCopyRights(authorizationRef,&rights,
                            kAuthorizationEmptyEnvironment,
                            flags,&authorizedRights);

        if(err != errAuthorizationSuccess) {
            NSRunCriticalAlertPanel(NSLocalizedString(@"Can't install daemon",@""),NSLocalizedString(@"DNSUpdate needs administrator privileges to install the daemon.",@""),NSLocalizedString(@"Quit",@""),nil,nil);
            [NSApp terminate:self];
        }
        
        AuthorizationFreeItemSet(authorizedRights);

        args[0]=installToolPath;
        args[1]=(char *)[daemonInBundle UTF8String];
        args[2]=NULL;
        
        NSLog(@"Executing %s %s %s", items[0].value, args[0], args[1]);
        // Install the new daemon
        
        NSLog(@"Installing and Launching daemon");
        [launchProgressIndicator startAnimation:self];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(daemonIsLaunched:) name:DUDaemonLaunched object:nil];

        err = AuthorizationExecuteWithPrivileges(authorizationRef,
                                                "/usr/bin/python",
                                                0,
                                                args,
                                                &communicationsPipe);

#ifdef USERDEBUG
        NSLog(@"Installation debug:");
        for(;;) {
            char s[30];
            int i;
            i = fread(s, sizeof(char), 20, communicationsPipe);
            if(i<=0) break;
            fwrite(s, sizeof(char), i, stdout);
        }
#endif
        [NSApp runModalForWindow:launchPanel];
        
        [launchProgressIndicator stopAnimation:self];
        [launchPanel orderOut:self];
        
#if 0
        NSRunAlertPanel(NSLocalizedString(@"DNSUpdate daemon was succesfully installed.",@""),NSLocalizedString(@"Due to some (yet) unresolved problem in DNSUpdate code, the daemon will unexpectedly quit if you log out this session. Rebooting will launch the daemon in a much better state.",@""),NSLocalizedString(@"Ok",@""),nil,nil);
#else
        NSRunAlertPanel(NSLocalizedString(@"DNSUpdate daemon was succesfully installed.",@""),@"",NSLocalizedString(@"Ok",@""),nil,nil);
#endif

    }
    
    duHasInstalled=installDaemon;
    
    return installDaemon;
}

- (void)getDaemon {
    BOOL hasInstalled=[self installDaemon];

    if(!isAdmin()) {
        NSRunCriticalAlertPanel(NSLocalizedString(@"DNSUpdate must be used by Administrator Users.",@""),NSLocalizedString(@"In order to connect to the daemon, DNSUpdate has to be launched by an Administrator.",@""),NSLocalizedString(@"Quit",@""),nil,nil);
        [NSApp terminate:self];
    }
    NSLog(@"Connecting to daemon");
    duDaemon=[DUClient connectAndGetDaemonFor:self];
    [duDaemon retain];
    if(!duDaemon) {
        if(!hasInstalled) {
            NSRunAlertPanel(NSLocalizedString(@"Can't connect to daemon",@""),NSLocalizedString(@"Can't connect to daemon. DNSUpdate will try to launch it.",@""),NSLocalizedString(@"Launch",@""),nil,nil);
            [self launchDaemon];
            duDaemon=[DUClient connectAndGetDaemonFor:self];
            [duDaemon retain];
        }
        if(!duDaemon) {
            NSRunCriticalAlertPanel(NSLocalizedString(@"Can't connect to daemon",@""),NSLocalizedString(@"Daemon refused the connection.\nThere must be a problem with the daemon. Try relaunching the application later.",@""),NSLocalizedString(@"Quit",@""),nil,nil);
            [NSApp terminate:self];
        }
        NSRunAlertPanel(NSLocalizedString(@"DNSUpdate daemon was succesfully launched.",@""),NSLocalizedString(@"Due to some (yet) unresolved problem in DNSUpdate code, the daemon will unexpectedly quit if you log out this session. Rebooting will launch the daemon in a much better state.",@""),NSLocalizedString(@"Ok",@""),nil,nil);
    }
    [duDaemon registerAsApplication:self];
}

- (void)connectionDidDie:theConnection
{
    NSRunCriticalAlertPanel(NSLocalizedString(@"Connection with Daemon Error",@""),NSLocalizedString(@"The connection with the daemon was lost.\nThere must be a problem with the daemon.",@""),NSLocalizedString(@"Quit",@""),nil,nil);
    [NSApp terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *userDefaults=[NSUserDefaults standardUserDefaults];
    NSFileManager *fm=[NSFileManager defaultManager];

    if(![fm fileExistsAtPath:@"/usr/bin/nohup"]) {
        NSRunCriticalAlertPanel(NSLocalizedString(@"The BSD package is not installed",@""),NSLocalizedString(@"DNSUpdate needs the BSD package.\nThe BSD package is available on the MacOS X Install CD. Install it and retry to launch DNSUpdate.",@""),NSLocalizedString(@"Quit",@""),nil,nil);
        [NSApp terminate:self];
    }
    [self getDaemon];

    [userDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithBool:YES], @"DUUsersWindowIsVisible",
                        [NSNumber numberWithBool:NO], @"DUMonitorWindowIsVisible",
                        [NSNumber numberWithBool:NO], @"DUSupportAlreadyShowed",
                        nil]];
    
    if(duHasInstalled||(![userDefaults boolForKey:@"DUSupportAlreadyShowed"])) {
        [self supportOpen:self];
        [userDefaults setBool:YES forKey:@"DUSupportAlreadyShowed"];
    }
    

    [usersWindow setFrameAutosaveName:@"DUUserWindow"];
    [monitorWindow setFrameAutosaveName:@"DUMonitorWindow"];
    
    if([userDefaults boolForKey:@"DUUsersWindowIsVisible"])
        [usersController openUsersWindow:self];
    if([userDefaults boolForKey:@"DUMonitorWindowIsVisible"])
        [monitorController openMonitorWindow:self];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDockMenu:) name:DUDataUpdated object:nil];
    [self updateDockMenu:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if(duDaemon) {
        NSUserDefaults *userDefaults=[NSUserDefaults standardUserDefaults];
        [duDaemon release];
        [userDefaults setBool:[usersWindow isVisible] forKey:@"DUUsersWindowIsVisible"];
        [userDefaults setBool:[monitorWindow isVisible] forKey:@"DUMonitorWindowIsVisible"];
    }
    
    [monitorController release];
    [usersController release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
        
    [duConnection release];

    return NSTerminateNow;
}

- (IBAction)uninstallDNSUpdate:sender {
        AuthorizationRef authorizationRef=NULL;
        AuthorizationRights rights;
        AuthorizationRights *authorizedRights;
        AuthorizationFlags flags;
        AuthorizationItem items[1];
        char *args[2];
        char *uninstallToolPath = (char *)[[[NSBundle mainBundle] pathForResource:@"duUninstallDaemon" ofType:@"py"] UTF8String];
        OSStatus err = 0;
        FILE *communicationsPipe=NULL;
        
        NSLog(@"Uninstalling DNSUpdate daemon");

        // Using security framework
        rights.count=0;
        rights.items = NULL;
        
        flags = kAuthorizationFlagDefaults;
    
        err = AuthorizationCreate(&rights,
                                kAuthorizationEmptyEnvironment, flags,
                                &authorizationRef);

        
        items[0].name = kAuthorizationRightExecute;
        items[0].value = "/usr/bin/python";
        items[0].valueLength = strlen(items[0].value);
        items[0].flags = 0;

        args[0]=uninstallToolPath;
        args[1]=NULL;
        
        rights.count=1;
        rights.items = items;
        
        flags = kAuthorizationFlagInteractionAllowed 
                    | kAuthorizationFlagExtendRights;

        // Get the root rights
        err = AuthorizationCopyRights(authorizationRef,&rights,
                            kAuthorizationEmptyEnvironment,
                            flags,&authorizedRights);

        if(err != errAuthorizationSuccess) {
            NSRunCriticalAlertPanel(NSLocalizedString(@"Can't uninstall daemon",@""),NSLocalizedString(@"DNSUpdate needs administrator privileges to uninstall the daemon.",@""),NSLocalizedString(@"Ok",@""),nil,nil);
            return;
        }
        
        AuthorizationFreeItemSet(authorizedRights);
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        // Uninstall the new daemon
        
        NSLog(@"Executing %s %s %s", items[0].value, args[0], args[1]);
        err = AuthorizationExecuteWithPrivileges(authorizationRef,
                                                "/usr/bin/python",
                                                0,
                                                args,
                                                &communicationsPipe);
        NS_DURING
#ifdef USERDEBUG
            NSLog(@"Uninstallation debug:");
            for(;;) {
                char s[30];
                int i;
                i = fread(s, sizeof(char), 20, communicationsPipe);
                if(i<=0) break;
                fwrite(s, sizeof(char), i, stdout);
            }
#endif
            
            NSRunAlertPanel(NSLocalizedString(@"DNSUpdate is now uninstalled.",@""),NSLocalizedString(@"You can now remove the DNSUpdate application, the DNSUpdate Users files, etc. DNSUpdate will now quit.",@""),NSLocalizedString(@"Quit",@""),nil,nil);
        NS_HANDLER
        NS_ENDHANDLER
        
        [NSApp terminate:self];

}

- (IBAction)openHelp:sender {
    if(!duIsHelpLoaded) {
        duIsHelpLoaded=[helpTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"DNSUpdateHelp" ofType:@"rtfd"]];
    }
    [helpWindow makeKeyAndOrderFront:self];
}

- (IBAction)pauseDaemon:sender {
    if([duDaemon isPaused])
        [duDaemon daemonStart];
    else
        [duDaemon pause];
}

- (IBAction)openLogFile:sender {
    [[NSWorkspace sharedWorkspace] openFile:@"/var/log/dnsupdate.log"];
}

- (void)updateDockMenu:(NSNotification *)theNotification {
    if([duDaemon isPaused]) {
        [pauseMenuItem setTitle:NSLocalizedString(@"Start Daemon",@"")];
    } else {
        [pauseMenuItem setTitle:NSLocalizedString(@"Pause Daemon",@"")];
    }
}

- (IBAction)supportOpen:sender {
    [supportWindow makeKeyAndOrderFront:self];
    
    [NSApp runModalForWindow:supportWindow];
    
}

- (IBAction)supportPay:sender {
    [NSApp stopModal];
    [supportWindow orderOut:self];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/xclick/business=donation%40dnsupdate.org&item_name=support+DNSUpdate&item_number=DNSUpdate&no_shipping=1&return=http%3A//www.dnsupdate.org/PaymentThanks.html"]];
}

- (IBAction)supportContact:sender {
    [NSApp stopModal];
    [supportWindow orderOut:self];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?subject=%@",@"mailto:help-proposal@dnsupdate.org",NSLocalizedString(@"SupportMailSubject",@"")]]];
}

- (IBAction)supportLater:sender {
    [NSApp stopModal];
    [supportWindow orderOut:self];
}

- (IBAction)openPreferencesWindow:sender {
    [startOptionRadioButtons selectCellWithTag:[duDaemon startOption]];
    [preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)setStartOption:sender {
    [duDaemon setStartOption:[[startOptionRadioButtons selectedCell] tag]];
}

@end

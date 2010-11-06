//
//  DUDynDNSInterface.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Mon Feb 11 2002.
//  Copyright (c) 2002 Julien Jalon. All rights reserved.
//

#import "DUDynDNSInterface.h"


@implementation DUDynDNSInterface

- (NSString *)getServiceName {
    return @"DynDNS.org";
}

- (void)validateUser:(DUUser *)theUser {
    // Must be implemented by subclass
}

- (void)validateHost:(DUHost *)theHost {
    [theHost setHostProperty:[hostDynDNSType titleOfSelectedItem] forKey:@"system" internalProperty:NO];
    if([[hostDynDNSMXField stringValue] isEqualToString:@""]) {
        [theHost setHostProperty:nil forKey:@"mx" internalProperty:NO];
    } else {
        [theHost setHostProperty:[hostDynDNSMXField stringValue] forKey:@"mx" internalProperty:NO];
    }
    if([hostDynDNSWildCard state]==NSOnState) {
        [theHost setHostProperty:@"ON" forKey:@"wildcard" internalProperty:NO];
    } else {
        [theHost setHostProperty:@"OFF" forKey:@"wildcard" internalProperty:NO];
    }
    if([hostDynDNSBackMX state]==NSOnState) {
        [theHost setHostProperty:@"YES" forKey:@"backmx" internalProperty:NO];
    } else {
        [theHost setHostProperty:@"NO" forKey:@"backmx" internalProperty:NO];
    }    
}

- (void)prepareHostViewForHost:(DUHost *)theHost {
    id dyndnsType=[theHost hostPropertyForKey:@"system"];

    if(!dyndnsType) {
        [hostDynDNSType selectItemWithTitle:@"dyndns"];
        [hostDynDNSWildCard setState:NSOffState];
        [hostDynDNSBackMX setState:NSOffState];
        [hostDynDNSMXField setStringValue:@""];
    } else {
        [hostDynDNSType selectItemWithTitle:dyndnsType];
        if([[theHost hostPropertyForKey:@"wildcard"] isEqualToString:@"ON"]) {
            [hostDynDNSWildCard setState:NSOnState];
        } else {
            [hostDynDNSWildCard setState:NSOffState];
        }
        if([[theHost hostPropertyForKey:@"backmx"] isEqualToString:@"YES"]) {
            [hostDynDNSBackMX setState:NSOnState];
        } else {
            [hostDynDNSBackMX setState:NSOffState];
        }
        if([theHost hostPropertyForKey:@"mx"]) {
            [hostDynDNSMXField setStringValue:[theHost hostPropertyForKey:@"mx"]];
        } else {
            [hostDynDNSMXField setStringValue:@""];
        }
    }
}

- (void)prepareUserViewForUser:(DUUser *)DUUser {
    // Must be implemented by subclass
}

- (void)clearHostView {
    [hostDynDNSType selectItemWithTitle:@"dyndns"];
    [hostDynDNSWildCard setState:NSOffState];
    [hostDynDNSBackMX setState:NSOffState];
    [hostDynDNSMXField setStringValue:@""];
}

- (void)clearUserView {
    // Must be implemented by subclass
}

- (IBAction)goToDynDNS:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.dyndns.org/"]];
}

@end

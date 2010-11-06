//
//  DUZoneEditInterface.m
//  DNSUpdate2
//
//  Created by Julien Jalon on Tue Feb 12 2002.
//  Copyright (c) 2002 Julien Jalon. All rights reserved.
//

#import "DUZoneEditInterface.h"


@implementation DUZoneEditInterface

- (NSString *)getServiceName {
    return @"ZoneEdit.com";
}

- (IBAction)goToZoneEdit:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.zoneedit.com/"]];
}

@end

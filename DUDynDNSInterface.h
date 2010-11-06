//
//  DUDynDNSInterface.h
//  DNSUpdate2
//
//  Created by Julien Jalon on Mon Feb 11 2002.
//  Copyright (c) 2002 Julien Jalon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DUServiceInterface.h"

@interface DUDynDNSInterface : DUServiceInterface {
    IBOutlet id hostDynDNSType;
    IBOutlet id hostDynDNSWildCard;
    IBOutlet id hostDynDNSBackMX;
    IBOutlet id hostDynDNSMXField;    
}

- (IBAction)goToDynDNS:(id)sender;

@end

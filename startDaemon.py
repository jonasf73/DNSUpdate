#!/usr/bin/python

import os, sys

def ossystem(x):
    print x
    os.system(x)
    
print "Starting DNSUpdate daemon"

if os.geteuid() != os.getuid():
    print "Setting real user id"
    os.setuid(os.geteuid());

print "Loading org.dnsupdate.daemon"
ossystem("/bin/launchctl load /Library/LaunchDaemons/org.dnsupdate.daemon.plist")
print "Starting org.dnsupdate.daemon"
ossystem("/bin/launchctl start org.dnsupdate.daemon")
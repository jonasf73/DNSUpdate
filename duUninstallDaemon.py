#!/usr/bin/python

import os, sys

def ossystem(x):
    print x
    os.system(x)

print "Running DNSUpdate daemon uninstall"

if os.geteuid() != os.getuid():
    print "Setting real user id"
    os.setuid(os.geteuid());

print "Unloading org.dnsupdate.daemon"
ossystem("/bin/launchctl unload /Library/LaunchDaemons/org.dnsupdate.daemon.plist")
print "Removing org.dnsupdate.daemon.plist"
ossystem("/bin/rm -rf /Library/LaunchDaemons/org.dnsupdate.daemon.plist")
print "Removing /usr/local/sbin/dnsupdate"
ossystem("/bin/rm -rf /usr/local/sbin/dnsupdate")

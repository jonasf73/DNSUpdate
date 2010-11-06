#!/usr/bin/python

import os, sys

def ossystem(x):
    print x
    os.system(x)
    
print "Running DNSUpdate daemon installation"

argv = sys.argv

if len(argv) != 2:
    print "Bad arguments: %s" % (argv, )
    sys.exit(1)
    
daemon_path = argv[1]
resource_path = os.path.dirname(daemon_path)
resource_path = resource_path.replace("\\", "\\\\")
resource_path = resource_path.replace("\"", "\\\"")
daemon_path = daemon_path.replace("\\", "\\\\")
daemon_path = daemon_path.replace("\"", "\\\"")

if os.geteuid() != os.getuid():
    print "Setting real user id"
    os.setuid(os.geteuid());
    
print "Unload org.dnsupdate.daemon if necessary"

old_mask = os.umask(0022)

ossystem("/bin/launchctl unload /Library/LaunchDaemons/org.dnsupdate.daemon.plist")

print "Killing any remaining daemon"

ossystem("/usr/bin/killall dnsupdate")

print "Installing daemon in /usr/local/sbin/dnsupdate from %s" % (daemon_path, )
ossystem("/bin/cp -f \"%s\" /usr/local/sbin/dnsupdate" % (daemon_path,))

try:
    os.stat("/usr/local/sbin")
except:
    print "Creating /usr/local/sbin"
    ossystem("/bin/mkdir -p /usr/local/sbin")
    
try:
    os.stat("/Library/StartupItems/DNSUpdate")
    ossystem("/bin/rm -rf /Library/StartupItems/DNSUpdate")
except:
    pass
    
print "Installing org.dnsupdate.daemon.plist from %s" % (resource_path, )

ossystem("/bin/mkdir -p /Library/LaunchDaemons")
ossystem("/bin/cp -f \"%s/org.dnsupdate.daemon.plist\" /Library/LaunchDaemons/" % (resource_path, ))

print "Launching daemon"

ossystem("/bin/launchctl load /Library/LaunchDaemons/org.dnsupdate.daemon.plist")

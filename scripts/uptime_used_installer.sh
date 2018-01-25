#!/bin/bash

# ======================================
#		Uptime_Used.php Installer
# ======================================
# This script works on debian based 
# machines and is intended to install
# and setup the required depends to run
# the uptime_used.php file.
# Make sure that you run this via:
#         sudo -or- root
#
# ======================================
# By: Cameron Munroe ~ Mun
# site: https://www.qwdsa.com/threads/serverstatus-rebuild.43/
# mysite: https://www.cameronmunroe.com/
#
# Ver: 1.4
# ======================================
#		Changelog
# ======================================

# Ver 1.4
# ======================================
# added ipv6 support on port 8081

# Ver 1.3
# ======================================
# Patched adduser command

# Ver 1.2
# ======================================
# Launched uptime_used.php at end of 
# file so that you don't have to start
# it by hand. Assuming you don't proptly
# restart the server.

# Ver 1.1
# ======================================
# Fixed the add account command

# Ver 1.0 
# ======================================
# Initial Commit


# ======================================
#		Notes
# ======================================

# Currently only works on debian and
# ubuntu machines.
# This will install php5-cli and screen.
# The daemon will run on port 8080.
# If you run iptables or a firewall
# you will need to confifure it!.
# This will also make an account called
# serverstatus to run the daemon.



# ======================================
#		Depends
# ======================================


apt-get update > /dev/null
apt-get install screen -y > /dev/null
apt-get install php5-cli -y > /dev/null

# ======================================
# 		Setup account
# ======================================

adduser --quiet --disabled-login --gecos "" serverstatus

# ======================================
#		Get files
# ======================================

cd /tmp
#
# Fun fact, github doesn't have ipv6 support
# So we get to use my gitlab for this....
#
wget -q https://git.enjen.net/Munzy/ServerStatus/raw/Munzy/uptime_used.php --no-check-certificate >/dev/null
mv /tmp/uptime_used.php /home/serverstatus/uptime_used.php
chown serverstatus:serverstatus /home/serverstatus/uptime_used.php


# ======================================
#		Install rc.local launcher
# ======================================

if grep -q 'su - serverstatus -c "screen -d -m php -S 0.0.0.0:8080 /home/serverstatus/uptime_used.php"' '/etc/rc.local'; then
	echo "skipping..."
else
	sed -i -e '$i \su - serverstatus -c "screen -d -m php -S 0.0.0.0:8080 /home/serverstatus/uptime_used.php"\n' /etc/rc.local
fi

if grep -q 'su - serverstatus -c "screen -d -m php -S [\'::\']:8081 /home/serverstatus/uptime_used.php"' '/etc/rc.local'; then
	echo "skipping..."
else
	sed -i -e '$i \su - serverstatus -c "screen -d -m php -S [\'::\']:8080 /home/serverstatus/uptime_used.php"\n' /etc/rc.local
fi


# ======================================
#		Launch it!
# ======================================

su - serverstatus -c "screen -d -m php -S 0.0.0.0:8080 /home/serverstatus/uptime_used.php"
su - serverstatus -c "screen -d -m php -S ['::']:8081 /home/serverstatus/uptime_used.php"


# ======================================
# 		Done
# ======================================

echo "# ======================================"
echo " \     Uptime_used.php Installed       /"
echo "# ======================================"
echo " \    Make sure to configure your      /"
echo " \     firewall and serverstatus       /"
echo " \              Enjoy!                 /"
echo "# ======================================"
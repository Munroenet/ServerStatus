#!/bin/bash

# ======================================
#		Uptime.php Installer
# ======================================
# This script works on debian based 
# machines and is intended to install
# and setup the required depends to run
# the uptime.php file.
# Make sure that you run this via:
#         sudo -or- root
#
# ======================================
# By: Cameron Munroe ~ Mun
# site: https://www.qwdsa.com/c/threads/serverstatus-rebuild.43/
# mysite: http://www.cameronmunroe.com/
#
# Ver: 1.3
# ======================================
#		Changelog
# ======================================

# Ver 1.3
# ======================================
# Patched adduser command


# Ver 1.0 
# ======================================
# Initial Commit based on 1.2 of 
# uptime_used_installer.sh



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
wget -q https://git.enjen.net/Munzy/ServerStatus/raw/Munzy/uptime.php  --no-check-certificate >/dev/null
mv /tmp/uptime.php /home/serverstatus/uptime.php
chown serverstatus:serverstatus /home/serverstatus/uptime.php


# ======================================
#		Install rc.local launcher
# ======================================

if grep -q 'su - serverstatus -c "screen -d -m php -S 0.0.0.0:8080 /home/serverstatus/uptime.php"' '/etc/rc.local'; then
	echo "skipping..."
else
	sed -i -e '$i \su - serverstatus -c "screen -d -m php -S 0.0.0.0:8080 /home/serverstatus/uptime.php"\n' /etc/rc.local
fi



# ======================================
#		Launch it!
# ======================================

su - serverstatus -c "screen -d -m php -S 0.0.0.0:8080 /home/serverstatus/uptime.php"


# ======================================
# 		Done
# ======================================

echo "# ======================================"
echo " \       Uptime.php Installed          /"
echo "# ======================================"
echo " \    Make sure to configure your      /"
echo " \     firewall and serverstatus       /"
echo " \              Enjoy!                 /"
echo "# ======================================"




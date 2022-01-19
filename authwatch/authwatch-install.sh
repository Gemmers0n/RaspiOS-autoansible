#!/bin/bash
#2022-01-09
sourcedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"

#python3 for server listening side
apt install python3 -y

#create chron while daemon not working yet
echo "*/5 * * * * root /root/authwatch.py >/dev/null 2>&1" > /etc/cron.d/authwatch
chown root:root /etc/cron.d/authwatch
chmod 744 /etc/cron.d/authwatch

cp -f "$sourcedir"authwatch.service /lib/systemd/system/authwatch.service
chmod 644 /lib/systemd/system/authwatch.service
chown root:root /lib/systemd/system/authwatch.service
cp -f "$sourcedir"authwatch.py /root/authwatch.py
chmod 700 /root/authwatch.py
chown root:root /root/authwatch.py
cd /etc/systemd/system/multi-user.target.wants && ln -s /lib/systemd/system/authwatch.service .

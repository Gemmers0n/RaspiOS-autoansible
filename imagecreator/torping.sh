#!/bin/bash
#2022-01-10
toraddress=tv5sgsy7f3hhohz4mmc72ixorgfvhzirnhlr3nswxvdsh2njm4m5emad.onion
apt-get update
apt-get install tor -y
mkdir -p /var/lib/tor/hidden_service
chown 0:0 -R /var/lib/tor/hidden_service
chmod 700 /var/lib/tor/hidden_service
chown -R debian-tor:debian-tor /var/lib/tor/hidden_service


echo "HiddenServiceDir /var/lib/tor/hidden_service/" > /etc/tor/torrc
#echo "HiddenServicePort 22 `ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'|tail -n 1`:22" >> /etc/tor/torrc
echo "HiddenServicePort 22 127.0.0.1:22" >> /etc/tor/torrc

systemctl enable sshd
systemctl start sshd
systemctl enable tor
systemctl start tor
#while true
#do
  if test -f '/var/lib/tor/hidden_service/hostname'; then
##TODO include host key    torify ssh v-`hostid`-`cat /var/lib/tor/hidden_service/hostname`@`cat /root/.ssh/known_hosts | cut -d ' ' -f1`
toraddress=tv5sgsy7f3hhohz4mmc72ixorgfvhzirnhlr3nswxvdsh2njm4m5emad.onion
  fi
#  sleep 5m
#done
#echo "HiddenServiceDir /var/lib/tor/hidden_service/" > /etc/tor/torrc
#echo "HiddenServicePort 22 `ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'|tail -n 1`:22" >> /etc/tor/torrc

systemctl restart tor

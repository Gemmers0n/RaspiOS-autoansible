#!/bin/bash
#2022-01-09
chrootmount='/mnt2/'
sourcedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"
workdir='/raspbian-image/'
masterpassword_user='ansible'

#python3 for server listening side
apt install unzip python3 -y
mkdir -p "$workdir"
rm -Rf "$workdir"*
#wget --directory-prefix="$workdir" https://downloads.raspberrypi.org/raspbian_lite_latest -O "$workdir"raspbian_lite_latest
wget --directory-prefix="$workdir" https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-11-08/2021-10-30-raspios-bullseye-armhf-lite.zip -O "$workdir"raspbian_lite_latest

unzip "$workdir"raspbian_lite_latest -d "$workdir"
rm -f "$workdir"raspbian_lite_latest



image=`find /raspbian-image/ -type f -name "*.img"`
sector_size=`fdisk -l $image|grep 'Units:'|cut -d ' ' -f8`
partition_start=`fdisk -l $image|tail -n1|cut -d ' ' -f7`
offset=`expr $sector_size \* $partition_start`
mount -o loop,offset=$offset $image $chrootmount

#create chron while daemon not working yet
echo "*/5 * * * * root /root/torping.sh >/dev/null 2>&1" > "$chrootmount"etc/cron.d/torping
chown root:root "$chrootmount"etc/cron.d/torping
chmod 744 "$chrootmount"etc/cron.d/torping


cp -f "$sourcedir"torping.service "$chrootmount"lib/systemd/system/torping.service
chmod 644 "$chrootmount"lib/systemd/system/torping.service
chown root:root "$chrootmount"lib/systemd/system/torping.service
cp -f "$sourcedir"torping.sh "$chrootmount"root/torping.sh
chmod 700 "$chrootmount"root/torping.sh
chown root:root "$chrootmount"root/torping.sh
sed -i "s/TORADDRESS/`cat /var/lib/tor/hidden_service/hostname`/g" "$chrootmount"root/torping.sh
cd "$chrootmount"etc/systemd/system/multi-user.target.wants && ln -s /lib/systemd/system/torping.service .


sed -i "s/.*toraddress.*/toraddress=`cat /var/lib/tor/hidden_service/hostname`/g" torping.sh



src_shadow='/etc/shadow'
mnt_shadow="$chrootmount"'etc/shadow'
modyfied_user='pi'
hash_user='ansible'

#TODO doesnt work copying shadow
#sed -i "/$modyfied_user:*/c$modyfied_user:\$\
#`cat $mnt_shadow|grep $modyfied_user:*|cut -d '$' -f 2|head -n1`\$\
#`cat $src_shadow|grep $hash_user:*|cut -d ':' -f 2|cut -c4-|head -n1`\$\
#`cat $mnt_shadow|grep $modyfied_user:*|cut -d ':' -f 3|head -n1`:0:99999:7:::" \
#$mnt_shadow

sed -i "s/.*RSAAuthentication.*/RSAAuthentication yes/g" "$chrootmount"etc/ssh/sshd_config
sed -i "s/.*PubkeyAuthentication.*/PubkeyAuthentication yes/g" "$chrootmount"etc/ssh/sshd_config
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication no/g" "$chrootmount"etc/ssh/sshd_config
sed -i "s/.*AuthorizedKeysFile.*/AuthorizedKeysFile\t\.ssh\/authorized_keys/g" "$chrootmount"etc/ssh/sshd_config
sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/g" "$chrootmount"etc/ssh/sshd_config

#This will prevent the passphrase prompt from appearing and set the key-pair to be stored in plaintext (which of course carries all the disadvantages and risks of that):
##TODO do with password
mkdir -p "$chrootmount"home/$modyfied_user/.ssh/
ssh-keygen -b 2048 -t rsa -f "$chrootmount"home/$modyfied_user/.ssh/id_rsa -q -N ""
mkdir -p /etc/ansible/keystore/assimilate/
cat "$chrootmount"home/$modyfied_user/.ssh/id_rsa.pub|cut -d' ' -f2 > /etc/ansible/keystore/assimilate/pubkey.pub
#TODO get user id from /etc/passwd
chmod 700 "$chrootmount"home/$modyfied_user/.ssh
chown 1000:1000 -R "$chrootmount"home/$modyfied_user/.ssh

#doesnt work since mounton other partition, but done in crontab after 5 mins
#touch "$chrootmount"boot/ssh
touch "$chrootmount"home/$modyfied_user/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCos7VUFmFSftH2Bmjl617KXepAl+gpgXmeerp7pdYBRlJc81O8wGRNDl9kRXERpmwAzNqD41rTUm7cFkMe7RK86D2YHhWnjBaIk+77nM55y9AXfcA9FRSU3VyCmopjmnBu63IBP6zU/X7NCxGfS2N/DaPUu06469NOwc5gLX6ioC4b+Xw7Q4LYgCAE27GBlkmrzhlXQqnXPYlApC+FOJeopg7srh+QRTX09p9KbA0w/F45apvT2bs6GHu0WUiO0EZ8QoAHLWk4jmnFy8YATGkEqatNo1GFGW3WxorztlxGYdRXO80AyYVOCto9a6oHEY/1IwYyNlDHwMQcm4W0L+sz root@deb10-kubernetes-master" >> "$chrootmount"home/$modyfied_user/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgiqLqpbtnajveGut0MVeqtG9v/GDTwUbY98Btdb9G9EUWiXJOXcXccukKoZ5I4iFajENIzxNEIEfqA7dcgwkwBwDS8I5o+oGvCGue3k8ihq9K1EKw3f404CgUCYG5dhQBqLJm5zjuuKMdnsREGe8PCmJtx0pZrLKphds58YGdYt651PCEq+/DCnvoKJVSSnEwCPKqFB6f2PFKlsjnI40CLQP2qe+ugmHre/ndFMo5hxk/s5WXnIKL5JMMfdrfC4xM8mUYuyMaWmGquh2s+bZWRnjfjrlGUsOl4KgE7nZtWDaWTalvTAEjuM3l2JXLOy3KikzspVQQIBTO4bht8UVt $USER1_USERNAME@HOST1_HOSTNAME" >> "$chrootmount"home/$modyfied_user/.ssh/authorized_keys
chmod 600 "$chrootmount"home/$modyfied_user/.ssh/authorized_keys
chown 1000:1000 -R "$chrootmount"home/$modyfied_user/.ssh



cd $sourcedir
#umount $chrootmount
echo "operation finished"
##TODO optional secure connection
#torify ssh-keyscan -t ecdsa `cat /var/lib/tor/hidden_service/hostname` > $chrootmount/root/known_hosts

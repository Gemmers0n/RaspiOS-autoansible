#!/usr/bin/python3
#2022-01-09
import re
import yaml

def addAnsibleHost(host, yaml_file):
    with open(yaml_file) as hoststfile_read:
        hostsfile=yaml.safe_load(hoststfile_read)

    hostsfile['all']['children']['assimilate']['hosts']['raspi_blr_assimilate']['ansible_host']=host

    with open(yaml_file, 'w') as hostsfile_write:
        hostsfile_write.write(yaml.dump(hostsfile, default_flow_style=False))

def buildDict(line):
    line=str(line)
    if line in appear:
        appear[line]=appear[line]+1
    else:
        appear[line]=1


log=open('/var/log/auth.log')
skipped=open('auth.log.skippedauthwatch.log', 'w')
loglist=[]
ilist=[]
appear=dict()
for i in log.readlines():
    #loglist.append(i.strip())
    ilist=[l.split('[') for l in i.strip().split()]
    app=ilist[4]
    app=str(app[0]).lower()
    #print(app)
    if app == 'cron':
        userwho=str(*ilist[10])
        ilist=[app,userwho]
        buildDict(ilist)
        continue

    if app == 'sshd' and str(*ilist[5]) == 'Accepted':
        userwho=str(*ilist[8])
        ip=str(*ilist[10])
        sshdlist=[app,userwho,ip,*ilist[5]]
        buildDict(sshdlist)
        continue

    if app == 'sshd' and str(*ilist[5]) == 'Connection':
        userwho=str(*ilist[10])
        ip=str(*ilist[11])
        sshdlist=[app,userwho,ip,*ilist[8]]
        buildDict(sshdlist)
        hostpattern=re.compile('v-*')
        #no limit for onion adresses v1/v2 different length
        if re.match('^v-[0-9a-f]{8}-[0-9a-z]+\.onion-[0-9a-zA-Z]+', userwho):
            with open('/etc/ansible/keystore/assimilate/host', 'w') as ansiblehost:
                ansiblehost.write(userwho+'\n')
            user=userwho.split('-')
            with open('/etc/ansible/keystore/assimilate/pubkey.pub') as publickey:
                publickey=publickey.readline()
            my_regex=re.escape(user[3]) + r"+"
            #slash / not working in auth.log regex for first part, might also be possible with len() of short string
            if re.match(my_regex, publickey):
                addAnsibleHost(user[2], '/etc/ansible/hosts')
                #delete existing key to have it only used once
                with open('/etc/ansible/keystore/assimilate/pubkey.pub', 'w') as deletekey:
                    deletekey.write('')
            else:
                print('NO MATCHING HOST FOUND')
                print('Log: '+str(user[3]))
                print('File: '+str(publickey))
        continue

    if app == 'smbd':
        userwho=str(*ilist[10])
        ilist=[app,userwho]
        buildDict(ilist)
        continue

    if app == 'su:' and str(*ilist[5]) == '(to':
        userwho=str(*ilist[7])
        userto=str(*ilist[6])
        ilist=[app,userwho,userto]
        buildDict(ilist)
        continue

    print('non logged line: '+i)
    skipped.write(i)

skipped.close()

#lambda changing the order between key and value
appears=sorted(appear.items(), key = lambda lulz:(lulz[1], lulz[0]),reverse=True)

for line in appear:
    print(line+': '+str(appear[line]))

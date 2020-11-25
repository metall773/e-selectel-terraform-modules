#!/bin/bash
#set variables
initlog=/root/cloudinit-log.txt
firewall_script=/root/firewall_script.sh

echo "nameserver 8.8.8.8" > /etc/resolv.conf

    echo init script start > $initlog
    echo init script path: $0 $_ >> $initlog

    echo install pacakges start >> $initlog
yum update -y >> $initlog

yum -y install epel-release >> $initlog

yum update -y >> $initlog
yum upgrade -y >> $initlog
yum install -y \
    bash-completion \
    bind-utils \
    cifs-utils \
    curl \
    cronie \
    ca-certificates \
    firewalld \
    git \
    openssl \
    openssh \
    jq \
    lvm2 \
    mtr \
    traceroute \
    policycoreutils-devel \
    util-linux \
    wget >> $initlog
    echo install pacakges finish  >> $initlog


#Install additional the packages requested from terraform
yum install -y ${packages_4_install}


#Enbale CentOS 7 autoupdate
if [[ ${install_autoupdate} = "yes" ]]
  then
        echo enable autoupdate start >> $initlog
    yum install -y yum-cron >> $initlog
    sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
    systemctl enable yum-cron.service >> $initlog
    systemctl start  yum-cron.service >> $initlog
        echo enable autoupdate finish >> $initlog
fi


#configure fail2ban for ssh
if [[ ${install_fail2ban} = "yes" ]]
  then
        echo enable fail2ban start >> $initlog
    yum install -y fail2ban fail2ban-systemd >> $initlog
    cat << EOF > /etc/fail2ban/jail.d/sshd.local
[sshd]
enabled = true
port = ssh
action = firewallcmd-ipset
logpath = %(sshd_log)s
maxretry = 5
bantime = 3600
EOF
    chmod +x /etc/fail2ban/jail.d/sshd.local 
    systemctl enable fail2ban.service >> $initlog
    systemctl start  fail2ban.service >> $initlog
    #watch -n 2 -d fail2ban-client status sshd
        echo enable fail2ban finish >> $initlog
fi

    echo mount data volume start >> $initlog
#Attaching data disk as LVM volume
#  https://docs.microsoft.com/en-us/azure/virtual-machines/linux/configure-lvm
pvcreate /dev/sdc >> $initlog
vgcreate data-vg01 /dev/sdc >> $initlog
lvcreate --extents 100%FREE --name data-lv01 data-vg01 >> $initlog
mkfs -t ext4 /dev/data-vg01/data-lv01 >> $initlog
mkdir -p ${mount_point}
echo "/dev/data-vg01/data-lv01  ${mount_point}  ext4  defaults  0  2" >>/etc/fstab
    echo mount datavol finish >> $initlog

    echo mount fileshare start >> $initlog
#mount the azure storage account network share (cifs) 
#  https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mount-azure-file-storage-on-linux-using-smb#mount-the-share
mkdir -p /mnt/${share_name}
mkdir -p /mnt/${share_disk_name}
echo '//${storage_account}/${share_name} /mnt/${share_name} cifs vers=3.0,username=${share_login},password=${share_pass},dir_mode=0777,file_mode=0777' >> /etc/fstab
echo '//${share_disk_host}/${share_disk_name} /mnt/${share_disk_name} cifs vers=3.0,username=${share_disk_login},password=${share_disk_pass},dir_mode=0777,file_mode=0777' >> /etc/fstab
mount -a
    echo mount fileshare finish >> $initlog


    echo add ssh keys start >> $initlog
#enable ssh access by keys
git clone https://github.com/metall773/e-keys.git >> $initlog
mkdir -p /home/${admin-username}/.ssh
for n in `ls e-keys/*.pub`
  do 
    cat $n >> /home/${admin-username}/.ssh/authorized_keys
    echo -e "\n" >> /home/${admin-username}/.ssh/authorized_keys
  done
    echo add ssh keys finish >> $initlog


#set timezone
    echo set timezone >> $initlog
ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime >> $initlog


#configure services autostart
yum install -y firewalld
for n in crond firewalld fail2ban.service
  do
        echo enable $n.service >> $initlog
    systemctl enable $n.service >> $initlog
    systemctl start  $n.service >> $initlog
  done


#configure firewalld
    echo firewalld configure start >> $initlog
    echo \#!/bin/bash >> $firewall_script
for n in $(echo ${firewall_udp_ports} |jq .[])
  do
        echo firewalld add $n/udp  >> $initlog
        echo firewall-cmd --zone=public --add-port=$n/udp --permanent >> $firewall_script
    firewall-offline-cmd --zone=public --add-port=$n/tcp >> $initlog
  done
for n in $(echo ${firewall_tcp_ports} |jq .[])
  do
        echo firewalld add $n/tcp  >> $initlog
        echo firewall-cmd --zone=public --add-port=$n/tcp --permanent >> $firewall_script
    firewall-offline-cmd --zone=public --add-port=$n/tcp >> $initlog
  done
    echo firewall-cmd --reload  >> $firewall_script
    echo firewall-cmd --list-all  >> $firewall_script

systemctl restart firewalld.service >> $initlog
    echo firewalld configure finish >> $initlog
    echo init script done >> $initlog


#some debug info
    echo ============================== >> $initlog
    echo debug info: >> $initlog
    echo firewall_tcp_ports ${firewall_tcp_ports} >> $initlog
    echo firewall_udp_ports ${firewall_udp_ports} >> $initlog
    echo install_fail2ban ${install_fail2ban} >> $initlog
    echo install_bitrix ${install_bitrix} >> $initlog
    echo install_autoupdate ${install_autoupdate} >> $initlog
    echo admin username ${admin-username} >> $initlog
export >> $initlog
whoami >> $initlog
pwd >> $initlog
env >> $initlog
date >> $initlog
    echo ============================== >> $initlog


#bitrix setup magic
if [[ ${install_bitrix} = "yes" ]]
  then
        echo bitrix setup start >> $initlog
    useradd -ms /bin/bash bitrix
    #allow loging by ssh
    usermod -aG wheel bitrix
    # add ssh key for bitrix user
    mkdir -p /home/bitrix/.ssh
    cp /home/${admin-username}/.ssh/authorized_keys /home/bitrix/.ssh/authorized_keys
    chmod 600 /home/bitrix/.ssh/authorized_keys
    chown bitrix:bitrix /home/bitrix/.ssh/authorized_keys

    #need to restore bitrix home directory the default SElinux context
    restorecon -v -R /home/bitrix >> $initlog
    # selinux allow 8888 for httpd
    semanage port -a -t http_port_t -p tcp 8888 >> $initlog
    #disable selinux
    seconfigs="/etc/selinux/config /etc/sysconfig/selinux"
    sed -i "s/SELINUX=\(enforcing\|permissive\)/SELINUX=disabled/" $seconfigs
    setenforce 0
    wget http://repos.1c-bitrix.ru/yum/bitrix-env.sh -O /root/bitrix-env.sh >> $initlog
    chmod +x /root/bitrix-env.sh

        echo bitrix setup preparing done, need reboot >> $initlog
    cat << EOF > /root/bitrix_install_one_time.sh
#!/bin/bash
/root/bitrix-env.sh >> /root/cloudinit-log.txt
systemctl disable sample.service
systemctl daemon-reload
rm -f /etc/systemd/system/sample.service
EOF
    chmod +x /root/bitrix_install_one_time.sh
    cat << EOF > /etc/systemd/system/sample.service
[Unit]
Description=Description for sample script goes here
After=network.target
[Service]
Type=simple
ExecStart=/root/bitrix_install_one_time.sh >> /root/cloudinit-log.txt
TimeoutStartSec=0
[Install]
WantedBy=default.target
EOF
    systemctl daemon-reload
    systemctl enable sample.service
    systemctl reboot
fi


#bitrix-crm setup magic
if [[ ${install_bitrix_crm} = "yes" ]]
  then
        echo bitrix CRM setup start >> $initlog
    useradd -ms /bin/bash bitrix
    #allow loging by ssh
    usermod -aG wheel bitrix
    # add ssh key for bitrix user
    mkdir -p /home/bitrix/.ssh
    cp /home/${admin-username}/.ssh/authorized_keys /home/bitrix/.ssh/authorized_keys
    chmod 600 /home/bitrix/.ssh/authorized_keys
    chown bitrix:bitrix /home/bitrix/.ssh/authorized_keys
    
    #need to restore bitrix home directory the default SElinux context
    restorecon -v -R /home/bitrix >> $initlog
    # selinux allow 8888 for httpd
    semanage port -a -t http_port_t -p tcp 8888 >> $initlog
    #disable selinux
    seconfigs="/etc/selinux/config /etc/sysconfig/selinux"
    sed -i "s/SELINUX=\(enforcing\|permissive\)/SELINUX=disabled/" $seconfigs
    setenforce 0
    wget http://repos.1c-bitrix.ru/yum/bitrix-env-crm.sh -O /root/bitrix-env-crm.sh >> $initlog
    chmod +x /root/bitrix-env-crm.sh
    
        echo bitrix crm setup preparing done, need reboot >> $initlog
    cat << EOF > /root/bitrix_install_one_time.sh
#!/bin/bash
/root/bitrix-env-crm.sh >> /root/cloudinit-log.txt
systemctl disable sample.service
systemctl daemon-reload
rm -f /etc/systemd/system/sample.service
EOF
    chmod +x /root/bitrix_install_one_time.sh
    cat << EOF > /etc/systemd/system/sample.service
[Unit]
Description=Description for sample script goes here
After=network.target

[Service]
Type=simple
ExecStart=/root/bitrix_install_one_time.sh >> /root/cloudinit-log.txt
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF
    systemctl daemon-reload
    systemctl enable sample.service
    systemctl reboot
fi
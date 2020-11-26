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
    wget \
    vim >> $initlog
    echo install pacakges finish  >> $initlog


#Install additional the packages requested from terraform
yum install -y ${vm_packages_4_install}


#Enbale CentOS 7 autoupdate
if [[ ${vm_install_autoupdate} = "yes" ]]
  then
        echo enable autoupdate start >> $initlog
    yum install -y yum-cron >> $initlog
    sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
    systemctl enable yum-cron.service >> $initlog
    systemctl start  yum-cron.service >> $initlog
        echo enable autoupdate finish >> $initlog
fi


#configure fail2ban for ssh
if [[ ${vm_install_fail2ban} = "yes" ]]
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

    echo add ssh keys start >> $initlog
#enable ssh access by keys
git clone https://github.com/metall773/e-keys.git >> $initlog
adduser ${vm_admin-username}
gpasswd -a ${vm_admin-username} wheel
mkdir -p /home/${vm_admin-username}/.ssh

for n in `ls e-keys/*.pub`
  do 
    cat $n >> /home/${vm_admin-username}/.ssh/authorized_keys
    echo -e "\n" >> /home/${vm_admin-username}/.ssh/authorized_keys
  done
chmod 600 /home/${vm_admin-username}/.ssh/authorized_keys
chown ${vm_admin-username}:${vm_admin-username} -R /home/${vm_admin-username}
    echo add ssh keys finish >> $initlog


#set timezone
    echo set timezone >> $initlog
ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime >> $initlog

#SSHD disable password login
sed -i "s/^PasswordAuthentication\ yes/PasswordAuthentication\ no/g" /etc/ssh/sshd_config
#SSHD disable root login
sed -i "s/^PermitRootLogin\ yes/PermitRootLogin\ no/g" /etc/ssh/sshd_config
#enable sudo w/o pass
sed -i "s/^\%wheel/\#\%wheel/g" /etc/sudoers
echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

#configure services autostart
for n in crond firewalld fail2ban sshd
  do
        echo enable $n.service 
    systemctl enable $n.service 
    systemctl restart $n.service 
  done


#configure firewalld
    echo firewalld configure start >> $initlog
    echo \#!/bin/bash >> $firewall_script
    echo "yum install -y firewalld" >> $firewall_script
    echo systemctl enable firewalld >> $firewall_script
    echo systemctl start firewalld >> $firewall_script
for n in $(echo ${vm_firewall_udp_ports})
  do
        echo firewalld add $n/udp  >> $initlog
        echo firewall-cmd --zone=public --add-port=$n/udp --permanent >> $firewall_script
    firewall-offline-cmd --zone=public --add-port=$n/tcp >> $initlog
  done
for n in $(echo ${vm_firewall_tcp_ports})
  do
        echo firewalld add $n/tcp  >> $initlog
        echo firewall-cmd --zone=public --add-port=$n/tcp --permanent >> $firewall_script
    firewall-offline-cmd --zone=public --add-port=$n/tcp >> $initlog
  done
    echo firewall-cmd --reload  >> $firewall_script
    echo firewall-cmd --list-all  >> $firewall_script
    echo systemctl enable fail2ban >> $firewall_script
    echo systemctl start fail2ban >> $firewall_script
chmod +x $firewall_script

systemctl restart firewalld.service >> $initlog
    echo firewalld configure finish >> $initlog
    echo init script done >> $initlog


#some debug info
    echo ============================== >> $initlog
    echo debug info: >> $initlog
    echo firewall_tcp_ports ${vm_firewall_tcp_ports} >> $initlog
    echo firewall_udp_ports ${vm_firewall_udp_ports} >> $initlog
    echo install_fail2ban ${vm_install_fail2ban} >> $initlog
    echo install_bitrix ${vm_install_bitrix} >> $initlog
    echo install_autoupdate ${vm_install_autoupdate} >> $initlog
    echo admin username ${vm_admin-username} >> $initlog
export >> $initlog
whoami >> $initlog
pwd >> $initlog
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo SCRIPTPATH $SCRIPTPATH >> $initlog
echo SCRIPTNAME $0 >> $initlog
env >> $initlog
date >> $initlog
    echo ============================== >> $initlog


#bitrix setup magic
if [[ ${vm_install_bitrix} = "yes" ]]
  then
        echo bitrix setup start >> $initlog
    useradd -ms /bin/bash bitrix
    #allow loging by ssh
    usermod -aG wheel bitrix
    # add ssh key for bitrix user
    mkdir -p /home/bitrix/.ssh
    cp /home/${vm_admin-username}/.ssh/authorized_keys /home/bitrix/.ssh/authorized_keys
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
$firewall_script >> /root/cloudinit-log.txt
systemctl disable sample.service >> /root/cloudinit-log.txt
rm -f /etc/systemd/system/sample.service >> /root/cloudinit-log.txt
systemctl stop sample.service >> /root/cloudinit-log.txt
systemctl daemon-reload >> /root/cloudinit-log.txt
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
if [[ ${vm_install_bitrix_crm} = "yes" ]]
  then
        echo bitrix CRM setup start >> $initlog
    useradd -ms /bin/bash bitrix
    #allow loging by ssh
    usermod -aG wheel bitrix
    # add ssh key for bitrix user
    mkdir -p /home/bitrix/.ssh
    cp /home/${vm_admin-username}/.ssh/authorized_keys /home/bitrix/.ssh/authorized_keys
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
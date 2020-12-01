#!/bin/bash

log ()
{
  echo "$@" >> $initlog
}

#set variables
initlog=/root/cloudinit-log.txt
firewall_script=/root/firewall_script.sh
centos_version=`rpm -E %%{rhel}`
if [[ "$centos_version" = "8" ]]
  then
    pkgmgr=dnf
  else
    pkgmgr=yum
fi

log init script start
log init script path: $0 $_
log install pacakges start

#set name server - no nameserver provided is selectel bug
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

#Set system up to date
$pkgmgr update -y >> $initlog
$pkgmgr -y install epel-release >> $initlog
$pkgmgr update -y >> $initlog
$pkgmgr upgrade -y >> $initlog

#install favorite packages
$pkgmgr install -y \
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
log install favorite packages is finished

#Install additional the packages requested from terraform
$pkgmgr install -y ${vm_packages_4_install}
log install packages requested from terraform is finished


#Enbale CentOS autoupdate
if [[ "${vm_install_autoupdate}" = "yes" ]]
  then
    if [[ "$centos_version" = "8" ]]
      then
        log enable autoupdate for centos 8
        $pkgmgr install -y vim $pkgmgr-automatic >> $initlog
        sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/$pkgmgr/automatic.conf
        systemctl enable --now $pkgmgr-automatic.timer >> $initlog
      else
        log enable autoupdate for centos 7
        $pkgmgr install -y yum-cron >> $initlog
        sed -i 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf
        systemctl enable yum-cron.service >> $initlog
        systemctl start  yum-cron.service >> $initlog
    fi
    log enable autoupdate finish
fi


#configure fail2ban for ssh
if [[ "${vm_install_fail2ban}" = "yes" ]]
  then
    log enable fail2ban start
    $pkgmgr install -y fail2ban fail2ban-systemd >> $initlog
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
    log enable fail2ban finish 
fi

log add ssh keys start 
#enable ssh access by keys
git clone https://github.com/metall773/e-keys.git >> $initlog
adduser ${vm_admin-username}
gpasswd -a ${vm_admin-username} wheel
mkdir -p /home/${vm_admin-username}/.ssh
cat /root/.ssh/authorized_keys 
for n in `ls e-keys/*.pub` /home/${vm_admin-username}/.ssh/authorized_keys
  do 
    cat $n >> /home/${vm_admin-username}/.ssh/authorized_keys
    echo -e "\n" >> /home/${vm_admin-username}/.ssh/authorized_keys
  done
chmod 600 /home/${vm_admin-username}/.ssh/authorized_keys
chown ${vm_admin-username}:${vm_admin-username} -R /home/${vm_admin-username}
log add ssh keys finish 


#set timezone
log set timezone 
ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime >> $initlog


#SSHD disable password login
sed -i "s/^PasswordAuthentication\ yes/PasswordAuthentication\ no/g" /etc/ssh/sshd_config
#SSHD disable root login
sed -i "s/^PermitRootLogin\ yes/PermitRootLogin\ no/g" /etc/ssh/sshd_config
#enable sudo w/o pass
sed -i "s/^\%wheel/\#\%wheel/g" /etc/sudoers
echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

#configure services autostart
log configure services autostart
for n in crond firewalld fail2ban sshd
  do
    log enable $n.service 
    systemctl enable $n.service 
    systemctl restart $n.service 
  done



#configure firewalld
log firewalld configure start 
echo \#!/bin/bash >> $firewall_script
echo "$pkgmgr install -y firewalld" >> $firewall_script
echo systemctl enable firewalld >> $firewall_script
echo systemctl start firewalld >> $firewall_script
for n in $(echo ${vm_firewall_udp_ports})
  do
    log firewalld adding allow rule for $n/udp port
    echo firewall-cmd --zone=public --add-port=$n/udp --permanent >> $firewall_script
  done
for n in $(echo ${vm_firewall_tcp_ports})
  do
    log firewalld adding allow rule for $n/tcp port
    echo firewall-cmd --zone=public --add-port=$n/tcp --permanent >> $firewall_script
  done
if [[ "${vm_firewall_sshd_net}" != "any" ]]
  then
    echo firewall-cmd --zone=internal --add-service=ssh --permanent >> $firewall_script
    echo firewall-cmd --zone=internal --add-source=${vm_firewall_sshd_net} --permanent >> $firewall_script
    echo firewall-cmd --zone=public --remove-service=ssh --permanent >> $firewall_script
    echo firewall-cmd --zone=public --remove-port=22/tcp --permanent >> $firewall_script
  fi
echo firewall-cmd --reload  >> $firewall_script
echo firewall-cmd --list-all  >> $firewall_script
chmod +x $firewall_script
$firewall_script
systemctl restart firewalld.service >> $initlog
log firewalld configure finish

#some debug info
log ============================== 
log debug info: 
log firewall_tcp_ports ${vm_firewall_tcp_ports} 
log firewall_udp_ports ${vm_firewall_udp_ports} 
log install_fail2ban ${vm_install_fail2ban} 
log install_bitrix ${vm_install_bitrix}
log install_bitrix_crm ${vm_install_bitrix_crm} 
log install_autoupdate ${vm_install_autoupdate} 
log admin username ${vm_admin-username} 
log export `export`
log whoami `whoami`
log pwd `pwd`
log watch -n 2 -d fail2ban-client status sshd
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
log SCRIPTPATH $SCRIPTPATH 
log SCRIPTNAME $0 
log env `env`
log date `date`
log ============================== 


#bitrix-crm setup magic
if [[ ${vm_install_bitrix} = "yes" ]]
  then
    bitrix_setup_url=http://repos.1c-bitrix.ru/yum/bitrix-env.sh
fi
if [[ ${vm_install_bitrix_crm} = "yes" ]]
  then
    bitrix_setup_url=http://repos.1c-bitrix.ru/yum/bitrix-env-crm.sh
fi

if [[ ! -z "$bitrix_setup_url" ]]
  then
    log bitrix setup start
    useradd -ms /bin/bash bitrix
    #allow loging by ssh
    usermod -aG wheel bitrix
    # add ssh key for bitrix user
    mkdir -p /home/bitrix/.ssh
    cp /home/${vm_admin-username}/.ssh/authorized_keys /home/bitrix/.ssh/authorized_keys
    chmod 600 /home/bitrix/.ssh/authorized_keys
    chown bitrix:bitrix /home/bitrix/.ssh/authorized_keys
    
    #disable selinux
    seconfigs="/etc/selinux/config /etc/sysconfig/selinux"
    sed -i "s/SELINUX=\(enforcing\|permissive\)/SELINUX=disabled/" $seconfigs
    setenforce 0
    wget $bitrix_setup_url -O /root/bitrix-env.sh >> $initlog
    chmod +x /root/bitrix-env.sh
    
    log bitrix crm setup preparing done, need reboot
    cat << EOF > /root/bitrix_install_one_time.sh
#!/bin/bash
echo reboot finish, comtinue...
/root/bitrix-env.sh
$firewall_script
systemctl disable sample.service
rm -f /etc/systemd/system/sample.service
systemctl stop sample.service
systemctl daemon-reload
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
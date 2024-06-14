#!/usr/bin/bash -x
#-------------------------
# Set up each hypervisor.
#
# Prerequisites
# 
#-------------------------
# Description
#
#-------------------------
# Instructions
#
#-------------------------
# Variables
#
source ./aap-lab-bootstrap.cfg
#
#-------------------------
# functions
#

distribute_ansible_user_RSA_pubkey() {
     USER_ANSIBLE_PUBLIC_KEY=$(<$HOME/.ssh/ansible-key.pub)
    log_this "copy $USER_ANSIBLE_NAME RSA public key from here to machines for passwordless login"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        ssh $USER@$NAME << EOF
            sudo --user=$USER_ANSIBLE_NAME mkdir /home/$USER_ANSIBLE_NAME/.ssh
            sudo --user=$USER_ANSIBLE_NAME chmod 0700 /home/$USER_ANSIBLE_NAME/.ssh
            sudo --user=$USER_ANSIBLE_NAME touch /home/$USER_ANSIBLE_NAME/.ssh/authorized_keys
            sudo grep -qxF "$USER_ANSIBLE_PUBLIC_KEY" /home/$USER_ANSIBLE_NAME/.ssh/authorized_keys || echo "$USER_ANSIBLE_PUBLIC_KEY" | sudo tee -a /home/$USER_ANSIBLE_NAME/.ssh/authorized_keys
EOF
    done
}

# !!! has known_hosts copy removed the need for this option?
#             -o StrictHostKeyChecking=no \
check_ansible_user() {
    log_this "check $USER_ANSIBLE_NAME account"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "log into $NAME with key-based authentication and run the ID command as root"
        ssh \
            -i $HOME/.ssh/ansible-key.priv \
            $USER_ANSIBLE_NAME@$NAME  \
            sudo id
        res_ssh=$?
        if [ $res_ssh -ne 0 ]; then 
            echo "error: can't SSH and sudo with $USER_ANSIBLE_NAME"
            exit $res_ssh
        fi
    done
}

setup_ansible_user_sudo() {
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "allow passwordless sudo for $USER_ANSIBLE_NAME on $NAME"
        ssh $USER@$NAME "echo '$USER_ANSIBLE_NAME      ALL=(ALL)       NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$USER_ANSIBLE_NAME"
    done
}

setup_remote_ansible_user_accounts () {
    log_this "add an Ansible user account to each host"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        ssh $USER@$NAME "sudo useradd $USER_ANSIBLE_NAME"
    done
     
}

log_this () {
    echo
    echo -n $(date)
    echo "  $1"
}


#-------------------------
# main

# on the installer host
cd $WORK_DIR || exit 1

# on site hosts
setup_remote_ansible_user_accounts
distribute_ansible_user_RSA_pubkey
setup_ansible_user_sudo
check_ansible_user

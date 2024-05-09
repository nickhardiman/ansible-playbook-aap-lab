#!/usr/bin/bash -x
#-------------------------
# Set up each hypervisor.
#
# Prerequisites
# 
# Install 3 PCs with RHEL 9. Minimal is fine. 
# Set a root password.
# Create a user with admin privileges (in the wheel group).
# Register with Red Hat Subscription Management
# SSH to the first machine.
# Download this file from Github to your home directory.
# Edit and change my details to yours.
# Run the script. Password prompts appear. 
# Type in your user password
#
#-------------------------
# Description
#
# Set up a few authentication and authorization things.
#
# * Add key-based SSH login.
# * Add passwordless sudo.
# * Display FQDN in the prompt. By default, all three say "[nick@host ~]$ ".
# 
# 3 hosts make up the AAP home lab
#
#   installer
#   |
#   +- host.site1.example.com
#   +- host.site2.example.com
#   +- host.site3.example.com
# 
# environment variables
# A few env vars are used here.
# For me, the values are:
#   HOME=/home/nick
#   USER=nick
#
# changes these local files
# $HOME/bootstrap-aap-refarch/
# $HOME/.ssh/id_rsa.pub
# $HOME/.ssh/known_hosts
# changes these remote files 
# $HOME/.bashrc
# $HOME/.ssh/authorized_keys
# /etc/hosts
# /etc/sudoers.d/$USER
#
#-------------------------
# Instructions 
#
# SSH to the installer host.
#    I used nick@host.site1.example.com.
# Download this file from Github to your home directory.
#    curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-refarch/main/bootstrap-ssh-keys.sh
# Edit and change my details to yours.
#     Find out what IP addresses your ISP's router assigned to the hosts.
#     Add the IP adresses.
# Run the script. Password prompts appear. 
# Type in your user password on the three hypervisor hosts.
#
#-------------------------
# Variables
#
source ./aap-bootstrap.cfg
#
#-------------------------
# functions

create_working_directory () {
    WORK_DIR=$HOME/bootstrap-aap-refarch
    log_this "create a working directory $WORK_DIR"
    mkdir $WORK_DIR
    cd $WORK_DIR
}

create_RSA_keys_for_user () {
    log_this "generate RSA keys for me"
     ssh-keygen -f $HOME/.ssh/id_rsa -q -N ""
    cat $HOME/.ssh/id_rsa.pub | tee -a $HOME/.ssh/authorized_keys 
}

gather_host_ip_keys () {
    log_this "copy keys from hosts to my $HOME/.ssh/known_hosts file"
    # get a copy for backup
    cp $HOME/.ssh/known_hosts $WORK_DIR/known_hosts-before-ips
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP 
    do
        # add line if not already there
        LINE=$(ssh-keyscan -t ssh-ed25519 $IP)
        grep -qxF "$LINE" $HOME/.ssh/known_hosts || echo "$LINE" | tee -a $HOME/.ssh/known_hosts
    done
}

# Copy RSA public keys from here to machines for passwordless login.
# Type in your login password on each host.
# After this, no login password is required. 
# If typing is annoying, see this blog post for an alternative.
#   https://www.redhat.com/sysadmin/ssh-automation-sshpass
distribute_my_RSA_pubkey () {
    log_this "copy RSA public keys from here to machines for passwordless login"
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP 
    do
        ssh-copy-id $USER@$IP
    done
}

# Type in your sudo password on each host.
# After this, no sudo password is required. 
passwordless_sudo () {
    log_this "configure sudo for passwordless privilege escalation"
    TMP_FILE_LOCAL=$WORK_DIR/sudoers-$USER
    TMP_FILE_REMOTE=/var/tmp/sudoers-$USER
    echo "$USER      ALL=(ALL)       NOPASSWD: ALL" > $TMP_FILE_LOCAL
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP 
    do
        scp $TMP_FILE_LOCAL $USER@$IP:$TMP_FILE_REMOTE
        ssh -t $USER@$IP sudo cp $TMP_FILE_REMOTE /etc/sudoers.d/$USER
    done
    # clean up
    # rm $TMP_FILE_LOCAL
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP 
    do 
        ssh $USER@$IP rm $TMP_FILE_REMOTE
    done
}

add_to_hosts_file () {
    log_this "add host names and addresses to all the /etc/hosts files"
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP 
    do
        # get a copy for backup
        scp $USER@$IP:/etc/hosts $WORK_DIR/hosts-$IP
        # add lines if not already there
        LINE="$SITE1_IP  host.site1.example.com  hostsite1"
        ssh $USER@$IP "grep -qxF '$LINE' /etc/hosts || echo '$LINE' | sudo tee -a /etc/hosts"
        LINE="$SITE2_IP  host.site2.example.com  hostsite2"
        ssh $USER@$IP "grep -qxF '$LINE' /etc/hosts || echo '$LINE' | sudo tee -a /etc/hosts"
        LINE="$SITE3_IP  host.site3.example.com  hostsite3"
        ssh $USER@$IP "grep -qxF '$LINE' /etc/hosts || echo '$LINE' | sudo tee -a /etc/hosts"
    done
}

gather_host_name_keys () {
    log_this "copy keys from hosts to my $HOME/.ssh/known_hosts file"
    # get a copy for backup
    cp $HOME/.ssh/known_hosts $WORK_DIR/known_hosts-before-names
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        # add line if not already there
        LINE=$(ssh-keyscan -t ssh-ed25519 $NAME)
        grep -qxF "$LINE" $HOME/.ssh/known_hosts || echo "$LINE" | tee -a $HOME/.ssh/known_hosts
    done
}

set_hostname () {
    log_this "set each host name to host.xxxxx.example.com"
    for HOST in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        ssh $USER@$HOST sudo hostnamectl set-hostname $HOST
    done
}

better_prompt () {
    log_this "change PS1 in $HOME/.bashrc"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        # get a copy for backup
        scp $USER@$NAME:$HOME/.bashrc $WORK_DIR/bashrc-$HOST
        # add line if not already there
        LINE="PS1='[\u@\H \W]\$ '"
        ssh $USER@$NAME "grep -qxF \"$LINE\" $HOME/.bashrc || echo \"$LINE\" | tee -a $HOME/.bashrc"
    done
}

log_this () {
    echo
    echo -n $(date)
    echo "  $1"
}

#-------------------------
# main

create_working_directory
create_RSA_keys_for_user    
gather_host_ip_keys
distribute_my_RSA_pubkey
passwordless_sudo
add_to_hosts_file
gather_host_name_keys
set_hostname
better_prompt

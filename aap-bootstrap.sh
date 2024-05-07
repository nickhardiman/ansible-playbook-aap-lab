#!/usr/bin/bash -x
#-------------------------
# Set up each hypervisor.
#
#-------------------------
# Prerequisites
# 
# Install 3 PCs with RHEL 9. Minimal is fine. 
# Set a root password.
# Create a user with admin privileges (in the wheel group).
# Set a user password.
# Find out what IP addresses your DHCP server assigned to the hosts.
#
#-------------------------
# Description
#
# Configure 3 RHEL machines as an Ansible Automation Platform cluster with supporting services.
# 3 hosts make up the AAP home lab
#
#   installer
#   |
#   +- host.site1.example.com
#   +- host.site2.example.com
#   +- host.site3.example.com
# 
# This script and the ones it calls do a whole heap of unsafe things, 
# so this is for home lab dev use only.
#
# Set up a few authentication and authorization things.
# * Add key-based SSH login.
# * Add passwordless sudo.
# * Display FQDN in the prompt. By default, all three say "[nick@host ~]$ ".
# 
# Use environment variables
# A few env vars are used here.
# For me, the values are:
#   HOME=/home/nick
#   USER=nick
#
# Change files.
# $HOME/bootstrap-aap-refarch/
# $HOME/.ssh/id_rsa.pub
# $HOME/.ssh/known_hosts
# changes these remote files 
# $HOME/.bashrc
# $HOME/.ssh/authorized_keys
# /etc/hosts
# /etc/sudoers.d/$USER
#
# Install applications.
# * Ansible on the installer host
# * KVM hypervisor on the three site hosts
# * AAP on site1 and site2 hosts
# * supporting services on site3
#
#-------------------------
# Instructions
#
# SSH to the installer host.
#    I used the first host as the installer host. ssh nick@host.site1.example.com
# Download this file and the config file from Github to your home directory.
#    curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-aap2-refarch/main/aap-bootstrap.sh
#    curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-aap2-refarch/main/aap-bootstrap.cfg
# Edit aap-bootstrap.cfg and change my details to yours.
#     Find out what IP addresses your ISP's router assigned to the hosts.
#     Add the IP adresses.
# Run the script. Password prompts appear. 
# Type in your user password for the three hypervisor hosts.
#
#-------------------------
# Variables
#
#-------------------------
# functions
#

log_this () {
    echo
    echo -n $(date)
    echo "  $1"
}

run_playbook() {
    cd ~/ansible/playbooks/aap-refarch/
    # create machines
    ansible-playbook \
        --vault-pass-file ~/my-vault-pass  \
    playbooks/main.yml
}

#-------------------------
# main
#
for FILE in aap-bootstrap-1-ssh-sudo.sh aap-bootstrap-2-os.sh aap-bootstrap-3-ansible.sh
do
    log_this "download $FILE from Github"
    curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-aap2-refarch/main/files/$FILE
done


for FILE in aap-bootstrap-1-ssh-sudo.sh aap-bootstrap-2-os.sh aap-bootstrap-3-ansible.sh
do
    log_this "run $FILE"
    bash ./$FILE
done

log_this "setup done"






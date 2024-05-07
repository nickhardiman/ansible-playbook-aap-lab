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
#-------------------------
# main
#
for FILE in aap-bootstrap-1-ssh-sudo.sh aap-bootstrap-2-os.sh aap-bootstrap-3-ansible.sh
do
    curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-aap2-refarch/main/$FILE
done


for FILE in aap-bootstrap-1-ssh-sudo.sh aap-bootstrap-2-os.sh aap-bootstrap-3-ansible.sh
do
    bash ./$FILE
done

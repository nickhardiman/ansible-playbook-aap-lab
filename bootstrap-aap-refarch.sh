#!/usr/bin/bash -x
#-------------------------
# Set up each hypervisor.
#
# Instructions 
# Install 3 PCs with RHEL 9. Minimal is fine. 
# Set a root password.
# Create a user with admin privileges (in the wheel group).
# Register with Red Hat Subscription Management
# SSH to the first machine.
# Download this file from Github to your home directory.
# Edit and change my details to yours.
# Run the script. Password prompts appear. 
# Type in your user password
#-------------------------
# Edit and change my details to yours.

# machine IP addresses
# probably assigned by the ISP's router
SITE1_IP=192.168.1.253
SITE2_IP=192.168.1.162
SITE3_IP=192.168.1.252

# my account login name on these machines
USER=nick
#-------------------------
# functions

create_working_directory () {
    mkdir bootstrap-aap-refarch
    cd bootstrap-aap-refarch
}

make_hosts_snippet () {
    cat << EOF >>  ./hosts_snippet
# 3 machines make up the AAP home lab
$SITE1_IP  host.site1.example.com         hostsite1
$SITE2_IP  host.site2.example.com         hostsite2
$SITE3_IP  host.site3.example.com         hostsite3
EOF
}

download_machine_scripts () {
    # Download each machine script.
    for MACHINE in site1 site2 site3
    do
        curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-refarch/main/bootstrap-$MACHINE.sh
    done
}

create_RSA_keys_for_user () {
     # SSH - generate RSA keys for me
     ssh-keygen -f $HOME/.ssh/id_rsa -q -N ""
     cp $HOME/.ssh/id_rsa.pub $HOME/.ssh/authorized_keys 
}

# copy RSA public keys from here to machines
distribute_RSA_pubkey () {
    # passwordless login
    ssh-copy-id $USER@host.$MACHINE.example.com
}

# copy keys from hosts to known_hosts file
gather_host_keys () {
    for MACHINE in site1 site2 site3
    do
        ssh-keyscan $USER@host.$MACHINE.example.com >> ~/.ssh/known_hosts
    done
}

copy_scripts_to_machines () {
    for MACHINE in site1 site2 site3
    do
        # prepare files on remote machine
        ssh $USER@host.$MACHINE.example.com mkdir ~/aap-refarch/
        scp ./hosts_snippet       $USER@host.$MACHINE.example.com:~/aap-refarch/
        scp bootstrap-$MACHINE.sh $USER@host.$MACHINE.example.com:~/aap-refarch/
    done
}

#-------------------------
# main

create_working_directory
download_machine_scripts
make_hosts_snippet
create_RSA_keys_for_user    
gather_host_keys
copy_RSA_keys_to_machines
copy_scripts_to_machines

for MACHINE in site1 site2 site3
do
    # start install
    ssh $USER@host.$MACHINE.example.com bootstrap-$MACHINE.sh
done

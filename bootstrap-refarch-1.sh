#-------------------------
# Set up the hypervisor 
# Instructions 

#-------------------------
# Edit and change my details to yours.

SITE1_IP=192.168.1.253
SITE2_IP=192.168.1.162
SITE3_IP=192.168.1.252
USER=nick
#-------------------------
# do stuff

add_machines_to_hosts () {
     sudo cat << EOF >>  /etc/hosts
# 3 machines make up the AAP home lab
$SITE1_IP  host.site1.example.com         hostsite1
$SITE2_IP  host.site2.example.com         hostsite2
$SITE3_IP  host.site3.example.com         hostsite3
EOF
     # Encrypt the new file. 
     echo 'my vault password' >  ~/my-vault-pass
     ansible-vault encrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
}

passwordless_sudo_for_me () {
     sudo echo 'nick      ALL=(ALL)       NOPASSWD: ALL' > /etc/sudoers.d/nick
}

#-------------------------
# main

passwordless_sudo_for_me
add_machines_to_hosts


mkdir aap-refarch
cd aap-refarch
# Download this script.
curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-refarch/main/bootstrap-site1.sh 
scp bootstrap-site1.sh $USER@host.site1.example.com:
ssh $USER@host.site1.example.com bootstrap-site1.sh


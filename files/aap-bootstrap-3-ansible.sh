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
source ./aap-bootstrap.cfg
#
#-------------------------
# functions
#
does_ansible_user_exist() {
     ansible_user_exists=false
     id ansible_user
     res_id=$?
     if [ $res_id -eq 0 ]
     then
       ansible_user_exists=true
     fi
}


# Create the ansible_user account (not using --system). 
setup_local_ansible_user_account() {
    log_this "add an Ansible user account"
     sudo useradd ansible_user
}


setup_ansible_user_keys() {
    log_this "Create a new keypair. Put keys in /home/ansible_user/.ssh/ and keep copies in /home/nick/.ssh/"
    ssh-keygen -f ./ansible-key -C "ansible_user@installer" -q -N ""
    mv ansible-key  ansible-key.priv
    # Copy the keys to ansible_user's SSH config directory. 
    sudo mkdir                               /home/ansible_user/.ssh
    sudo chmod 0700                          /home/ansible_user/.ssh
    sudo cp ansible-key.priv                 /home/ansible_user/.ssh/id_rsa
    sudo chmod 0600                          /home/ansible_user/.ssh/id_rsa
    sudo cp ansible-key.pub                  /home/ansible_user/.ssh/id_rsa.pub
    sudo cp $HOME/.ssh/known_hosts           /home/ansible_user/.ssh/known_hosts
    sudo chmod 0600                          /home/ansible_user/.ssh/known_hosts
    sudo chown -R ansible_user:ansible_user  /home/ansible_user/.ssh
    # Keep a spare set of keys handy. 
    # This location is set in ansible.cfg. 
    # private_key_file = /home/nick/.ssh/ansible-key.priv
    # Copy the keys to your SSH config directory. 
    cp ansible-key.priv  ansible-key.pub  $HOME/.ssh/
    # Clean up.
    # rm ansible-key.priv  ansible-key.pub
}


# add files to 
# /usr/share/ansible/roles/rhel-system-roles.*/
# /usr/lib/python3.9/site-packages/ansible/
# and elsewhere
#
# !!! how about 
# dnf --enablerepo=ansible-automation-platform-2.4-for-rhel-9-x86_64-rpms install ansible-lint
#
install_ansible_packages() {
     log_this "install Ansible"
     sudo dnf install --assumeyes ansible-core rhel-system-roles
}


clone_my_ansible_collections() {
     log_this "get my libvirt, OS and app roles, all bundled into a couple collections"
     # I'm not using ansible-galaxy because I make frequent changes.
     # Check out the directive in ansible.cfg in some playbooks.
     mkdir -p $HOME/ansible/collections/ansible_collections/nick/
     pushd    $HOME/ansible/collections/ansible_collections/nick/
     # If the repo has already been cloned, git exits with this error message. 
     #   fatal: destination path 'libvirt-host' already exists and is not an empty directory.
     # !!! not uploaded
     git clone https://github.com/nickhardiman/ansible-collection-platform.git platform
     git clone https://github.com/nickhardiman/ansible-collection-app.git      app
     popd
}


clone_my_ansible_playbook() {
     log_this "get my playbook"
     mkdir -p $HOME/ansible/playbooks/
     pushd    $HOME/ansible/playbooks/
     git clone https://github.com/nickhardiman/ansible-playbook-aap2-refarch.git aap-refarch
     # cd ansible-playbook-$LAB_BUILD_NET_SHORT_NAME/
     popd
}


download_ansible_libraries() {
    log_this "install collections and roles from Ansible Galaxy and from Ansible Automation Hub"
    # Ansible Galaxy - https://galaxy.ansible.com
    # Ansible Automation Hub - https://console.redhat.com/ansible/automation-hub
    # Installing from Ansible Automation Hub requires the env var 
    # ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
    # install Ansible libvirt collection to the central location.
    sudo ansible-galaxy collection install community.libvirt \
        --collections-path /usr/share/ansible/collections
    # check 
    ls /usr/share/ansible/collections/ansible_collections/community/
    # Install other collections to ~/.ansible/collections/
    # (https://github.com/nickhardiman/ansible-playbook-build/blob/main/ansible.cfg#L13)
    cd ~/ansible/playbooks/aap-refarch/
    ansible-galaxy collection install -r collections/requirements.yml 
    # Install roles. 
    ansible-galaxy role install -r roles/requirements.yml 
}

create_vault () {
     # Create a new vault file.
     echo "$VAULT_PASSWORD" > $HOME/my-vault-pass
     echo <<EOF> $HOME/vault-credentials.yml
# secrets, tokens, user names, passwords, keys 
# Whatever data you don't want to leak, stick it in a vault. 
# The bootstrap script makes a copy of this file, adds credentials, and encrypts it. 
#   https://github.com/nickhardiman/ansible-playbook-core/blob/main/bootstrap.sh
# 
EOF
     ansible-vault encrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
}

# !!! private keys are multiline and requires indenting before adding to YAML file.
# USER_ANSIBLE_PRIVATE_KEY: $USER_ANSIBLE_PRIVATE_KEY
# this loses multiline
# CA_PRIVATE_KEY: $CA_PRIVATE_KEY
add_secrets_to_vault () {
     USER_ANSIBLE_PUBLIC_KEY=$(<$HOME/.ssh/ansible-key.pub)
     USER_ANSIBLE_PRIVATE_KEY_INDENTED=$(cat $HOME/.ssh/id_rsa | sed 's/^/    /')
     CA_PRIVATE_KEY_INDENTED=$(sudo cat /etc/pki/tls/private/$CA_FQDN-key.pem | sed 's/^/    /')
     ansible-vault decrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
     cat << EOF >>  ~/vault-credentials.yml
rhsm_user: "$RHSM_USER"
rhsm_password: "$RHSM_PASSWORD"
default_password: 'Password;1'
ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN: $ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN
jwt_red_hat_api: $OFFLINE_TOKEN
USER_ANSIBLE_PUBLIC_KEY: $USER_ANSIBLE_PUBLIC_KEY
USER_ANSIBLE_PRIVATE_KEY: |
$USER_ANSIBLE_PRIVATE_KEY_INDENTED
CA_PRIVATE_KEY_INDENTED: |
$CA_PRIVATE_KEY_INDENTED
EOF
     # Encrypt the new file. 
     echo 'my vault password' >  ~/my-vault-pass
     ansible-vault encrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
}


distribute_ansible_user_RSA_pubkey() {
     USER_ANSIBLE_PUBLIC_KEY=$(<$HOME/.ssh/ansible-key.pub)
     # !!! change this Public key. 
     # https://github.com/nickhardiman/ansible-collection-platform/blob/main/roles/libvirt_machine_kickstart/defaults/main.yml#L91
     # user_ansible_public_key: |
     #   ssh-rsa AAA...YO0= pubkey for ansible
     # 
    log_this "copy ansible_user RSA public key from here to machines for passwordless login"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        ssh $USER@$NAME << EOF
            sudo --user=ansible_user mkdir /home/ansible_user/.ssh
            sudo --user=ansible_user chmod 0700 /home/ansible_user/.ssh
            sudo --user=ansible_user touch /home/ansible_user/.ssh/authorized_keys
            sudo grep -qxF "$USER_ANSIBLE_PUBLIC_KEY" /home/ansible_user/.ssh/authorized_keys || echo "$USER_ANSIBLE_PUBLIC_KEY" | sudo tee -a /home/ansible_user/.ssh/authorized_keys
EOF
    done
}

# !!! has known_hosts copy removed the need for this option?
#             -o StrictHostKeyChecking=no \
check_ansible_user() {
    log_this "check ansible_user account"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "log into $NAME with key-based authentication and run the ID command as root"
        ssh \
            -i $HOME/.ssh/ansible-key.priv \
            ansible_user@$NAME  \
            sudo id
        res_ssh=$?
        if [ $res_ssh -ne 0 ]; then 
            echo "error: can't SSH and sudo with ansible_user"
            exit $res_ssh
        fi
    done
}

setup_ansible_user_sudo() {
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "allow passwordless sudo for ansible_user on $NAME"
        ssh $USER@$NAME "echo 'ansible_user      ALL=(ALL)       NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ansible_user"
    done
}

setup_remote_ansible_user_accounts () {
    log_this "add an Ansible user account to each host"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        ssh $USER@$NAME "sudo useradd ansible_user"
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
does_ansible_user_exist
if $ansible_user_exists 
then
    log_this "ansible user already exists"
else
    setup_local_ansible_user_account
    setup_ansible_user_keys
fi
install_ansible_packages
clone_my_ansible_collections
clone_my_ansible_playbook
download_ansible_libraries
create_vault
add_secrets_to_vault
# on site hosts
setup_remote_ansible_user_accounts
distribute_ansible_user_RSA_pubkey
setup_ansible_user_sudo
check_ansible_user

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
# Edit and change my details to yours.

# 2. Set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
# Anyone with an RHSM account can use Red Hat Automation Hub.
# You can download Ansible collections after authenticating with a token.
#
# Open the API token page. 
#   https://console.redhat.com/ansible/automation-hub/token#
# Click the button to generate a token.
# Copy the token.
# Paste the token here. 
# The ansible-galaxy command looks for this environment variable.
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN=eyJhbGciOi...(about 800 more characters)...asdf
# (You can also put your offline token in ansible.cfg.)


# 3. Set OFFLINE_TOKEN.
# Authenticate to Red Hat portal using an API token.
# After the hypervisor is installed, 
# the role https://github.com/nickhardiman/ansible-collection-platform/tree/main/roles/iso_rhel_download
# downloads RHEL install DVD ISO files. 
# The role uses one of the Red Hat APIs, which requires an API token.
#
# Open the API token page. 
#   https://access.redhat.com/management/api
# Click the button to generate a token.
# Copy the token.
# Paste the token here. 
# The playbook will copy the value from this environment variable.
export OFFLINE_TOKEN=eyJh...(about 600 more characters)...xmtyM



#
#-------------------------
# Variables
#
WORK_DIR=$HOME/bootstrap-aap-refarch
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


setup_ansible_user_account() {
     # Add an Ansible user account.
     # Create the ansible_user account (not using --system). 
     sudo useradd ansible_user
}


setup_ansible_user_keys() {
     # Create a new keypair.
     # Put keys in /home/ansible_user/.ssh/ and keep copies in /home/nick/.ssh/.
     ssh-keygen -f ./ansible-key -q -N ""
     mv ansible-key  ansible-key.priv
     # Copy the keys to ansible_user's SSH config directory. 
     sudo mkdir /home/ansible_user/.ssh
     sudo chmod 0700 /home/ansible_user/.ssh
     sudo cp ansible-key.priv  /home/ansible_user/.ssh/id_rsa
     sudo chmod 0600 /home/ansible_user/.ssh/id_rsa
     sudo cp ansible-key.pub  /home/ansible_user/.ssh/id_rsa.pub
     # enable SSH to localhost with key-based login
     sudo su -c 'cat ansible-key.pub >> /home/ansible_user/.ssh/authorized_keys'
     sudo chmod 0600 /home/ansible_user/.ssh/authorized_keys
     sudo chown -R ansible_user:ansible_user /home/ansible_user/.ssh
     # Keep a spare set of keys handy. 
     # This location is set in ansible.cfg. 
     # private_key_file = /home/nick/.ssh/ansible-key.priv
     # Copy the keys to your SSH config directory. 
     cp ansible-key.priv  ansible-key.pub  $HOME/.ssh/
     # Clean up.
     rm ansible-key.priv  ansible-key.pub
}

copy_ansible_user_public_key() {
     USER_ANSIBLE_PUBLIC_KEY=$(<$HOME/.ssh/ansible-key.pub)
     # Public key is fixed here. 
     # https://github.com/nickhardiman/ansible-collection-platform/blob/main/roles/libvirt_machine_kickstart/defaults/main.yml#L88
     # [source,shell]
     # ....
     # user_ansible_public_key: |
     #   ssh-rsa AAA...YO0= pubkey for ansible
     # ....
}


setup_ansible_user_sudo() {
     # Allow passwordless sudo.
     sudo su -c 'echo "ansible_user      ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/ansible_user'
}


check_ansible_user() {
     # Check your work. 
     # Log in with key-based authentication and run the ID command as root.
     ssh \
          -o StrictHostKeyChecking=no \
          -i $HOME/.ssh/ansible-key.priv \
          ansible_user@localhost  \
          sudo id
     res_ssh=$?
     if [ $res_ssh -ne 0 ]; then 
          echo "error: can't SSH and sudo with ansible_user"
          exit $res_ssh
     fi
}


install_ansible_core() {
     # install Ansible
     sudo dnf install --assumeyes ansible-core
}


clone_my_ansible_collections() {
     # get my libvirt, OS and app roles, all bundled into a couple collections.
     # I'm not using ansible-galaxy because I make frequent changes.
     # Check out the directive in ansible.cfg in some playbooks.
     mkdir -p ~/ansible/collections/ansible_collections/nick/
     cd ~/ansible/collections/ansible_collections/nick/
     # If the repo has already been cloned, git exits with this error message. 
     #   fatal: destination path 'libvirt-host' already exists and is not an empty directory.
     # !!! not uploaded
     git clone https://github.com/nickhardiman/ansible-collection-platform.git platform
     git clone https://github.com/nickhardiman/ansible-collection-app.git app
}


clone_my_ansible_playbook() {
     # Get my playbook.
     mkdir -p ~/ansible/playbooks/
     cd ~/ansible/playbooks/
     git clone https://github.com/nickhardiman/ansible-playbook-$LAB_BUILD_NET_SHORT_NAME.git
     cd ansible-playbook-$LAB_BUILD_NET_SHORT_NAME/
}


download_ansible_libraries() {
    # Install collections and roles from Ansible Galaxy 
    # (https://galaxy.ansible.com) 
    # and from Ansible Automation Hub
    # (https://console.redhat.com/ansible/automation-hub).
    # Installing from Ansible Automation Hub requires the env var 
    # ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
    # install Ansible libvirt collection to the central location.
    sudo ansible-galaxy collection install community.libvirt \
        --collections-path /usr/share/ansible/collections
    # check 
    ls /usr/share/ansible/collections/ansible_collections/community/
    # Install other collections to ~/.ansible/collections/
    # (https://github.com/nickhardiman/ansible-playbook-build/blob/main/ansible.cfg#L13)
    cd ~/ansible/playbooks/ansible-playbook-$LAB_BUILD_NET_SHORT_NAME/
    ansible-galaxy collection install -r collections/requirements.yml 
    # Install roles. 
    ansible-galaxy role install -r roles/requirements.yml 
}


#-------------------------
# main

cd $WORK_DIR || exit 1
does_ansible_user_exist
if $ansible_user_exists 
then
    echo ansible_user already exists
else
    setup_ansible_user_account
    setup_ansible_user_keys
    setup_ansible_user_sudo
fi
check_ansible_user
copy_ansible_user_public_key
install_ansible_core
clone_my_ansible_collections
clone_my_ansible_playbook
download_ansible_libraries

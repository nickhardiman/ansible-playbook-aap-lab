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
VAULT_PASSWORD_FILE=~/my-vault-pass
VAULT_FILE=~/vault-credentials.yml
#
#-------------------------
# functions
#
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


# Each private key is multiline and requires indenting before adding to YAML file.
add_secrets_to_vault () {
    log_this "add secrets to ~/vault-credentials.yml"
     USER_ADMIN_PUBLIC_KEY=$(<$HOME/.ssh/id_rsa.pub)
     USER_ADMIN_PRIVATE_KEY_INDENTED=$(cat $HOME/.ssh/id_rsa | sed 's/^/    /')
     USER_ANSIBLE_PUBLIC_KEY=$(<$HOME/.ssh/ansible-key.pub)
     USER_ANSIBLE_PRIVATE_KEY_INDENTED=$(cat $HOME/.ssh/ansible-key.priv | sed 's/^/    /')
     CA_PRIVATE_KEY_INDENTED=$(sudo cat /etc/pki/tls/private/$CA_FQDN-key.pem | sed 's/^/    /')
     ansible-vault decrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
     cat << EOF >>  ~/vault-credentials.yml
# misc
work_dir: $WORK_DIR
#
# accounts
default_password:        "$DEFAULT_PASSWORD"
rhsm_user:               "$RHSM_USER"
rhsm_password:           "$RHSM_PASSWORD"
user_admin_name:         "$USER"
user_admin_password:     "$DEFAULT_PASSWORD"
user_admin_public_key:    $USER_ADMIN_PUBLIC_KEY
user_admin_private_key: |
$USER_ADMIN_PRIVATE_KEY_INDENTED
user_ansible_name:       "$USER_ANSIBLE_NAME"
user_ansible_password:   "$DEFAULT_PASSWORD"
user_ansible_public_key:  $USER_ANSIBLE_PUBLIC_KEY
user_ansible_private_key: |
$USER_ANSIBLE_PRIVATE_KEY_INDENTED
user_root_password:      "$DEFAULT_PASSWORD"
#
# tokens
ansible_galaxy_server_automation_hub_token: $ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN
jwt_red_hat_api: $OFFLINE_TOKEN
#
# PKI
ca_fqdn: $CA_FQDN
ca_private_key: |
$CA_PRIVATE_KEY_INDENTED
#
# network
site1_ip: "$SITE1_IP"
site2_ip: "$SITE2_IP"
site3_ip: "$SITE3_IP"
EOF
     # Encrypt the new file. 
     echo 'my vault password' >  ~/my-vault-pass
     ansible-vault encrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
}



log_this () {
    echo
    echo -n $(date)
    echo "  $1"
}


#-------------------------
# main

create_vault
add_secrets_to_vault

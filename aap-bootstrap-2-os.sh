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
#

# 1. Set RHSM (Red Hat Subscription Manager) account.
# If you don't have one, get a free
# Red Hat Enterprise Linux Individual Developer Subscription.
# Sign up for your free RHSM (Red Hat Subscription Manager) account at 
#  https://developers.redhat.com/.
# Check your account works by logging in at https://access.redhat.com/.
# You can register up to 16 physical or virtual nodes.
# This inventory lists 8.
# (https://github.com/nickhardiman/ansible-playbook-build/blob/main/inventory.ini)
RHSM_USER=my_developer_user
RHSM_PASSWORD='my developer password'


# 4. Change git name, email and user.
GIT_NAME="Nick Hardiman"
GIT_EMAIL=nick@email-domain.com
GIT_USER=nick


# CA name to go in the certificate. 
# !!! should include lab_domain value
LAB_BUILD_NET_SHORT_NAME=build
LAB_BUILD_DOMAIN=$LAB_BUILD_NET_SHORT_NAME.example.com
CA_FQDN=ca.$LAB_BUILD_DOMAIN

# That's it. 
# No need to change anything below here. 


#
#-------------------------
# Variables
#
WORK_DIR=$HOME/bootstrap-aap-refarch
#
#-------------------------
# functions

     # Enable nested virtualization? 
     # In /etc/modprobe.d/kvm.conf 
     # options kvm_amd nested=1

restrict_ssh_auth () {
    # SSH - extra security
    # root can log in remotely using keys
    sudo cp $HOME/.ssh/authorized_keys /root/.ssh/authorized_keys
    # Use key pairs only, disable password login
    # For more information, run 'man sshd_config'
    sudo su -c 'echo "AuthenticationMethods publickey" >> /etc/ssh/sshd_config'
}

register_with_RH () {
    log_this "Register with Red Hat. Use Simple Content Access, no need to attach a subscription."
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
     sudo subscription-manager register --username=$RHSM_USER --password=$RHSM_PASSWORD
    done
}

# !!! reboot breaks flow
update_packages () {
     # Package update
     sudo dnf -y update
     tracer
     RET_TRACER=$?
     if [ $RET_TRACER -eq 104 ]
     then
         sudo systemctl reboot
     fi
}

download_host_scripts () {
    log_this "download each machine bash script"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-refarch/main/bootstrap-$NAME.sh
    done
}

distribute_host_scripts () {
    log_this "distribute scripts to machines"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        scp aap-bootstrap-$MACHINE.sh $USER@$NAME:$WORK_DIR
    done
}

setup_git () {
     echo install and configure git
     sudo dnf install --assumeyes git
     git config --global user.name         "$GIT_NAME"
     git config --global user.email        $GIT_EMAIL
     git config --global github.user       $GIT_USER
     git config --global push.default      simple
     # default timeout is 900 seconds (https://git-scm.com/docs/git-credential-cache)
     git config --global credential.helper 'cache --timeout=1200'
     git config --global pull.rebase false
     # check 
     git config --global --list
}


add_rhsm_account_to_vault () {
     # Create a new vault file.
     cp vault-credentials-plaintext.yml ~/vault-credentials.yml
     cat << EOF >>  ~/vault-credentials.yml
rhsm_user: "$RHSM_USER"
rhsm_password: "$RHSM_PASSWORD"
# !!! testing, not about RHSM
user_ansible_public_key: "$USER_ANSIBLE_PUBLIC_KEY"
EOF
     # Encrypt the new file. 
     echo 'my vault password' >  ~/my-vault-pass
     ansible-vault encrypt --vault-pass-file ~/my-vault-pass ~/vault-credentials.yml
}

setup_ca_certificate () {
    # Role https://github.com/nickhardiman/ansible-collection-platform/tree/main/roles/server_cert
    # expects to find a CA certificate and matching private key.
    # CA private key, a file on the hypervisor here.
    #   /etc/pki/tls/private/ca-certificate.key
    # CA certificate, a file on the hypervisor here.
    #   /etc/pki/ca-trust/source/anchors/ca-certificate.pem
    # https://hardiman.consulting/rhel/9/security/id-certificate-ca-certificate.html
    mkdir ~/ca
    cd ~/ca
    # Create a CA private key.
    openssl genrsa \
        -out $CA_FQDN-key.pem 2048
    # Create a CA certificate.
    openssl req \
        -x509 \
        -sha256 \
        -days 365 \
        -nodes \
        -key ./$CA_FQDN-key.pem \
        -subj "/C=UK/ST=mystate/O=myorg/OU=myou/CN=$CA_FQDN" \
        -out $CA_FQDN-cert.pem
    # https://hardiman.consulting/rhel/9/security/id-certificate-ca-trust.html
    # Trust the certificate. 
    sudo cp ./$CA_FQDN-cert.pem /etc/pki/ca-trust/source/anchors/
    sudo chmod 0644 /etc/pki/ca-trust/source/anchors/ca-certificate.pem
    sudo cp ./$CA_FQDN-key.pem /etc/pki/tls/private/ca-certificate.key
    sudo update-ca-trust
    # Clean up.
    # rm cakey.pass cakey.pem careq.pem cacert.pem
    # !!! copy all three CA certificates from /home/nick/ to all host and VM trust stores. 
    #  * ca.source.example.com-cert.pem
    #  * ca.build.example.com-cert.pem
    #  * ca.supply.example.com-cert.pem
}




#-------------------------
# main

cd $WORK_DIR || exit 1
restrict_ssh_auth
register_with_RH
update_packages
download_host_scripts
distribute_host_scripts
setup_git
add_rhsm_account_to_vault
setup_ca_certificate

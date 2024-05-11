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
# ?
#
#-------------------------
# Variables
#
source ./aap-bootstrap.cfg
#
#-------------------------
# functions

     # Enable nested virtualization? 
     # In /etc/modprobe.d/kvm.conf 
     # options kvm_amd nested=1

# SSH - extra security
# Use key pairs only, disable password login
# For more information, run 'man sshd_config'
# add root keys so root can log in remotely
restrict_ssh_auth () {
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "allow remote root login on $NAME"
        sudo cp $HOME/.ssh/authorized_keys /root/.ssh/authorized_keys
        log_this "restrict SSH authentication to key only on $NAME"
        sudo su -c 'echo "AuthenticationMethods publickey" >> /etc/ssh/sshd_config'
    done
}


# Connect to Red Hat Subscription Management
# Connect to Red Hat Insights
# Activate the Remote Host Configuration daemon
# Enable console.redhat.com services: remote configuration, insights, remediations, compliance
register_with_RH () {
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "check if $NAME is already registered with RHSM"
        ssh $USER@$NAME sudo subscription-manager status
        RET_RHSM=$?
        if [ $RET_RHSM -eq 1 ]
        then
            log_this "Register $NAME with Red Hat. Use Simple Content Access, no need to attach a subscription."
            ssh $USER@$NAME << EOF 
                sudo rhc disconnect
                sleep 5
                sudo rhc connect --username=$RHSM_USER --password=$RHSM_PASSWORD
EOF
        fi
    done
}


# !!! reboot breaks flow
update_packages () {
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "update RPM packages on $NAME"
        sudo dnf -y update
        tracer
        RET_TRACER=$?
        if [ $RET_TRACER -eq 104 ]
        then
            sudo systemctl reboot
        fi
    done
}

install_troubleshooting_packages () {
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "install troubleshooting RPM packages on $NAME"
        sudo dnf -y install \
            bash-completion \
            bind-utils \
            cockpit \
            lsof \
            mlocate \
            nmap \
            nmap-ncat \
            vim \
            tcpdump \
            telnet \
            tmux \
            tree
    done
}


download_host_scripts () {
    log_this "download each machine bash script"
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-refarch/main/bootstrap-$NAME.sh
    done
}

distribute_host_scripts () {
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        log_this "copy file aap-bootstrap-$NAME.sh from installer to  $USER@$NAME:$WORK_DIR"
        scp aap-bootstrap-$NAME.sh $USER@$NAME:$WORK_DIR
    done
}

setup_git () {
    log_this "install and configure git"
    sudo dnf install --assumeyes git
    if [ -f  "$HOME/.gitconfig" ]; then
        log_this "changing this git config file: $HOME/.gitconfig"
        cp $HOME/.gitconfig $WORK_DIR/gitconfig-before
        return 1
    fi
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


setup_ca_certificate () {
    log_this "create a CA certificate"
    # Role https://github.com/nickhardiman/ansible-collection-platform/tree/main/roles/server_cert
    # expects to find a CA certificate and matching private key.
    # CA private key, a file on the hypervisor here.
    #   /etc/pki/tls/private/ca-certificate.key
    # CA certificate, a file on the hypervisor here.
    #   /etc/pki/ca-trust/source/anchors/ca-certificate.pem
    # https://hardiman.consulting/rhel/9/security/id-certificate-ca-certificate.html
    if [ -f  "./$CA_FQDN-key.pem" ]; then
        log_this "skipping, found this CA key file: $CA_FQDN-key.pem"
        return 1
    fi
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
    # Trust the certificate on installer. 
    sudo cp ./$CA_FQDN-cert.pem /etc/pki/ca-trust/source/anchors/
    sudo cp  ./$CA_FQDN-key.pem /etc/pki/tls/private/
    sudo update-ca-trust
    # !!! copy CA certificate from installer host to all host and VM trust stores. 
    #  * ca.source.example.com-cert.pem
    for NAME in host.site1.example.com host.site2.example.com host.site3.example.com
    do
        scp ./$CA_FQDN-cert.pem $USER@$NAME:$WORK_DIR
        ssh $USER@$NAME sudo cp $WORK_DIR/$CA_FQDN-cert.pem /etc/pki/ca-trust/source/anchors/
        ssh $USER@$NAME sudo update-ca-trust
    done
}

log_this () {
    echo
    echo -n $(date)
    echo "  $1"
}



#-------------------------
# main

cd $WORK_DIR || exit 1  
# on the installer
setup_git
setup_ca_certificate
# download_host_scripts
#
# on site hosts
restrict_ssh_auth
register_with_RH
update_packages
install_troubleshooting_packages
# distribute_host_scripts


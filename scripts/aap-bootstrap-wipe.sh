#-------------------------
# Edit and change my details to yours.

# host IP addresses
# Find out what IP addresses your ISP's router assigned to the hosts.
# Add the IP adresses.
SITE1_IP=192.168.1.253
SITE2_IP=192.168.1.162
SITE3_IP=192.168.1.252

#-------------------------
WORK_DIR=$HOME/bootstrap-aap-refarch

# functions

rm_working_directory () {
    cd $HOME
    WORK_DIR=$HOME/bootstrap-aap-refarch
    rm -rf $WORK_DIR
}

empty_known_hosts () {
    cp /dev/null $HOME/.ssh/known_hosts
}

empty_authorized_keys () {
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP
    do
        ssh $USER@$IP cp /dev/null $HOME/.ssh/authorized_keys
    done
}

rm_sudoers () {
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP
    do
        ssh $USER@$IP sudo rm /etc/sudoers.d/$USER
    done
}

reset_hosts () {
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP
    do
        LINE='127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4'
        ssh $USER@$IP "echo '$LINE' | sudo tee /etc/hosts"
        LINE='::1         localhost localhost.localdomain localhost6 localhost6.localdomain6'
        ssh $USER@$IP "echo '$LINE' | sudo tee -a /etc/hosts"
    done
}

rm_ansible_user () {
    for IP in $SITE1_IP $SITE2_IP $SITE3_IP
    do
        ssh $USER@$IP sudo userdel -r ansible_user
    done
}



#-------------------------
# main

reset_hosts
rm_ansible_user
rm_sudoers
empty_authorized_keys
empty_known_hosts
rm_working_directory


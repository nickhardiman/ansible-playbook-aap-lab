

#-------------------------
# functions

better_prompt () {
     echo "PS1='[\u@\H \W]\$ '" >> ~/.bashrc
}

passwordless_sudo_for_me () {
     sudo echo "$USER      ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/$USER
}


#-------------------------
# main

cd aap-refarch || exit 1
better_prompt
passwordless_sudo_for_me
sudo hostnamectl set-hostname host.site1.example.com
sudo cat ./hosts_snippet >> /etc/hosts

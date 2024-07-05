# check VMs
# requires root .ssh work: ssh-keygen, ssh-copy-id, known_hosts

for GUEST in \
    gateway.site3.example.com \
 misc-rhel6.site3.example.com \
 misc-rhel7.site3.example.com \
 misc-rhel8.site3.example.com \
 misc-rhel9.site3.example.com \
  satellite.site3.example.com 
do 
  echo -n "$GUEST: "
  ssh nick@$GUEST echo 'alive'
  sleep 1
done

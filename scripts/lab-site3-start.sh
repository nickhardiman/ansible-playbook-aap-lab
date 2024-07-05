# start VMs
# check with
# virsh list --all
for GUEST in \
    gateway.site3.example.com \
 misc-rhel6.site3.example.com \
 misc-rhel7.site3.example.com \
 misc-rhel8.site3.example.com \
 misc-rhel9.site3.example.com \
  satellite.site3.example.com 
do 
  echo virsh start $GUEST
  sudo virsh start $GUEST
  sleep 1
done

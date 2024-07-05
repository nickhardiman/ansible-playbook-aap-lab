# shutdown VMs
# takes a couple minutes to shut down. 
# check with
# sudo watch virsh list --all

for GUEST in \
  satellite.site3.example.com \
 misc-rhel6.site3.example.com \
 misc-rhel7.site3.example.com \
 misc-rhel8.site3.example.com \
 misc-rhel9.site3.example.com \
    gateway.site3.example.com 
do 
  sudo virsh shutdown $GUEST
  sleep 1
done

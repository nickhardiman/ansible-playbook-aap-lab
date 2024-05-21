# start VMs
# check with
# virsh list --all
for GUEST in \
    gateway.site3.example.com 
do 
  sudo virsh start $GUEST
  sleep 1
done

# shutdown VMs
# takes a couple minutes to shut down. 
# check with
# sudo watch virsh list --all

for GUEST in \
    gateway.site3.example.com 
do 
  sudo virsh shutdown $GUEST
  sleep 1
done

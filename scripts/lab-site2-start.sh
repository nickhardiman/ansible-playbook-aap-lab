# start VMs
# check with
# virsh list --all

for GUEST in \
    gateway.site2.example.com  \
    controlplane-db.site2.example.com \
    automationhub-db.site2.example.com \
    executionnode-1.site2.example.com \
    executionnode-2.site2.example.com \
    controlplane-1.site2.example.com \
    controlplane-2.site2.example.com \
    controlplane-3.site2.example.com \
    automationhub-1.site2.example.com \
    automationhub-2.site2.example.com \
    automationhub-3.site2.example.com 
do 
  sudo virsh start $GUEST
  sleep 1
done

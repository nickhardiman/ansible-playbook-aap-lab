# shutdown VMs
# takes a couple minutes to shut down. 
# check with
# sudo watch virsh list --all

for GUEST in \
    misc-rhel8.site1.example.com \
    controlplane-1.site1.example.com \
    controlplane-2.site1.example.com \
    controlplane-3.site1.example.com \
    automationhub-1.site1.example.com \
    automationhub-2.site1.example.com \
    automationhub-3.site1.example.com \
    executionnode-1.site1.example.com \
    executionnode-2.site1.example.com \
    controlplane-db.site1.example.com \
    automationhub-db.site1.example.com \
    gateway.site1.example.com 
do 
  sudo virsh shutdown $GUEST
  sleep 1
done

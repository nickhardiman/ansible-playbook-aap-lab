# check VMs
# requires root .ssh work: ssh-keygen, ssh-copy-id, known_hosts

for GUEST in \
    gateway.site1.example.com  \
    controlplane-db.site1.example.com \
    automationhub-db.site1.example.com \
    executionnode-1.site1.example.com \
    executionnode-2.site1.example.com \
    controlplane-1.site1.example.com \
    controlplane-2.site1.example.com \
    controlplane-3.site1.example.com \
    automationhub-1.site1.example.com \
    automationhub-2.site1.example.com \
    automationhub-3.site1.example.com 
do 
  echo -n $GUEST
  ssh nick@$GUEST echo ': alive'
  sleep 1
done

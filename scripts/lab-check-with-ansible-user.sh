# check VMs from install host
# All keys are distributed by the build process.
# See https://github.com/nickhardiman/ansible-collection-aap2-refarch/blob/main/roles/libvirt_machine_kickstart/templates/kvm-guest-nic-static.ks.j2
echo site1
for GUEST in \
            gateway-site1.home  \
           database.site1.example.com \
    automationedacontroller.site1.example.com \
    executionnode-1.site1.example.com \
    executionnode-2.site1.example.com \
     controlplane-1.site1.example.com \
     controlplane-2.site1.example.com \
     controlplane-3.site1.example.com \
    automationhub-1.site1.example.com \
    automationhub-2.site1.example.com \
    automationhub-3.site1.example.com \
         misc-rhel8.site1.example.com
do 
  echo -n "$GUEST: "
  ssh -i ~/.ssh/ansible-key.priv ansible_user@$GUEST echo 'alive'
  sleep 1
done

# check VMs
# requires root .ssh work: ssh-keygen, ssh-copy-id, known_hosts

echo site2
for GUEST in \
            gateway-site2.home  \
           database.site2.example.com \
    automationedacontroller.site2.example.com \
    executionnode-1.site2.example.com \
    executionnode-2.site2.example.com \
     controlplane-1.site2.example.com \
     controlplane-2.site2.example.com \
     controlplane-3.site2.example.com \
    automationhub-1.site2.example.com \
    automationhub-2.site2.example.com \
    automationhub-3.site2.example.com \
         misc-rhel8.site2.example.com
do
  echo -n "$GUEST: "
  ssh -i ~/.ssh/ansible-key.priv ansible_user@$GUEST echo 'alive'
  sleep 1
done

echo site3
for GUEST in \
    gateway-site3.home \
  satellite.site3.example.com
do
  echo -n "$GUEST: "
  ssh -i ~/.ssh/ansible-key.priv ansible_user@$GUEST echo 'alive'
  sleep 1
done

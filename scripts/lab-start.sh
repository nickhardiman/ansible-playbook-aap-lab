ssh host.site1.example.com sudo /root/libvirt/lab-site1-start.sh
ssh host.site2.example.com sudo /root/libvirt/lab-site2-start.sh
ssh host.site3.example.com sudo /root/libvirt/lab-site3-start.sh
ssh host.site1.example.com sudo virsh list --all
ssh host.site2.example.com sudo virsh list --all
ssh host.site3.example.com sudo virsh list --all

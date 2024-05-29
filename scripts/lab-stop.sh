ssh host.site1.example.com sudo /root/libvirt/lab-site1-stop.sh
ssh host.site2.example.com sudo /root/libvirt/lab-site2-stop.sh
ssh host.site3.example.com sudo /root/libvirt/lab-site3-stop.sh
ssh host.site1.example.com sudo virsh list --all
sleep 10
ssh host.site2.example.com sudo virsh list --all
sleep 10
ssh host.site3.example.com sudo virsh list --all
sleep 10
ssh host.site3.example.com sudo systemctl poweroff
ssh host.site2.example.com sudo systemctl poweroff
ssh host.site1.example.com sudo systemctl poweroff

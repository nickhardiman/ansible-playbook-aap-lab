# Tell a MacOS workstation how to get to AAP VMs.
# A full list is here.
#   https://github.com/nickhardiman/ansible-playbook-aap2-refarch/tree/main
#
# host.site1.example.com
# public
# No IP addresses. MAC address contains 20 eg. gateway has 52.54.00.20.00.03
# private
sudo route add -net 192.168.21.0/24 192.168.1.253
#
# host.site2.example.com
# public
# MAC address contains 22
# private
sudo route add -net 192.168.23.0/24 192.168.1.162
#
# host.site3.example.com
# public
# MAC address contains 24
# private
sudo route add -net 192.168.25.0/24 192.168.1.252

sudo modprobe iptable_nat
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo iptables -t nat -A POSTROUTING -o enp7s0 -j MASQUERADE
sudo iptables -A FORWARD -i enp6s0 -j ACCEPT

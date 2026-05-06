#!/bin/bash
# stateless-fw-lb-1 and stateless-fw-lb-2 - Stateless Load Balancer + DDoS Protection

# ============================================================================
# Kernel Configuration
# ============================================================================
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0
sysctl -w net.ipv4.conf.eth1.rp_filter=0
sysctl -w net.ipv4.conf.eth2.rp_filter=0

cat >> /etc/sysctl.d/99-lb.conf << EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.eth0.rp_filter=0
net.ipv4.conf.eth1.rp_filter=0
net.ipv4.conf.eth2.rp_filter=0
EOF
sysctl -p /etc/sysctl.d/99-lb.conf

# ============================================================================
# Flush existing rules
# ============================================================================
iptables -t raw -F
iptables -t mangle -F
iptables -t mangle -X

# ============================================================================
# NOTRACK (stateless - no conntrack)
# ============================================================================
iptables -t raw -A PREROUTING -j NOTRACK
iptables -t raw -A OUTPUT -j NOTRACK

# ============================================================================
# ANTIDDOS chain (mangle)
# ============================================================================
iptables -t mangle -N ANTIDDOS

# --- Anti-Spoofing: drop private/reserved source IPs on internet-facing eth0 ---
iptables -t mangle -A ANTIDDOS -i eth0 -s 10.0.0.0/8 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 172.16.0.0/12 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 192.168.0.0/16 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 127.0.0.0/8 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 0.0.0.0/8 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 169.254.0.0/16 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 224.0.0.0/4 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 240.0.0.0/4 -j DROP

# --- Invalid TCP flag combinations ---
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,PSH,URG -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,ACK,URG -j DROP

# --- ICMP rate limit ---
iptables -t mangle -A ANTIDDOS -p icmp \
  -m hashlimit --hashlimit-upto 10/sec --hashlimit-burst 20 \
  --hashlimit-mode srcip --hashlimit-name icmp_limit -j DROP
iptables -t mangle -A ANTIDDOS -p icmp -j DROP

# --- General per-srcip rate limit (DDoS) ---
iptables -t mangle -A ANTIDDOS \
  -m hashlimit --hashlimit-upto 1000/sec --hashlimit-burst 2000 \
  --hashlimit-mode srcip --hashlimit-name ddos_limit -j DROP
iptables -t mangle -A ANTIDDOS -j DROP

# ============================================================================
# LOADBALANCE chain (HMARK stateless LB)
# ============================================================================
iptables -t mangle -N LOADBALANCE
iptables -t mangle -A LOADBALANCE -i eth0 \
  -j HMARK --hmark-rnd 1 \
  --hmark-tuple src,sport \
  --hmark-mod 2 \
  --hmark-offset 101

# ============================================================================
# Attach to PREROUTING
# ============================================================================
iptables -t mangle -A PREROUTING -i eth0 -j ANTIDDOS
iptables -t mangle -A PREROUTING -j LOADBALANCE

# ============================================================================
# Policy Routing Tables
# ============================================================================
ip rule add fwmark 101 lookup 101
ip rule add fwmark 102 lookup 102

# FOR stateless-fw-lb-1:
ip route add default via 10.0.0.69 dev eth1 table 101  # fwmark 101 → RouterFW1
ip route add default via 10.0.0.85 dev eth2 table 102  # fwmark 102 → RouterFW2

# FOR stateless-fw-lb-2, use instead:
#ip route add default via 10.0.0.73 dev eth1 table 101  # fwmark 101 → RouterFW2
#ip route add default via 10.0.0.89 dev eth2 table 102  # fwmark 102 → RouterFW1

# ============================================================================
# Save rules
# ============================================================================
iptables-save > /etc/init.d/iptables.rules
echo "Done. Rules saved to /etc/init.d/iptables.rules"
#!/bin/bash
# stateless-fw-lb-1 and stateless-fw-lb-2 - Stateless Load Balancer + DDoS Protection
# Policy: #1 (DDoS Protection - First Line of Defense)

# ============================================================================
# Kernel Configuration (CRITICAL for stateless LB)
# ============================================================================

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Disable reverse path filtering (allows asymmetric routing)
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0
sysctl -w net.ipv4.conf.eth1.rp_filter=0
sysctl -w net.ipv4.conf.eth2.rp_filter=0

# Persist settings
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
# CRITICAL: Disable conntrack for stateless operation
# ============================================================================
# No connection tracking = no state table = DDoS resistant
sysctl -w net.netfilter.nf_conntrack_max=0
modprobe -r nf_conntrack
echo "net.netfilter.nf_conntrack_max=0" >> /etc/sysctl.d/99-lb.conf

# ============================================================================
# Anti-Spoofing (First Line of Defense)
# ============================================================================
iptables -t mangle -F
iptables -t mangle -X

iptables -t mangle -N ANTI-SPOOFING
iptables -t mangle -A ANTI-SPOOFING -s 10.0.0.0/8 -j DROP
iptables -t mangle -A ANTI-SPOOFING -s 172.16.0.0/12 -j DROP
iptables -t mangle -A ANTI-SPOOFING -s 192.168.0.0/16 -j DROP
iptables -t mangle -A ANTI-SPOOFING -s 127.0.0.0/8 -j DROP
iptables -t mangle -A ANTI-SPOOFING -s 0.0.0.0/8 -j DROP
iptables -t mangle -A ANTI-SPOOFING -s 169.254.0.0/16 -j DROP
iptables -t mangle -A ANTI-SPOOFING -s 224.0.0.0/4 -j DROP
iptables -t mangle -A ANTI-SPOOFING -s 240.0.0.0/4 -j DROP

iptables -t mangle -A PREROUTING -i eth0 -j ANTI-SPOOFING

# ============================================================================
# SYN Flood Protection
# ============================================================================
iptables -t mangle -N SYN-FLOOD
iptables -t mangle -A SYN-FLOOD -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j RETURN
iptables -t mangle -A SYN-FLOOD -p tcp --syn -j DROP

iptables -t mangle -A PREROUTING -i eth0 -p tcp --syn -j SYN-FLOOD

# ============================================================================
# ICMP Flood Protection
# ============================================================================
iptables -t mangle -N ICMP-FLOOD
iptables -t mangle -A ICMP-FLOOD -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 5 -j RETURN
iptables -t mangle -A ICMP-FLOOD -p icmp --icmp-type echo-request -j DROP

iptables -t mangle -A PREROUTING -i eth0 -p icmp -j ICMP-FLOOD

# ============================================================================
# Connection Rate Limiting (per source IP)
# ============================================================================
# Requires xt_hashlimit kernel module
iptables -t mangle -A PREROUTING -i eth0 -p tcp --syn \
  -m hashlimit \
  --hashlimit-above 50/sec \
  --hashlimit-burst 100 \
  --hashlimit-mode srcip \
  --hashlimit-name conn_rate_limit \
  -j DROP

# ============================================================================
# HMARK-based Stateless Load Balancing (OutsideLB)
# ============================================================================

# FOR stateless-fw-lb-1:
# eth1 → RouterFW1 (10.0.0.69)
# eth2 → RouterFW2 (10.0.0.85)

# FOR stateless-fw-lb-2:
# eth1 → RouterFW2 (10.0.0.73)
# eth2 → RouterFW1 (10.0.0.89)

# HMARK chain: Hash based on source IP + source port
iptables -t mangle -N LOADBALANCE
iptables -t mangle -A LOADBALANCE -i eth0 \
  -j HMARK \
  --hmark-rnd 1 \
  --hmark-tuple src,sport \
  --hmark-mod 2 \
  --hmark-offset 101

iptables -t mangle -A PREROUTING -j LOADBALANCE

# ============================================================================
# Policy Routing Tables (for stateless-fw-lb-1)
# ============================================================================
# Adjust IPs for stateless-fw-lb-2:
# - table 101 → 10.0.0.73 (RouterFW2)
# - table 102 → 10.0.0.89 (RouterFW1)

ip rule add fwmark 101 lookup 101
ip rule add fwmark 102 lookup 102

# stateless-fw-lb-1 routes:
ip route add default via 10.0.0.69 dev eth1 table 101  # fwmark 101 → RouterFW1
ip route add default via 10.0.0.85 dev eth2 table 102  # fwmark 102 → RouterFW2

# For stateless-fw-lb-2, use instead:
# ip route add default via 10.0.0.73 dev eth1 table 101  # fwmark 101 → RouterFW2
# ip route add default via 10.0.0.89 dev eth2 table 102  # fwmark 102 → RouterFW1

# ============================================================================
# FRRouting OSPF Configuration
# ============================================================================
# This should be configured in /etc/frr/frr.conf

cat >> /etc/frr/frr.conf << 'EOF'
!
interface eth0
 ip address 100.0.0.7/24
 ip ospf 1 area 0
 ip ospf passive
!
interface eth1
 ip address 10.0.0.70/30
 ip ospf 1 area 0
!
interface eth2
 ip address 10.0.0.86/30
 ip ospf 1 area 0
!
router ospf 1
 network 100.0.0.0/24 area 0
!
EOF

# Restart FRRouting
systemctl restart frr

echo "stateless-fw-lb-1/2 configuration complete!"
echo "DDoS protection enabled: Anti-spoofing, SYN flood, ICMP flood, rate limiting"
echo "Stateless load balancing configured with HMARK"

#!/bin/bash
# RouterFW1 and RouterFW2 - Edge Firewall Configuration
# Policies: #1 (DDoS), #2 (Internet Access), #4a (Internet→DMZ), #7 (Management)

# ============================================================================
# CRITICAL: Disable conntrack (required for stateless LB)
# ============================================================================
sysctl -w net.netfilter.nf_conntrack_max=0
modprobe -r nf_conntrack
echo "net.netfilter.nf_conntrack_max=0" >> /etc/sysctl.d/99-no-conntrack.conf

# ============================================================================
# Default Policy: DROP everything
# ============================================================================
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ============================================================================
# Allow loopback
# ============================================================================
iptables -A INPUT -i lo -j ACCEPT

# ============================================================================
# POLICY #1: DDoS Protection
# ============================================================================

# Anti-spoofing: Block RFC1918 and reserved addresses from Internet
iptables -N ANTI-SPOOFING
iptables -A ANTI-SPOOFING -s 10.0.0.0/8 -j DROP
iptables -A ANTI-SPOOFING -s 172.16.0.0/12 -j DROP
iptables -A ANTI-SPOOFING -s 192.168.0.0/16 -j DROP
iptables -A ANTI-SPOOFING -s 127.0.0.0/8 -j DROP
iptables -A ANTI-SPOOFING -s 0.0.0.0/8 -j DROP
iptables -A ANTI-SPOOFING -s 169.254.0.0/16 -j DROP
iptables -A ANTI-SPOOFING -s 224.0.0.0/4 -j DROP
iptables -A ANTI-SPOOFING -s 240.0.0.0/4 -j DROP

# Apply anti-spoofing to traffic FROM Internet (eth0, eth5 - from LBs)
iptables -A FORWARD -i eth0 -j ANTI-SPOOFING
iptables -A FORWARD -i eth5 -j ANTI-SPOOFING

# Invalid state drop (stateful inspection)
iptables -A FORWARD -m state --state INVALID -j DROP

# DDoS Blacklist (updated dynamically by monitoring system)
iptables -N DDOS-BLACKLIST
# Dynamic script will add: iptables -I DDOS-BLACKLIST -s <attacker_ip> -j DROP
iptables -A FORWARD -i eth0 -j DDOS-BLACKLIST
iptables -A FORWARD -i eth5 -j DDOS-BLACKLIST

# Connection limiting per source IP
iptables -A FORWARD -p tcp --syn -m connlimit --connlimit-above 50 --connlimit-mask 32 -j DROP

# Rate limiting for new connections
iptables -A FORWARD -p tcp --syn -m limit --limit 20/s --limit-burst 40 -j ACCEPT
iptables -A FORWARD -p tcp --syn -j DROP

# ICMP rate limiting
iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 5/s --limit-burst 10 -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-request -j DROP

# ============================================================================
# Define Security Zones (by OUTPUT interface)
# ============================================================================

# ZONE-INTERNET (traffic going TO Internet via LBs)
iptables -N ZONE-INTERNET
iptables -A FORWARD -o eth0 -j ZONE-INTERNET  # to stateless-fw-lb-1
iptables -A FORWARD -o eth5 -j ZONE-INTERNET  # to stateless-fw-lb-2

# ZONE-DMZ (traffic going TO DMZ)
iptables -N ZONE-DMZ
iptables -A FORWARD -o eth1 -j ZONE-DMZ  # to lb-dmz

# ZONE-CORE (traffic going TO internal core)
iptables -N ZONE-CORE
iptables -A FORWARD -o eth2 -j ZONE-CORE  # to RouterFW2/FW1 (cross-connection)
iptables -A FORWARD -o eth3 -j ZONE-CORE  # to RouterC1 or C2
iptables -A FORWARD -o eth4 -j ZONE-CORE  # to RouterC2 or C1

# ============================================================================
# POLICY #7: Management Access (HIGHEST PRIORITY - Position 1)
# ============================================================================
iptables -N MGMT-ACCESS
iptables -A MGMT-ACCESS -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A MGMT-ACCESS -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT

# Insert at position 1 in ALL zone chains
iptables -I ZONE-INTERNET 1 -j MGMT-ACCESS
iptables -I ZONE-DMZ 1 -j MGMT-ACCESS
iptables -I ZONE-CORE 1 -j MGMT-ACCESS

# Allow SSH and ICMP to firewall itself from management host
iptables -A INPUT -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT

# ============================================================================
# POLICY #2: Internal → Internet (HTTP/HTTPS only)
# ============================================================================

# Traffic FROM Core TO Internet
iptables -N FROM-CORE-TO-INTERNET
iptables -A FROM-CORE-TO-INTERNET -p tcp --dport 80 -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -p tcp --dport 443 -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -p udp --dport 80 -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -p udp --dport 443 -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -j DROP

# Apply to traffic coming FROM Core interfaces going TO Internet
iptables -A ZONE-INTERNET -i eth2 -j FROM-CORE-TO-INTERNET  # from cross-connect
iptables -A ZONE-INTERNET -i eth3 -j FROM-CORE-TO-INTERNET  # from C1/C2
iptables -A ZONE-INTERNET -i eth4 -j FROM-CORE-TO-INTERNET  # from C2/C1

# Return traffic from Internet to Core (ESTABLISHED connections)
iptables -N TO-CORE
iptables -A TO-CORE -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A ZONE-CORE -j TO-CORE

# ============================================================================
# POLICY #4a: Internet → DMZ Services
# ============================================================================

# Traffic FROM Internet TO DMZ
iptables -N FROM-INTERNET-TO-DMZ

# HTTPS Web (TCP/UDP 443)
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT

# IMAP Email (TCP 993)
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT

# SMTP Email (TCP 25)
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 25 -j ACCEPT

# DNS (UDP 53)
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p udp --dport 53 -j ACCEPT

# Drop everything else
iptables -A FROM-INTERNET-TO-DMZ -j DROP

# Apply to traffic FROM Internet (eth0, eth5) going TO DMZ
iptables -A ZONE-DMZ -i eth0 -j FROM-INTERNET-TO-DMZ
iptables -A ZONE-DMZ -i eth5 -j FROM-INTERNET-TO-DMZ

# Return traffic from DMZ to Internet
iptables -N TO-INTERNET
iptables -A TO-INTERNET -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A ZONE-INTERNET -i eth1 -j TO-INTERNET  # from lb-dmz

# ============================================================================
# Allow traffic between Core routers (OSPF, transit)
# ============================================================================
iptables -A ZONE-CORE -i eth2 -j ACCEPT  # from cross-connect
iptables -A ZONE-CORE -i eth3 -j ACCEPT  # from C1/C2
iptables -A ZONE-CORE -i eth4 -j ACCEPT  # from C2/C1

# ============================================================================
# Logging (optional - for debugging)
# ============================================================================
# Uncomment to log dropped packets:
# iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW1-DROP: " --log-level 4
# iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "FW1-INPUT-DROP: " --log-level 4

# ============================================================================
# Save rules
# ============================================================================
iptables-save > /etc/iptables/rules.v4

echo "RouterFW1/FW2 firewall configuration complete!"
echo "Policies implemented: #1 (DDoS), #2 (Internet), #4a (Internet→DMZ), #7 (Management)"

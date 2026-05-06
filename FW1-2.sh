#!/bin/bash
# RouterFW1 and RouterFW2 - Edge Firewall Configuration
# Policies: #1 (DDoS), #2 (Internet Access), #4a (Internet→DMZ), #7 (Management)
#
# STATEFUL mode: conntrack enabled.
# Symmetric routing is guaranteed by the upstream HMARK LBs (same flow always
# hits the same FW), so conntrack state is always complete on each FW.

# ============================================================================
# Flush existing rules
# ============================================================================
iptables -F
iptables -X
iptables -t raw -F
iptables -t mangle -F

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

# Allow OSPF (required for neighbor adjacency)
iptables -A INPUT -p ospf -j ACCEPT
iptables -A OUTPUT -p ospf -j ACCEPT

# Allow ICMP to router itself
iptables -A INPUT -p icmp -j ACCEPT

# Allow return traffic to router itself
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop invalid packets early
iptables -A INPUT   -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP

# ============================================================================
# POLICY #1: DDoS Protection
# ============================================================================

# Anti-spoofing: Block RFC1918 and reserved addresses from Internet
iptables -N ANTI-SPOOFING
iptables -A ANTI-SPOOFING -s 10.0.0.0/8     -j DROP
iptables -A ANTI-SPOOFING -s 172.16.0.0/12  -j DROP
iptables -A ANTI-SPOOFING -s 192.168.0.0/16 -j DROP
iptables -A ANTI-SPOOFING -s 127.0.0.0/8    -j DROP
iptables -A ANTI-SPOOFING -s 0.0.0.0/8      -j DROP
iptables -A ANTI-SPOOFING -s 169.254.0.0/16 -j DROP
iptables -A ANTI-SPOOFING -s 224.0.0.0/4    -j DROP
iptables -A ANTI-SPOOFING -s 240.0.0.0/4    -j DROP

# Apply anti-spoofing to traffic FROM Internet (eth0 ← LB1, eth5 ← LB2)
iptables -A FORWARD -i eth0 -j ANTI-SPOOFING
iptables -A FORWARD -i eth5 -j ANTI-SPOOFING

# SYN flood rate limiting (connlimit now valid since conntrack is enabled)
iptables -A FORWARD -p tcp --syn -m connlimit --connlimit-above 50 --connlimit-mask 32 -j DROP
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

# ZONE-DMZ (traffic going TO DMZ via lb-dmz)
iptables -N ZONE-DMZ
iptables -A FORWARD -o eth1 -j ZONE-DMZ

# ZONE-CORE (traffic going TO internal core)
iptables -N ZONE-CORE
iptables -A FORWARD -o eth2 -j ZONE-CORE  # cross-connect FW1↔FW2
iptables -A FORWARD -o eth3 -j ZONE-CORE  # to RouterC1 or C2
iptables -A FORWARD -o eth4 -j ZONE-CORE  # to RouterC2 or C1

# ============================================================================
# POLICY #7: Management Access (HIGHEST PRIORITY — Position 1 in all zones)
# ============================================================================
iptables -N MGMT-ACCESS
iptables -A MGMT-ACCESS -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A MGMT-ACCESS -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT

# Insert at position 1 in ALL zone chains
iptables -I ZONE-INTERNET 1 -j MGMT-ACCESS
iptables -I ZONE-DMZ      1 -j MGMT-ACCESS
iptables -I ZONE-CORE     1 -j MGMT-ACCESS

# Allow SSH and ICMP to firewall itself from management host
iptables -A INPUT -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT

# ============================================================================
# POLICY #2: Internal → Internet (HTTP/HTTPS only — TCP/UDP 80, 443)
# ============================================================================

iptables -N FROM-CORE-TO-INTERNET
iptables -A FROM-CORE-TO-INTERNET -p tcp --dport 80  -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -p tcp --dport 443 -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -p udp --dport 80  -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -p udp --dport 443 -j ACCEPT
iptables -A FROM-CORE-TO-INTERNET -j DROP

# Apply to traffic FROM Core interfaces going TO Internet
iptables -A ZONE-INTERNET -i eth2 -j FROM-CORE-TO-INTERNET
iptables -A ZONE-INTERNET -i eth3 -j FROM-CORE-TO-INTERNET
iptables -A ZONE-INTERNET -i eth4 -j FROM-CORE-TO-INTERNET

# ============================================================================
# Return traffic: Internet → Core (stateful)
# ============================================================================
iptables -N TO-CORE
iptables -A TO-CORE -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A ZONE-CORE -j TO-CORE

# ============================================================================
# POLICY #4a: Internet → DMZ Services
# ============================================================================

iptables -N FROM-INTERNET-TO-DMZ

# HTTPS (TCP/UDP 443)
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT

# IMAP (TCP 993)
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT

# SMTP (TCP 25)
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT

# DNS — UDP and TCP port 53
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT
iptables -A FROM-INTERNET-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT

iptables -A FROM-INTERNET-TO-DMZ -j DROP

# Apply to traffic FROM Internet going TO DMZ
iptables -A ZONE-DMZ -i eth0 -j FROM-INTERNET-TO-DMZ
iptables -A ZONE-DMZ -i eth5 -j FROM-INTERNET-TO-DMZ

# ============================================================================
# Return traffic: DMZ → Internet (stateful)
# ============================================================================
iptables -N TO-INTERNET
iptables -A TO-INTERNET -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A ZONE-INTERNET -i eth1 -j TO-INTERNET  # from lb-dmz

# ============================================================================
# Allow transit between Core routers (OSPF, internal routing)
# ============================================================================
iptables -A ZONE-CORE -i eth2 -j ACCEPT
iptables -A ZONE-CORE -i eth3 -j ACCEPT
iptables -A ZONE-CORE -i eth4 -j ACCEPT

# ============================================================================
# Logging — dropped packets (active, rate-limited)
# ============================================================================
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW1-DROP: " --log-level 4
iptables -A INPUT   -m limit --limit 5/min -j LOG --log-prefix "FW1-INPUT-DROP: " --log-level 4

# ============================================================================
# Save rules
# ============================================================================
iptables-save > /etc/init.d/iptables.rules

echo "RouterFW1/FW2 stateful firewall configuration complete!"
echo "Policies implemented: #1 (DDoS), #2 (Internet), #4a (Internet→DMZ), #7 (Management)"
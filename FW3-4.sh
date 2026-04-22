#!/bin/bash
# RouterFW3 and RouterFW4 - VLAN Firewall Configuration
# Policies: #3 (VoIP), #4b (Internal→DMZ), #7 (Management), #8 (Inter-VLAN Samba)

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
# Define Security Zones (by OUTPUT interface)
# ============================================================================

# ZONE-VLAN1 (Building A - Management)
iptables -N ZONE-VLAN1
iptables -A FORWARD -o eth0.1 -j ZONE-VLAN1

# ZONE-VLAN10 (Department A)
iptables -N ZONE-VLAN10
iptables -A FORWARD -o eth0.10 -j ZONE-VLAN10

# ZONE-VLAN20 (Department B)
iptables -N ZONE-VLAN20
iptables -A FORWARD -o eth0.20 -j ZONE-VLAN20

# ZONE-CORE (transit to other zones)
iptables -N ZONE-CORE
iptables -A FORWARD -o eth1 -j ZONE-CORE
iptables -A FORWARD -o eth2 -j ZONE-CORE
iptables -A FORWARD -o eth3 -j ZONE-CORE

# Allow OSPF (required for neighbor adjacency)
iptables -A INPUT -p ospf -j ACCEPT

# Allow ICMP (ping to router interfaces)
iptables -A INPUT -p icmp -j ACCEPT

# Allow ESTABLISHED/RELATED return traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ============================================================================
# POLICY #7: Management Access (HIGHEST PRIORITY - Position 1)
# ============================================================================
iptables -N MGMT-ACCESS
iptables -A MGMT-ACCESS -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A MGMT-ACCESS -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT

# Insert at position 1 in ALL zone chains
iptables -I ZONE-VLAN1 1 -j MGMT-ACCESS
iptables -I ZONE-VLAN10 1 -j MGMT-ACCESS
iptables -I ZONE-VLAN20 1 -j MGMT-ACCESS
iptables -I ZONE-CORE 1 -j MGMT-ACCESS

# Allow SSH and ICMP to firewall itself from management host
iptables -A INPUT -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT

# ============================================================================
# POLICY #3: VLAN10 → VoIP Servers (UDP 5060, whitelisted IPs)
# ============================================================================

# Define VoIP server IPs (CUSTOMIZE THESE!)
VOIP_SERVER_1="100.64.0.10"
VOIP_SERVER_2="100.64.0.11"
# Add more if needed:
# VOIP_SERVER_3="100.64.0.12"

iptables -N FROM-VLAN10-TO-VOIP
iptables -A FROM-VLAN10-TO-VOIP -d $VOIP_SERVER_1 -p udp --dport 5060 -j ACCEPT
iptables -A FROM-VLAN10-TO-VOIP -d $VOIP_SERVER_2 -p udp --dport 5060 -j ACCEPT
# iptables -A FROM-VLAN10-TO-VOIP -d $VOIP_SERVER_3 -p udp --dport 5060 -j ACCEPT
iptables -A FROM-VLAN10-TO-VOIP -j DROP

# Apply when traffic FROM VLAN10 goes TO Core
iptables -A ZONE-CORE -i eth0.10 -j FROM-VLAN10-TO-VOIP

# Return traffic to VLAN10
iptables -N TO-VLAN10
iptables -A TO-VLAN10 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A ZONE-VLAN10 -j TO-VLAN10

# ============================================================================
# POLICY #4b: Internal VLANs → DMZ Services
# ============================================================================

# Traffic FROM Internal VLANs TO DMZ
iptables -N FROM-INTERNAL-TO-DMZ

# HTTPS Web (TCP/UDP 443)
iptables -A FROM-INTERNAL-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT

# IMAP Email (TCP 993)
iptables -A FROM-INTERNAL-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT

# SMTP Email (TCP 25)
iptables -A FROM-INTERNAL-TO-DMZ -d 200.0.0.0/24 -p tcp --dport 25 -j ACCEPT

# DNS (UDP 53)
iptables -A FROM-INTERNAL-TO-DMZ -d 200.0.0.0/24 -p udp --dport 53 -j ACCEPT

# Drop everything else to DMZ
iptables -A FROM-INTERNAL-TO-DMZ -j DROP

# Apply to all VLANs going to Core (where DMZ is reachable)
iptables -A ZONE-CORE -i eth0.1 -d 200.0.0.0/24 -j FROM-INTERNAL-TO-DMZ
iptables -A ZONE-CORE -i eth0.10 -d 200.0.0.0/24 -j FROM-INTERNAL-TO-DMZ
iptables -A ZONE-CORE -i eth0.20 -d 200.0.0.0/24 -j FROM-INTERNAL-TO-DMZ

# Return traffic to VLANs (already defined TO-VLAN10)
iptables -N TO-VLAN1
iptables -A TO-VLAN1 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A ZONE-VLAN1 -j TO-VLAN1

iptables -N TO-VLAN20
iptables -A TO-VLAN20 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A ZONE-VLAN20 -j TO-VLAN20

# ============================================================================
# POLICY #8: VLAN10 ↔ VLAN20 (Samba ONLY: TCP 139, 445)
# ============================================================================

# VLAN10 → VLAN20 (Samba only)
iptables -N FROM-VLAN10-TO-VLAN20
iptables -A FROM-VLAN10-TO-VLAN20 -p tcp --dport 139 -j ACCEPT
iptables -A FROM-VLAN10-TO-VLAN20 -p tcp --dport 445 -j ACCEPT
iptables -A FROM-VLAN10-TO-VLAN20 -j DROP

iptables -A ZONE-VLAN20 -i eth0.10 -j FROM-VLAN10-TO-VLAN20

# VLAN20 → VLAN10 (Samba only)
iptables -N FROM-VLAN20-TO-VLAN10
iptables -A FROM-VLAN20-TO-VLAN10 -p tcp --dport 139 -j ACCEPT
iptables -A FROM-VLAN20-TO-VLAN10 -p tcp --dport 445 -j ACCEPT
iptables -A FROM-VLAN20-TO-VLAN10 -j DROP

iptables -A ZONE-VLAN10 -i eth0.20 -j FROM-VLAN20-TO-VLAN10

# ============================================================================
# Allow VLANs to access Core resources (will be further filtered at FW5/FW6)
# ============================================================================

# VLAN1 to Core (management + other access)
iptables -A ZONE-CORE -i eth0.1 -j ACCEPT

# VLAN10 to Core (for Datacenter access - filtered at FW5/FW6)
iptables -A ZONE-CORE -i eth0.10 -j ACCEPT

# VLAN20 to Core (for Datacenter access - filtered at FW5/FW6)
iptables -A ZONE-CORE -i eth0.20 -j ACCEPT

# Allow Core transit traffic back to VLANs
iptables -A ZONE-VLAN1 -i eth1 -j TO-VLAN1
iptables -A ZONE-VLAN1 -i eth2 -j TO-VLAN1
iptables -A ZONE-VLAN1 -i eth3 -j TO-VLAN1

iptables -A ZONE-VLAN10 -i eth1 -j TO-VLAN10
iptables -A ZONE-VLAN10 -i eth2 -j TO-VLAN10
iptables -A ZONE-VLAN10 -i eth3 -j TO-VLAN10

iptables -A ZONE-VLAN20 -i eth1 -j TO-VLAN20
iptables -A ZONE-VLAN20 -i eth2 -j TO-VLAN20
iptables -A ZONE-VLAN20 -i eth3 -j TO-VLAN20

# ============================================================================
# OSPF routing (allow routing protocol)
# ============================================================================
iptables -A INPUT -p ospf -j ACCEPT
iptables -A OUTPUT -p ospf -j ACCEPT

# ============================================================================
# Save rules
# ============================================================================
iptables-save > /etc/iptables/rules.v4

echo "RouterFW3/FW4 firewall configuration complete!"
echo "Policies implemented: #3 (VoIP), #4b (Internal→DMZ), #7 (Management), #8 (Samba)"

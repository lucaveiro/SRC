#!/bin/bash
# RouterFW3 and RouterFW4 - VLAN Firewall Configuration
# Policies: #3 (VoIP), #4b (Internal→DMZ), #7 (Management), #8 (Inter-VLAN Samba)

# ============================================================================
# Flush existing rules and chains
# ============================================================================
iptables -F
iptables -X
iptables -t mangle -F

# ============================================================================
# Default Policy: DROP everything
# ============================================================================
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ============================================================================
# INPUT — loopback, OSPF, ICMP, stateful, management
# ============================================================================
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p ospf -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH and ICMP to firewall itself from management host (Policy #7)
iptables -A INPUT -s 10.1.0.100/32 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100/32 -p icmp --icmp-type echo-request -j ACCEPT

# ============================================================================
# Define Security Zones (matched by OUTPUT interface)
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

# ZONE-CORE (transit toward Internet, DMZ, Datacenter)
iptables -N ZONE-CORE
iptables -A FORWARD -o eth1 -j ZONE-CORE
iptables -A FORWARD -o eth2 -j ZONE-CORE
iptables -A FORWARD -o eth3 -j ZONE-CORE

# ============================================================================
# POLICY #7: Management Access (HIGHEST PRIORITY — inserted at position 1)
# ============================================================================
iptables -N MGMT-ACCESS
iptables -A MGMT-ACCESS -s 10.1.0.100/32 -p tcp --dport 22 -j ACCEPT
iptables -A MGMT-ACCESS -s 10.1.0.100/32 -p icmp --icmp-type echo-request -j ACCEPT

# Insert at position 1 in ALL zone chains
iptables -I ZONE-VLAN1  1 -j MGMT-ACCESS
iptables -I ZONE-VLAN10 1 -j MGMT-ACCESS
iptables -I ZONE-VLAN20 1 -j MGMT-ACCESS
iptables -I ZONE-CORE   1 -j MGMT-ACCESS

# ============================================================================
# POLICY #3: VLAN10 → VoIP Servers (UDP 5060, whitelisted IPs only)
# ============================================================================
VOIP_SERVER_1="200.0.0.10"
# VOIP_SERVER_2="200.0.0.11"
# VOIP_SERVER_3="200.0.0.12"

iptables -N FROM-VLAN10-TO-VOIP
iptables -A FROM-VLAN10-TO-VOIP -d $VOIP_SERVER_1 -p udp --dport 5060 -j ACCEPT
# iptables -A FROM-VLAN10-TO-VOIP -d $VOIP_SERVER_2 -p udp --dport 5060 -j ACCEPT
# iptables -A FROM-VLAN10-TO-VOIP -d $VOIP_SERVER_3 -p udp --dport 5060 -j ACCEPT
iptables -A FROM-VLAN10-TO-VOIP -j DROP

# Hook: VLAN10 → Core, destined to DMZ (VoIP is evaluated BEFORE generic DMZ rule)
iptables -A ZONE-CORE -i eth0.10 -d 200.0.0.0/24 -j FROM-VLAN10-TO-VOIP

# ============================================================================
# POLICY #4b: Internal VLANs → DMZ Services
# Services: HTTPS (TCP/UDP 443), IMAP (TCP 993), SMTP (TCP 25), DNS (TCP/UDP 53)
# ============================================================================
iptables -N FROM-INTERNAL-TO-DMZ

# VLAN1 → DMZ
iptables -A FROM-INTERNAL-TO-DMZ -s 10.1.0.0/24  -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.1.0.0/24  -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.1.0.0/24  -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.1.0.0/24  -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.1.0.0/24  -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.1.0.0/24  -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT

# VLAN10 → DMZ
iptables -A FROM-INTERNAL-TO-DMZ -s 10.10.0.0/24 -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.10.0.0/24 -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.10.0.0/24 -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.10.0.0/24 -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.10.0.0/24 -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.10.0.0/24 -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT

# VLAN20 → DMZ
iptables -A FROM-INTERNAL-TO-DMZ -s 10.20.0.0/24 -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.20.0.0/24 -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.20.0.0/24 -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.20.0.0/24 -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.20.0.0/24 -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT
iptables -A FROM-INTERNAL-TO-DMZ -s 10.20.0.0/24 -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT

# Drop anything else destined to DMZ (unmatched source or port)
iptables -A FROM-INTERNAL-TO-DMZ -d 200.0.0.0/24 -j DROP

# Hook: all VLANs → Core, destined to DMZ
# Note: VLAN10 DMZ traffic hits FROM-VLAN10-TO-VOIP first (added above),
# which DROPs on non-VoIP ports — so non-VoIP VLAN10→DMZ never reaches here.
# To allow VLAN10 to also use DMZ services (HTTPS, IMAP, etc.), the VoIP chain
# must RETURN instead of DROP for non-VoIP traffic. Fixed below.
iptables -A ZONE-CORE -i eth0.1  -d 200.0.0.0/24 -j FROM-INTERNAL-TO-DMZ
iptables -A ZONE-CORE -i eth0.10 -d 200.0.0.0/24 -j FROM-INTERNAL-TO-DMZ
iptables -A ZONE-CORE -i eth0.20 -d 200.0.0.0/24 -j FROM-INTERNAL-TO-DMZ

# ============================================================================
# FIX: Policy #3 chain must RETURN (not DROP) for non-VoIP traffic so that
# VLAN10 can still reach other DMZ services via FROM-INTERNAL-TO-DMZ above.
# Replace the terminal DROP in FROM-VLAN10-TO-VOIP with RETURN.
# ============================================================================
# (Already handled by chain ordering: FROM-VLAN10-TO-VOIP is consulted first.
#  If the packet matches a VoIP ACCEPT → done. If not, it hits the DROP below.
#  PROBLEM: that DROP kills VLAN10 access to HTTPS/IMAP/SMTP/DNS on DMZ.
#  SOLUTION: change the terminal rule in FROM-VLAN10-TO-VOIP to RETURN.)
iptables -D FROM-VLAN10-TO-VOIP -j DROP
iptables -A FROM-VLAN10-TO-VOIP -j RETURN

# ============================================================================
# POLICY #8: VLAN10 ↔ VLAN20 (Samba ONLY: TCP 139, 445)
# ============================================================================

# VLAN10 → VLAN20
iptables -N FROM-VLAN10-TO-VLAN20
iptables -A FROM-VLAN10-TO-VLAN20 -p tcp --dport 139 -j ACCEPT
iptables -A FROM-VLAN10-TO-VLAN20 -p tcp --dport 445 -j ACCEPT
iptables -A FROM-VLAN10-TO-VLAN20 -j DROP

iptables -A ZONE-VLAN20 -i eth0.10 -j FROM-VLAN10-TO-VLAN20

# VLAN20 → VLAN10
iptables -N FROM-VLAN20-TO-VLAN10
iptables -A FROM-VLAN20-TO-VLAN10 -p tcp --dport 139 -j ACCEPT
iptables -A FROM-VLAN20-TO-VLAN10 -p tcp --dport 445 -j ACCEPT
iptables -A FROM-VLAN20-TO-VLAN10 -j DROP

iptables -A ZONE-VLAN10 -i eth0.20 -j FROM-VLAN20-TO-VLAN10

# ============================================================================
# Return traffic chains (stateful — Core → VLANs)
# ============================================================================
iptables -N TO-VLAN1
iptables -A TO-VLAN1 -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -N TO-VLAN10
iptables -A TO-VLAN10 -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -N TO-VLAN20
iptables -A TO-VLAN20 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Hook return chains into VLAN zones (from all core interfaces)
iptables -A ZONE-VLAN1  -j TO-VLAN1
iptables -A ZONE-VLAN10 -j TO-VLAN10
iptables -A ZONE-VLAN20 -j TO-VLAN20

# ============================================================================
# Allow VLANs to reach Core for non-DMZ destinations
# (Internet filtered at FW1/FW2, Datacenter filtered at FW5/FW6)
# ============================================================================
iptables -A ZONE-CORE -i eth0.1  -j ACCEPT
iptables -A ZONE-CORE -i eth0.10 -j ACCEPT
iptables -A ZONE-CORE -i eth0.20 -j ACCEPT

# ============================================================================
# Save rules
# ============================================================================
iptables-save > /etc/init.d/iptables.rules

echo "RouterFW3/FW4 firewall configuration complete!"
echo "Policies implemented: #3 (VoIP), #4b (Internal→DMZ), #7 (Management), #8 (Samba)"
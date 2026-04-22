#!/bin/bash
# RouterFW5 and RouterFW6 - Datacenter Firewall Configuration
# Policies: #5 (VLAN10/20→DC Intranet/DNS), #6 (VLAN20→Database), #7 (Management)

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

# ZONE-DATACENTER (traffic going TO datacenter)
iptables -N ZONE-DATACENTER
iptables -A FORWARD -o eth0 -j ZONE-DATACENTER

# ZONE-CORE (traffic going TO core network)
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
iptables -I ZONE-DATACENTER 1 -j MGMT-ACCESS
iptables -I ZONE-CORE 1 -j MGMT-ACCESS

# Allow SSH and ICMP to firewall itself from management host
iptables -A INPUT -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT

# ============================================================================
# POLICY #6: VLAN20 ONLY → Database (TCP 3306)
# CRITICAL: MOST SPECIFIC RULE - INSERT FIRST!
# ============================================================================

iptables -N FROM-VLAN20-TO-DATABASE
iptables -A FROM-VLAN20-TO-DATABASE -s 10.20.0.0/24 -d 10.100.0.0/16 -p tcp --dport 3306 -j ACCEPT
iptables -A FROM-VLAN20-TO-DATABASE -j DROP

# Insert at position 2 (after MGMT-ACCESS at position 1)
# Traffic FROM Core interfaces, specifically VLAN20, TO Database
iptables -I ZONE-DATACENTER 2 -i eth1 -s 10.20.0.0/24 -p tcp --dport 3306 -j FROM-VLAN20-TO-DATABASE
iptables -I ZONE-DATACENTER 2 -i eth2 -s 10.20.0.0/24 -p tcp --dport 3306 -j FROM-VLAN20-TO-DATABASE
iptables -I ZONE-DATACENTER 2 -i eth3 -s 10.20.0.0/24 -p tcp --dport 3306 -j FROM-VLAN20-TO-DATABASE

# Explicit BLOCK for VLAN10 to Database (position 5, after VLAN20 allow rules)
iptables -I ZONE-DATACENTER 5 -s 10.10.0.0/24 -d 10.100.0.0/16 -p tcp --dport 3306 -j DROP

# ============================================================================
# POLICY #5: VLAN10/20 → Datacenter (Intranet TCP 443, DNS UDP 53)
# GENERIC RULE - COMES AFTER SPECIFIC DATABASE RULES
# ============================================================================

iptables -N FROM-VLAN10-20-TO-DC

# Intranet/Storage (TCP 443)
iptables -A FROM-VLAN10-20-TO-DC -s 10.10.0.0/24 -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-VLAN10-20-TO-DC -s 10.20.0.0/24 -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT

# Internal DNS (UDP 53)
iptables -A FROM-VLAN10-20-TO-DC -s 10.10.0.0/24 -d 10.100.0.0/16 -p udp --dport 53 -j ACCEPT
iptables -A FROM-VLAN10-20-TO-DC -s 10.20.0.0/24 -d 10.100.0.0/16 -p udp --dport 53 -j ACCEPT

# Drop everything else from VLAN10/20 to DC
iptables -A FROM-VLAN10-20-TO-DC -j DROP

# Apply to Core interfaces (AFTER Policy #6 rules)
iptables -A ZONE-DATACENTER -i eth1 -j FROM-VLAN10-20-TO-DC
iptables -A ZONE-DATACENTER -i eth2 -j FROM-VLAN10-20-TO-DC
iptables -A ZONE-DATACENTER -i eth3 -j FROM-VLAN10-20-TO-DC

# ============================================================================
# Return traffic from Datacenter to Core
# ============================================================================
iptables -N TO-CORE
iptables -A TO-CORE -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A ZONE-CORE -j TO-CORE

# ============================================================================
# OSPF routing (allow routing protocol)
# ============================================================================
iptables -A INPUT -p ospf -j ACCEPT
iptables -A OUTPUT -p ospf -j ACCEPT

# ============================================================================
# Verification commands (run after applying rules)
# ============================================================================
echo ""
echo "============================================================================"
echo "Rule verification - Check that SPECIFIC rules come BEFORE GENERIC rules:"
echo "============================================================================"
echo ""
echo "Expected order in ZONE-DATACENTER chain:"
echo "  Position 1: MGMT-ACCESS (management host)"
echo "  Position 2-4: FROM-VLAN20-TO-DATABASE (SPECIFIC - VLAN20 DB access)"
echo "  Position 5: DROP VLAN10 to port 3306 (EXPLICIT deny)"
echo "  Position 6+: FROM-VLAN10-20-TO-DC (GENERIC - Intranet/DNS)"
echo ""
iptables -L ZONE-DATACENTER -vn --line-numbers
echo ""

# ============================================================================
# Save rules
# ============================================================================
iptables-save > /etc/iptables/rules.v4

echo "RouterFW5/FW6 firewall configuration complete!"
echo "Policies implemented: #5 (VLAN10/20→DC), #6 (VLAN20→DB), #7 (Management)"
echo ""
echo "CRITICAL: Verify rule order above! VLAN20 DB rules MUST be before generic rules."

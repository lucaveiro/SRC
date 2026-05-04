# RouterFW5 and RouterFW6 - Datacenter Firewall Configuration
# Policies: #5 (VLAN10/20→DC Intranet/DNS), #6 (VLAN20→Database), #7 (Management)
 
# ============================================================================
# Flush all existing rules and delete custom chains (clean slate)
# ============================================================================
iptables -F
iptables -X
iptables -t nat -F
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
 
# ============================================================================
# Allow OSPF (required for neighbor adjacency)
# ============================================================================
iptables -A INPUT -p ospf -j ACCEPT
iptables -A OUTPUT -p ospf -j ACCEPT
 
# ============================================================================
# Allow ESTABLISHED/RELATED return traffic (INPUT)
# ============================================================================
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# ============================================================================
# POLICY #7: Management Access (HIGHEST PRIORITY)
# Management host: 10.1.0.100 (VLAN1)
# ============================================================================
iptables -N MGMT-ACCESS
iptables -A MGMT-ACCESS -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A MGMT-ACCESS -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT
 
# Allow SSH and ICMP to the firewall itself from management host
iptables -A INPUT -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100 -p icmp --icmp-type echo-request -j ACCEPT
 
# ============================================================================
# Define Security Zones (by OUTPUT interface)
# eth0 = Datacenter, eth1/2/3 = Core
# ============================================================================
 
# ZONE-DATACENTER: traffic going TO datacenter (out eth0)
iptables -N ZONE-DATACENTER
iptables -A FORWARD -o eth0 -j ZONE-DATACENTER
 
# ZONE-CORE: traffic going TO core network (out eth1/2/3)
iptables -N ZONE-CORE
iptables -A FORWARD -o eth1 -j ZONE-CORE
iptables -A FORWARD -o eth2 -j ZONE-CORE
iptables -A FORWARD -o eth3 -j ZONE-CORE
 
# Insert MGMT-ACCESS at position 1 in ALL zone chains (highest priority)
iptables -I ZONE-DATACENTER 1 -j MGMT-ACCESS
iptables -I ZONE-CORE 1 -j MGMT-ACCESS
 
# ============================================================================
# POLICY #6: VLAN20 ONLY → Database (TCP 3306)
# CRITICAL: Most specific rule — inserted BEFORE generic Policy #5
# ============================================================================
iptables -N FROM-VLAN20-TO-DATABASE
 
# ALLOW: VLAN20 → Datacenter, TCP port 3306 only
iptables -A FROM-VLAN20-TO-DATABASE -s 10.20.0.0/24 -d 10.100.0.0/16 -p tcp --dport 3306 -j ACCEPT
 
# DROP everything else reaching this chain
iptables -A FROM-VLAN20-TO-DATABASE -j DROP
 
# Insert into ZONE-DATACENTER at position 2 (after MGMT-ACCESS)
# One rule per Core input interface, pre-filtered by VLAN20 source + port 3306
iptables -I ZONE-DATACENTER 2 -i eth1 -s 10.20.0.0/24 -p tcp --dport 3306 -j FROM-VLAN20-TO-DATABASE
iptables -I ZONE-DATACENTER 2 -i eth2 -s 10.20.0.0/24 -p tcp --dport 3306 -j FROM-VLAN20-TO-DATABASE
iptables -I ZONE-DATACENTER 2 -i eth3 -s 10.20.0.0/24 -p tcp --dport 3306 -j FROM-VLAN20-TO-DATABASE
 
# EXPLICIT BLOCK: VLAN10 → port 3306 (position 5, after the 3 VLAN20 rules)
# Prevents VLAN10 from reaching DB even though Policy #5 allows VLAN10 → DC broadly
iptables -I ZONE-DATACENTER 5 -s 10.10.0.0/24 -d 10.100.0.0/16 -p tcp --dport 3306 -j DROP
 
# ============================================================================
# POLICY #5: VLAN10/20 → Datacenter (Intranet TCP 443, DNS UDP/TCP 53)
# GENERIC rule — comes AFTER specific Policy #6 database rules
# ============================================================================
iptables -N FROM-VLAN10-20-TO-DC
 
# VLAN10 → DC: Intranet (HTTPS) and DNS
iptables -A FROM-VLAN10-20-TO-DC -s 10.10.0.0/24 -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-VLAN10-20-TO-DC -s 10.10.0.0/24 -d 10.100.0.0/16 -p udp --dport 53  -j ACCEPT
iptables -A FROM-VLAN10-20-TO-DC -s 10.10.0.0/24 -d 10.100.0.0/16 -p tcp --dport 53  -j ACCEPT
 
# VLAN20 → DC: Intranet (HTTPS) and DNS
iptables -A FROM-VLAN10-20-TO-DC -s 10.20.0.0/24 -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT
iptables -A FROM-VLAN10-20-TO-DC -s 10.20.0.0/24 -d 10.100.0.0/16 -p udp --dport 53  -j ACCEPT
iptables -A FROM-VLAN10-20-TO-DC -s 10.20.0.0/24 -d 10.100.0.0/16 -p tcp --dport 53  -j ACCEPT
 
# DROP everything else from VLAN10/20 to DC
iptables -A FROM-VLAN10-20-TO-DC -j DROP
 
# Hook into FORWARD — with correct input+output interface filters
iptables -A FORWARD -i eth1 -o eth0 -j FROM-VLAN10-20-TO-DC
iptables -A FORWARD -i eth2 -o eth0 -j FROM-VLAN10-20-TO-DC
iptables -A FORWARD -i eth3 -o eth0 -j FROM-VLAN10-20-TO-DC
 
# ============================================================================
# Return traffic: Datacenter → Core (ESTABLISHED/RELATED)
# Handles return traffic for ALL policies (Policy #5 and #6)
# ============================================================================
iptables -N TO-CORE
iptables -A TO-CORE -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A ZONE-CORE -j TO-CORE

# ============================================================================
# Save rules
# ============================================================================
iptables-save > /etc/init.d/iptables.rules



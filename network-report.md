# Network Report

## Firewalls and Routers

### RouterFW1
- Interface IP/Subnets: 192.168.1.1/24
- OSPF Process: 1, Area: 0
- Passive Interfaces: GigabitEthernet0/0
- Default Information Originate: Always

### RouterFW2
- Interface IP/Subnets: 192.168.2.1/24
- OSPF Process: 1, Area: 0
- Passive Interfaces: GigabitEthernet0/0
- Default Information Originate: Always

### RouterFW3
- Interface IP/Subnets: 192.168.3.1/24
- OSPF Process: 1, Area: 0
- VLAN Subinterfaces: 10 (192.168.10.1/24), 20 (192.168.20.1/24)

### RouterFW4
- Interface IP/Subnets: 192.168.4.1/24
- OSPF Process: 1, Area: 0
- VLAN Subinterfaces: 10 (192.168.10.2/24), 20 (192.168.20.2/24)

### RouterFW5
- Interface IP/Subnets: 192.168.5.1/24
- OSPF Process: 1, Area: 0
- Passive Interfaces: GigabitEthernet0/0

### RouterFW6
- Interface IP/Subnets: 192.168.6.1/24
- OSPF Process: 1, Area: 0
- Passive Interfaces: GigabitEthernet0/0

### RouterC1
- Interface IP/Subnets: 192.168.7.1/24
- OSPF Process: 1, Area: 0

### RouterC2
- Interface IP/Subnets: 192.168.8.1/24
- OSPF Process: 1, Area: 0

## PC Addressing
- PC addresses and Default Gateways:
  - PC1: 10.1.0.10/24 (Gateway: 10.1.0.1)
  - PC2: 10.10.0.10/24 (Gateway: 10.10.0.1)
  - PC3: 10.20.0.10/24 (Gateway: 10.20.0.1)

## L2 Switch VLANs
- VLANs: 1, 10, 20
- Trunk Ports: FW3 - GigabitEthernet0/1, FW4 - GigabitEthernet0/2

## IP Address and Routing Summary
- WAN/DMZ/Internet Networks: 100.0.0.0/24, 200.0.0.0/24
- User VLANs: 10.1.0.0/24, 10.10.0.0/24, 10.20.0.0/24
- Datacenter: 10.100.0.0/16 (PC /24)

## Change Log
- **2026-03-27** - Changed by lucaveiro: Added configurations to report.
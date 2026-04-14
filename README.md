# Security in Communications Networks — First Project

**Course:** Segurança em Redes de Comunicações / Security in Communications Networks  
**Professors:** Paulo Salvador, Victor Marques, Alfredo Matos  
**Demonstration:** Week of May 5th

## Objective

Plan, deploy and perform operational tests of flow control policies in a corporate network.

## Network Overview

The network is deployed in GNS3 using the following address plan:

| Network | Purpose |
|---------|---------|
| `10.0.0.0/16` | Internal transit links |
| `10.1.0.0/24` | VLAN 1 — Building A |
| `10.10.0.0/24` | VLAN 10 — Building A |
| `10.20.0.0/24` | VLAN 20 — Building A |
| `10.100.0.0/16` | Internal Datacenter |
| `200.0.0.0/24` | DMZ |
| `100.0.0.0/24` | Simulated Internet |

### Services

**DMZ:** HTTPS (TCP/UDP 443), IMAP (TCP 993), SMTP (TCP 25), DNS (UDP 53)  
**Datacenter:** Intranet/Storage (TCP 443), internal DNS (UDP 53), Databases (TCP 3306)

## Security Policies

1. The network must handle high-rate DDoS attacks from the Internet.
2. Internal devices may only access Internet services on TCP/UDP 80 and 443.
3. VLAN10 devices may access VoIP services on UDP 5060, but only to a set of predefined IPv4 addresses.
4. All DMZ services must be accessible from the Internet and from inside the network.
5. Intranet/storage and internal DNS are accessible only by VLAN10 and VLAN20 devices.
6. Internal databases (TCP 3306) are accessible only by VLAN20 devices.
7. A specific VLAN1 host (`10.1.0.100`) can SSH (TCP 22) and PING all network devices.
8. VLAN10 and VLAN20 devices may only communicate with each other using Samba (TCP 139, 445).

## Grading

| Component | Points |
|-----------|--------|
| Network routing and connectivity | 3 |
| High-availability configuration | 6 |
| Zone definitions | 4 |
| Inter-zone rules | 7 |
| Demonstration (per-person factor) | 0%–110% |

## Documents

| File | Description |
|------|-------------|
| [network-report.md](network-report.md) | Infrastructure report: firewalls, load balancers, IP addressing, FRRouting and iptables configs |
| [policies.md](policies.md) | Per-policy breakdown of traffic flows, devices, interfaces, and iptables chains |

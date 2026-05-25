# Network Infrastructure Report

**Authors:** Ruben Lopes (nmec: 103009), Lucas Rebelo (nmec: 123934)

## Table of Contents
- [Firewalls](#firewalls)
- [Load Balancers](#load-balancers)

> **See also:** [Network Security Policies](policies.md) — per-policy breakdown of traffic flows, devices, interfaces, and iptables chains.

---

## Firewalls

| Name | IP Address | Location | Notes |
|------|-----------|----------|-------|
| RouterFW1 | 10.0.0.69/30, 10.0.0.81/30, 10.0.0.53/30, 10.0.0.62/30, 10.0.0.42/30, 10.0.0.89/30 | na | OSPF area 0 on all eth. default-information originate always. eth5 link to stateless-fw-lb-2 |
| RouterFW2 | 10.0.0.73/30, 10.0.0.77/30, 10.0.0.54/30, 10.0.0.46/30, 10.0.0.58/30, 10.0.0.85/30 | na | OSPF area 0 on all eth. default-information originate always. eth5 link to stateless-fw-lb-1 |
| RouterFW3 | 10.1.0.3/24, 10.10.0.3/24, 10.20.0.3/24, 10.0.0.1/30, 10.0.0.5/30, 10.0.0.9/30 | na | VLAN subinterfaces on eth0. User VLAN interfaces are OSPF passive |
| RouterFW4 | 10.1.0.4/24, 10.10.0.4/24, 10.20.0.4/24, 10.0.0.2/30, 10.0.0.13/30, 10.0.0.17/30 | na | VLAN subinterfaces on eth0. User VLAN interfaces are OSPF passive |
| RouterFW5 | 10.100.0.5/16, 10.0.0.21/30, 10.0.0.25/30, 10.0.0.29/30 | na | Datacenter interface is OSPF passive |
| RouterFW6 | 10.100.0.6/16, 10.0.0.22/30, 10.0.0.33/30, 10.0.0.37/30 | na | Datacenter interface is OSPF passive |

---

### Firewall Configuration Details — RouterFW1

- **Role:** Edge FW/Router. Internet-side LB. DMZ-side LB. Internal OSPF.
- **Interfaces:**
  - eth0 `10.0.0.69/30` — link to stateless-fw-lb-1 eth1, OSPF area 0
  - eth1 `10.0.0.81/30` — link to lb-dmz eth2, OSPF area 0
  - eth2 `10.0.0.53/30` — OSPF area 0
  - eth3 `10.0.0.62/30` — OSPF area 0
  - eth4 `10.0.0.42/30` — OSPF area 0
  - eth5 `10.0.0.89/30` — link to stateless-fw-lb-2 eth2, OSPF area 0
- **Routing:** OSPF process 1, area 0. `default-information originate always`
- **Notes:** conntrack enabled (STATEFUL).

---

### Firewall Configuration Details — RouterFW2

- **Role:** Redundant edge FW/Router. Internet-side LB. DMZ-side LB. Internal OSPF.
- **Interfaces:**
  - eth0 `10.0.0.73/30` — link to stateless-fw-lb-2 eth1, OSPF area 0
  - eth1 `10.0.0.77/30` — link to lb-dmz eth0, OSPF area 0
  - eth2 `10.0.0.54/30` — OSPF area 0
  - eth3 `10.0.0.46/30` — OSPF area 0
  - eth4 `10.0.0.58/30` — OSPF area 0
  - eth5 `10.0.0.85/30` — link to stateless-fw-lb-1 eth2, OSPF area 0
- **Routing:** OSPF process 1, area 0. `default-information originate always`
- **Notes:** conntrack enabled (STATEFUL).

---

### Firewall Configuration Details — RouterFW3

- **Role:** Inter-VLAN gateway. VLAN 1/10/20. OSPF router.
- **802.1Q VLANs/Subinterfaces on eth0:**
  - eth0.1 VLAN 1 `10.1.0.3/24` — OSPF area 0, passive
  - eth0.10 VLAN 10 `10.10.0.3/24` — OSPF area 0, passive
  - eth0.20 VLAN 20 `10.20.0.3/24` — OSPF area 0, passive
- **Transit Interfaces:**
  - eth1 `10.0.0.1/30` — OSPF area 0
  - eth2 `10.0.0.5/30` — OSPF area 0
  - eth3 `10.0.0.9/30` — OSPF area 0
- **Routing:** OSPF process 1, area 0

---

### Firewall Configuration Details — RouterFW4

- **Role:** Redundant inter-VLAN gateway. VLAN 1/10/20. OSPF router.
- **802.1Q VLANs/Subinterfaces on eth0:**
  - eth0.1 VLAN 1 `10.1.0.4/24` — OSPF area 0, passive
  - eth0.10 VLAN 10 `10.10.0.4/24` — OSPF area 0, passive
  - eth0.20 VLAN 20 `10.20.0.4/24` — OSPF area 0, passive
- **Transit Interfaces:**
  - eth1 `10.0.0.2/30` — OSPF area 0
  - eth2 `10.0.0.13/30` — OSPF area 0
  - eth3 `10.0.0.17/30` — OSPF area 0
- **Routing:** OSPF process 1, area 0

---

### Firewall Configuration Details — RouterFW5

- **Role:** Datacenter edge router. DC subnet. OSPF core.
- **Interfaces:**
  - eth0 `10.100.0.5/16` — OSPF area 0, passive
  - eth1 `10.0.0.21/30` — OSPF area 0
  - eth2 `10.0.0.25/30` — OSPF area 0
  - eth3 `10.0.0.29/30` — OSPF area 0
- **Routing:** OSPF process 1, area 0

---

### Firewall Configuration Details — RouterFW6

- **Role:** Redundant datacenter edge router. DC subnet. OSPF core.
- **Interfaces:**
  - eth0 `10.100.0.6/16` — OSPF area 0, passive
  - eth1 `10.0.0.22/30` — OSPF area 0
  - eth2 `10.0.0.33/30` — OSPF area 0
  - eth3 `10.0.0.37/30` — OSPF area 0
- **Routing:** OSPF process 1, area 0

---

## Load Balancers

| Name | IP Address | Algorithm | Backend Pool | Notes |
|------|-----------|-----------|-------------|-------|
| stateless-fw-lb-1 | eth0 `100.0.0.7/24`, eth1 `10.0.0.70/30`, eth2 `10.0.0.86/30` | HMARK `src,sport` (OutsideLB) | RouterFW1, RouterFW2 | rp_filter=0. ip_forward=1. NOTRACK. fwmark 101→FW1, 102→FW2 |
| stateless-fw-lb-2 | eth0 `100.0.0.8/24`, eth1 `10.0.0.74/30`, eth2 `10.0.0.90/30` | HMARK `src,sport` (OutsideLB) | RouterFW1, RouterFW2 | rp_filter=0. ip_forward=1. NOTRACK. fwmark 101→FW2, 102→FW1 |
| lb-dmz | eth0 `10.0.0.78/30`, eth1 `200.0.0.254/24`, eth2 `10.0.0.82/30` | Stateless gateway | DMZ server `200.0.0.100` | Single DMZ server. NOTRACK only. rp_filter=0. OSPF active eth0/eth2, passive eth1. TBD — pending discussion |

---

### Load Balancer Configuration Details — stateless-fw-lb-1

- **Role:** Hash Function based stateless LB (OutsideLB). Internet → Switch4 → RouterFW1 or RouterFW2. No FW state synchronization.
- **Interfaces:**
  - eth0 `100.0.0.7/24` — Internet Switch4, OSPF area 0, passive
  - eth1 `10.0.0.70/30` — link to RouterFW1 eth0, OSPF area 0
  - eth2 `10.0.0.86/30` — link to RouterFW2 eth5, OSPF area 0
- **Load Balancing Method:** HMARK `src,sport`. fwmark 101 → FW1 via eth1. fwmark 102 → FW2 via eth2. Same flow always hits the same FW — no state synchronization.

- **Policy Routing:**
```bash
ip rule add fwmark 101 lookup 101
ip rule add fwmark 102 lookup 102
# stateless-fw-lb-1:
ip route add default via 10.0.0.69 dev eth1 table 101  # fwmark 101 → RouterFW1
ip route add default via 10.0.0.85 dev eth2 table 102  # fwmark 102 → RouterFW2
# stateless-fw-lb-2 (swap FW1/FW2):
# ip route add default via 10.0.0.73 dev eth1 table 101  # fwmark 101 → RouterFW2
# ip route add default via 10.0.0.89 dev eth2 table 102  # fwmark 102 → RouterFW1
```

- **iptables rules (mangle table — DDoS + LB):**
```bash
# NOTRACK (stateless)
iptables -t raw -A PREROUTING -j NOTRACK
iptables -t raw -A OUTPUT -j NOTRACK

# ANTIDDOS chain: anti-spoofing, invalid TCP flags, ICMP rate limit, per-srcip rate limit
iptables -t mangle -N ANTIDDOS
iptables -t mangle -A ANTIDDOS -i eth0 -s 10.0.0.0/8 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 172.16.0.0/12 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 192.168.0.0/16 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 127.0.0.0/8 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 0.0.0.0/8 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 169.254.0.0/16 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 224.0.0.0/4 -j DROP
iptables -t mangle -A ANTIDDOS -i eth0 -s 240.0.0.0/4 -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
iptables -t mangle -A ANTIDDOS -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP
iptables -t mangle -A ANTIDDOS -p icmp \
  -m hashlimit --hashlimit-upto 10/sec --hashlimit-burst 20 \
  --hashlimit-mode srcip --hashlimit-name icmp_limit -j DROP
iptables -t mangle -A ANTIDDOS -p icmp -j DROP
iptables -t mangle -A ANTIDDOS \
  -m hashlimit --hashlimit-upto 1000/sec --hashlimit-burst 2000 \
  --hashlimit-mode srcip --hashlimit-name ddos_limit -j DROP
iptables -t mangle -A ANTIDDOS -j DROP

# LOADBALANCE chain: HMARK hash on src+sport, mod 2, offset 101
iptables -t mangle -N LOADBALANCE
iptables -t mangle -A LOADBALANCE -i eth0 \
  -j HMARK --hmark-rnd 1 \
  --hmark-tuple src,sport \
  --hmark-mod 2 \
  --hmark-offset 101

```
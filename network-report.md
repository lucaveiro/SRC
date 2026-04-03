# Network Infrastructure Report

## Table of Contents
- [Firewalls](#firewalls)
- [Load Balancers](#load-balancers)
- [Routers](#routers)
- [Other Devices](#other-devices)
- [Change Log](#change-log)

---

## Firewalls

| Name | IP Address | Location | Notes |
|------|------------|----------|-------|
| RouterFW1 | 10.0.0.69/30, 10.0.0.81/30, 10.0.0.53/30, 10.0.0.62/30, 10.0.0.42/30, 10.0.0.89/30 | (n/a) | OSPF area 0 on all eth; default-information originate always; eth5 new — link to stateless-fw-lb-2 |
| RouterFW2 | 10.0.0.73/30, 10.0.0.77/30, 10.0.0.54/30, 10.0.0.46/30, 10.0.0.58/30, 10.0.0.85/30 | (n/a) | OSPF area 0 on all eth; default-information originate always; eth5 new — link to stateless-fw-lb-1 |
| RouterFW3 | 10.1.0.3/24, 10.10.0.3/24, 10.20.0.3/24, 10.0.0.1/30, 10.0.0.5/30, 10.0.0.9/30 | (n/a) | VLAN subinterfaces on eth0; user VLAN interfaces are OSPF passive |
| RouterFW4 | 10.1.0.4/24, 10.10.0.4/24, 10.20.0.4/24, 10.0.0.2/30, 10.0.0.13/30, 10.0.0.17/30 | (n/a) | VLAN subinterfaces on eth0; user VLAN interfaces are OSPF passive |
| RouterFW5 | 10.100.0.5/16, 10.0.0.21/30, 10.0.0.25/30, 10.0.0.29/30 | (n/a) | Datacenter interface is OSPF passive |
| RouterFW6 | 10.100.0.6/16, 10.0.0.22/30, 10.0.0.33/30, 10.0.0.37/30 | (n/a) | Datacenter interface is OSPF passive |

### Firewall Configuration Details

#### RouterFW1
- **Role:** Edge FW/Router (Internet-side LB + DMZ-side LB + internal OSPF)
- **Interfaces:**
  - `eth0` — `10.0.0.69/30` (link to stateless-fw-lb-1 eth1), OSPF area 0 *(changed from `100.0.0.1/24` — resolves subnet overlap with LB-1)*
  - `eth1` — `10.0.0.81/30` (link to lb-dmz eth2), OSPF area 0 *(changed from `200.0.0.1/24` after lb-dmz insertion; passive removed)*
  - `eth2` — `10.0.0.53/30`, OSPF area 0
  - `eth3` — `10.0.0.62/30`, OSPF area 0
  - `eth4` — `10.0.0.42/30`, OSPF area 0
  - `eth5` — `10.0.0.89/30` (link to stateless-fw-lb-2 eth2), OSPF area 0 *(new adapter)*
- **Routing:**
  - OSPF process `1`, area `0`
  - `default-information originate always`
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 10.0.0.69/30
   ip ospf 1 area 0
  !
  interface eth1
   ip address 10.0.0.81/30
   ip ospf 1 area 0
  !
  interface eth2
   ip address 10.0.0.53/30
   ip ospf 1 area 0
  !
  interface eth3
   ip address 10.0.0.62/30
   ip ospf 1 area 0
  !
  interface eth4
   ip address 10.0.0.42/30
   ip ospf 1 area 0
  !
  interface eth5
   ip address 10.0.0.89/30
   ip ospf 1 area 0
  !
  router ospf 1
   default-information originate always
  ```
- **Notes:** Phantom `interface 0` removed from FRR config. eth5 is the new adapter connecting to stateless-fw-lb-2. Routes `100.0.0.0/24` and `200.0.0.0/24` learned via OSPF. conntrack disabled — required for stateless LB without FW synchronization. Verified working ✅

#### RouterFW2
- **Role:** Redundant edge FW/Router (Internet-side LB + DMZ-side LB + internal OSPF)
- **Interfaces:**
  - `eth0` — `10.0.0.73/30` (link to stateless-fw-lb-2 eth1), OSPF area 0 *(changed from `100.0.0.2/24` — resolves subnet overlap with LB-2)*
  - `eth1` — `10.0.0.77/30` (link to lb-dmz eth0), OSPF area 0 *(changed from `200.0.0.2/24` after lb-dmz insertion; passive removed)*
  - `eth2` — `10.0.0.54/30`, OSPF area 0
  - `eth3` — `10.0.0.46/30`, OSPF area 0
  - `eth4` — `10.0.0.58/30`, OSPF area 0
  - `eth5` — `10.0.0.85/30` (link to stateless-fw-lb-1 eth2), OSPF area 0 *(new adapter)*
- **Routing:**
  - OSPF process `1`, area `0`
  - `default-information originate always`
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 10.0.0.73/30
   ip ospf 1 area 0
  !
  interface eth1
   ip address 10.0.0.77/30
   ip ospf 1 area 0
  !
  interface eth2
   ip address 10.0.0.54/30
   ip ospf 1 area 0
  !
  interface eth3
   ip address 10.0.0.46/30
   ip ospf 1 area 0
  !
  interface eth4
   ip address 10.0.0.58/30
   ip ospf 1 area 0
  !
  interface eth5
   ip address 10.0.0.85/30
   ip ospf 1 area 0
  !
  router ospf 1
   default-information originate always
  ```
- **Notes:** eth5 is the new adapter connecting to stateless-fw-lb-1. Routes `100.0.0.0/24` and `200.0.0.0/24` learned via OSPF. conntrack disabled — required for stateless LB without FW synchronization. Verified working ✅

#### RouterFW3
- **Role:** Inter-VLAN gateway (VLAN 1/10/20) + OSPF router
- **802.1Q VLANs/Subinterfaces on `eth0`:**
  - `eth0.1` (VLAN 1) — `10.1.0.3/24`, OSPF area 0, **passive**
  - `eth0.10` (VLAN 10) — `10.10.0.3/24`, OSPF area 0, **passive**
  - `eth0.20` (VLAN 20) — `10.20.0.3/24`, OSPF area 0, **passive**
- **Transit Interfaces:**
  - `eth1` — `10.0.0.1/30`, OSPF area 0
  - `eth2` — `10.0.0.5/30`, OSPF area 0
  - `eth3` — `10.0.0.9/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

#### RouterFW4
- **Role:** Redundant inter-VLAN gateway (VLAN 1/10/20) + OSPF router
- **802.1Q VLANs/Subinterfaces on `eth0`:**
  - `eth0.1` (VLAN 1) — `10.1.0.4/24`, OSPF area 0, **passive**
  - `eth0.10` (VLAN 10) — `10.10.0.4/24`, OSPF area 0, **passive**
  - `eth0.20` (VLAN 20) — `10.20.0.4/24`, OSPF area 0, **passive**
- **Transit Interfaces:**
  - `eth1` — `10.0.0.2/30`, OSPF area 0
  - `eth2` — `10.0.0.13/30`, OSPF area 0
  - `eth3` — `10.0.0.17/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

#### RouterFW5
- **Role:** Datacenter edge router (DC subnet + OSPF core)
- **Interfaces:**
  - `eth0` — `10.100.0.5/16`, OSPF area 0, **passive**
  - `eth1` — `10.0.0.21/30`, OSPF area 0
  - `eth2` — `10.0.0.25/30`, OSPF area 0
  - `eth3` — `10.0.0.29/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

#### RouterFW6
- **Role:** Redundant datacenter edge router (DC subnet + OSPF core)
- **Interfaces:**
  - `eth0` — `10.100.0.6/16`, OSPF area 0, **passive**
  - `eth1` — `10.0.0.22/30`, OSPF area 0
  - `eth2` — `10.0.0.33/30`, OSPF area 0
  - `eth3` — `10.0.0.37/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

---

## Load Balancers

| Name | IP Address | Algorithm | Backend Pool | Notes |
|------|------------|-----------|--------------|-------|
| stateless-fw-lb-1 | eth0: 100.0.0.7/24, eth1: 10.0.0.70/30, eth2: 10.0.0.86/30 | Hash Function based LB (stateless, no FW sync) | RouterFW1 + RouterFW2 | OSPF passive on eth0; active on eth1/eth2; ip_forward=1; kernel ECMP fib_multipath_hash_policy=1; no conntrack |
| stateless-fw-lb-2 | eth0: 100.0.0.8/24, eth1: 10.0.0.74/30, eth2: 10.0.0.90/30 | Hash Function based LB (stateless, no FW sync) | RouterFW1 + RouterFW2 | OSPF passive on eth0; active on eth1/eth2; ip_forward=1; kernel ECMP fib_multipath_hash_policy=1; no conntrack |
| lb-dmz | eth0: 10.0.0.78/30, eth1: 200.0.0.254/24, eth2: 10.0.0.82/30 | Stateless ECMP L4 hash | DMZ servers via Switch3 | OSPF active eth0/eth2; passive eth1 (DMZ); ip_forward=1 |

### Load Balancer Configuration Details

#### stateless-fw-lb-1
- **Role:** Hash Function based stateless LB — Internet (Switch4) → RouterFW1 or RouterFW2 (no FW state synchronization)
- **Interfaces:**
  - `eth0` — `100.0.0.7/24` (Internet / Switch4), OSPF area 0, **passive**
  - `eth1` — `10.0.0.70/30` (link to RouterFW1 eth0), OSPF area 0
  - `eth2` — `10.0.0.86/30` (link to RouterFW2 eth5), OSPF area 0 *(new adapter)*
- **Load Balancing Method:** nftables `jhash` over 5-tuple (src IP, dst IP, protocol, src port, dst port) mod 2 → deterministic per-flow forwarding to FW1 (`10.0.0.69` via eth1) or FW2 (`10.0.0.73` via eth2). Same flow always hits the same FW → no firewall state synchronization required.
- **Kernel config:**
  ```bash
  # Enable L3+L4 hash for multipath (persistent across reboots via /etc/sysctl.d/)
  sysctl -w net.ipv4.fib_multipath_hash_policy=1
  ```
- **nftables hash-based LB config:**
  ```bash
  nft add table ip hash_lb
  nft add chain ip hash_lb prerouting '{ type nat hook prerouting priority dstnat; }'
  nft add rule ip hash_lb prerouting     ip protocol { tcp, udp }     dnat ip to jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {       0 : 10.0.0.69,       1 : 10.0.0.73      }
  ```
- **nftables running config (final):**
  ```
  table ip hash_lb {
    chain prerouting {
      type nat hook prerouting priority dstnat;
      ip protocol { tcp, udp } dnat ip to         jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {
          0 : 10.0.0.69,
          1 : 10.0.0.73
        }
    }
  }
  ```
- **FRRouting running-config (final):**
  ```
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
  ```
- **Notes:** No nftables rules configured — load balancing handled entirely by kernel ECMP. No conntrack, no session table. `100.0.0.0/24` announced via OSPF `network` statement so RouterC1/C2 learn the return path. Verified working ✅

#### stateless-fw-lb-2
- **Role:** Hash Function based stateless LB — Internet (Switch4) → RouterFW1 or RouterFW2 (no FW state synchronization)
- **Interfaces:**
  - `eth0` — `100.0.0.8/24` (Internet / Switch4), OSPF area 0, **passive**
  - `eth1` — `10.0.0.74/30` (link to RouterFW2 eth0), OSPF area 0
  - `eth2` — `10.0.0.90/30` (link to RouterFW1 eth5), OSPF area 0 *(new adapter)*
- **Load Balancing Method:** Identical to LB-1 — kernel ECMP with `fib_multipath_hash_policy=1`. Both LBs apply the same kernel hash policy. Since the hash is computed per-flow by the kernel, any packet for the same flow routed through either LB will take a consistent path to the same FW.
- **Kernel config:**
  ```bash
  sysctl -w net.ipv4.fib_multipath_hash_policy=1
  ```
- **nftables hash-based LB config:**
  ```bash
  nft add table ip hash_lb
  nft add chain ip hash_lb prerouting '{ type nat hook prerouting priority dstnat; }'
  nft add rule ip hash_lb prerouting     ip protocol { tcp, udp }     dnat ip to jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {       0 : 10.0.0.69,       1 : 10.0.0.73      }
  ```
- **nftables running config (final):**
  ```
  table ip hash_lb {
    chain prerouting {
      type nat hook prerouting priority dstnat;
      ip protocol { tcp, udp } dnat ip to         jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {
          0 : 10.0.0.69,
          1 : 10.0.0.73
        }
    }
  }
  ```
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 100.0.0.8/24
   ip ospf 1 area 0
   ip ospf passive
  !
  interface eth1
   ip address 10.0.0.74/30
   ip ospf 1 area 0
  !
  interface eth2
   ip address 10.0.0.90/30
   ip ospf 1 area 0
  !
  router ospf 1
  ```
- **Notes:** No nftables rules configured. No conntrack, no session table. `100.0.0.0/24` announced via OSPF `network` statement. Verified working ✅

#### lb-dmz
- **Role:** Stateless DMZ LB — RouterFW1/FW2 → DMZ servers via Switch3
- **Interfaces:**
  - `eth0` — `10.0.0.78/30` (link to RouterFW2 eth1), OSPF area 0
  - `eth1` — `200.0.0.254/24` (DMZ gateway / Switch3), OSPF area 0, **passive**
  - `eth2` — `10.0.0.82/30` (link to RouterFW1 eth1), OSPF area 0
- **Routing:** Default route learned via OSPF from RouterFW1/FW2
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 10.0.0.78/30
   ip ospf 1 area 0
  !
  interface eth1
   ip address 200.0.0.254/24
   ip ospf 1 area 0
   ip ospf passive
  !
  interface eth2
   ip address 10.0.0.82/30
   ip ospf 1 area 0
  !
  router ospf 1
  ```
- **Notes:** `default-information originate always` NOT configured — lb-dmz has no Internet exit. Resolves routing loop between FW1↔FW2 for DMZ-bound traffic.

---

## Routers

| Name | IP Address | Location | Routing Protocol | Notes |
|------|------------|----------|-----------------|-------|
| RouterC1 | 10.0.0.41/30, 10.0.0.45/30, 10.0.0.49/30, 10.0.0.34/30, 10.0.0.30/30, 10.0.0.14/30, 10.0.0.10/30 | (n/a) | OSPF (proc 1, area 0) | Core router with multiple /30 transit links |
| RouterC2 | 10.0.0.57/30, 10.0.0.61/30, 10.0.0.50/30, 10.0.0.6/30, 10.0.0.18/30, 10.0.0.26/30, 10.0.0.38/30 | (n/a) | OSPF (proc 1, area 0) | Core router with multiple /30 transit links |

### Router Configuration Details

#### RouterC1
- **Routing:** OSPF process `1`, area `0`
- **Interfaces:**
  - `eth0` — `10.0.0.41/30`, OSPF area 0
  - `eth1` — `10.0.0.45/30`, OSPF area 0
  - `eth2` — `10.0.0.49/30`, OSPF area 0
  - `eth3` — `10.0.0.34/30`, OSPF area 0
  - `eth4` — `10.0.0.30/30`, OSPF area 0
  - `eth5` — `10.0.0.14/30`, OSPF area 0
  - `eth6` — `10.0.0.10/30`, OSPF area 0

#### RouterC2
- **Routing:** OSPF process `1`, area `0`
- **Interfaces:**
  - `eth0` — `10.0.0.57/30`, OSPF area 0
  - `eth1` — `10.0.0.61/30`, OSPF area 0
  - `eth2` — `10.0.0.50/30`, OSPF area 0
  - `eth3` — `10.0.0.6/30`, OSPF area 0
  - `eth4` — `10.0.0.18/30`, OSPF area 0
  - `eth5` — `10.0.0.26/30`, OSPF area 0
  - `eth6` — `10.0.0.38/30`, OSPF area 0

---

## Other Devices

| Name | Type | IP Address | Location | Notes |
|------|------|------------|----------|-------|
| L2-SW1 | Layer 2 Switch | (n/a) | (n/a) | VLANs 1/10/20 for access ports; dot1q trunks to FW3 and FW4 |
| PC-VLAN1 | PC | 10.1.0.100/24 | (n/a) | Default via 10.1.0.3 (metric 10) then 10.1.0.4 (metric 20) |
| PC-VLAN10 | PC | 10.10.0.100/24 | (n/a) | Default via 10.10.0.3 (metric 10) then 10.10.0.4 (metric 20) |
| PC-VLAN20 | PC | 10.20.0.100/24 | (n/a) | Default via 10.20.0.3 (metric 10) then 10.20.0.4 (metric 20) |
| PC-DC | PC | 10.100.0.100/24 | (n/a) | Default via 10.100.0.5 (metric 10) then 10.100.0.6 (metric 20) |
| PC-DMZ | PC | 200.0.0.100/24 | (n/a) | Default via 200.0.0.254 (lb-dmz) *(corrected from 200.0.0.1/200.0.0.2)* |
| PC-INET | PC | 100.0.0.100/24 | (n/a) | ECMP default via 100.0.0.7 (LB-1) and 100.0.0.8 (LB-2) equal weight — kernel hash distributes flows; stale routes 100.0.0.1 and 100.0.0.2 removed |

### Device Configuration Details

#### L2-SW1 (Layer 2 Switch)
- **VLANs:** 1, 10, 20
- **Access ports:** configured for VLAN 1 / 10 / 20 (to test PCs)
- **Trunk ports:** 802.1Q (dot1q) trunks to RouterFW3 and RouterFW4

#### PCs
- **PC (VLAN 1)**
  - IP: `10.1.0.100/24`
  - Default routes: via `10.1.0.3` metric 10 / via `10.1.0.4` metric 20
- **PC (VLAN 10)**
  - IP: `10.10.0.100/24`
  - Default routes: via `10.10.0.3` metric 10 / via `10.10.0.4` metric 20
- **PC (VLAN 20)**
  - IP: `10.20.0.100/24`
  - Default routes: via `10.20.0.3` metric 10 / via `10.20.0.4` metric 20
- **PC (Datacenter)**
  - IP: `10.100.0.100/24`
  - Default routes: via `10.100.0.5` metric 10 / via `10.100.0.6` metric 20
- **PC (DMZ)**
  - IP: `200.0.0.100/24`
  - Default route: via `200.0.0.254` (lb-dmz eth1) *(corrected from `200.0.0.1` metric 10 / `200.0.0.2` metric 20)*
- **PC (Internet)**
  - IP: `100.0.0.100/24`
  - ECMP default routes (equal weight — hash-based flow distribution):
    ```bash
    ip route add default nexthop via 100.0.0.7 weight 1 nexthop via 100.0.0.8 weight 1
    ```
  - **Notes:** Changed from primary/backup (metric 10/20) to equal-cost ECMP. Kernel uses L3+L4 hash (`net.ipv4.fib_multipath_hash_policy=1`) to distribute flows. Same flow always hits the same LB → same FW → no state sync needed.

---

## Change Log

| Date | Changed By | Device | Description |
|------|-----------|--------|-------------|
| 2026-03-27 | lucaveiro | Multiple | Initial report: RouterFW1–FW6, RouterC1–C2, L2-SW1, all PCs with addressing and OSPF details. |
| 2026-03-31 | lucaveiro | stateless-fw-lb-1 | Fixed subnet overlaps (removed 100.0.0.3/24 from eth1, 100.0.0.5/25 from eth2). Added 10.0.0.70/30 to eth1. Removed phantom `interface 0`. Removed passive from eth1. Fixed default route loop. |
| 2026-03-31 | lucaveiro | stateless-fw-lb-2 | Fixed subnet overlaps (removed 100.0.0.4/30 from eth1, 100.0.0.6/24 from eth2). Added missing `router ospf 1`. Removed passive from eth1. |
| 2026-03-31 | lucaveiro | RouterFW1 | eth0 changed from `100.0.0.1/24` to `10.0.0.69/30` (resolves subnet overlap with LB-1). Removed phantom `interface 0`. |
| 2026-03-31 | lucaveiro | RouterFW2 | eth0 changed from `100.0.0.2/24` to `10.0.0.73/30` (resolves subnet overlap with LB-2). |
| 2026-03-31 | lucaveiro | PC-INET | Default gateways corrected: `100.0.0.1` → `100.0.0.7` (LB-1, metric 10); `100.0.0.2` → `100.0.0.8` (LB-2, metric 20). |
| 2026-04-02 | lucaveiro | lb-dmz | New device added. eth0 `10.0.0.78/30` (FW2 side), eth1 `200.0.0.254/24` (DMZ gateway, passive), eth2 `10.0.0.82/30` (FW1 side). Resolves FW1↔FW2 DMZ routing loop. |
| 2026-04-02 | lucaveiro | RouterFW1 | eth1 changed from `200.0.0.1/24` to `10.0.0.81/30` after lb-dmz insertion. OSPF passive removed from eth1. |
| 2026-04-02 | lucaveiro | RouterFW2 | eth1 changed from `200.0.0.2/24` to `10.0.0.77/30` after lb-dmz insertion. OSPF passive removed from eth1. |
| 2026-04-02 | lucaveiro | PC-DMZ | Default gateway corrected from `200.0.0.1/200.0.0.2` to `200.0.0.254` (lb-dmz eth1). |
| 2026-04-03 | lucaveiro | stateless-fw-lb-1 | Changed to Hash Function based LB (stateless, no FW sync). Added eth2 `10.0.0.86/30` (link to RouterFW2 eth5). Kernel ECMP fib_multipath_hash_policy=1 — no nftables NAT, no conntrack. Added OSPF network 100.0.0.0/24 for return path. Verified ✅ |
| 2026-04-03 | lucaveiro | stateless-fw-lb-2 | Same change as LB-1 — kernel ECMP fib_multipath_hash_policy=1. Added eth2 `10.0.0.90/30` (link to RouterFW1 eth5). No nftables NAT, no conntrack. Added OSPF network 100.0.0.0/24. Verified ✅ |
| 2026-04-03 | lucaveiro | RouterFW1 | Added eth5 `10.0.0.89/30` — new adapter linking to stateless-fw-lb-2 eth2. Disabled conntrack for stateless LB compatibility. Verified ✅ |
| 2026-04-03 | lucaveiro | RouterFW2 | Added eth5 `10.0.0.85/30` — new adapter linking to stateless-fw-lb-1 eth2. Disabled conntrack for stateless LB compatibility. Verified ✅ |
| 2026-04-03 | lucaveiro | PC-INET | Changed to equal-cost ECMP (nexthop weight 1/1). Removed stale routes via 100.0.0.1 (metric 10) and 100.0.0.2 (metric 20). Verified ✅ |

---

## Firewall Rules

### Security Policies Overview

| # | Policy | Devices |
|---|--------|---------|
| 1 | DDoS protection from Internet | RouterFW1, RouterFW2 |
| 2 | Internal → Internet: TCP/UDP 80, 443 only | RouterFW1, RouterFW2 |
| 3 | VLAN10 → VoIP UDP 5060 to predefined IPs only | RouterFW3/4/5/6 |
| 4 | DMZ services accessible from Internet and internal network | RouterFW1, RouterFW2 |
| 5 | Intranet/Storage + internal DNS: VLAN10 and VLAN20 only | RouterFW3/4/5/6 |
| 6 | Databases TCP 3306: VLAN20 only | RouterFW3/4/5/6 |
| 7 | VLAN1 device 10.1.0.100: PING + SSH to all network devices | RouterFW1/2/3/4/5/6 |
| 8 | VLAN10 ↔ VLAN20: Samba TCP 139/445 only | RouterFW3/4/5/6 |

> **Note:** All firewalls have conntrack disabled (stateless LB requirement). Return traffic must be explicitly permitted using TCP flags (ACK, RST, FIN,ACK) and UDP source ports — `--state ESTABLISHED,RELATED` cannot be used.

---

### RouterFW1 + RouterFW2 — Perimeter Rules

Applies to both RouterFW1 and RouterFW2 identically.

```bash
#!/bin/bash
# ============================================================
# FIREWALL RULES — RouterFW1 / RouterFW2 (Perimeter)
# ============================================================

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t mangle -F

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# INPUT — loopback + OSPF
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p ospf -j ACCEPT

# INPUT — SSH + PING from VLAN1 admin device only
iptables -A INPUT -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100 -p icmp -j ACCEPT

# Policy 1 — DDoS protection
iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
iptables -A FORWARD -i eth0 -p icmp -m limit --limit 5/s --limit-burst 10 -j ACCEPT
iptables -A FORWARD -i eth0 -p icmp -j DROP

# Policy 2 — Internal → Internet: TCP/UDP 80,443 only
iptables -A FORWARD -s 10.1.0.0/24   -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.1.0.0/24   -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT

# Policy 4 — Internet → DMZ
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT  # HTTPS
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT  # HTTPS UDP
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT  # IMAP
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT  # SMTP
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT  # DNS
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT  # DNS TCP

# Policy 4 — Internal → DMZ
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT

# DMZ → Internet (SMTP relay, DNS outbound, HTTPS)
iptables -A FORWARD -s 200.0.0.0/24 -o eth0 -p tcp --dport 25  -j ACCEPT
iptables -A FORWARD -s 200.0.0.0/24 -o eth0 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 200.0.0.0/24 -o eth0 -p tcp --dport 443 -j ACCEPT

# Return traffic (stateless — no conntrack)
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK ACK     -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL RST          -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL FIN,ACK      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-reply      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type time-exceeded   -j ACCEPT
iptables -A FORWARD -p udp --sport 53  -j ACCEPT
iptables -A FORWARD -p udp --sport 443 -j ACCEPT
```

---

### RouterFW3/4/5/6 — Internal Rules

Applies to all internal firewalls.

```bash
#!/bin/bash
# ============================================================
# FIREWALL RULES — RouterFW3/4/5/6 (Internal)
# ============================================================

# Flush existing rules
iptables -F
iptables -X
iptables -t mangle -F

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# INPUT — loopback + OSPF
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p ospf -j ACCEPT

# Policy 7 — VLAN1 admin device: SSH + PING to all devices
iptables -A INPUT   -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT   -s 10.1.0.100 -p icmp           -j ACCEPT
iptables -A FORWARD -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.1.0.100 -p icmp           -j ACCEPT

# Policy 3 — VLAN10 → VoIP UDP 5060 (predefined IPs only)
# Replace <VOIP_SERVER_1> and <VOIP_SERVER_2> with real IPs
iptables -A FORWARD -s 10.10.0.0/24 -d <VOIP_SERVER_1> -p udp --dport 5060 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24 -d <VOIP_SERVER_2> -p udp --dport 5060 -j ACCEPT
iptables -A FORWARD -s <VOIP_SERVER_1> -d 10.10.0.0/24 -p udp --sport 5060 -j ACCEPT
iptables -A FORWARD -s <VOIP_SERVER_2> -d 10.10.0.0/24 -p udp --sport 5060 -j ACCEPT

# Policy 5 — Intranet TCP 443 + internal DNS: VLAN10 and VLAN20 only
iptables -A FORWARD -s 10.10.0.0/24  -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -d 10.100.0.0/16 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -d 10.100.0.0/16 -p tcp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p tcp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.10.0.0/24  -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.20.0.0/24  -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.10.0.0/24  -p udp --sport 53  -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.20.0.0/24  -p udp --sport 53  -j ACCEPT

# Policy 6 — Databases TCP 3306: VLAN20 only
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p tcp --dport 3306 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.20.0.0/24  -p tcp --sport 3306 -j ACCEPT

# Policy 8 — VLAN10 ↔ VLAN20: Samba TCP 139/445 only
iptables -A FORWARD -s 10.10.0.0/24 -d 10.20.0.0/24 -p tcp -m multiport --dports 139,445 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24 -d 10.10.0.0/24 -p tcp -m multiport --dports 139,445 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24 -d 10.10.0.0/24 -p tcp -m multiport --sports 139,445 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24 -d 10.20.0.0/24 -p tcp -m multiport --sports 139,445 -j ACCEPT

# Return traffic (stateless — no conntrack)
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK ACK     -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL RST          -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL FIN,ACK      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-reply      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type time-exceeded   -j ACCEPT
iptables -A FORWARD -p udp --sport 53  -j ACCEPT
iptables -A FORWARD -p udp --sport 443 -j ACCEPT
```

---

### Persist Rules After Reboot

```bash
# Save rules
iptables-save > /etc/iptables/rules.v4

# Restore on boot (Debian/Ubuntu)
apt-get install -y iptables-persistent
```
# Network Infrastructure Report

## Table of Contents
- [Firewalls](#firewalls)
- [Load Balancers](#load-balancers)
- [Routers](#routers)
- [Other Devices](#other-devices)
- [Change Log](#change-log)

---

## Firewalls

| Name | IP Address | Location | Notes |
|------|------------|----------|-------|
| RouterFW1 | 10.0.0.69/30, 10.0.0.81/30, 10.0.0.53/30, 10.0.0.62/30, 10.0.0.42/30, 10.0.0.89/30 | (n/a) | OSPF area 0 on all eth; default-information originate always; eth5 new — link to stateless-fw-lb-2 |
| RouterFW2 | 10.0.0.73/30, 10.0.0.77/30, 10.0.0.54/30, 10.0.0.46/30, 10.0.0.58/30, 10.0.0.85/30 | (n/a) | OSPF area 0 on all eth; default-information originate always; eth5 new — link to stateless-fw-lb-1 |
| RouterFW3 | 10.1.0.3/24, 10.10.0.3/24, 10.20.0.3/24, 10.0.0.1/30, 10.0.0.5/30, 10.0.0.9/30 | (n/a) | VLAN subinterfaces on eth0; user VLAN interfaces are OSPF passive |
| RouterFW4 | 10.1.0.4/24, 10.10.0.4/24, 10.20.0.4/24, 10.0.0.2/30, 10.0.0.13/30, 10.0.0.17/30 | (n/a) | VLAN subinterfaces on eth0; user VLAN interfaces are OSPF passive |
| RouterFW5 | 10.100.0.5/16, 10.0.0.21/30, 10.0.0.25/30, 10.0.0.29/30 | (n/a) | Datacenter interface is OSPF passive |
| RouterFW6 | 10.100.0.6/16, 10.0.0.22/30, 10.0.0.33/30, 10.0.0.37/30 | (n/a) | Datacenter interface is OSPF passive |

### Firewall Configuration Details

#### RouterFW1
- **Role:** Edge FW/Router (Internet-side LB + DMZ-side LB + internal OSPF)
- **Interfaces:**
  - `eth0` — `10.0.0.69/30` (link to stateless-fw-lb-1 eth1), OSPF area 0 *(changed from `100.0.0.1/24` — resolves subnet overlap with LB-1)*
  - `eth1` — `10.0.0.81/30` (link to lb-dmz eth2), OSPF area 0 *(changed from `200.0.0.1/24` after lb-dmz insertion; passive removed)*
  - `eth2` — `10.0.0.53/30`, OSPF area 0
  - `eth3` — `10.0.0.62/30`, OSPF area 0
  - `eth4` — `10.0.0.42/30`, OSPF area 0
  - `eth5` — `10.0.0.89/30` (link to stateless-fw-lb-2 eth2), OSPF area 0 *(new adapter)*
- **Routing:**
  - OSPF process `1`, area `0`
  - `default-information originate always`
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 10.0.0.69/30
   ip ospf 1 area 0
  !
  interface eth1
   ip address 10.0.0.81/30
   ip ospf 1 area 0
  !
  interface eth2
   ip address 10.0.0.53/30
   ip ospf 1 area 0
  !
  interface eth3
   ip address 10.0.0.62/30
   ip ospf 1 area 0
  !
  interface eth4
   ip address 10.0.0.42/30
   ip ospf 1 area 0
  !
  interface eth5
   ip address 10.0.0.89/30
   ip ospf 1 area 0
  !
  router ospf 1
   default-information originate always
  ```
- **Notes:** Phantom `interface 0` removed from FRR config. eth5 is the new adapter connecting to stateless-fw-lb-2. Routes `100.0.0.0/24` and `200.0.0.0/24` learned via OSPF. conntrack disabled — required for stateless LB without FW synchronization. Verified working ✅

#### RouterFW2
- **Role:** Redundant edge FW/Router (Internet-side LB + DMZ-side LB + internal OSPF)
- **Interfaces:**
  - `eth0` — `10.0.0.73/30` (link to stateless-fw-lb-2 eth1), OSPF area 0 *(changed from `100.0.0.2/24` — resolves subnet overlap with LB-2)*
  - `eth1` — `10.0.0.77/30` (link to lb-dmz eth0), OSPF area 0 *(changed from `200.0.0.2/24` after lb-dmz insertion; passive removed)*
  - `eth2` — `10.0.0.54/30`, OSPF area 0
  - `eth3` — `10.0.0.46/30`, OSPF area 0
  - `eth4` — `10.0.0.58/30`, OSPF area 0
  - `eth5` — `10.0.0.85/30` (link to stateless-fw-lb-1 eth2), OSPF area 0 *(new adapter)*
- **Routing:**
  - OSPF process `1`, area `0`
  - `default-information originate always`
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 10.0.0.73/30
   ip ospf 1 area 0
  !
  interface eth1
   ip address 10.0.0.77/30
   ip ospf 1 area 0
  !
  interface eth2
   ip address 10.0.0.54/30
   ip ospf 1 area 0
  !
  interface eth3
   ip address 10.0.0.46/30
   ip ospf 1 area 0
  !
  interface eth4
   ip address 10.0.0.58/30
   ip ospf 1 area 0
  !
  interface eth5
   ip address 10.0.0.85/30
   ip ospf 1 area 0
  !
  router ospf 1
   default-information originate always
  ```
- **Notes:** eth5 is the new adapter connecting to stateless-fw-lb-1. Routes `100.0.0.0/24` and `200.0.0.0/24` learned via OSPF. conntrack disabled — required for stateless LB without FW synchronization. Verified working ✅

#### RouterFW3
- **Role:** Inter-VLAN gateway (VLAN 1/10/20) + OSPF router
- **802.1Q VLANs/Subinterfaces on `eth0`:**
  - `eth0.1` (VLAN 1) — `10.1.0.3/24`, OSPF area 0, **passive**
  - `eth0.10` (VLAN 10) — `10.10.0.3/24`, OSPF area 0, **passive**
  - `eth0.20` (VLAN 20) — `10.20.0.3/24`, OSPF area 0, **passive**
- **Transit Interfaces:**
  - `eth1` — `10.0.0.1/30`, OSPF area 0
  - `eth2` — `10.0.0.5/30`, OSPF area 0
  - `eth3` — `10.0.0.9/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

#### RouterFW4
- **Role:** Redundant inter-VLAN gateway (VLAN 1/10/20) + OSPF router
- **802.1Q VLANs/Subinterfaces on `eth0`:**
  - `eth0.1` (VLAN 1) — `10.1.0.4/24`, OSPF area 0, **passive**
  - `eth0.10` (VLAN 10) — `10.10.0.4/24`, OSPF area 0, **passive**
  - `eth0.20` (VLAN 20) — `10.20.0.4/24`, OSPF area 0, **passive**
- **Transit Interfaces:**
  - `eth1` — `10.0.0.2/30`, OSPF area 0
  - `eth2` — `10.0.0.13/30`, OSPF area 0
  - `eth3` — `10.0.0.17/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

#### RouterFW5
- **Role:** Datacenter edge router (DC subnet + OSPF core)
- **Interfaces:**
  - `eth0` — `10.100.0.5/16`, OSPF area 0, **passive**
  - `eth1` — `10.0.0.21/30`, OSPF area 0
  - `eth2` — `10.0.0.25/30`, OSPF area 0
  - `eth3` — `10.0.0.29/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

#### RouterFW6
- **Role:** Redundant datacenter edge router (DC subnet + OSPF core)
- **Interfaces:**
  - `eth0` — `10.100.0.6/16`, OSPF area 0, **passive**
  - `eth1` — `10.0.0.22/30`, OSPF area 0
  - `eth2` — `10.0.0.33/30`, OSPF area 0
  - `eth3` — `10.0.0.37/30`, OSPF area 0
- **Routing:** OSPF process `1`, area `0`

---

## Load Balancers

| Name | IP Address | Algorithm | Backend Pool | Notes |
|------|------------|-----------|--------------|-------|
| stateless-fw-lb-1 | eth0: 100.0.0.7/24, eth1: 10.0.0.70/30, eth2: 10.0.0.86/30 | Hash Function based LB (stateless, no FW sync) | RouterFW1 + RouterFW2 | OSPF passive on eth0; active on eth1/eth2; ip_forward=1; kernel ECMP fib_multipath_hash_policy=1; no conntrack |
| stateless-fw-lb-2 | eth0: 100.0.0.8/24, eth1: 10.0.0.74/30, eth2: 10.0.0.90/30 | Hash Function based LB (stateless, no FW sync) | RouterFW1 + RouterFW2 | OSPF passive on eth0; active on eth1/eth2; ip_forward=1; kernel ECMP fib_multipath_hash_policy=1; no conntrack |
| lb-dmz | eth0: 10.0.0.78/30, eth1: 200.0.0.254/24, eth2: 10.0.0.82/30 | Stateless ECMP L4 hash | DMZ servers via Switch3 | OSPF active eth0/eth2; passive eth1 (DMZ); ip_forward=1 |

### Load Balancer Configuration Details

#### stateless-fw-lb-1
- **Role:** Hash Function based stateless LB — Internet (Switch4) → RouterFW1 or RouterFW2 (no FW state synchronization)
- **Interfaces:**
  - `eth0` — `100.0.0.7/24` (Internet / Switch4), OSPF area 0, **passive**
  - `eth1` — `10.0.0.70/30` (link to RouterFW1 eth0), OSPF area 0
  - `eth2` — `10.0.0.86/30` (link to RouterFW2 eth5), OSPF area 0 *(new adapter)*
- **Load Balancing Method:** nftables `jhash` over 5-tuple (src IP, dst IP, protocol, src port, dst port) mod 2 → deterministic per-flow forwarding to FW1 (`10.0.0.69` via eth1) or FW2 (`10.0.0.73` via eth2). Same flow always hits the same FW → no firewall state synchronization required.
- **Kernel config:**
  ```bash
  # Enable L3+L4 hash for multipath (persistent across reboots via /etc/sysctl.d/)
  sysctl -w net.ipv4.fib_multipath_hash_policy=1
  ```
- **nftables hash-based LB config:**
  ```bash
  nft add table ip hash_lb
  nft add chain ip hash_lb prerouting '{ type nat hook prerouting priority dstnat; }'
  nft add rule ip hash_lb prerouting     ip protocol { tcp, udp }     dnat ip to jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {       0 : 10.0.0.69,       1 : 10.0.0.73      }
  ```
- **nftables running config (final):**
  ```
  table ip hash_lb {
    chain prerouting {
      type nat hook prerouting priority dstnat;
      ip protocol { tcp, udp } dnat ip to         jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {
          0 : 10.0.0.69,
          1 : 10.0.0.73
        }
    }
  }
  ```
- **FRRouting running-config (final):**
  ```
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
  ```
- **Notes:** No nftables rules configured — load balancing handled entirely by kernel ECMP. No conntrack, no session table. `100.0.0.0/24` announced via OSPF `network` statement so RouterC1/C2 learn the return path. Verified working ✅

#### stateless-fw-lb-2
- **Role:** Hash Function based stateless LB — Internet (Switch4) → RouterFW1 or RouterFW2 (no FW state synchronization)
- **Interfaces:**
  - `eth0` — `100.0.0.8/24` (Internet / Switch4), OSPF area 0, **passive**
  - `eth1` — `10.0.0.74/30` (link to RouterFW2 eth0), OSPF area 0
  - `eth2` — `10.0.0.90/30` (link to RouterFW1 eth5), OSPF area 0 *(new adapter)*
- **Load Balancing Method:** Identical to LB-1 — kernel ECMP with `fib_multipath_hash_policy=1`. Both LBs apply the same kernel hash policy. Since the hash is computed per-flow by the kernel, any packet for the same flow routed through either LB will take a consistent path to the same FW.
- **Kernel config:**
  ```bash
  sysctl -w net.ipv4.fib_multipath_hash_policy=1
  ```
- **nftables hash-based LB config:**
  ```bash
  nft add table ip hash_lb
  nft add chain ip hash_lb prerouting '{ type nat hook prerouting priority dstnat; }'
  nft add rule ip hash_lb prerouting     ip protocol { tcp, udp }     dnat ip to jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {       0 : 10.0.0.69,       1 : 10.0.0.73      }
  ```
- **nftables running config (final):**
  ```
  table ip hash_lb {
    chain prerouting {
      type nat hook prerouting priority dstnat;
      ip protocol { tcp, udp } dnat ip to         jhash ip saddr . ip daddr . ip protocol . tcp sport . tcp dport mod 2 map {
          0 : 10.0.0.69,
          1 : 10.0.0.73
        }
    }
  }
  ```
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 100.0.0.8/24
   ip ospf 1 area 0
   ip ospf passive
  !
  interface eth1
   ip address 10.0.0.74/30
   ip ospf 1 area 0
  !
  interface eth2
   ip address 10.0.0.90/30
   ip ospf 1 area 0
  !
  router ospf 1
  ```
- **Notes:** No nftables rules configured. No conntrack, no session table. `100.0.0.0/24` announced via OSPF `network` statement. Verified working ✅

#### lb-dmz
- **Role:** Stateless DMZ LB — RouterFW1/FW2 → DMZ servers via Switch3
- **Interfaces:**
  - `eth0` — `10.0.0.78/30` (link to RouterFW2 eth1), OSPF area 0
  - `eth1` — `200.0.0.254/24` (DMZ gateway / Switch3), OSPF area 0, **passive**
  - `eth2` — `10.0.0.82/30` (link to RouterFW1 eth1), OSPF area 0
- **Routing:** Default route learned via OSPF from RouterFW1/FW2
- **FRRouting running-config (final):**
  ```
  interface eth0
   ip address 10.0.0.78/30
   ip ospf 1 area 0
  !
  interface eth1
   ip address 200.0.0.254/24
   ip ospf 1 area 0
   ip ospf passive
  !
  interface eth2
   ip address 10.0.0.82/30
   ip ospf 1 area 0
  !
  router ospf 1
  ```
- **Notes:** `default-information originate always` NOT configured — lb-dmz has no Internet exit. Resolves routing loop between FW1↔FW2 for DMZ-bound traffic.

---

## Routers

| Name | IP Address | Location | Routing Protocol | Notes |
|------|------------|----------|-----------------|-------|
| RouterC1 | 10.0.0.41/30, 10.0.0.45/30, 10.0.0.49/30, 10.0.0.34/30, 10.0.0.30/30, 10.0.0.14/30, 10.0.0.10/30 | (n/a) | OSPF (proc 1, area 0) | Core router with multiple /30 transit links |
| RouterC2 | 10.0.0.57/30, 10.0.0.61/30, 10.0.0.50/30, 10.0.0.6/30, 10.0.0.18/30, 10.0.0.26/30, 10.0.0.38/30 | (n/a) | OSPF (proc 1, area 0) | Core router with multiple /30 transit links |

### Router Configuration Details

#### RouterC1
- **Routing:** OSPF process `1`, area `0`
- **Interfaces:**
  - `eth0` — `10.0.0.41/30`, OSPF area 0
  - `eth1` — `10.0.0.45/30`, OSPF area 0
  - `eth2` — `10.0.0.49/30`, OSPF area 0
  - `eth3` — `10.0.0.34/30`, OSPF area 0
  - `eth4` — `10.0.0.30/30`, OSPF area 0
  - `eth5` — `10.0.0.14/30`, OSPF area 0
  - `eth6` — `10.0.0.10/30`, OSPF area 0

#### RouterC2
- **Routing:** OSPF process `1`, area `0`
- **Interfaces:**
  - `eth0` — `10.0.0.57/30`, OSPF area 0
  - `eth1` — `10.0.0.61/30`, OSPF area 0
  - `eth2` — `10.0.0.50/30`, OSPF area 0
  - `eth3` — `10.0.0.6/30`, OSPF area 0
  - `eth4` — `10.0.0.18/30`, OSPF area 0
  - `eth5` — `10.0.0.26/30`, OSPF area 0
  - `eth6` — `10.0.0.38/30`, OSPF area 0

---

## Other Devices

| Name | Type | IP Address | Location | Notes |
|------|------|------------|----------|-------|
| L2-SW1 | Layer 2 Switch | (n/a) | (n/a) | VLANs 1/10/20 for access ports; dot1q trunks to FW3 and FW4 |
| PC-VLAN1 | PC | 10.1.0.100/24 | (n/a) | Default via 10.1.0.3 (metric 10) then 10.1.0.4 (metric 20) |
| PC-VLAN10 | PC | 10.10.0.100/24 | (n/a) | Default via 10.10.0.3 (metric 10) then 10.10.0.4 (metric 20) |
| PC-VLAN20 | PC | 10.20.0.100/24 | (n/a) | Default via 10.20.0.3 (metric 10) then 10.20.0.4 (metric 20) |
| PC-DC | PC | 10.100.0.100/24 | (n/a) | Default via 10.100.0.5 (metric 10) then 10.100.0.6 (metric 20) |
| PC-DMZ | PC | 200.0.0.100/24 | (n/a) | Default via 200.0.0.254 (lb-dmz) *(corrected from 200.0.0.1/200.0.0.2)* |
| PC-INET | PC | 100.0.0.100/24 | (n/a) | ECMP default via 100.0.0.7 (LB-1) and 100.0.0.8 (LB-2) equal weight — kernel hash distributes flows; stale routes 100.0.0.1 and 100.0.0.2 removed |

### Device Configuration Details

#### L2-SW1 (Layer 2 Switch)
- **VLANs:** 1, 10, 20
- **Access ports:** configured for VLAN 1 / 10 / 20 (to test PCs)
- **Trunk ports:** 802.1Q (dot1q) trunks to RouterFW3 and RouterFW4

#### PCs
- **PC (VLAN 1)**
  - IP: `10.1.0.100/24`
  - Default routes: via `10.1.0.3` metric 10 / via `10.1.0.4` metric 20
- **PC (VLAN 10)**
  - IP: `10.10.0.100/24`
  - Default routes: via `10.10.0.3` metric 10 / via `10.10.0.4` metric 20
- **PC (VLAN 20)**
  - IP: `10.20.0.100/24`
  - Default routes: via `10.20.0.3` metric 10 / via `10.20.0.4` metric 20
- **PC (Datacenter)**
  - IP: `10.100.0.100/24`
  - Default routes: via `10.100.0.5` metric 10 / via `10.100.0.6` metric 20
- **PC (DMZ)**
  - IP: `200.0.0.100/24`
  - Default route: via `200.0.0.254` (lb-dmz eth1) *(corrected from `200.0.0.1` metric 10 / `200.0.0.2` metric 20)*
- **PC (Internet)**
  - IP: `100.0.0.100/24`
  - ECMP default routes (equal weight — hash-based flow distribution):
    ```bash
    ip route add default nexthop via 100.0.0.7 weight 1 nexthop via 100.0.0.8 weight 1
    ```
  - **Notes:** Changed from primary/backup (metric 10/20) to equal-cost ECMP. Kernel uses L3+L4 hash (`net.ipv4.fib_multipath_hash_policy=1`) to distribute flows. Same flow always hits the same LB → same FW → no state sync needed.

---

## Change Log

| Date | Changed By | Device | Description |
|------|-----------|--------|-------------|
| 2026-03-27 | lucaveiro | Multiple | Initial report: RouterFW1–FW6, RouterC1–C2, L2-SW1, all PCs with addressing and OSPF details. |
| 2026-03-31 | lucaveiro | stateless-fw-lb-1 | Fixed subnet overlaps (removed 100.0.0.3/24 from eth1, 100.0.0.5/25 from eth2). Added 10.0.0.70/30 to eth1. Removed phantom `interface 0`. Removed passive from eth1. Fixed default route loop. |
| 2026-03-31 | lucaveiro | stateless-fw-lb-2 | Fixed subnet overlaps (removed 100.0.0.4/30 from eth1, 100.0.0.6/24 from eth2). Added missing `router ospf 1`. Removed passive from eth1. |
| 2026-03-31 | lucaveiro | RouterFW1 | eth0 changed from `100.0.0.1/24` to `10.0.0.69/30` (resolves subnet overlap with LB-1). Removed phantom `interface 0`. |
| 2026-03-31 | lucaveiro | RouterFW2 | eth0 changed from `100.0.0.2/24` to `10.0.0.73/30` (resolves subnet overlap with LB-2). |
| 2026-03-31 | lucaveiro | PC-INET | Default gateways corrected: `100.0.0.1` → `100.0.0.7` (LB-1, metric 10); `100.0.0.2` → `100.0.0.8` (LB-2, metric 20). |
| 2026-04-02 | lucaveiro | lb-dmz | New device added. eth0 `10.0.0.78/30` (FW2 side), eth1 `200.0.0.254/24` (DMZ gateway, passive), eth2 `10.0.0.82/30` (FW1 side). Resolves FW1↔FW2 DMZ routing loop. |
| 2026-04-02 | lucaveiro | RouterFW1 | eth1 changed from `200.0.0.1/24` to `10.0.0.81/30` after lb-dmz insertion. OSPF passive removed from eth1. |
| 2026-04-02 | lucaveiro | RouterFW2 | eth1 changed from `200.0.0.2/24` to `10.0.0.77/30` after lb-dmz insertion. OSPF passive removed from eth1. |
| 2026-04-02 | lucaveiro | PC-DMZ | Default gateway corrected from `200.0.0.1/200.0.0.2` to `200.0.0.254` (lb-dmz eth1). |
| 2026-04-03 | lucaveiro | stateless-fw-lb-1 | Changed to Hash Function based LB (stateless, no FW sync). Added eth2 `10.0.0.86/30` (link to RouterFW2 eth5). Kernel ECMP fib_multipath_hash_policy=1 — no nftables NAT, no conntrack. Added OSPF network 100.0.0.0/24 for return path. Verified ✅ |
| 2026-04-03 | lucaveiro | stateless-fw-lb-2 | Same change as LB-1 — kernel ECMP fib_multipath_hash_policy=1. Added eth2 `10.0.0.90/30` (link to RouterFW1 eth5). No nftables NAT, no conntrack. Added OSPF network 100.0.0.0/24. Verified ✅ |
| 2026-04-03 | lucaveiro | RouterFW1 | Added eth5 `10.0.0.89/30` — new adapter linking to stateless-fw-lb-2 eth2. Disabled conntrack for stateless LB compatibility. Verified ✅ |
| 2026-04-03 | lucaveiro | RouterFW2 | Added eth5 `10.0.0.85/30` — new adapter linking to stateless-fw-lb-1 eth2. Disabled conntrack for stateless LB compatibility. Verified ✅ |
| 2026-04-03 | lucaveiro | PC-INET | Changed to equal-cost ECMP (nexthop weight 1/1). Removed stale routes via 100.0.0.1 (metric 10) and 100.0.0.2 (metric 20). Verified ✅ |

---

## Firewall Rules

### Security Policies Overview

| # | Policy | Devices |
|---|--------|---------|
| 1 | DDoS protection from Internet | RouterFW1, RouterFW2 |
| 2 | Internal → Internet: TCP/UDP 80, 443 only | RouterFW1, RouterFW2 |
| 3 | VLAN10 → VoIP UDP 5060 to predefined IPs only | RouterFW3/4/5/6 |
| 4 | DMZ services accessible from Internet and internal network | RouterFW1, RouterFW2 |
| 5 | Intranet/Storage + internal DNS: VLAN10 and VLAN20 only | RouterFW3/4/5/6 |
| 6 | Databases TCP 3306: VLAN20 only | RouterFW3/4/5/6 |
| 7 | VLAN1 device 10.1.0.100: PING + SSH to all network devices | RouterFW1/2/3/4/5/6 |
| 8 | VLAN10 ↔ VLAN20: Samba TCP 139/445 only | RouterFW3/4/5/6 |

> **Note:** All firewalls have conntrack disabled (stateless LB requirement). Return traffic must be explicitly permitted using TCP flags (ACK, RST, FIN,ACK) and UDP source ports — `--state ESTABLISHED,RELATED` cannot be used.

---

### RouterFW1 + RouterFW2 — Perimeter Rules

Applies to both RouterFW1 and RouterFW2 identically.

```bash
#!/bin/bash
# ============================================================
# FIREWALL RULES — RouterFW1 / RouterFW2 (Perimeter)
# ============================================================

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t mangle -F

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# INPUT — loopback + OSPF
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p ospf -j ACCEPT

# INPUT — SSH + PING from VLAN1 admin device only
iptables -A INPUT -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 10.1.0.100 -p icmp -j ACCEPT

# Policy 1 — DDoS protection
iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
iptables -A FORWARD -i eth0 -p icmp -m limit --limit 5/s --limit-burst 10 -j ACCEPT
iptables -A FORWARD -i eth0 -p icmp -j DROP

# Policy 2 — Internal → Internet: TCP/UDP 80,443 only
iptables -A FORWARD -s 10.1.0.0/24   -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -o eth0 -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.1.0.0/24   -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -o eth0 -p udp -m multiport --dports 80,443 -j ACCEPT

# Policy 4 — Internet → DMZ
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT  # HTTPS
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT  # HTTPS UDP
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT  # IMAP
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT  # SMTP
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT  # DNS
iptables -A FORWARD -i eth0 -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT  # DNS TCP

# Policy 4 — Internal → DMZ
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p udp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 993 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 25  -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 200.0.0.0/24 -p tcp --dport 53  -j ACCEPT

# DMZ → Internet (SMTP relay, DNS outbound, HTTPS)
iptables -A FORWARD -s 200.0.0.0/24 -o eth0 -p tcp --dport 25  -j ACCEPT
iptables -A FORWARD -s 200.0.0.0/24 -o eth0 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 200.0.0.0/24 -o eth0 -p tcp --dport 443 -j ACCEPT

# Return traffic (stateless — no conntrack)
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK ACK     -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL RST          -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL FIN,ACK      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-reply      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type time-exceeded   -j ACCEPT
iptables -A FORWARD -p udp --sport 53  -j ACCEPT
iptables -A FORWARD -p udp --sport 443 -j ACCEPT
```

---

### RouterFW3/4/5/6 — Internal Rules

Applies to all internal firewalls.

```bash
#!/bin/bash
# ============================================================
# FIREWALL RULES — RouterFW3/4/5/6 (Internal)
# ============================================================

# Flush existing rules
iptables -F
iptables -X
iptables -t mangle -F

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# INPUT — loopback + OSPF
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p ospf -j ACCEPT

# Policy 7 — VLAN1 admin device: SSH + PING to all devices
iptables -A INPUT   -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT   -s 10.1.0.100 -p icmp           -j ACCEPT
iptables -A FORWARD -s 10.1.0.100 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.1.0.100 -p icmp           -j ACCEPT

# Policy 3 — VLAN10 → VoIP UDP 5060 (predefined IPs only)
# Replace <VOIP_SERVER_1> and <VOIP_SERVER_2> with real IPs
iptables -A FORWARD -s 10.10.0.0/24 -d <VOIP_SERVER_1> -p udp --dport 5060 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24 -d <VOIP_SERVER_2> -p udp --dport 5060 -j ACCEPT
iptables -A FORWARD -s <VOIP_SERVER_1> -d 10.10.0.0/24 -p udp --sport 5060 -j ACCEPT
iptables -A FORWARD -s <VOIP_SERVER_2> -d 10.10.0.0/24 -p udp --sport 5060 -j ACCEPT

# Policy 5 — Intranet TCP 443 + internal DNS: VLAN10 and VLAN20 only
iptables -A FORWARD -s 10.10.0.0/24  -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -d 10.100.0.0/16 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p udp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24  -d 10.100.0.0/16 -p tcp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p tcp --dport 53  -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.10.0.0/24  -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.20.0.0/24  -p tcp --sport 443 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.10.0.0/24  -p udp --sport 53  -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.20.0.0/24  -p udp --sport 53  -j ACCEPT

# Policy 6 — Databases TCP 3306: VLAN20 only
iptables -A FORWARD -s 10.20.0.0/24  -d 10.100.0.0/16 -p tcp --dport 3306 -j ACCEPT
iptables -A FORWARD -s 10.100.0.0/16 -d 10.20.0.0/24  -p tcp --sport 3306 -j ACCEPT

# Policy 8 — VLAN10 ↔ VLAN20: Samba TCP 139/445 only
iptables -A FORWARD -s 10.10.0.0/24 -d 10.20.0.0/24 -p tcp -m multiport --dports 139,445 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24 -d 10.10.0.0/24 -p tcp -m multiport --dports 139,445 -j ACCEPT
iptables -A FORWARD -s 10.20.0.0/24 -d 10.10.0.0/24 -p tcp -m multiport --sports 139,445 -j ACCEPT
iptables -A FORWARD -s 10.10.0.0/24 -d 10.20.0.0/24 -p tcp -m multiport --sports 139,445 -j ACCEPT

# Return traffic (stateless — no conntrack)
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK ACK     -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL RST          -j ACCEPT
iptables -A FORWARD -p tcp --tcp-flags ALL FIN,ACK      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-reply      -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type time-exceeded   -j ACCEPT
iptables -A FORWARD -p udp --sport 53  -j ACCEPT
iptables -A FORWARD -p udp --sport 443 -j ACCEPT
```

---

### Persist Rules After Reboot

```bash
# Save rules
iptables-save > /etc/iptables/rules.v4

# Restore on boot (Debian/Ubuntu)
apt-get install -y iptables-persistent
```

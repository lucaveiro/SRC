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
| RouterFW1 | 10.0.0.69/30, 10.0.0.81/30, 10.0.0.53/30, 10.0.0.62/30, 10.0.0.42/30 | (n/a) | OSPF area 0 on all eth; default-information originate always; eth0 changed from 100.0.0.1/24; eth1 changed from 200.0.0.1/24 |
| RouterFW2 | 10.0.0.73/30, 10.0.0.77/30, 10.0.0.54/30, 10.0.0.46/30, 10.0.0.58/30 | (n/a) | OSPF area 0 on all eth; default-information originate always; eth0 changed from 100.0.0.2/24; eth1 changed from 200.0.0.2/24 |
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
  router ospf 1
   default-information originate always
  ```
- **Notes:** Phantom `interface 0` removed from FRR config. Routes `100.0.0.0/24` and `200.0.0.0/24` now learned via OSPF (from LB-1 and lb-dmz respectively).

#### RouterFW2
- **Role:** Redundant edge FW/Router (Internet-side LB + DMZ-side LB + internal OSPF)
- **Interfaces:**
  - `eth0` — `10.0.0.73/30` (link to stateless-fw-lb-2 eth1), OSPF area 0 *(changed from `100.0.0.2/24` — resolves subnet overlap with LB-2)*
  - `eth1` — `10.0.0.77/30` (link to lb-dmz eth0), OSPF area 0 *(changed from `200.0.0.2/24` after lb-dmz insertion; passive removed)*
  - `eth2` — `10.0.0.54/30`, OSPF area 0
  - `eth3` — `10.0.0.46/30`, OSPF area 0
  - `eth4` — `10.0.0.58/30`, OSPF area 0
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
  router ospf 1
   default-information originate always
  ```
- **Notes:** Routes `100.0.0.0/24` and `200.0.0.0/24` now learned via OSPF (from LB-2 and lb-dmz respectively).

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
| stateless-fw-lb-1 | eth0: 100.0.0.7/24, eth1: 10.0.0.70/30 | Stateless ECMP L4 hash | RouterFW1 | OSPF passive on eth0; active on eth1; ip_forward=1 |
| stateless-fw-lb-2 | eth0: 100.0.0.8/24, eth1: 10.0.0.74/30 | Stateless ECMP L4 hash | RouterFW2 | OSPF passive on eth0; active on eth1; ip_forward=1 |
| lb-dmz | eth0: 10.0.0.78/30, eth1: 200.0.0.254/24, eth2: 10.0.0.82/30 | Stateless ECMP L4 hash | DMZ servers via Switch3 | OSPF active eth0/eth2; passive eth1 (DMZ); ip_forward=1 |

### Load Balancer Configuration Details

#### stateless-fw-lb-1
- **Role:** Stateless perimeter LB — Internet (Switch4) → RouterFW1
- **Interfaces:**
  - `eth0` — `100.0.0.7/24` (Internet / Switch4), OSPF area 0, **passive**
  - `eth1` — `10.0.0.70/30` (link to RouterFW1 eth0), OSPF area 0
- **Corrections applied:**
  - Removed `100.0.0.3/24` from eth1 and `100.0.0.5/25` from eth2 (subnet overlaps)
  - Removed phantom `interface 0` from FRR config
  - Fixed default route loop (was pointing to own IPs)
  - Removed `ip ospf passive` from eth1
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
  router ospf 1
  ```

#### stateless-fw-lb-2
- **Role:** Stateless perimeter LB — Internet (Switch4) → RouterFW2
- **Interfaces:**
  - `eth0` — `100.0.0.8/24` (Internet / Switch4), OSPF area 0, **passive**
  - `eth1` — `10.0.0.74/30` (link to RouterFW2 eth0), OSPF area 0
- **Corrections applied:**
  - Removed `100.0.0.4/30` from eth1 and `100.0.0.6/24` from eth2 (subnet overlaps)
  - Added missing `router ospf 1` process declaration
  - Removed `ip ospf passive` from eth1
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
  router ospf 1
  ```

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
| PC-INET | PC | 100.0.0.100/24 | (n/a) | Default via 100.0.0.7 metric 10 (LB-1), 100.0.0.8 metric 20 (LB-2) *(corrected from 100.0.0.1/100.0.0.2)* |

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
  - Default routes: via `100.0.0.7` metric 10 (stateless-fw-lb-1) / via `100.0.0.8` metric 20 (stateless-fw-lb-2) *(corrected from `100.0.0.1` / `100.0.0.2`)*

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

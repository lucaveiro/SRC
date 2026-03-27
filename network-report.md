# Network Infrastructure Report

## Table of Contents
- [Firewalls](#firewalls)
- [Load Balancers](#load-balancers)
- [Routers](#routers)
- [Other Devices](#other-devices)
- [Change Log](#change-log)

---

## Firewalls

| Name | IP Address | Model | Firmware Version | Location | Rules/Policies | Status | Notes |
|------|------------|-------|-----------------|----------|----------------|--------|-------|
| RouterFW1 | 100.0.0.1/24, 200.0.0.1/24, 10.0.0.53/30, 10.0.0.62/30, 10.0.0.42/30 | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | OSPF area 0 on eth1-eth4; originates default route always |
| RouterFW2 | 100.0.0.2/24, 200.0.0.2/24, 10.0.0.54/30, 10.0.0.46/30, 10.0.0.58/30 | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | OSPF area 0 on eth1-eth4; originates default route always |
| RouterFW3 | 10.1.0.3/24, 10.10.0.3/24, 10.20.0.3/24, 10.0.0.1/30, 10.0.0.5/30, 10.0.0.9/30 | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | VLAN subinterfaces on eth0; user VLAN interfaces are OSPF passive |
| RouterFW4 | 10.1.0.4/24, 10.10.0.4/24, 10.20.0.4/24, 10.0.0.2/30, 10.0.0.13/30, 10.0.0.17/30 | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | VLAN subinterfaces on eth0; user VLAN interfaces are OSPF passive |
| RouterFW5 | 10.100.0.5/16, 10.0.0.21/30, 10.0.0.25/30, 10.0.0.29/30 | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | Datacenter interface is OSPF passive |
| RouterFW6 | 10.100.0.6/16, 10.0.0.22/30, 10.0.0.33/30, 10.0.0.37/30 | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | Datacenter interface is OSPF passive |

### Firewall Configuration Details

#### RouterFW1
- **Role:** Edge FW/Router (Internet + DMZ + internal OSPF)
- **Interfaces:**
  - `eth0` — `100.0.0.1/24` (Internet segment)
  - `eth1` — `200.0.0.1/24` (DMZ segment), OSPF process 1 area 0
  - `eth2` — `10.0.0.53/30`, OSPF process 1 area 0
  - `eth3` — `10.0.0.62/30`, OSPF process 1 area 0
  - `eth4` — `10.0.0.42/30`, OSPF process 1 area 0
- **Routing:**
  - OSPF process `1`, area `0`
  - `default-information originate always`
- **Notes:** No explicit passive-interface configured in provided snippet.

#### RouterFW2
- **Role:** Redundant edge FW/Router (Internet + DMZ + internal OSPF)
- **Interfaces:**
  - `eth0` — `100.0.0.2/24` (Internet segment)
  - `eth1` — `200.0.0.2/24` (DMZ segment), OSPF process 1 area 0
  - `eth2` — `10.0.0.54/30`, OSPF process 1 area 0
  - `eth3` — `10.0.0.46/30`, OSPF process 1 area 0
  - `eth4` — `10.0.0.58/30`, OSPF process 1 area 0
- **Routing:**
  - OSPF process `1`, area `0`
  - `default-information originate always`
- **Notes:** No explicit passive-interface configured in provided snippet.

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

| Name | IP Address | Model | Firmware Version | Algorithm | Backend Pool | Status | Notes |
|------|------------|-------|-----------------|-----------|--------------|--------|-------|
| (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | No load balancer configuration provided |

---

## Routers

| Name | IP Address | Model | Firmware Version | Location | Routing Protocol | Status | Notes |
|------|------------|-------|-----------------|----------|-----------------|--------|-------|
| RouterFW3 | 10.1.0.3/24, 10.10.0.3/24, 10.20.0.3/24, 10.0.0.1/30, 10.0.0.5/30, 10.0.0.9/30 | (n/a) | (n/a) | (n/a) | OSPF (proc 1, area 0) | (n/a) | Inter-VLAN gateway; VLAN subinterfaces on eth0; VLAN interfaces are OSPF passive |
| RouterFW4 | 10.1.0.4/24, 10.10.0.4/24, 10.20.0.4/24, 10.0.0.2/30, 10.0.0.13/30, 10.0.0.17/30 | (n/a) | (n/a) | (n/a) | OSPF (proc 1, area 0) | (n/a) | Inter-VLAN gateway (redundant); VLAN subinterfaces on eth0; VLAN interfaces are OSPF passive |
| RouterC1 | 10.0.0.41/30, 10.0.0.45/30, 10.0.0.49/30, 10.0.0.34/30, 10.0.0.30/30, 10.0.0.14/30, 10.0.0.10/30 | (n/a) | (n/a) | (n/a) | OSPF (proc 1, area 0) | (n/a) | Core router with multiple /30 transit links |
| RouterC2 | 10.0.0.57/30, 10.0.0.61/30, 10.0.0.50/30, 10.0.0.6/30, 10.0.0.18/30, 10.0.0.26/30, 10.0.0.38/30 | (n/a) | (n/a) | (n/a) | OSPF (proc 1, area 0) | (n/a) | Core router with multiple /30 transit links |

### Router Configuration Details

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
- **Notes:** All listed interfaces participate in OSPF per provided config.

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
- **Notes:** All listed interfaces participate in OSPF per provided config.

---

## Other Devices

| Name | Type | IP Address | Model | Firmware Version | Location | Status | Notes |
|------|------|------------|-------|-----------------|----------|--------|-------|
| L2-SW1 | Layer 2 Switch | (n/a) | (n/a) | (n/a) | (n/a) | (n/a) | VLANs 1/10/20 for access ports; dot1q trunks to FW3 and FW4 |
| PC-VLAN1 | PC | 10.1.0.100/24 | (n/a) | (n/a) | (n/a) | (n/a) | Default via 10.1.0.3 (metric 10) then 10.1.0.4 (metric 20) |
| PC-VLAN10 | PC | 10.10.0.100/24 | (n/a) | (n/a) | (n/a) | (n/a) | Default via 10.10.0.3 (metric 10) then 10.10.0.4 (metric 20) |
| PC-VLAN20 | PC | 10.20.0.100/24 | (n/a) | (n/a) | (n/a) | (n/a) | Default via 10.20.0.3 (metric 10) then 10.20.0.4 (metric 20) |
| PC-DC | PC | 10.100.0.100/24 | (n/a) | (n/a) | (n/a) | (n/a) | Default via 10.100.0.5 (metric 10) then 10.100.0.6 (metric 20) |
| PC-DMZ | PC | 200.0.0.100/24 | (n/a) | (n/a) | (n/a) | (n/a) | Default via 200.0.0.1 (metric 10) then 200.0.0.2 (metric 20) |
| PC-INET | PC | 100.0.0.100/24 | (n/a) | (n/a) | (n/a) | (n/a) | Default via 100.0.0.1 (metric 10) then 100.0.0.2 (metric 20) |

### Device Configuration Details

#### L2-SW1 (Layer 2 Switch)
- **VLANs:** 1, 10, 20
- **Access ports:** configured for VLAN 1 / 10 / 20 (to test PCs)
- **Trunk ports:** 802.1Q (dot1q) trunks to RouterFW3 and RouterFW4
- **Notes:** No management IP was provided.

#### PCs
- **PC (VLAN 1)**
  - IP: `10.1.0.100/24`
  - Default routes:
    - via `10.1.0.3` metric 10
    - via `10.1.0.4` metric 20
- **PC (VLAN 10)**
  - IP: `10.10.0.100/24`
  - Default routes:
    - via `10.10.0.3` metric 10
    - via `10.10.0.4` metric 20
- **PC (VLAN 20)**
  - IP: `10.20.0.100/24`
  - Default routes:
    - via `10.20.0.3` metric 10
    - via `10.20.0.4` metric 20
- **PC (Datacenter)**
  - IP: `10.100.0.100/24`
  - Default routes:
    - via `10.100.0.5` metric 10
    - via `10.100.0.6` metric 20
- **PC (DMZ)**
  - IP: `200.0.0.100/24`
  - Default routes:
    - via `200.0.0.1` metric 10
    - via `200.0.0.2` metric 20
- **PC (Internet)**
  - IP: `100.0.0.100/24`
  - Default routes:
    - via `100.0.0.1` metric 10
    - via `100.0.0.2` metric 20

---

## Change Log

| Date | Changed By | Device | Description of Change |
|------|-----------|--------|----------------------|
| 2026-03-27 | lucaveiro | Multiple | Added RouterFW1–RouterFW6, RouterC1–RouterC2, L2 switch VLAN/trunk notes, and PC addressing/default routes (including OSPF + passive/default-originate details). |

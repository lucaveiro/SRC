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
- **FRRouting running-config (final):**
```frr
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
- **Notes:** conntrack disabled. Verified ✅

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
- **FRRouting running-config (final):**
```frr
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
- **Notes:** conntrack disabled. Verified ✅

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
<<<<<<< HEAD
| stateless-fw-lb-1 | eth0 `100.0.0.7/24`, eth1 `10.0.0.70/30`, eth2 `10.0.0.86/30` | HMARK `src,sport` (OutsideLB) | RouterFW1, RouterFW2 | rp_filter=0. ip_forward=1. NOTRACK. fwmark 101→FW1, 102→FW2 |
| stateless-fw-lb-2 | eth0 `100.0.0.8/24`, eth1 `10.0.0.74/30`, eth2 `10.0.0.90/30` | HMARK `src,sport` (OutsideLB) | RouterFW1, RouterFW2 | rp_filter=0. ip_forward=1. NOTRACK. fwmark 101→FW2, 102→FW1 |
| lb-dmz | eth0 `10.0.0.78/30`, eth1 `200.0.0.254/24`, eth2 `10.0.0.82/30` | Stateless gateway | DMZ server `200.0.0.100` | Single DMZ server. NOTRACK only. rp_filter=0. OSPF active eth0/eth2, passive eth1. TBD — pending discussion |
=======
| stateless-fw-lb-1 | eth0 `100.0.0.7/24`, eth1 `10.0.0.70/30`, eth2 `10.0.0.86/30` | **HMARK** `src,sport` (OutsideLB) | RouterFW1, RouterFW2 | rp_filter=0 all ifaces. ip_forward=1. NOTRACK on all ifaces. Policy routing fwmark 101→FW1, 102→FW2 |
| stateless-fw-lb-2 | eth0 `100.0.0.8/24`, eth1 `10.0.0.74/30`, eth2 `10.0.0.90/30` | **HMARK** `src,sport` (OutsideLB) | RouterFW1, RouterFW2 | rp_filter=0 all ifaces. ip_forward=1. NOTRACK on all ifaces. Policy routing fwmark 101→FW2, 102→FW1 |
| lb-dmz | eth0 `10.0.0.78/30`, eth1 `200.0.0.254/24`, eth2 `10.0.0.82/30` | Stateless ECMP L4 hash | DMZ servers via Switch3 | OSPF active eth0/eth2, passive eth1. ip_forward=1 |
>>>>>>> 1a83e323df6afcaa1e237d4899e5cac06bbc81dc

---

### Load Balancer Configuration Details — stateless-fw-lb-1

- **Role:** Hash Function based stateless LB (OutsideLB). Internet → Switch4 → RouterFW1 or RouterFW2. No FW state synchronization.
- **Interfaces:**
  - eth0 `100.0.0.7/24` — Internet Switch4, OSPF area 0, passive
  - eth1 `10.0.0.70/30` — link to RouterFW1 eth0, OSPF area 0
  - eth2 `10.0.0.86/30` — link to RouterFW2 eth5, OSPF area 0
- **Load Balancing Method:** HMARK `src,sport`. fwmark 101 → FW1 via eth1. fwmark 102 → FW2 via eth2. Same flow always hits the same FW — no state synchronization required.

- **`/etc/init.d/disable_reverse_path_validation`:**
```bash
#!/bin/bash
### BEGIN INIT INFO
# Provides:          disable_reverse_path_validation
# Required-Start:    $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Disable Reverse Path Validation (rp_filter)
### END INIT INFO

case "$1" in
  start)
    sysctl -w net.ipv4.conf.all.rp_filter=0
    sysctl -w net.ipv4.conf.default.rp_filter=0
    sysctl -w net.ipv4.conf.eth0.rp_filter=0
    sysctl -w net.ipv4.conf.eth1.rp_filter=0
    sysctl -w net.ipv4.conf.eth2.rp_filter=0
    ;;
  stop)
    sysctl -w net.ipv4.conf.all.rp_filter=1
    sysctl -w net.ipv4.conf.default.rp_filter=1
    sysctl -w net.ipv4.conf.eth0.rp_filter=1
    sysctl -w net.ipv4.conf.eth1.rp_filter=1
    sysctl -w net.ipv4.conf.eth2.rp_filter=1
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
exit 0
```
<<<<<<< HEAD

- **Policy Routing:**
=======
- **NOTRACK config (disables conntrack — mandatory for stateless operation):**
```bash
# Desativa conntrack em todas as interfaces — sem isto o iptables mangle
# ativa conntrack internamente, tornando o LB stateful
iptables -t raw -A PREROUTING -i eth0 -j NOTRACK
iptables -t raw -A PREROUTING -i eth1 -j NOTRACK
iptables -t raw -A PREROUTING -i eth2 -j NOTRACK
iptables -t raw -A OUTPUT -j NOTRACK
```
- **HMARK + Policy Routing config:**
>>>>>>> 1a83e323df6afcaa1e237d4899e5cac06bbc81dc
```bash
ip rule add fwmark 101 lookup 101
ip rule add fwmark 102 lookup 102
ip route add default via 10.0.0.69 dev eth1 table 101
ip route add default via 10.0.0.85 dev eth2 table 102
```

- **`/etc/init.d/iptables.rules` (gerado via `iptables-save`):**
```bash
# Aplicar e depois guardar com: iptables-save > /etc/init.d/iptables.rules

iptables -t raw -F
iptables -t raw -A PREROUTING -j NOTRACK
iptables -t raw -A OUTPUT -j NOTRACK

iptables -t mangle -F
iptables -t mangle -N LOADBALANCE
iptables -t mangle -A LOADBALANCE -i eth0 \
  -j HMARK --hmark-rnd 1 \
  --hmark-tuple src,sport \
  --hmark-mod 2 \
  --hmark-offset 101
iptables -t mangle -A PREROUTING -j LOADBALANCE

iptables-save > /etc/init.d/iptables.rules
```

- **Restaurar no boot:**
```bash
iptables-restore < /etc/init.d/iptables.rules
```

- **FRRouting running-config (final):**
```frr
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
 network 100.0.0.0/24 area 0
```
<<<<<<< HEAD
- **Notes:** No nftables.
=======
- **Notes:** No nftables. NOTRACK on all interfaces — conntrack fully disabled. No session table. `100.0.0.0/24` announced via OSPF `network` statement so RouterC1/C2 learn the return path. Verified ✅

---

### Load Balancer Configuration Details — stateless-fw-lb-2

- **Role:** Hash Function based stateless LB (OutsideLB). Internet → Switch4 → RouterFW1 or RouterFW2. No FW state synchronization.
- **Interfaces:**
  - eth0 `100.0.0.8/24` — Internet Switch4, OSPF area 0, passive
  - eth1 `10.0.0.74/30` — link to RouterFW2 eth0, OSPF area 0
  - eth2 `10.0.0.90/30` — link to RouterFW1 eth5, OSPF area 0 *(new adapter)*
- **Load Balancing Method:** iptables HMARK on `src,sport` (OutsideLB). Hash computed over source IP + source port, mod 2. fwmark 101 → FW2 via eth1. fwmark 102 → FW1 via eth2. Inverse mapping vs LB1 — same flow always hits same FW regardless of which LB receives it.
- **Kernel config:**
```bash
# ip_forward
sysctl -w net.ipv4.ip_forward=1

# rp_filter disabled (asymmetric paths)
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0
sysctl -w net.ipv4.conf.eth1.rp_filter=0
sysctl -w net.ipv4.conf.eth2.rp_filter=0

# Persist
echo "net.ipv4.conf.all.rp_filter=0"     >> /etc/sysctl.d/99-lb.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.d/99-lb.conf
```
- **NOTRACK config (disables conntrack — mandatory for stateless operation):**
```bash
# Desativa conntrack em todas as interfaces
iptables -t raw -A PREROUTING -i eth0 -j NOTRACK
iptables -t raw -A PREROUTING -i eth1 -j NOTRACK
iptables -t raw -A PREROUTING -i eth2 -j NOTRACK
iptables -t raw -A OUTPUT -j NOTRACK
```
- **HMARK + Policy Routing config:**
```bash
# HMARK — OutsideLB hash by src,sport (inverse mapping vs LB1)
iptables -t mangle -F
iptables -t mangle -N LOADBALANCE
iptables -t mangle -A LOADBALANCE -i eth0 \
  -j HMARK --hmark-rnd 1 \
  --hmark-tuple src,sport \
  --hmark-mod 2 \
  --hmark-offset 101
iptables -t mangle -A PREROUTING -j LOADBALANCE

# Policy routing tables — NOTE: inverse vs LB1
ip rule add fwmark 101 lookup 101
ip rule add fwmark 102 lookup 102
ip route add default via 10.0.0.73 dev eth1 table 101  # fwmark 101 → FW2
ip route add default via 10.0.0.89 dev eth2 table 102  # fwmark 102 → FW1
```
- **FRRouting running-config (final):**
```frr
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
 network 100.0.0.0/24 area 0
```
- **Notes:** No nftables. NOTRACK on all interfaces — conntrack fully disabled. No session table. `100.0.0.0/24` announced via OSPF. Verified ✅

---

### Load Balancer Configuration Details — lb-dmz

- **Role:** Stateless ECMP L4 load balancer for DMZ. FW1/FW2 → lb-dmz → Switch3 → DMZ servers.
- **Interfaces:**
  - eth0 `10.0.0.78/30` — link to RouterFW2 eth1, OSPF area 0
  - eth1 `200.0.0.254/24` — DMZ gateway via Switch3, OSPF area 0, passive
  - eth2 `10.0.0.82/30` — link to RouterFW1 eth1, OSPF area 0
- **Kernel config:**
```bash
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
```
- **Routing:**
```bash
# Rota default via FW2 (primário) e FW1 (backup)
ip route add default via 10.0.0.77 metric 10
ip route add default via 10.0.0.81 metric 20
```
- **FRRouting running-config (final):**
```frr
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
 default-information originate always
```
- **Notes:** `200.0.0.0/24` announced via OSPF — rota aprendida por todos os routers internos. PC DMZ usa `200.0.0.254` como gateway. Verified ✅

---

## Routers

| Name | IP Address | Notes |
|------|-----------|-------|
| RouterC1 | 10.0.0.41/30, 10.0.0.45/30, 10.0.0.49/30, 10.0.0.34/30, 10.0.0.30/30, 10.0.0.14/30, 10.0.0.10/30 | Core router. OSPF area 0 all interfaces. |
| RouterC2 | 10.0.0.57/30, 10.0.0.61/30, 10.0.0.50/30, 10.0.0.6/30, 10.0.0.18/30, 10.0.0.26/30, 10.0.0.38/30 | Core router. OSPF area 0 all interfaces. |

---

## Other Devices

| Name | IP Address | Gateway | Notes |
|------|-----------|---------|-------|
| PC VLAN1 | 10.1.0.100/24 | 10.1.0.3 (metric 10), 10.1.0.4 (metric 20) | Default via FW3, failover FW4 |
| PC VLAN10 | 10.10.0.100/24 | 10.10.0.3 (metric 10), 10.10.0.4 (metric 20) | Default via FW3, failover FW4 |
| PC VLAN20 | 10.20.0.100/24 | 10.20.0.3 (metric 10), 10.20.0.4 (metric 20) | Default via FW3, failover FW4 |
| PC Datacenter | 10.100.0.100/24 | 10.100.0.5 (metric 10), 10.100.0.6 (metric 20) | Default via FW5, failover FW6 |
| PC DMZ | 200.0.0.100/24 | 200.0.0.254 | Gateway = lb-dmz eth1 |
| PC Internet | 100.0.0.100/24 | 100.0.0.1 (metric 10), 100.0.0.2 (metric 20) | Simulated Internet host |

---

## Change Log

| Date | Change | Status |
|------|--------|--------|
| — | Initial OSPF routing config (professor base) | ✅ Done |
| — | IP forward ativado em todos os routers | ✅ Done |
| — | stateless-fw-lb-1 e lb-2 adicionados ao edge | ✅ Done |
| — | FW1/FW2 eth0 reconfigurado para ligar aos LBs | ✅ Done |
| — | lb-dmz configurado entre FW1/FW2 e Switch3 DMZ | ✅ Done |
| — | FW1/FW2 eth1 OSPF passive removido — vizinhança lb-dmz estabelecida | ✅ Done |
| — | PC DMZ gateway corrigido para 200.0.0.254 | ✅ Done |
| — | NOTRACK adicionado em LB1 e LB2 — conntrack desativado | ✅ Done |
| — | VRRP (FW3+FW4, FW5+FW6) | 🔲 Pendente |
| — | Zonas de segurança | 🔲 Pendente |
| — | Regras de firewall (8 políticas) | 🔲 Pendente |
>>>>>>> 1a83e323df6afcaa1e237d4899e5cac06bbc81dc

# Network Security Policies

**Authors:** Ruben Lopes (nmec: 103009), Lucas Rebelo (nmec: 123934)

Detailed breakdown of each security policy with devices, interfaces, traffic flow, and iptables chains.

---

## Zones

| Zone | Network | Gateway Firewalls |
|------|---------|-------------------|
| **Internet** | — (external) | RouterFW1 / RouterFW2 (eth0) |
| **DMZ** | `200.0.0.0/24` | RouterFW1 / RouterFW2 (eth1) via lb-dmz |
| **Core** | `10.0.0.0/16` (transit) | RouterFW1/FW2 (eth2-4), RouterFW3/FW4 (eth1-3), RouterFW5/FW6 (eth1-3) |
| **VLAN1** (Building A — Management) | `10.1.0.0/24` | RouterFW3 / RouterFW4 (eth0.1) |
| **VLAN10** (Building A) | `10.10.0.0/24` | RouterFW3 / RouterFW4 (eth0.10) |
| **VLAN20** (Building A) | `10.20.0.0/24` | RouterFW3 / RouterFW4 (eth0.20) |
| **Datacenter** | `10.100.0.0/16` | RouterFW5 / RouterFW6 (eth0) |

The Core zone is the OSPF backbone (`10.0.0.0/16`). It is a transit zone — no services are hosted there — but it is enforced via `ZONE-CORE` chains on all firewalls. Return traffic into the core is handled by `TO-CORE` (ESTABLISHED/RELATED) on FW1/FW2 and FW5/FW6. Enforcement points:

- **FW1/FW2** — Internet ↔ DMZ, Internet ↔ Core
- **FW3/FW4** — VLAN1/10/20 ↔ Core (inter-VLAN and outbound)
- **FW5/FW6** — Core ↔ Datacenter

---

## Policy #1: DDoS Protection from Internet

**Devices Involved:**
- **stateless-fw-lb-1** — eth0 `100.0.0.7/24` ← Internet, eth1 `10.0.0.70/30` → FW1, eth2 `10.0.0.86/30` → FW2 (backup)
- **stateless-fw-lb-2** — eth0 `100.0.0.8/24` ← Internet, eth1 `10.0.0.74/30` → FW2, eth2 `10.0.0.90/30` → FW1 (backup)
- **RouterFW1** — eth0 `10.0.0.69/30` ← LB1, eth5 `10.0.0.85/30` ← LB2
- **RouterFW2** — eth0 `10.0.0.73/30` ← LB2, eth5 `10.0.0.89/30` ← LB1

**Traffic Flow:** Internet → Load Balancers (HMARK hash on src-IP+sport, mod 2) → Edge Firewalls → Internal

**LB Chains (mangle table):** `ANTIDDOS` (anti-spoofing + invalid TCP flags + ICMP rate limit + per-srcip rate limit), `LOADBALANCE`

**FW1/FW2 Chains (filter table):** `ANTI-SPOOFING`

---

## Policy #2: Internal → Internet (TCP/UDP 80, 443 Only)

**Devices Involved:**
- **RouterFW3/FW4** — VLAN gateways: eth0.1, eth0.10, eth0.20
- **RouterC1/C2** — OSPF core routing
- **RouterFW1/FW2** — Edge firewalls: eth2-4 ← Core, eth0/eth5 → Internet (via LBs)

**Traffic Flow:** VLANs → FW3/FW4 → Core Routers → FW1/FW2 (filter ports) → Internet

**Chain:** `FROM-CORE-TO-INTERNET`

---

## Policy #3: VLAN10 → VoIP Servers (UDP 5060, Whitelisted IPs)

**Devices Involved:**
- **VLAN10 users** — `10.10.0.0/24`
- **RouterFW3/FW4** — eth0.10 ← VLAN10, eth1-3 → Core
- **VoIP Servers** — `200.0.0.10`

**Traffic Flow:** VLAN10 → FW3/FW4 (check whitelist) → Specific VoIP servers only

**Chain:** `FROM-VLAN10-TO-VOIP`

---

## Policy #4: DMZ Services Accessible from Internet AND Internal

**Services:** HTTPS (443), IMAP (993), SMTP (25), DNS (53)

**Path A — Internet → DMZ:**
- Internet → **RouterFW1/FW2** (eth0 ← Internet, eth1 → DMZ)
- **Chain:** `FROM-INTERNET-TO-DMZ`

**Path B — Internal → DMZ:**
- VLAN1/10/20 → **RouterFW3/FW4** (eth0.* ← VLANs)
- **Chain:** `FROM-INTERNAL-TO-DMZ`

Both paths → **lb-dmz** → DMZ servers

---

## Policy #5: VLAN10/20 → Datacenter (Intranet TCP 443, DNS UDP 53)

**Devices Involved:**
- **VLAN10, VLAN20** — allowed
- **VLAN1** — not in policy for these services
- **RouterFW3/FW4** — VLAN gateways
- **RouterC1/C2** — core routing
- **RouterFW5/FW6** — datacenter firewalls: eth0 → DC, eth1-3 ← Core

**Traffic Flow:** VLAN10/20 → FW3/FW4 → Core → FW5/FW6 (filter by source VLAN + service) → Datacenter

**Chain:** `FROM-VLAN-TO-DC` (FW3/FW4), `FROM-VLAN10-20-TO-DC` (FW5/FW6)

---

## Policy #6: VLAN20 ONLY → Database (TCP 3306)

**Devices Involved:**
- **VLAN20** — allowed for database
- **VLAN10** — explicitly blocked for database, but allowed for other DC services per Policy #5
- **RouterFW3/FW4** — VLAN gateways
- **RouterC1/C2** — core
- **RouterFW5/FW6** — datacenter firewalls with **critical rule ordering**

**Rule Order in ZONE-DATACENTER:**

1. `MGMT-ACCESS` — management host (highest priority)
2–4. `FROM-VLAN20-TO-DATABASE` — ALLOW VLAN20 → DB (port 3306), one rule per Core interface (eth1/2/3)
5. Explicit DROP VLAN10 → port 3306
6+. `FROM-VLAN10-20-TO-DC` — GENERIC ALLOW VLAN10/20 → Intranet/DNS (Policy #5)

**Chain:** `FROM-VLAN20-TO-DATABASE` (position 2, after MGMT-ACCESS)

---

## Policy #7: Management Host → All Devices (SSH TCP 22, ICMP)

**Privileged Device:**
- **Management Host:** VLAN1 `10.1.0.100` ONLY

**Target Devices (ALL):**
- RouterFW1, FW2, FW3, FW4, FW5, FW6
- DMZ servers
- Datacenter servers
- VLAN devices

**Implementation:** `MGMT-ACCESS` chain inserted at **position 1** (highest priority) in ALL zone chains on ALL firewalls

---

## Policy #8: VLAN10 ↔ VLAN20 (Samba TCP 139, 445 ONLY)

**Devices Involved:**
- **VLAN10** — `10.10.0.0/24`
- **VLAN20** — `10.20.0.0/24`
- **RouterFW3/FW4** — inter-VLAN gateway: eth0.10, eth0.20

**Traffic Flow:**
- VLAN10 → VLAN20: Samba ports only
- VLAN20 → VLAN10: Samba ports only
- **Bidirectional** — both directions configured with separate chains

**Blocked:** SSH, HTTP, PING, all other protocols (implicit DROP)

**Chains:** `FROM-VLAN10-TO-VLAN20`, `FROM-VLAN20-TO-VLAN10`

---

## Summary Table: All Policies with Devices and Interfaces

| Policy | Source | Destination | Firewalls | Key Interfaces | Chains |
|--------|--------|-------------|-----------|----------------|--------|
| **#1 DDoS** | Internet | All | LB1/2, FW1/2 | **LB:** eth0 ← Internet, eth1 → primary FW, eth2 → backup FW<br>**FW:** eth0 ← LB1, eth5 ← LB2 | **LB (mangle):** `ANTIDDOS`, `LOADBALANCE`<br>**FW (filter):** `ANTI-SPOOFING` |
| **#2 HTTP/S** | VLANs | Internet | FW3/4, FW1/2 | **FW3/4:** eth0.* ← VLANs, eth1-3 → Core<br>**FW1/2:** eth2-4 ← Core, eth0/eth5 → Internet | `FROM-CORE-TO-INTERNET` |
| **#3 VoIP** | VLAN10 | VoIP IPs | FW3/4 | **FW3/4:** eth0.10 ← VLAN10, eth1-3 → Core | `FROM-VLAN10-TO-VOIP` |
| **#4a DMZ** | Internet | DMZ | FW1/2 | **FW1/2:** eth0 ← Internet, eth1 → DMZ | `FROM-INTERNET-TO-DMZ` |
| **#4b DMZ** | VLANs | DMZ | FW3/4 | **FW3/4:** eth0.* ← VLANs, eth1-3 → Core | `FROM-INTERNAL-TO-DMZ` |
| **#5 DC** | VLAN10/20 | Datacenter | FW3/4, FW5/6 | **FW3/4:** eth0.10/20 ← VLANs, eth1-3 → Core<br>**FW5/6:** eth1-3 ← Core, eth0 → DC | `FROM-VLAN-TO-DC` (FW3/4), `FROM-VLAN10-20-TO-DC` (FW5/6) |
| **#6 DB** | VLAN20 | Datacenter | FW5/6 | **FW5/6:** eth1-3 ← Core, eth0 → DC | `FROM-VLAN20-TO-DATABASE` (pos 1) |
| **#7 Mgmt** | VLAN1 host | All | ALL FW | All zones | `MGMT-ACCESS` (pos 1) |
| **#8 Samba** | VLAN10 ↔ 20 | VLAN20 ↔ 10 | FW3/4 | **FW3/4:** eth0.10, eth0.20 | `FROM-VLAN10-TO-VLAN20`<br>`FROM-VLAN20-TO-VLAN10` |

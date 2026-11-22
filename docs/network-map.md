# Network map — discovered 2026-11-06

Passive discovery only (Pi-hole DHCP leases + FTL `network` table, local ARP cache, OUI lookup). No logins.
LAN is 192.168.0.0/16 (Mac en0 = 192.168.91.55/16). DNS = Pi-hole on rasphermes.home:53. Gateway = mymodem 192.168.1.1.

| IP | Name (PTR/DHCP) | MAC | Vendor/OUI | Device |
|---|---|---|---|---|
| 192.168.1.1 | mymodem | f0:4d:d4:58:b6:8b | — | gateway/router |
| 192.168.1.28 | truneas.home | 60:cf:84:d9:1c:5f | ASUSTek | TrueNAS (alt IP 192.168.1.18, 192.168.14.226) |
| 192.168.1.100 | rasphermes.home | e4:5f:01:c4:b8:52 | **Raspberry Pi Trading** | **RPi — DietPi + Pi-hole :53 (LAN DNS)** |
| **192.168.0.210** | **rpi-control-10.local** (mDNS only; no `.home` PTR) | e4:5f:01:c4:b8:ce | **Raspberry Pi Trading** | **RPi — the masternode/cluster box, formerly alias raspshiva)** |
| 192.168.87.85 | asus-rog-flow14.home | 60:dd:8e:c7:bb:b8 | Intel | ASUS ROG Flow 14 laptop |
| 192.168.58.220 | asusu-manjaro-22.home | ce:28:bc:ac:6b:84 | Intel | Manjaro laptop (alt IP 192.168.1.50) |
| 192.168.91.55 | MacBookPro.home | c2:f9:27:7f:65:9f | Apple | this Mac (alt IP 192.168.32.185) |

## Findings
- Exactly **two** Raspberry Pi OUI (E4:5F:01) devices on the LAN: `rasphermes` (192.168.1.100) and **192.168.0.210**.
- 192.168.0.210's current hostname (via mDNS reverse-PTR) is **`rpi-control-10.local`** — it is NOT in Pi-hole `.home` DNS (`rpi-control-10.home` and `raspshiva.home` both NXDOMAIN). Formerly aliased `raspshiva`.
- To make it resolvable as `.home`, we need to add a Pi-hole Local DNS record `rpi-control-10.home -> 192.168.0.210`.
- `~/.ssh/rpi_id_ed25519` was created recently and is **not authorized on any Pi yet** → Ansible/SSH logins will fail until the key is pushed (bootstrap step). Do not attempt logins before that.
- `osmc-Prentis` is a Vero V (per owner), not a Raspberry Pi.

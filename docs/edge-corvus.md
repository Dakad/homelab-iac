# Edge proxy & DuckDNS — what & why

rasphermes is the entrypoint + exitpoint for the homelab. This doc explains **why** each piece exists and **how the moving parts fit**, so it's readable standalone.

## The network role of rasphermes

```
Internet
   │ :80 / :443
   ▼
┌──────────────────────────────────────────────┐
│       rasphermes.home (192.168.1.100)        │
│  ┌────────────┐  :80/:443  ┌──────────────┐  │
│  │  Corvus    │──────────▶│  services     │  │
│  │  (edge WAF │  forward  │  on other     │  │
│  │  proxy)    │  by IP    │  VLANs        │  │
│  └────────────┘           └───────────────┘  │
│  ┌────────────┐  :53                         │ 
│  │  Pi-hole   │◀─── LAN DNS ─────────────┐   │
│  └────────────┘                          │   │ 
└──────────────────────────────────────────────┘
     :22  ansible bootstrap                ▼
                                          │ 192.168.x (VLANs via OpenWRT)
                                         TrueNAS / AI box / phones / TV
```

- **Inbound:** visitors hit `:80`/`:443` on rasphermes → Corvus forwards to a
  service by its **private IP** (e.g. `10.2.0.x`). Corvus doesn't need to run
  next to the service; it just needs to reach it over the LAN.
- **LAN DNS:** Pi-hole on `rasphermes:53` answers internal names. The OpenWRT
  router (future) points DHCP clients there.
- **DuckDNS:** the A record keeps the home IP fresh. Corvus is **not** involved
  yet (plain HTTP). See the DuckDNS section below.

## Corvus (edge proxy)

**Why a reverse proxy instead of exposing services directly?**
- One place on `:80`/`:443` that every service flows through.
- Built-in WAF (attack blocking, IP lists, bans) — free, like Nginx Proxy
  Manager.
- TLS in one place if you later add certs.

**Image:** `ghcr.io/corvus-gateway/corvus:1.9.0` — pinned to the latest **stable**
release. `ghcr.io` = GitHub Container Registry. We do **not** use `:latest`: a
pin means a bad upgrade can't silently break your proxy, and you can see exactly
what Ansible deploys. (There are `1.9.1-rc.1` release candidates, but RCs are
untested — pin the stable line for now.)

**Why Ansible manages the compose file, not the image?**
Docker images move (tag `latest` changes). If Ansible tried to `docker pull`
and diff the image, every run would "change" it. The right split:
- **Ansible** owns the *declarative* config: compose file + data volume +
  ownership.
- **Docker** owns the *runtime*: pull the image, apply the compose, upgrade.

That's why the playbook:
1. creates the data dir and `chown`s it to the container's user (`10001`),
2. copies our version-controlled compose into that dir,
3. runs `docker compose restart`,
4. waits until `:9443` answers.

**`user: "10001:10001"`** — the Corvus image runs as unprivileged uid/gid
`10001` and owns `./data`. We must create that dir with the same owner before
binding it in, otherwise the container can't write its db/secrets.

## DuckDNS (dynamic DNS)

The home ISP reassigns the public IP. DuckDNS gives you a free domain
(`yourname.duckdns.org`) and updates its A record whenever the IP changes.

**Two API calls:**
- `GET  https://duckdns.org/api/getToken` → returns your `token`
- `POST https://duckdns.org/api/query?subdomain=<sub>&token=<token>` →
  updates the record (IP auto-detected from the internet)

**Who writes the record?** Only one process can be the writer per subdomain.
We chose **rasphermes** as the updater: an hourly cron runs the script, which
curls DuckDNS only when the IP actually changed. The token lives on rasphermes
in a local env file, never in this repo.

**Why Corvus doesn't need the token (this phase):**
Corvus issues certs via **DNS-01** — it must *write a TXT record into DuckDNS*
to prove ownership. That needs the DuckDNS write token. But we're doing **plain
HTTP forwarding**, no certs. So Corvus never talks to DuckDNS. The only things
touching DuckDNS are the cron updater and the dashboard.

**When you later want wildcard certs** (`*.duckdns.org`), Corvus would need the
token too. Then the token (currently on rasphermes) is shared with the
Corvus container, and Corvus becomes the DuckDNS writer. That's a deliberate
later step, not the current setup.

## How to add a proxy host (the actual work)

Corvus configures itself in the console (`:9443`), not in the compose file. To
forward a domain:
1. Console → **Proxy hosts → Add proxy host**
   - **Domains:** `service.duckdns.org` (or `rasphermes.duckdns.org`)
   - **Scheme:** `http`
   - **Host / IP:** `10.2.0.x` (the service's private IP)
   - **Port:** `80`
2. Save → Corvus creates a new config version, tests `openresty -t`, deploys
   without dropping connections.

**Watch the forward host name:** Corvus resolves names via public DNS at
request time and does **not** append search domains. Use the **full name**
(`service.duckdns.org`), not a short one (`service`), or you get 502.

## Playbook order (dependency)

The two plays are independent in code but ordered at run time. Corvus has a
**prerequisite guard** task (task #0) that asserts the DuckDNS token file
exists before it does anything. If the DuckDNS play hasn't run, Corvus stops
loudly instead of deploying a proxy it can't manage.

Run them in this order:

```bash
# 1. DuckDNS first — installs the updater, writes the cron, expects the token
ansible rasphermes -i ./hosts -t duckdns \
  --user dietpi --private-key=...

# 2. Then Corvus — the prerequisite guard verifies #1 succeeded
ansible rasphermes -i ./hosts -t corvus \
  --user dietpi --private-key=...
```

You can run them in one shot too:

```bash
ansible rasphermes -i ./hosts -t duckdns,corvus \
  --user dietpi --private-key=...
```

- The `duckdns` play installs `/usr/local/bin/duckdns_update.sh`, writes
  `/etc/cron.d/duckdns`, and needs `/etc/duckdns/duckdns.env` (TOKEN +
  SUBDOMAIN) present on the Pi.
- The `corvus` play needs that env file to exist (its guard task checks it).

**Tags, not `import_playbook`:** Ansible removed cross-playbook imports long
ago, so "prerequisite" is expressed with tags + task ordering, not a formal
dependency. The `duckdns` tag is also on the Corvus play (so `-t duckdns` alone
won't re-run Corvus), and the guard task fails the Corvus play if DuckDNS is
missing.

## Re-running / upgrading

```bash
# on rasphermes, as dietpi (passwordless sudo) or root:
ansible rasphermes -i ./hosts -t corvus --user dietpi --private-key=...
```

- Changing the compose file and re-running → `docker compose restart` picks it
  up.
- New Corvus version → `docker compose pull && docker compose up -d`
  (run once manually; Ansible won't fight the image layer).

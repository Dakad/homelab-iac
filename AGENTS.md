# AGENTS.md — homelab-iac

Minimal Ansible repo provisioning the homelab: a single managed Pi (`rasphermes`) and a two-Pi cluster (`rasphermes`, `raspshiva`). No per-host config management — the playbook only does bootstrap + maintenance (user, sudo, key, apt update, dist-upgrade). Targets: LAN `.home` domain on SSH port 22, `dietpi` is the `remote_user`, `ansible` is the script-created maintenance user.

## Dev environment & run
- Inventory: `hosts`; private key: `$HOME/.ssh/ansible.id_ed25519`; public key pushed to hosts: `files/ansible.id_ed25519.pub`. `ansible.cfg` shortcuts these (`ansible.cfg`).
- Run: `mise run ansible:full` (standard), or `ansible-playbook common_playbook.yml --user dietpi --private-key=$HOME/.ssh/ansible.id_ed25519 -i ./hosts` (manual).
- Host list / facts: `ansible all --list-hosts`; `ansible all -u ansible -m gather_facts` (pipe to `less`).
- Ad-hoc run: prefer the mise task `mise run ansible:shell <host> "<command>"`, which expands to `ansible <host> -u ansible -m shell -a "<command>"`. Both the host and the command are configurable (usage-spec, see `.mise.toml`). Raw ad-hoc: `ansible rasphermes -u ansible -m shell -a "uname -a"`; `ansible rasphermes -u ansible -m apt -a "upgrade=dist" --become --ask-become-pass`.

## Playbook acts (common_playbook.yml)
1. **bootstrap** (tag `bootstrap`): create user `ansible` (**password hash is hardcoded at line 13** — only runs once, no `changelog` guard, and it's committed to git; re-running rewrites it and locks anyone with a manual shell password), adds it to sudoers, grafts `files/*.pub` into authorized_keys.
2. **apt / pkg** (tag `apt,pkg`): install/upgrade `htop`.
3. **always**: `apt update` + `upgrade=dist`, autoremove/autoclean; `debug` dumps last log line to confirm success.

## Conventions
- `remote_user: dietpi` at playbook top; `become_user: ansible` inside the apt act.
- Host tags cluster under `rpis:children` (now only `rpi-clusters`); laptops were experimental — commented out under `[laptops]`.
- Python 3.13 here but this is Ansible-only; no manifests/tests/linting configured.
- Commit style is informal/playful (not strict Conventional Commits).

## Pitfalls
- **World-writable run dir**: Ansible warns from `mnt/Data/Workspace/...` and skips `./ansible.cfg` as config source. Remediation: `chmod g-wx $(pwd)`, or `export ANSIBLE_CONFIG=./ansible.cfg`.
- **`tags: always`** upgrade is unconditional — no `--skip-tags` off-ramp for the users group.
- **Bootstrap password is in git**: avoids re-running it once set.
- Don't edit the `.env` file (secret) or `files/*.pub` (keys) by hand — they're loaded directly by the tooling.
- Targets must have the `ansible.id_ed25519.pub` key installed first (see README) or the bootstrap/authorized_key tasks fail.

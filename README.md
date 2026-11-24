# HomeLab IAC with Ansible

Little repo to host ansible config about my homelab's rapberry-pi clusters and laptop

## Setup & Usage

This project uses `mise` to manage the environment and `bin/setup` for initial configuration.

### Initial Setup

Run the setup script to install required tools and configure the local environment:

```bash
./bin/setup
```

### Running Playbooks

Use `mise` to run the defined tasks (e.g., bootstrap, maintenance, etc.):

```bash
# Examples:
mise run ansible:bootstrap
mise run ansible:maintenance
mise run ansible:shell rasphermes "uptime"
```

See the `docs` folder for more information and common commands.

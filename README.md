# HomeLab IAC with Ansible

Little repo to host ansible config about my homelab's rapberry-pi clusters and laptop

## Before start

All targets host must have the ansible SSH keys to allow Ansible to easily connect without password 
To generate the SSH keys (this has to be done only once, if the file already exists, retrieve it):

``` bash
ssh-keygen -t ed25519 -C "Homelab Ansible" -f $HOME/.ssh/ansible.id_ed25519
```

Now, we need to send the ssh to the target hosts using ``ssh-copy-id``, repeat the command for every host:
For instance, to send to raspodin

``` bash
# Dietpi will be used as become user for rpi and pihole (user of reference if needed intead of root)
ssh-copy-id -p 22 -i ~/.ssh/ansible.id_ed25519 dietpi@raspodin.home
```

To  run the playbook, use the following command:

``` bash
ansible-playbook common_playbook.yml --u dietpi  --private-key=$HOME/.ssh/ansible.id_ed25519 -i ./hosts
```

## Docs

THere is folder `docs` with all necessary information and usefull commands to use


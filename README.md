# HomeLab IAAC with Ansible

Little repo to host ansible config about my homelab's rapberry-pi clusters and laptop

# Before start

All targets host must have the ansible SSH keys to allow Ansible to easily connect without password 
To generate the SSH keys (this has to be done only once, if the file already exists, retrieve it):

``` bash
ssh-keygen -t ed25519 -C "Homelab Ansible" -f $HOME/.ssh/ansible.id_ed25519
```

Now, we need to send the ssh to the target hosts using ``ssh-copy-id``, repeat the command for every host:
For instance, to send to raspodin

``` bash
ssh-copy-id -p 22 -i ~/.ssh/ansible.id_ed25519 dietpi@raspodin.home
```


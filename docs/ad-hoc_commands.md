# Ad-hoc commands

Here is little doc about usefull Ansible ad-hoc command to use


To list all registred hosts, `ansible all --list-hosts`

To get all possible info about the hosts, usefull to know the IP address or the disto name

```bash
ansible all -u ansible -m gather_facts | less

# To get only a specific host
ansible all -u ansible -m gather_facts --limit raspodin.home
```

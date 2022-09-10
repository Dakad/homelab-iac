# Ad-hoc commands

Here is little doc about usefull Ansible ad-hoc command to use

To list all registred hosts, `ansible all --list-hosts` or 
``` bash 
ansible-inventory --list 
```

To get all possible info about the hosts, usefull to know the IP address or the disto name

```bash
ansible all -u ansible -m gather_facts | less

# To get only a specific host
ansible all -u ansible -m gather_facts --limit raspodin.home
```

To quick exec a command on hosts

```bash
ansible raspodin.home -u ansible -m shell -a "unamme -a"
```

To exec an elevated command (requiring sudo perm.):

``` bash
# -b or --become will use elevated privileges (aka sudo)
# -K or --ask-become-pass will ask for the 'become' password
ansible all -u ansible -m apt -a update_cache=true --become

## Or sudo apt update && sudo apt install vim-nox
ansible all -u ansible -m apt -a update_cache=true -a name=vim-nox --become --ask-become-pass

## Get the list of upgradable packages
ansible all -u ansible -m shell -a "apt list --upgradable" -b -K

## sudo apt upgrade a specific package 
ansible all -u ansible -m apt -a "name=gpg state=latest" --become --ask-become-pass

## sudo apt upgrade-dist # Update all packages
ansible all -u ansible -m apt -a "upgrade=dist" --become --ask-become-pass
```


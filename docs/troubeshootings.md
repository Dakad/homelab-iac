
# After running any ansible command, this warning appears

```
> ansible all -m gather_fact

[WARNING]: Ansible is being run in a world writable directory (/mnt/Data/Workspace/lab/homelab-iaac), ignoring it as an ansible.cfg source. For more information see
https://docs.ansible.com/ansible/devel/reference_appendices/config.html#cfg-in-world-writable-dir
```

SOLUCE:

- Either `chmod g-wx $(pwd)`

- if not possible then set the env var `export ANSIBLE_CONFIG=./ansible.cfg && echo " ANSIBLE_CONFIG=./ansible.cfg" > .env`

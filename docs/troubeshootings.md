
# After running any ansible command, this warning appears

```
> ansible all -m gather_fact

[WARNING]: Ansible is being run in a world writable directory (/mnt/Data/Workspace/lab/homelab-iaac), ignoring it as an ansible.cfg source. For more information see
https://docs.ansible.com/ansible/devel/reference_appendices/config.html#cfg-in-world-writable-dir
```

SOLUCE:

- Either `chmod g-wx $(pwd)`

- if not possible then set the env var `export ANSIBLE_CONFIG=./ansible.cfg && echo " ANSIBLE_CONFIG=./ansible.cfg" > .env`

# When trying the task to apt install package
```bash
> ansible-playbook common_playbook.yml --tags pkg

TASK [Gathering Facts] ********************************************************************************************
fatal: [raspodin.home]: FAILED! => {"msg": "Failed to set permissions on the temporary files Ansible needs to create when becoming an unprivileged user (rc: 1, err: chmod: invalid mode: ‘A+user:ansible:rx:allow’\nTry 'chmod --help' for more information.\n}). For information on working around this, see https://docs.ansible.com/ansible-core/2.13/user_guide/become.html#risks-of-becoming-an-unprivileged-user"}
```
- REASON:
  - https://docs.ansible.com/ansible-core/2.13/user_guide/become.html#risks-of-becoming-an-unprivileged-user
  - https://github.com/ansible/ansible/issues/74830#issuecomment-848817825
- SOLUCE: Instal ACL (Access Control Lists) package
Either add to ansible.cfg `pipelining = True` or/and
```bash
ansible rpi_kube --become -K -m shell -a "sudo apt update && sudo apt install --yes acl"
```


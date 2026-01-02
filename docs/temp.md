# Test connectivity
ansible all -m ping

# Run the playbook
ansible-playbook playbooks/setup-k3s.yml

ssh -i ~/.ssh/ansible_homelab_id_rsa lingling@192.168.0.197


ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/setup-k3s.yml
ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/setup-aliases.yml
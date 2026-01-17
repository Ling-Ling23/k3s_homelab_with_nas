#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/000-setup-raspi.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/0010setup-k3s.yml#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/003a_deploy-nfs-storage.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/003a-deploy-nfs-storage.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/003b-deploy-longhorn-storage.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/004-deploy-cert-manager.yml --vault-password-file ansible/.vaultpass
ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/005-deploy-metallb-nginx-ingress.yml
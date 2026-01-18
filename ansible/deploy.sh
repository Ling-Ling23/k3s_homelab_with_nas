#ansible all -m ping
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/000-setup-raspi.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/0010setup-k3s.yml#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/003a_deploy-nfs-storage.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/003a-deploy-nfs-storage.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/003b-deploy-longhorn-storage.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/004-deploy-cert-manager.yml --vault-password-file ansible/.vaultpass
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/005-deploy-metallb-nginx-ingress.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/006-deploy-monitoring.yml
#ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/007-deploy-logging.yml
ansible-playbook -e @group_vars/all.yml -i inventory/hosts.yml playbooks/008-deploy-sealed-secrets.yml # --vault-password-file secrets/.vaultpass

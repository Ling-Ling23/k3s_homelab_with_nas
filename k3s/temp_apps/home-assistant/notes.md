# INSTALL
# Cluster commands are run from the Pi
$ ssh raspi1
$ cd ~/k3s_homelab_with_nas

 helm repo add pajikos http://pajikos.github.io/home-assistant-helm-chart/
 helm repo update
 VALUES_FILE=./k3s/apps/home-assistant/helm_values/home-assistant-values.yaml
 helm install home-assistant pajikos/home-assistant \
  --namespace home-assistant \
  --create-namespace \
  -f $VALUES_FILE

# If the release already exists
$ helm upgrade home-assistant pajikos/home-assistant \
  --namespace home-assistant \
  -f $VALUES_FILE

# If upgrade fails with StatefulSet immutable field error:
# "updates to statefulset spec ... are forbidden"
$ kubectl delete statefulset -n home-assistant home-assistant
$ helm upgrade home-assistant pajikos/home-assistant \
  --namespace home-assistant \
  -f $VALUES_FILE

# Note: release namespace is still set with --namespace; namespaceOverride comes from values YAML.

# Apply ingress after Helm release
$ kubectl apply -f ./k3s/apps/home-assistant/ingress.yaml

# Quick checks
$ kubectl get pods -n home-assistant
$ kubectl get svc -n home-assistant home-assistant
$ kubectl get ingress -n home-assistant home-assistant-ingress
$ kubectl get pvc -n home-assistant
$ kubectl logs -n home-assistant statefulset/home-assistant --tail=80

# Uninstall
helm uninstall home-assistant -n home-assistant 

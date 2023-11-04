#! /bin/bash

# Initialise cluster
LOAD_BALANCER_IP=$1
POD_CIDR="10.0.0.1/24"

sudo kubeadm init --control-plane-endpoint=$LOAD_BALANCER_IP --apiserver-advertise-address=192.168.56.12 --upload-certs --apiserver-cert-extra-sans=$LOAD_BALANCER_IP --node-name=$(hostname -s) --pod-network-cidr=$POD_CIDR

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Remove previous config files
rm -rf /vagrant/config

# Create path
mkdir -p /vagrant/config

cp -i /etc/kubernetes/admin.conf /vagrant/config/config
touch /vagrant/config/join_master.sh
touch /vagrant/config/join_worker.sh
chmod +x /vagrant/config/join_master.sh
chmod +x /vagrant/config/join_worker.sh

# Create cluster join command for worker nodes and save to script
kubeadm token create --print-join-command > /vagrant/config/join_worker.sh

# Create cluster join command for master nodes and save to script - need to allow arguments to be passed in for each master node IP and node name
JOIN_CMD=$(cat /vagrant/config/join_worker.sh)
echo "$JOIN_CMD --control-plane --certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -1) --apiserver-advertise-address=\$1 --node-name=\$2" > /vagrant/config/join_master.sh

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics-server deployment to use --kubelet-insecure-tls arg - https://github.com/kubernetes-sigs/metrics-server
kubectl patch deployment metrics-server -n kube-system --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls" }]'

# Install Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml

# Create dashboard User
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Export admin token for dashboard
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" >> /vagrant/config/token

# Patch dashboard service to use NodePort on specific port
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30000}]'

kubectl apply -f https://raw.githubusercontent.com/AndyReynolds1/kubernetes-service-example/master/simple/deployment.yml
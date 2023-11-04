# Vagrant Kubernetes Cluster High Availability

Testing using Vagrant to automate deploying a local Kubernetes cluster with multiple control plane and worker nodes behind load balancers.

## Run

```bash
vagrant up
```

### Links

- HAProxy Stats - Control Plane: [https://192.168.56.10:8080](https://192.168.56.10:3000)
- HAProxy Stats - Workers: [https://192.168.56.11:8080](https://192.168.56.11:3000)
- Kuberenetes Dashboard (via control plane load balancer): [https://192.168.56.10:30000](https://192.168.56.10:30000)
- Demo website (via worker load balancer): [http://192.168.56.11](http://192.168.56.11)

Admin token for logging into the dashboard will be output into the `config/token` file.

# Grafana on Kubernetes

This repository contains Kubernetes manifests for deploying Grafana on a Kubernetes cluster.

## Prerequisites

- A Kubernetes cluster
- kubectl installed and configured to communicate with your cluster
- kubectl kustomize plugin (optional, but recommended)

## Configuration

Before deploying, you may want to customize the following:

1.  In `manifests/configmap.yaml`: Adjust Grafana configuration settings
2.  In `manifests/secret.yaml`: Change the admin password (it's "admin" by default)
3.  In `manifests/pvc.yaml`: Adjust storage size and storage class based on your cluster
4.  In `manifests/deployment.yaml`: Adjust resource limits/requests
5.  In `manifests/service.yaml`: Change service type if needed (e.g., to LoadBalancer)
6.  In `manifests/ingress.yaml`: Update the host and path settings

## Deployment

### Using kubectl apply

```bash
# Create all resources
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/pvc.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml
```

### Using kustomize

```bash
# From the root directory
kubectl apply -k manifests/
```

## Accessing Grafana

### Using port-forward

```bash
kubectl port-forward -n monitoring svc/grafana 8080:80
```

Then access Grafana at http://localhost:8080

### Using Ingress

If you've configured the Ingress properly and have an Ingress controller running, you can access Grafana at:

http://monitoring.example.com/grafana

## Default Credentials

- Username: admin
- Password: admin (unless you changed it in the secret.yaml)

## Adding Data Sources

After logging in, you'll need to configure data sources for Grafana. Common data sources include:

- Prometheus
- Loki
- InfluxDB
- Elasticsearch

## Troubleshooting

### Check pod status

```bash
kubectl get pods -n monitoring
```

### Check pod logs

```bash
kubectl logs -n monitoring deployment/grafana
```

### Check events

```bash
kubectl get events -n monitoring
```

## Cleanup

To remove all resources:

```bash
kubectl delete -k manifests/
```

Or individually:

```bash
kubectl delete -f manifests/ingress.yaml
kubectl delete -f manifests/service.yaml
kubectl delete -f manifests/deployment.yaml
kubectl delete -f manifests/pvc.yaml
kubectl delete -f manifests/secret.yaml
kubectl delete -f manifests/configmap.yaml
kubectl delete -f manifests/namespace.yaml
```

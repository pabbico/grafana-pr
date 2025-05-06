#!/bin/bash

# Script to deploy Grafana to Kubernetes

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Grafana on Kubernetes Deployment Script${NC}"
echo "----------------------------------------"

# Function to check if kubectl is installed
check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ kubectl found${NC}"
}

# Function to check if the cluster is accessible
check_cluster() {
  if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Please check your kubeconfig and cluster status"
    exit 1
  fi
  echo -e "${GREEN}✓ Kubernetes cluster is accessible${NC}"
}

# Function to deploy using kubectl apply
deploy_kubectl() {
  echo "Deploying Grafana using kubectl apply..."
  
  echo "Creating namespace..."
  kubectl apply -f manifests/namespace.yaml
  
  echo "Creating ConfigMap..."
  kubectl apply -f manifests/configmap.yaml
  
  echo "Creating Secret..."
  kubectl apply -f manifests/secret.yaml
  
  echo "Creating PersistentVolumeClaim..."
  kubectl apply -f manifests/pvc.yaml
  
  echo "Creating Deployment..."
  kubectl apply -f manifests/deployment.yaml
  
  echo "Creating Service..."
  kubectl apply -f manifests/service.yaml
  
  echo "Creating Ingress..."
  kubectl apply -f manifests/ingress.yaml
  
  echo -e "${GREEN}✓ Deployment completed${NC}"
}

# Function to deploy using kustomize
deploy_kustomize() {
  echo "Deploying Grafana using kustomize..."
  kubectl apply -k manifests/
  echo -e "${GREEN}✓ Deployment completed${NC}"
}

# Function to check deployment status
check_status() {
  echo "Checking deployment status..."
  echo "Waiting for pods to be ready..."
  kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s || {
    echo -e "${YELLOW}Warning: Pods are not ready within timeout period${NC}"
    echo "Checking pod status:"
    kubectl get pods -n monitoring -l app=grafana
    echo "Checking pod events:"
    kubectl get events -n monitoring --sort-by='.lastTimestamp' | grep grafana
    echo "You may need to troubleshoot the deployment."
    return 1
  }
  
  echo -e "${GREEN}✓ Grafana pods are ready${NC}"
  
  # Get service details
  local service_type=$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.type}')
  
  echo "Grafana service type: $service_type"
  
  if [ "$service_type" == "LoadBalancer" ]; then
    local external_ip=$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$external_ip" ]; then
      echo -e "${YELLOW}External IP is not yet assigned. You can check later with:${NC}"
      echo "kubectl get svc grafana -n monitoring"
    else
      echo -e "${GREEN}Grafana is accessible at: http://$external_ip${NC}"
    fi
  elif [ "$service_type" == "NodePort" ]; then
    local node_port=$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')
    echo -e "${GREEN}Grafana is accessible at NodePort: $node_port${NC}"
    echo "Access via: http://<node-ip>:$node_port"
  else
    echo -e "${YELLOW}For ClusterIP service type, use port-forwarding to access Grafana:${NC}"
    echo "kubectl port-forward -n monitoring svc/grafana 8080:80"
    echo "Then access: http://localhost:8080"
  fi
  
  echo -e "${YELLOW}Default credentials:${NC}"
  echo "Username: admin"
  echo "Password: admin (unless changed in secret.yaml)"
}

# Function to clean up deployment
cleanup() {
  echo "Cleaning up Grafana deployment..."
  kubectl delete -k manifests/ || {
    echo -e "${YELLOW}Warning: Cleanup using kustomize failed, trying individual resources...${NC}"
    kubectl delete -f manifests/ingress.yaml --ignore-not-found
    kubectl delete -f manifests/service.yaml --ignore-not-found
    kubectl delete -f manifests/deployment.yaml --ignore-not-found
    kubectl delete -f manifests/pvc.yaml --ignore-not-found
    kubectl delete -f manifests/secret.yaml --ignore-not-found
    kubectl delete -f manifests/configmap.yaml --ignore-not-found
    kubectl delete -f manifests/namespace.yaml --ignore-not-found
  }
  echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Function to setup port-forwarding
port_forward() {
  echo "Setting up port-forwarding to Grafana service..."
  echo "Press Ctrl+C to stop port-forwarding"
  kubectl port-forward -n monitoring svc/grafana 8080:80
}

# Main script logic
case "$1" in
  deploy)
    check_kubectl
    check_cluster
    if [ "$2" == "kustomize" ]; then
      deploy_kustomize
    else
      deploy_kubectl
    fi
    check_status
    ;;
  status)
    check_kubectl
    check_status
    ;;
  port-forward)
    check_kubectl
    port_forward
    ;;
  cleanup)
    check_kubectl
    cleanup
    ;;
  *)
    echo "Usage: $0 {deploy|status|port-forward|cleanup}"
    echo ""
    echo "Commands:"
    echo "  deploy [kustomize]  Deploy Grafana to Kubernetes (optionally using kustomize)"
    echo "  status              Check deployment status"
    echo "  port-forward        Set up port-forwarding to access Grafana"
    echo "  cleanup             Remove Grafana deployment"
    exit 1
    ;;
esac

exit 0

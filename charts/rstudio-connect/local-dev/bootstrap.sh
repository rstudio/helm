#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(git rev-parse --show-toplevel)"
DEV_DIR="${REPO_ROOT}/charts/rstudio-connect/local-dev"
CONNECT_NAMESPACE="connect-dev"
CONNECT_VERSION="$(yq '.versionOverride' "${DEV_DIR}/values.yaml")"

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    info "Checking requirements..."

    local required_tools=("docker" "k3d" "kubectl" "helm" "yq")

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool is not installed. Please install $tool."
            exit 1
        fi
    done

    if ! docker ps &> /dev/null; then
        error "Docker is not accessible. Please ensure Docker is running."
        exit 1
    fi
}

setup_k3d_cluster() {
    info "Creating k3d cluster..."
    k3d cluster create --config "${DEV_DIR}/k3d-config.yaml" || true

    local cluster_name
    cluster_name="$(yq '.metadata.name' "${DEV_DIR}/k3d-config.yaml")"

    k3d image import \
        "ghcr.io/rstudio/rstudio-connect:ubuntu2204-${CONNECT_VERSION}" \
        "ghcr.io/rstudio/rstudio-connect-content-init:ubuntu2204-${CONNECT_VERSION}" \
        "ghcr.io/rstudio/content-base:r4.2.3-py3.11.9-ubuntu2204" \
        --cluster "${cluster_name}"

    info "Waiting for k3d cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
}

install_cnpg_operator() {
    info "Installing CloudNativePG operator..."
    
    # TODO: use latest version dynamically
    kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.26/releases/cnpg-1.26.0.yaml
    
    info "Waiting for CNPG operator to be ready..."
    kubectl wait --for=condition=Available deployment/cnpg-controller-manager -n cnpg-system --timeout=300s
    
    info "CloudNativePG operator installed"
}

setup_nfs_server() {
    info "Setting up NFS server..."

    helm repo add nfs-ganesha-server-and-external-provisioner \
        https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner > /dev/null 2>&1 || true

    helm repo update nfs-ganesha-server-and-external-provisioner
    helm upgrade --install dev-nfs \
        nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner \
        --set persistence.enabled=true \
        --set persistence.size="1Gi" \
        --set storageClass.name="nfs" \
        --set storageClass.mountOptions="{vers=4}" \
        --namespace nfs-server \
        --create-namespace

    info "NFS server setup complete"
}

setup_postgres() {
    info "Setting up PostgreSQL cluster..."

    kubectl apply -f "${DEV_DIR}/postgres-cluster.yaml"

    local pg_cluster_name
    pg_cluster_name="$(yq '.metadata.name' "${DEV_DIR}/postgres-cluster.yaml")"

    info "Waiting for PostgreSQL cluster to be ready..."
    kubectl wait --for=condition=Ready "cluster/${pg_cluster_name}" --namespace ${CONNECT_NAMESPACE} --timeout=600s

    info "PostgreSQL cluster ready"
}

install_connect() {
    info "Installing Posit Connect..."

    kubectl create secret generic connect-license --from-file=connect.lic --namespace ${CONNECT_NAMESPACE} || true
    kubectl apply -f "${DEV_DIR}/connect-pvc.yaml"

    pushd "${REPO_ROOT}/charts/rstudio-connect" > /dev/null
    helm dependency build
    popd > /dev/null

    helm upgrade --install connect "${REPO_ROOT}/charts/rstudio-connect" \
        --namespace ${CONNECT_NAMESPACE} \
        --values "${DEV_DIR}/values.yaml" \
        --wait \
        --timeout=600s
    
    info "Posit Connect installed"
}

main() {
    info "Starting Posit Connect development cluster setup..."
    
    check_requirements
    setup_k3d_cluster
    install_cnpg_operator
    setup_nfs_server
    kubectl create namespace ${CONNECT_NAMESPACE} || true
    setup_postgres
    install_connect

    info "Setup complete! Connect is available at http://localhost:3939"
}

main

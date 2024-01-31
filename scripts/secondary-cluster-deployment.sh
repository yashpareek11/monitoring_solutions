#!/bin/bash

# Define variables
CHARTS_ROOT="/home/juned/Documents/monitering/"  # Replace with the root folder containing all Helm charts
NAMESPACE="obf"   # Replace with the Kubernetes namespace


# Function to create Kubernetes namespace
create_namespace() {
  local NAMESPACE=$1

  echo "Creating Kubernetes namespace $NAMESPACE..."
  
  # Create namespace
  kubectl create namespace $NAMESPACE

  # Check if the namespace creation was successful
  if [ $? -eq 0 ]; then
    echo "Namespace $NAMESPACE created successfully."
  else
    echo "Error: Namespace $NAMESPACE creation failed."
    exit 1
  fi
}


# Function to install Helm chart
install_chart() {
  local CHART_PATH=$1
  local RELEASE_NAME=$2

  echo "Installing Helm chart $CHART_PATH in namespace $NAMESPACE with release name $RELEASE_NAME..."
  
  # Install Helm chart from local path
  helm install $RELEASE_NAME $CHART_PATH \
    --namespace $NAMESPACE

  # Check if the installation was successful
  if [ $? -eq 0 ]; then
    echo "Helm chart $CHART_PATH installed successfully."
  else
    echo "Error: Helm chart $CHART_PATH installation failed."
    exit 1
  fi
}

# Create Kubernetes namespace
create_namespace $NAMESPACE

# Install fluent-bit. 
echo "Installing fluentbit..."
install_chart "$CHARTS_ROOT/fluent-bit" "fluentbit"

# Install filebeat.
echo "Installing filebeat..."
install_chart "$CHARTS_ROOT/filebeat" "filebeat"

# Install filebeat.
echo "Installing kube-state-metrics"
install_chart "$CHARTS_ROOT/kube-state-metrics" "kube-state-metrics"


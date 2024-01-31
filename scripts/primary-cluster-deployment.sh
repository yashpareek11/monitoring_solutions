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

# Install Elasticsearch
install_chart "$CHARTS_ROOT/elasticsearch" "elasticsearch"

# Wait for Elasticsearch deployment to be ready
echo "Waiting for Elasticsearch deployment to be ready..."
ELASTICSEARCH_RETRY_COUNT=0
ELASTICSEARCH_RETRY_MAX=10  # Adjust the maximum number of retries as needed

while [ $ELASTICSEARCH_RETRY_COUNT -lt $ELASTICSEARCH_RETRY_MAX ]; do
  sleep 5  # Adjust the sleep duration as needed
  ELASTICSEARCH_POD_READY=$(kubectl get pods -l app=elasticsearch-master -n $NAMESPACE --no-headers=true | awk '{print $2}' | grep "^1/1" | wc -l)
  
  if [ $ELASTICSEARCH_POD_READY -eq 1 ]; then
    echo "Elasticsearch deployment is ready. Proceeding with Kibana deployment."
    break
  fi
  
  ELASTICSEARCH_RETRY_COUNT=$((ELASTICSEARCH_RETRY_COUNT + 1))
done

# Check if Elasticsearch is ready
if [ $ELASTICSEARCH_POD_READY -ne 1 ]; then
  echo "Error: Elasticsearch deployment is not ready after $((ELASTICSEARCH_RETRY_COUNT * 5)) seconds. Exiting."
  exit 1
fi

# Install Kibana
install_chart "$CHARTS_ROOT/kibana" "kibana"

# Install strimzi-kafka-operator 
install_chart "$CHARTS_ROOT/strimzi-kafka-operator" "strimzi-kafka"

# Wait for strimzi-kafka deployment to be ready
echo "Waiting for strimzi-kafka deployment to be ready..."
STRIMZI_RETRY_COUNT=0
STRIMZI_RETRY_MAX=10  # Adjust the maximum number of retries as needed

while [ $STRIMZI_RETRY_COUNT -lt $STRIMZI_RETRY_MAX ]; do
  sleep 5  # Adjust the sleep duration as needed
  STRIMZI_POD_READY=$(kubectl get deployment -n $NAMESPACE --no-headers=true | grep strimzi-cluster-operator  | awk '{print $2}' | grep "^1/1" | wc -l)
  
  if [ $STRIMZI_POD_READY -eq 1 ]; then
    echo "strimzi-kafka deployment is ready. Proceeding with Kibana deployment."
    break
  fi
  
  STRIMZI_RETRY_COUNT=$((STRIMZI_RETRY_COUNT + 1))
done

# Check if Strimzi-kafka-operator is ready
if [ $STRIMZI_POD_READY -ne 1 ]; then
  echo "Error: strimzi-kafka deployment is not ready after $((STRIMZI_RETRY_COUNT * 5)) seconds. Exiting."
  exit 1
fi

# Install Kafka 
install_chart "$CHARTS_ROOT/obf-kafka" "obf-kafka"

# Wait for kafka-entity-operator deployment to be ready
echo "Waiting for kafka-entity-operator deployment to be ready..."
KAFKA_RETRY_COUNT=0
KAFKA_RETRY_MAX=10  # Adjust the maximum number of retries as needed

while [ $KAFKA_RETRY_COUNT -lt $KAFKA_RETRY_MAX ]; do
  sleep 10  # Adjust the sleep duration as needed
  KAFKA_POD_READY=$(kubectl get deployment -n $NAMESPACE --no-headers=true | grep obf-kafka-entity-operator | awk '{print $2}' | grep "^1/1" | wc -l)
  
  if [ $KAFKA_POD_READY -eq 1 ]; then
    echo "kafka deployment is ready. Proceeding with Logstash deployment."
    break
  fi  
  KAFKA_RETRY_COUNT=$((STRIMZI_RETRY_COUNT + 1))
done

# Check if Kafka is ready
if [ $KAFKA_POD_READY -ne 1 ]; then
  echo "Error: Kafka deployment is not ready after $((KAFKA_RETRY_COUNT * 5)) seconds. Exiting."
  exit 1
fi

# Install fluent-bit. 
echo "Installing fluentbit..."
install_chart "$CHARTS_ROOT/fluent-bit" "fluentbit"

# Install filebeat.
echo "Installing filebeat..."
install_chart "$CHARTS_ROOT/filebeat" "filebeat"

# Install Logstash pipeline... 
echo "Installing Logstash..."
install_chart "$CHARTS_ROOT/logstash" "logstash"

# Install Prometheus
echo "Installing Prometheus..."
kubectl apply -f "$CHARTS_ROOT/prometheus/" -n $NAMESPACE


# Install Grafana
echo "Installing Grafana..."
kubectl apply -f "$CHARTS_ROOT/grafana/" -n $NAMESPACE


# Install afka-adaptor... 
echo "Installing kafka-adaptor..."
install_chart "$CHARTS_ROOT/kafka-adapter" "kafka-adap"


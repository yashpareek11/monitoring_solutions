#!/bin/bash


echo "Start Installation of Filebeat..............."

# Add the Elastic APT repository and GPG key
sudo apt-get install -y apt-transport-https
sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update

# Install Filebeat
sudo apt-get install -y filebeat

# Get the VM IP address
VM_IP=$(hostname -I | awk '{print $1}')

# Configure Filebeat to send logs to a unique Kafka topic based on VM IP
sudo tee /etc/filebeat/filebeat.yml > /dev/null <<EOL
filebeat.inputs:
- type: log
  paths:
    - /var/log/*.log
  multiline.pattern: '^[[:space:]]'
  multiline.negate: false
  multiline.match: after

processors:
  - add_fields:
      target: ""
      fields:
        vm_ip: "${VM_IP}"
        vm_topic: "filebeat_${VM_IP}"

output.kafka:
  hosts: ["kafka-kafka:9092"]
  topic: "%{[fields][vm_topic]}"
  required_acks: 1
  compression: gzip
  max_message_bytes: 1000000
  message_key: "vm_ip"
EOL

# Start Filebeat
sudo service filebeat start

echo "Start Installation of Node Exporter..............."

# Install Node Exporter on Ubuntu

# Specify the Node Exporter version
NODE_EXPORTER_VERSION="1.5.0"

# Download and install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64

# Create a system user for Node Exporter
sudo useradd -rs /bin/false node_exporter

# Create a systemd service for Node Exporter
cat << EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOF

# Reload systemd and start Node Exporter
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Print installation status
echo "Node Exporter installed successfully."

#!/bin/bash

set -i
#
export TERM=xterm-256color
export DEBIAN_FRONTEND=noninteractive
export DATACENTER_NAME="blogr"

echo "Determining local IP address"
LOCAL_IPV4=$(hostname --ip-address)
echo "Using ${LOCAL_IPV4} as IP address for configuration and anouncement"
apt-add-repository --yes --update ppa:ansible/ansible
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    jq \
    unzip \
    dnsmasq \
    ansible

echo "create dummy interface"
ip link add dummy0 type dummy
ip addr add 169.254.1.1/32 dev dummy0
ip link set dev dummy0 up

cat << EODMCF >/etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
# server=/consul/127.0.0.1#8600
server=/consul/169.254.1.1#8600
listen-address=127.0.0.1
listen-address=169.254.1.1
EODMCF

systemctl restart dnsmasq

echo "Checking latest Consul versions..."
CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
CONSUL_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')

cd /tmp/

echo "Fetching Consul version ${CONSUL_VERSION} ..."
curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
echo "Installing Consul version ${CONSUL_VERSION} ..."
unzip consul.zip
chmod +x consul
mv consul /usr/local/bin/consul

echo "Configuring Consul And Nomad"
mkdir -p /var/lib/consul /etc/consul.d 

cat << EOCCF >/etc/consul.d/server.hcl
advertise_addr = "${LOCAL_IPV4}"
bootstrap_expect = 1
client_addr =  "0.0.0.0"
data_dir = "/var/lib/consul"
datacenter = "${DATACENTER_NAME}"
enable_syslog = true
log_level = "DEBUG"
recursors =  ["127.0.0.1"]
retry_join = ["provider=aws tag_key=Name tag_value=consul-master"]
server = true
ui = true
EOCCF

cat << EOCSU >/etc/systemd/system/consul.service
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target
[Service]
LimitNOFILE=65536
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Type=notify
[Install]
WantedBy=multi-user.target
EOCSU

systemctl daemon-reload
systemctl start consul

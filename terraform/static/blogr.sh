#!/bin/bash

set -x
export TERM=xterm-256color
export DEBIAN_FRONTEND=noninteractive
export DATACENTER_NAME="dummy"

#Bringing the Information
echo "Determining local IP address"
LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
echo "Using ${LOCAL_IPV4} as IP address for configuration and anouncement"

NODE_NAME=$(curl "http://169.254.169.254/latest/meta-data/hostname")

apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    jq \
    unzip \
    dnsmasq

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install -y docker-ce

echo "Configuring Docker to use local DNSMasq for DNS resolution (Enabling *.service.consul resolutions inside containers)"
cat << EODDCF >/etc/docker/daemon.json
{
  "dns": ["${LOCAL_IPV4}"]
}
EODDCF

systemctl restart docker.service

echo "Enabling *.service.consul resolution system wide"
cat << EODMCF >/etc/dnsmasq.d/10-consul
# Enable forward lookup of the 'consul' domain:
server=/consul/127.0.0.1#8600
EODMCF

systemctl restart dnsmasq

CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
CONSUL_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')

cd /tmp/

echo "Checking latest Consul and Nomad versions..."
echo "Fetching Consul version ${CONSUL_VERSION} ..."
curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
echo "Installing Consul version ${CONSUL_VERSION} ..."
unzip consul.zip
chmod +x consul
mv consul /usr/local/bin/consul

echo "Configuring Consul And Nomad"
mkdir -p /var/lib/consul  /etc/consul.d 

cat << EOCCF >/etc/consul.d/agent.hcl
client_addr =  "0.0.0.0"
recursors =  ["127.0.0.1"]
bootstrap =  false
datacenter = "${DATACENTER_NAME}"
data_dir = "/var/lib/consul"
enable_syslog = true
log_level = "DEBUG"
retry_join = ["provider=aws tag_key=Name tag_value=consul-master"]
advertise_addr = "${LOCAL_IPV4}"
EOCCF

cat << EOCSU >/etc/consul.d/dummy.json
{"service": {
    "name": "blogr",
    "tags": ["blogr"], 
    "port": 5000, 
    "check": {
        "http": "http://localhost:5000",
        "interval": "10s"
        }
    }
}
EOCSU

cat << EOCSU >/etc/systemd/system/consul.service
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target
[Service]
LimitNOFILE=65536
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Type=notify
[Install]
WantedBy=multi-user.target
EOCSU

cat << EOS >/tmp/filebeat.yml
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - /tmp/dummy_app.log

setup.kibana:
  host: "kibana.service.consul:5601"

output.elasticsearch:
  hosts: ["elasticsearch.service.consul:9200"]
  index: "filebeat-${LOCAL_IPV4}-%{+yyyy.MM.dd}"

setup.template.name: "${LOCAL_IPV4}"
setup.template.pattern: "${LOCAL_IPV4}-*"
EOS
systemctl daemon-reload
systemctl start consul

sudo docker pull denzal/blogr
# sudo docker run \
#             -p 5000:5000 \
#             -v /tmp:/tmp \
#             --restart=always \
#             denzal/dummy &
sudo docker run --name blogr -d -p 5000:5000 --rm \
     -e DATABASE_URL='mysql+mysqlconnector://blogr:blogr@10.0.10.10:3306/blogr' \
     denzal/blogr:latest

# sudo docker run -v /tmp/filebeat.yml:/usr/share/filebeat/filebeat.yml \
#                 -v /tmp:/tmp:ro \
#                 --restart=always \
#                 docker.elastic.co/beats/filebeat:6.5.4 &

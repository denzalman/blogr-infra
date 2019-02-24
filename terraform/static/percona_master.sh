#!/bin/bash
# set -x
# export TERM=xterm-256color
# export DEBIAN_FRONTEND=noninteractive
# export DATACENTER_NAME="dummy"

# #Bringing the Information
# echo "Determining local IP address"
# LOCAL_IPV4=$(curl "http://169.254.169.254/latest/meta-data/local-ipv4")
# echo "Using ${LOCAL_IPV4} as IP address for configuration and anouncement"

# NODE_NAME=$(curl "http://169.254.169.254/latest/meta-data/hostname")

# apt-get update
# apt-get install -y \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     software-properties-common \
#     jq \
#     unzip \
#     dnsmasq

# echo "Enabling *.service.consul resolution system wide"
# cat << EODMCF >/etc/dnsmasq.d/10-consul
# # Enable forward lookup of the 'consul' domain:
# server=/consul/127.0.0.1#8600
# EODMCF

# systemctl restart dnsmasq

# CHECKPOINT_URL="https://checkpoint-api.hashicorp.com/v1/check"
# CONSUL_VERSION=$(curl -s "${CHECKPOINT_URL}"/consul | jq .current_version | tr -d '"')

# cd /tmp/

# echo "Checking latest Consul version..."
# echo "Fetching Consul version ${CONSUL_VERSION} ..."
# curl -s https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
# echo "Installing Consul version ${CONSUL_VERSION} ..."
# unzip consul.zip
# chmod +x consul
# mv consul /usr/local/bin/consul

# echo "Configuring Consul"
# mkdir -p /var/lib/consul  /etc/consul.d 

# cat << EOCCF >/etc/consul.d/agent.hcl
# client_addr =  "0.0.0.0"
# recursors =  ["127.0.0.1"]
# bootstrap =  false
# datacenter = "${DATACENTER_NAME}"
# data_dir = "/var/lib/consul"
# enable_syslog = true
# log_level = "DEBUG"
# retry_join = ["provider=aws tag_key=Name tag_value=consul-master"]
# advertise_addr = "${LOCAL_IPV4}"
# EOCCF

# cat << EOCSU >/etc/consul.d/percona.json
# {"service": {
#     "name": "percona",
#     "tags": ["percona"], 
#     "port": 3306, 
#     "check": {
#         "http": "http://localhost:3306",
#         "interval": "10s"
#         }
#     }
# }
# EOCSU

# cat << EOCSU >/etc/systemd/system/consul.service
# [Unit]
# Description=consul agent
# Requires=network-online.target
# After=network-online.target
# [Service]
# LimitNOFILE=65536
# Restart=on-failure
# ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d
# ExecReload=/bin/kill -HUP $MAINPID
# KillSignal=SIGINT
# Type=notify
# [Install]
# WantedBy=multi-user.target
# EOCSU

# systemctl daemon-reload
# systemctl start consul

### Percona DB install

wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo percona-release setup ps80

#ROOTPASSWDDB="$(openssl rand -base64 12)"
ROOTPASSWDDB="password"
#echo "rootdbpass: $ROOTPASSWDDB" >> ./dbpass.txt

#DONE: CHANGE ROOT PASSWORD! 
package="percona-server-server-5.7"
c1="$package percona-server-server-5.7/root-pass password"
sudo debconf-set-selections <<< "$c1 $ROOTPASSWDDB"
#sudo debconf-set-selections <<< "$c1 rootpassword"
c2="$package percona-server-server-5.7/re-root-pass password"
sudo debconf-set-selections <<< "$c2 $ROOTPASSWDDB"
#sudo debconf-set-selections <<< "$c2 rootpassword"

sudo apt-get install -qq -y percona-server-server-5.7 percona-server-client-5.7

#TODO: Make initial creation if not exist DATABASE <BLOGR> and tables <users> and <messages>:

# CREATE DATABASE blogr;
mysql -uroot -p${ROOTPASSWDDB} -e "CREATE DATABASE blogr /*\!40100 DEFAULT CHARACTER SET utf8 */;"
#mysql -uroot -p${ROOTPASSWDDB} -e "USE blogr;"
#mysql -uroot -p${ROOTPASSWDDB} -e "CREATE TABLE user (id INT NOT NULL AUTO_INCREMENT, name VARCHAR(20) NOT NULL, password VARCHAR(20) NOT NULL, PRIMARY KEY (id)) ENGINE=INNODB;"
mysql -uroot -p${ROOTPASSWDDB} -e "CREATE USER 'blogr'@'localhost' IDENTIFIED BY 'blogr';"
mysql -uroot -p${ROOTPASSWDDB} -e "CREATE USER 'blogr'@'%' IDENTIFIED BY 'blogr';"
#mysql -uroot -p${ROOTPASSWDDB} -e "GRANT ALL PRIVILEGES ON blogr.* TO 'blogr'@'%' IDENTIFIED BY 'blogr';"

mysql -uroot -p${ROOTPASSWDDB} -e "GRANT ALL ON *.* TO 'blogr'@'localhost';"
mysql -uroot -p${ROOTPASSWDDB} -e "GRANT ALL ON *.* TO 'blogr'@'%';"
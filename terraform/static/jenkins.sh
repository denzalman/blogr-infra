#!/bin/bash

set -x
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    dnsmasq

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

apt-get update
apt-get install -y docker-cels
chmod 777 /dev/sdh/var/jenkins_home

docker run -p 80:8080 -p 50000:50000 -d --rm\
        -v /dev/sdh/var/jenkins_home:/var/jenkins_home \
        jenkins/jenkins
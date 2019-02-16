#!/bin/bash
set -x

apt-get update
apt-get -y install software-properties-common
apt-get -y install haproxy
apt-add-repository --yes --update ppa:ansible/ansible
apt-get -y install ansible


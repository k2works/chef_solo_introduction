#!/usr/bin/env bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
apt-get update
apt-get install -y curl
\curl -sSL https://get.rvm.io | bash -s stable
apt-get install -y git

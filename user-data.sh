#!/bin/bash
# Update and install Docker
apt update
apt install -y docker.io
# Start and enable Docker
systemctl start docker
systemctl enable docker


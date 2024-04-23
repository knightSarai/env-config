#!/bin/bash

set -e

echo "Updating package database..."
sudo apt-get update

echo "Installing dependencies..."
sudo apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common

echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "Adding the Docker repository..."
sudo add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "Updating package database..."
sudo apt-get update

echo "Installing Docker CE..."
sudo apt-get install -y docker-ce

echo "Ensuring Docker starts on boot and is currently running..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Docker installation is complete. Docker is now running."

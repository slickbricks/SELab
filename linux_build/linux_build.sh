#!/bin/bash

##############################################
# Dev Environment Setup Script
##############################################
#
# This script automates the setup of a development environment on Ubuntu 22X.
# It installs Anaconda, GitHub Desktop, Chrome, and Docker Desktop.
# Make sure to review and modify the script to suit your needs before running it.
# Before running the script, make sure to:
#   1. Update the 'anaconda_ver' variable with the desired Anaconda version.
#   2. Update the 'docker_version' variable with the desired Docker Desktop version.
#   3. Update the 'log_file' variable with the desired log file path.
#   4. Ensure you have superuser privileges to install packages.
#
##############################################

# Update the Anaconda version you want to install
anaconda_ver="Anaconda3-2021.05-Linux-x86_64.sh"

# Update the Docker Desktop version you want to install
docker_version="docker-desktop-4.21.1-amd64.deb"

# Update the log file path
log_file="$HOME/dev_environment_setup.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Function to handle errors and exit script
handle_error() {
    local error_code="$?"
    log "ERROR: $1"
    exit "$error_code"
}

# Register error handling function
trap 'handle_error "An error occurred in line $LINENO."' ERR

set -e

log "Begin install..."
sudo apt update && sudo apt upgrade -y

# Set Anaconda version
anaconda_installer="$HOME/Downloads/$anaconda_ver"
log "Downloading Anaconda..."
wget "https://repo.anaconda.com/archive/$anaconda_ver" -O "$anaconda_installer"
log "Installing Anaconda..."
bash "$anaconda_installer" -b -p ~/anaconda3
echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
rm -f "$anaconda_installer"

# Install GitHub Desktop
log "Install GitHub Desktop..."
github_deb_file="github-desktop.deb"
wget -qO "$github_deb_file" https://github.com/shiftkey/desktop/releases/latest/download/github-desktop-linux-2.9.4-linux1.deb
sudo apt install -y "./$github_deb_file"
rm -f "$github_deb_file"

# Install Chrome
log "Install Chrome..."
chrome_deb_file="google-chrome-stable.deb"
wget -qO "$chrome_deb_file" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y "./$chrome_deb_file"
rm -f "$chrome_deb_file"

# Install Docker Desktop
log "Install Docker Desktop (Version: $docker_version)..."
docker_deb_file="$docker_version"
wget "https://desktop.docker.com/linux/main/amd64/$docker_deb_file"
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
docker_gpg_keyring="/etc/apt/keyrings/docker.gpg"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o "$docker_gpg_keyring"
sudo chmod a+r "$docker_gpg_keyring"
echo "deb [arch=$(dpkg --print-architecture) signed-by=$docker_gpg_keyring] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y "./$docker_deb_file"
rm -f "$docker_deb_file"

log "Done!!!"

#!/bin/bash
#
# Script Name: start.sh
# Author: John DeHart
# Date: 7/27/23
#
# Description: This bash script sets up and starts a Docker environment with 
#              The Littlest JupyterHub (tljh), with additional configurations for multiple
#              Python environments, and pre-installation of required packages and tools like Elyra.
#              It also updates the Sysmlv2 kernel model publishing location.
#
# Usage: 
# 1. Make the script executable: chmod +x tljh_docker_setup.sh
# 2. Run the script: ./tljh_docker_setup.sh
#
# Prerequisites: Docker and Docker Compose should be installed and running on the machine where the script is executed.
#
# Steps:
# 1. The script sets up a Docker network and a volume (if they don't exist).
# 2. It then removes the 'selab-tljh' image if it exists and starts up the Docker containers defined in docker-compose.yml.
# 3. TLJH is installed and configured with an admin user.
# 4. Base Conda environment is updated with packages defined in /tmp/updates/base_env.yaml inside the TLJH Docker container.
# 5. Additional Conda environments are created or updated based on yaml files in /tmp/envs inside the TLJH Docker container.
# 6. Elyra is installed using the requirements file /tmp/envs/elyra.txt.
# 7. The Sysmlv2 kernel model publishing location is updated.
#
# Output: 
# The script logs its output to a logfile that is created in the 'logs' directory in the same directory as the script. 
# The logfile is named 'logfile_<timestamp>.log'.
#
# Note: 
# This script assumes the presence of specific files and directories, and does not check if they exist. 
# Ensure all necessary files and directories are present before running the script.
#

set -e #
set -o pipefail

# Define a log file with a timestamp
NOW=$(date +"%Y%m%d_%H%M%S")
LOGFILE="$(dirname "$0")/logs/logfile_$NOW.log"

# Get the directory containing this script.
SCRIPT_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Define a function to check the status
check_status() {
    if [ $? -eq 0 ]; then
        echo "SUCCESS: $1" | tee -a $LOGFILE
    else
        echo "FAILED: $1" | tee -a $LOGFILE
        exit 1
    fi
}

# Start docker-compose
start_docker() {

    # Check if the Docker network exists and create it if it does not
    if [ -z "$(docker network ls | grep thenetwork)" ]; then
    docker network create thenetwork
    fi

    # Check if the Docker volume exists and create it if it does not
    if [ -z "$(docker volume ls | grep postgresdbserver)" ]; then
    docker volume create postgresdbserver
    fi

    # Check if the Docker volume exists and create it if it does not
    if [ -z "$(docker volume ls | grep user-data)" ]; then
    docker volume create user-data
    fi
    
    echo "Starting docker-compose..." | tee -a $LOGFILE
    # docker image rm -f selab
    #docker-compose up -d
    docker-compose up -d --build
    check_status "docker-compose start"
}

# Install tljh
# Note: the scratch directory must be removed before updating tljh
install_tljh() {
    AUTH_ADMIN=${AUTH_ADMIN:-"admin:admin"}
    echo "Create User: $AUTH_ADMIN" | tee -a $LOGFILE
    docker-compose exec tljh bash -c \
        "rm -rf /etc/skel/scratch/scratch && \
        curl -L https://tljh.jupyter.org/bootstrap.py \
        | sudo python3 - --show-progress-page --admin $AUTH_ADMIN --plugin git+https://github.com/kafonek/tljh-shared-directory \
        --user-requirements-txt-url https://raw.githubusercontent.com/avianinc/SELab/build/sos_install_from_config/envs/requirements.txt"
    check_status "Installed tljh"
}

# Update sysmlv2 kernel model publish location
install_sysmlv2_kernel() {
    echo "Updating the Sysmlv2 kernel model publishing location" | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/mamba install jupyter-sysml-kernel -y;  \
        sudo sed -i 's|\"ISYSML_API_BASE_PATH\": \"http://sysml2.intercax.com:9000\"|\"ISYSML_API_BASE_PATH\": \"http://sysmlapiserver:9000\"|g' /opt/tljh/user/share/jupyter/kernels/sysml/kernel.json"
    check_status "Sysmlv2 model publish location"
}

# Install sos kernels
install_sos_kernels() {
    echo "Installing SoS Kernels" | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
        echo 'Installing SoS Kernels'; \
        sudo -E /opt/tljh/user/bin/pip install jupyterlab-sos sos-python sos-scilab sos-bash bash_kernel jupyterlab-rise; \
        sudo -E /opt/tljh/user/bin/mamba install -c conda-forge sos-r nodejs -y; \
        sudo -E /opt/tljh/user/bin/python -m bash_kernel.install; \
        sudo -E /opt/tljh/user/bin/python -m sos_notebook.install;"
    check_status "Installed SoS Kernels"
}

# Had to hack a bit to slow down the modifiying of the kernel.json file
# to allow the kernel to be installed first.
install_scilab_kernel() {
    echo "Installing Scilab Kernel" | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
    sudo -E /opt/tljh/user/bin/pip install scilab-kernel; \
    for i in {1..30}; do \
        if [ -f /opt/tljh/user/share/jupyter/kernels/scilab/kernel.json ]; then \
            sudo jq '. += {\"env\": {\"SCILAB_EXECUTABLE\": \"/opt/scilab-6.0.2/bin/scilab-adv-cli\"}}' /opt/tljh/user/share/jupyter/kernels/scilab/kernel.json > /tmp/temp.json; \
            sudo mv /tmp/temp.json /opt/tljh/user/share/jupyter/kernels/scilab/kernel.json; \
            break; \
        else \
            echo 'Waiting for kernel.json to be created'; \
            sleep 2; \
        fi; \
    done"
    check_status "Installed Scilab Kernel"
}

# Call the functions
start_docker
install_tljh
install_sysmlv2_kernel
install_sos_kernels
install_scilab_kernel

# Done!!!
echo "Script completed successfully." | tee -a $LOGFILE

# Notes:
# 10/5/23 - Simplified installation requirements. Removed the need for a separate requirements.txt file for Elyra.
# 10/6/23 - Updated nodejs in base environment to 18.x (Dockerfile.tljh)
# 10/10/23 - Major clean up most kernels installed and working. Finishing up Dakota kernel
# 11/15/23 - Added Scilab kernel and cleaned up the script will move to main branch (no elayra yet, waiting on jl4 support)
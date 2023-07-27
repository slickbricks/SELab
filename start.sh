#!/bin/bash
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
    
    echo "Starting docker-compose..." | tee -a $LOGFILE
    docker image rm -f selab-tljh
    docker-compose up -d
    check_status "docker-compose start"
}

# Install tljh
install_tljh() {
    AUTH_ADMIN=${AUTH_ADMIN:-"admin:admin"}
    echo "Create User: $AUTH_ADMIN" | tee -a $LOGFILE
    docker-compose exec tljh bash -c \
        "curl -L https://tljh.jupyter.org/bootstrap.py \
        | sudo python3 - --show-progress-page --admin $AUTH_ADMIN"
    check_status "Installed tljh"
}

update_base_env() {
    echo "Installing base env packages..." | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/mamba update conda -y && \
        sudo -E /opt/tljh/user/bin/mamba env update -n base -f /tmp/updates/base_env.yaml"
    check_status "Base environments update"
}

build_env_kernels() {
    echo "Building environment kernels..." | tee -a $LOGFILE
    docker-compose exec tljh bash -c 'set -e; 
        for env_file in $(ls /tmp/envs/*.yaml); do
            env_name=$(basename $env_file .yaml);
            echo "Processing environment: $env_name";
            echo "List of environments:";
            sudo -E /opt/tljh/user/bin/mamba info --envs;
            if [[ $(sudo -E /opt/tljh/user/bin/mamba info --envs | grep -w $env_name) ]]; then
                echo "Updating environment $env_name";
                sudo -E /opt/tljh/user/bin/mamba env update --name $env_name -f $env_file
            else
                echo "Creating environment $env_name";
                sudo -E /opt/tljh/user/bin/mamba env create -f $env_file
            fi
        done && sudo -E /opt/tljh/user/bin/mamba env update -f /tmp/updates/update_kernels.yaml'
    check_status "Build environment kernels"
}

install_elyra() {
    echo "Installing Elyra..." | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/pip install --upgrade -r /tmp/envs/elyra.txt"
    check_status "Elyra Installation"
}

# Update sysmlv2 kernel model publish location
update_sysmlv2() {
    echo "Updating the Sysmlv2 kernel model publishing location" | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
        sudo sed -i 's|\"ISYSML_API_BASE_PATH\": \"http://sysml2.intercax.com:9000\"|\"ISYSML_API_BASE_PATH\": \"http://sysmlapiserver:9000\"|g' /opt/tljh/user/envs/sysmlv2/share/jupyter/kernels/sysml/kernel.json"
    check_status "Sysmlv2 model publish location"
}

# Call the functions
start_docker
install_tljh
update_base_env
build_env_kernels
install_elyra
update_sysmlv2

echo "Script completed successfully." | tee -a $LOGFILE

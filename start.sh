#!/bin/bash
set -e
set -o pipefail

# Define a log file with a timestamp
NOW=$(date +"%Y%m%d_%H%M%S")
LOGFILE="$(dirname "$0")/logs/logfile_$NOW.log"


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

# Update base env
update_base_env() {
    echo "Installing base env packages..." | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/mamba update conda -y && \
        sudo -E /opt/tljh/user/bin/mamba install python="3.9" && \
        sudo -E /opt/tljh/user/bin/mamba install -c conda-forge \
        nodejs ipyparallel scipy pandas matplotlib scikit-learn keras tensorflow -y"
    check_status "Base environments update"
}

# Build environments
build_envs() {
    echo "Building Sysml environments..." | tee -a $LOGFILE
    docker-compose exec tljh bash -c "\
        sudo /opt/tljh/user/bin/mamba create --name sysmlv2 jupyter-sysml-kernel -y && \
        sudo /opt/tljh/user/bin/mamba create --name r_env r-irkernel -y && \
        sudo /opt/tljh/user/bin/mamba install nb_conda_kernels -y"
    check_status "Conda environments setup"
}

# Install elyra
install_elyra() {
    echo "Installing Elyra..." | tee -a $LOGFILE
    docker-compose exec tljh bash -c "set -e; \
        sudo -E /opt/tljh/user/bin/pip install --upgrade 'elyra[all]'"
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
build_envs
install_elyra
update_sysmlv2

echo "Script completed successfully." | tee -a $LOGFILE

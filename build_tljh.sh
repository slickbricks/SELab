#!/bin/bash
set -e

# Define a function to check the status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✔ $1\e[0m"
    else
        echo -e "\e[31m✘ $1\e[0m"
    fi
}

echo "Starting docker-compose..."
docker image rm -f selab-tljh
docker-compose up -d
check_status "docker-compose start"

# Install tljh
AUTH_ADMIN=admin:admin
if [[ -n $1 ]]; then
    AUTH_ADMIN=$1
fi
echo "Create User: $AUTH_ADMIN"
docker-compose exec tljh bash -c \
    "curl -L https://tljh.jupyter.org/bootstrap.py \
    | sudo python3 - --show-progress-page --admin $AUTH_ADMIN"
check_status "Installed tljh"

# Update base env
echo "Installing base env packages..."
docker-compose exec tljh bash -c "set -e; \
    sudo -E /opt/tljh/user/bin/mamba update conda -y && \
    sudo -E /opt/tljh/user/bin/mamba install python="3.9" && \
    sudo -E /opt/tljh/user/bin/mamba install -c conda-forge \
    nodejs ipyparallel scipy pandas matplotlib scikit-learn keras tensorflow -y"
check_status "Base envrironments update"

# Build environments
echo "Building Sysml enviorments..."
docker-compose exec tljh bash -c "\
    sudo /opt/tljh/user/bin/mamba create --name sysmlv2 jupyter-sysml-kernel -y && \
    sudo /opt/tljh/user/bin/mamba create --name r_env r-irkernel -y && \
    sudo /opt/tljh/user/bin/mamba install nb_conda_kernels -y"
check_status "Conda envrironments setup"

# Install elyra
echo "Installing Elyra..."
docker-compose exec tljh bash -c "set -e; \
    sudo -E /opt/tljh/user/bin/pip install --upgrade 'elyra[all]'"
check_status "Elyra Installtion"

echo "Script completed successfully."

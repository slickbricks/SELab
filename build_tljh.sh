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

# Check if TLJH is already installed
echo "Checking TLJH installation..."
if docker-compose exec tljh bash -c "[ ! -d /opt/tljh ] || [ ! -d /opt/tljh/user/bin/conda ]"; then
    echo "TLJH not fully installed. Installing..."
    # Install tljh
    AUTH_ADMIN=admin:admin
    if [[ -n $1 ]]; then
        AUTH_ADMIN=$1
    fi
    docker-compose exec tljh bash -c "set -e; \
        curl -L https://tljh.jupyter.org/bootstrap.py \
        | sudo python3 - --show-progress-page --admin $AUTH_ADMIN"
    check_status "TLJH installation"
else
    echo "TLJH already fully installed. Skipping installation."
fi

# Update base env
echo "Installing base env packages..."
docker-compose exec tljh bash -c "set -e; \
    sudo -E /opt/tljh/user/bin/mamba update conda -y && \
    sudo -E /opt/tljh/user/bin/mamba install python="3.9"
    sudo -E /opt/tljh/user/bin/mamba install -c conda-forge \
    nodejs ipyparallel scipy pandas matplotlib scikit-learn keras tensorflow -y"
check_status "Base envrironments update"

# Build environments
echo "Building Sysml enviorments..."
docker-compose exec tljh bash -c "\
    sudo /opt/tljh/user/bin/mamba create --name sysmlv2 jupyter-sysml-kernel -y && \
    sudo /opt/tljh/user/bin/mamba create --name r_env r-irkernel -y"
check_status "Conda envrironments setup"

# Install nb_kerenls...
echo "Installing nb_kernels..."
docker-compose exec tljh bash -c "\
    sudo /opt/tljh/user/bin/mamba install nb_conda_kernels -y"
check_status "Create environment kernels"

# Install elyra (Watch the order here or things can brake so elyra last using pip...)
echo "Installing Elyra..."
docker-compose exec tljh bash -c "set -e; \
    sudo -E /opt/tljh/user/bin/pip install --upgrade 'elyra[all]'"
check_status "Elyra Installtion"

echo "Script completed successfully."

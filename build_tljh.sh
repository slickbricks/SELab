#!/bin/bash
echo "Starting docker-compose..."
docker-compose up -d

# Install tljh
AUTH_ADMIN=admin:admin
if [[ -n $1 ]]; then
    AUTH_ADMIN=$1
fi
echo "Create User: $AUTH_ADMIN"
docker-compose exec tljh bash -c \
    "curl -L https://tljh.jupyter.org/bootstrap.py \
    | sudo python3 - --show-progress-page --admin $AUTH_ADMIN"

# Update conda and set solver to libmamba to prevent crash
echo "Updating conda base..." # separate lines or the -y will throw and error
docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda update -n base conda -y"
docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda update --all -y"
docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda install -n base conda-libmamba-solver -y"
docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda config --set solver libmamba"

# Wait for the installation process to complete
#while [ ! -f /opt/tljh/user/bin/conda ]; do
#  sleep 2
#done

# Install additional conda packages
# List the packages you want to install in the for loop
# Use spaces between the packages e.g. ("package1" "package2")
#PACKAGES=("jupyter-sysml-kernel")

# Join the packages with space
#PACKAGES_STR="${PACKAGES[@]}"

# Install the packages
#echo "Installing PACKAGES"
#   docker-compose exec tljh bash -c \
#    "sudo /opt/tljh/user/bin/conda install -c conda-forge $PACKAGES_STR"
#done

echo "Installing jupyter-sysml-kernel..."
docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda install -c conda-forge jupyter-sysml-kernel -y"

# Done
echo "TLJH Installation Complete!!!"
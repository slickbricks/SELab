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

echo "Updating conda base..." # separate lines or the -y will throw and error
docker-compose exec tljh bash -c "\
sudo -E /opt/tljh/user/bin/conda update -n base conda -y && \
sudo -E /opt/tljh/user/bin/conda update --all -y && \
sudo -E /opt/tljh/user/bin/conda install -n base conda-libmamba-solver -y && \
sudo -E /opt/tljh/user/bin/conda config --set solver libmamba"

# Install R kernel
echo "Installing R kernel..."
docker-compose exec tljh bash -c "\
sudo /opt/tljh/user/bin/conda config --add channels r && \
sudo /opt/tljh/user/bin/conda install --yes r-irkernel"

# Install sysmlv2 kernel
echo "Installing jupyter packages..."
docker-compose exec tljh bash -c "\
sudo /opt/tljh/user/bin/conda install -c conda-forge \
jupyter-sysml-kernel nodejs ipyparallel -y"

# Install Elyra kernel
#echo "Installing Elyra..."
#docker-compose exec tljh bash -c "\
#/opt/tljh/user/bin/conda install -c conda-forge "elyra[all]"

# Install git extension
# echo "Installing jupyter-git..."
# #docker-compose exec tljh bash -c "sudo pip install --upgrade jupyterlab-git && \
# docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda install -c conda-forge jupyterlab-git -y && \
# #sudo /opt/tljh/user/bin/jupyter server extension enable --sys-prefix --py jupyterlab_git"
# #sudo /opt/tljh/user/bin/jupyter server extension enable --user --py jupyterlab_git"

# pip install jupyterlab-git==0.30

# # Install C++ Kernel
# echo "Installing xeus kernel..."
# docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda install xeus-cling -c conda-forge -y"
# # docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda install xeus -c conda-forge -y"

# # Final clean up
# echo "Finishing installation..."
# docker-compose exec tljh bash -c "sudo /opt/tljh/user/bin/conda update --all -y && \
# sudo /opt/tljh/user/bin/jupyter lab  build"

# # Done
# echo "TLJH Installation Complete!!!"


# # sudo chmod -R 777 /opt/tljh/user/
#!/bin/bash

# Install SOS core and SOS Notebook
sudo pip install sos sos-notebook --no-deps

# Install SOS language kernels
sudo pip install sos-r sos-bash sos-python --no-deps

# Install jupyterlab-sos without upgrading JupyterLab
sudo pip install jupyterlab-sos --no-deps

# Install ipykernel for Python
sudo pip install ipykernel --no-deps
sudo python -m ipykernel install

# Register Python kernel with SoS
sudo sos register Python

# Install and register R kernel with SoS (assumes Rscript is in your PATH)
sudo Rscript -e "install.packages('IRkernel', repos='http://cran.r-project.org')"
sudo Rscript -e "IRkernel::installspec(user = FALSE)"
sudo sos register R

# Install SOS notebook kernel
sudo python -m sos_notebook.install

# Verify installations
sudo pip freeze | grep sos
sudo pip freeze | grep jupyterlab-sos

# List Jupyter kernels
sudo jupyter kernelspec list

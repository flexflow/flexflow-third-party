#!/bin/bash
set -euo pipefail
set -x

# General dependencies
echo "Installing apt dependencies..."
sudo apt-get update && sudo apt-get install -y --no-install-recommends wget binutils git zlib1g-dev && \
    sudo rm -rf /var/lib/apt/lists/*

# Install CUDNN
CUDA_VERSION=${CUDA_VERSION:-11.1.1}
./install_cudnn.sh "${CUDA_VERSION}"

# Install Miniconda
echo "Installing Miniconda..."
wget -c -q https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x ./Miniconda3-latest-Linux-x86_64.sh && \
    ./Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm ./Miniconda3-latest-Linux-x86_64.sh && \
    /opt/conda/bin/conda upgrade --all && \
    /opt/conda/bin/conda install conda-build conda-verify && \
    /opt/conda/bin/conda clean -ya

# Install HIP dependencies if needed
FF_GPU_BACKEND=${FF_GPU_BACKEND:-"cuda"}
if [[ "${FF_GPU_BACKEND}" != @(cuda|hip_cuda|hip_rocm|intel) ]]; then
  echo "Error, value of FF_GPU_BACKEND (${FF_GPU_BACKEND}) is invalid."
  exit 1
elif [[ "$FF_GPU_BACKEND" == "hip_cuda" || "$FF_GPU_BACKEND" = "hip_rocm" ]]; then
    echo "FF_GPU_BACKEND: ${FF_GPU_BACKEND}. Installing HIP dependencies"
    wget https://repo.radeon.com/amdgpu-install/22.20.5/ubuntu/focal/amdgpu-install_22.20.50205-1_all.deb
    sudo apt-get install -y ./amdgpu-install_22.20.50205-1_all.deb
    rm ./amdgpu-install_22.20.50205-1_all.deb
    sudo amdgpu-install -y --usecase=hip,rocm --no-dkms
    sudo apt-get install -y hip-dev hipblas miopen-hip rocm-hip-sdk
else
    echo "FF_GPU_BACKEND: ${FF_GPU_BACKEND}. Skipping installing HIP dependencies"
fi
sudo rm -rf /var/lib/apt/lists/*

# Install conda packages
echo "Installing conda packages..."
export PATH=/opt/conda/bin:$PATH
conda install cmake make
conda install -c conda-forge numpy keras-preprocessing pybind11 cmake-build-extension pillow=9.0.0

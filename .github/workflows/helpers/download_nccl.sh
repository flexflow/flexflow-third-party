#!/bin/bash
set -euo pipefail
set -x

mkdir -p nccl_downloads
cd nccl_downloads

ubuntu_version=$(lsb_release -rs)
ubuntu_version=${ubuntu_version//./}
wget "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${ubuntu_version}/x86_64/cuda-keyring_1.0-1_all.deb"
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update -y
rm -f cuda-keyring_1.0-1_all.deb

if [[ "$ubuntu_version" == "2004" ]]; then
    sudo apt download libnccl2=2.15.5-1+cuda11.0 libnccl-dev=2.15.5-1+cuda11.0
	sudo apt download libnccl2=2.8.4-1+cuda11.1 libnccl-dev=2.8.4-1+cuda11.1
	sudo apt download libnccl2=2.8.4-1+cuda11.2 libnccl-dev=2.8.4-1+cuda11.2
	sudo apt download libnccl2=2.9.9-1+cuda11.3 libnccl-dev=2.9.9-1+cuda11.3
	sudo apt download libnccl2=2.11.4-1+cuda11.4 libnccl-dev=2.11.4-1+cuda11.4
	sudo apt download libnccl2=2.11.4-1+cuda11.5 libnccl-dev=2.11.4-1+cuda11.5
	sudo apt download libnccl2=2.12.12-1+cuda11.6 libnccl-dev=2.12.12-1+cuda11.6
	sudo apt download libnccl2=2.14.3-1+cuda11.7 libnccl-dev=2.14.3-1+cuda11.7
elif [[ "$ubuntu_version" == "1804" ]]; then
	# Additional key required to download the CUDA 10.1 version
	sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub
	wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
	sudo dpkg -i nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
	sudo apt-get update -y
	rm -f nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
    sudo apt download libnccl2=2.8.3-1+cuda10.1 libnccl-dev=2.8.3-1+cuda10.1
	sudo apt download libnccl2=2.15.5-1+cuda10.2 libnccl-dev=2.15.5-1+cuda10.2
	sudo apt download libnccl2=2.15.5-1+cuda11.0 libnccl-dev=2.15.5-1+cuda11.0
	sudo apt download libnccl2=2.8.4-1+cuda11.1 libnccl-dev=2.8.4-1+cuda11.1
	sudo apt download libnccl2=2.8.4-1+cuda11.2 libnccl-dev=2.8.4-1+cuda11.2
	sudo apt download libnccl2=2.9.9-1+cuda11.3 libnccl-dev=2.9.9-1+cuda11.3
	sudo apt download libnccl2=2.11.4-1+cuda11.4 libnccl-dev=2.11.4-1+cuda11.4
	sudo apt download libnccl2=2.11.4-1+cuda11.5 libnccl-dev=2.11.4-1+cuda11.5
	sudo apt download libnccl2=2.12.12-1+cuda11.6 libnccl-dev=2.12.12-1+cuda11.6
	sudo apt download libnccl2=2.14.3-1+cuda11.7 libnccl-dev=2.14.3-1+cuda11.7
fi

for debfile in *.deb; do
    temp_str=${debfile#*+}
    temp_str=${temp_str%_*}
	cuda_version=${temp_str:4}
	mkdir -p "cuda-$cuda_version/nccl"
	dpkg-deb -xv "$debfile" "./cuda-$cuda_version/nccl"
	cd "cuda-$cuda_version/nccl"
	[ -d ./usr/include ] && mv ./usr/include ./
	mkdir -p lib
	files_to_move=(./usr/lib/x86_64-linux-gnu/*.a)
	[ -f "${files_to_move[0]}" ] && mv ./usr/lib/x86_64-linux-gnu/*.a ./lib/
	files_to_move=(./usr/lib/x86_64-linux-gnu/*.so)
	[ -f "${files_to_move[0]}" ] && mv ./usr/lib/x86_64-linux-gnu/*.so ./lib/
	files_to_move=(./usr/lib/x86_64-linux-gnu/*.so.*)
	[ -f "${files_to_move[0]}" ] && mv ./usr/lib/x86_64-linux-gnu/*.so.* ./lib/
	symlinks_to_move="$(find ./usr/lib/x86_64-linux-gnu/ -type l )"
	for s in $symlinks_to_move; do
		fname="$(basename $s)"
		ln -s "$(readlink $s )" ./lib/$fname
	done
	rm -rf usr
	cd ../../
done

rm -rf *.deb

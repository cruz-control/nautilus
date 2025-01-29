# Usefull for setting up basic tools in a pod/deployment

apt update
apt install -y wget git

DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
apt-get update && apt-get install ffmpeg libsm6 libxext6 tmux git wget curl -y

mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh

. ~/miniconda3/bin/activate && conda init --all

conda create -n conda -y python=3.9 && conda activate conda
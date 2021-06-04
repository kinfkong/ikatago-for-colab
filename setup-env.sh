#!/bin/bash

KATAGO_BACKEND=$1
WEIGHT_FILE=$2
USE_HIGHTHREADS=$3
RELEASE_VERSION=2.0.0
GPU_NAME=`nvidia-smi -q | grep "Product Name" | cut -d":" -f2 | tr -cd '[:alnum:]._-'`
#GPU_NAME=TeslaT4

detect_auto_backend () {
  if [ "$GPU_NAME" == "TeslaT4" ]
  then
    KATAGO_BACKEND="CUDA"
  else
    KATAGO_BACKEND="OPENCL"
  fi
}

detect_auto_weight () {
  if [ "$GPU_NAME" == "TeslaK80" ]
  then
    WEIGHT_FILE="20b"
  elif [ "$GPU_NAME" == "TeslaP4" ]
  then
    WEIGHT_FILE="20b"
  else
    WEIGHT_FILE="40b"
  fi
}

if [ "$KATAGO_BACKEND" == "AUTO" ]
then
  detect_auto_backend
fi

if [ "$WEIGHT_FILE" == "AUTO" ]
then
  detect_auto_weight
fi

echo "Using GPU: " $GPU_NAME
echo "Using Katago Backend: " $KATAGO_BACKEND
echo "Using Katago Weight: " $WEIGHT_FILE



cd /content
apt install --yes libzip4 1>/dev/null
rm -rf work
wget --quiet https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/work.zip -O work.zip
unzip -qq work.zip

cd /content/work
wget https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/weight_urls.txt -O weight_urls.txt
WEIGHT_URL=`grep "^$WEIGHT_FILE " ./weight_urls.txt | cut -d ' ' -f2`
echo "Using Weight URL: " $WEIGHT_URL

#download the binarires
if [ "$USE_HIGHTHREADS" == "TRUE" ]
then
wget --quiet https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/katago-highthread.zip
unzip katago-highthread.zip
cp ./katago-$KATAGO_BACKEND-highthread ./data/bins/katago
else
wget https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/katago-$KATAGO_BACKEND -O ./data/bins/katago
fi 
chmod +x ./data/bins/katago



mkdir -p /root/.katago/
cp -r ./opencltuning /root/.katago/

#download the weights
if [[ "$WEIGHT_FILE" == "kata1"* ]]
  then
wget --quiet https://github.com/kinfkong/ikatago-for-colab/releases/download/$RELEASE_VERSION/kata1_weights.py -O kata1_weights.py
python kata1_weights.py $WEIGHT_FILE
WEIGHT_FILE="40b"
cp /root/.katago/opencltuning/tune6_gpuTeslaK80_x19_y19_c256_mv8.txt /root/.katago/opencltuning/tune6_gpuTeslaK80_x19_y19_c256_mv10.txt
cp /root/.katago/opencltuning/tune6_gpuTeslaP100PCIE16GB_x19_y19_c256_mv8.txt /root/.katago/opencltuning/tune6_gpuTeslaP100PCIE16GB_x19_y19_c256_mv10.txt
cp /root/.katago/opencltuning/tune6_gpuTeslaP100PCIE16GB_x19_y19_c384_mv8.txt /root/.katago/opencltuning/tune6_gpuTeslaP100PCIE16GB_x19_y19_c384_mv10.txt
cp /root/.katago/opencltuning/tune8_gpuTeslaK80_x19_y19_c256_mv8.txt /root/.katago/opencltuning/tune8_gpuTeslaK80_x19_y19_c256_mv10.txt
cp /root/.katago/opencltuning/tune8_gpuTeslaP100PCIE16GB_x19_y19_c256_mv8.txt /root/.katago/opencltuning/tune8_gpuTeslaP100PCIE16GB_x19_y19_c256_mv10.txt
elif [[ "$WEIGHT_URL" == *"zip" ]]
  then
  WEIGHT_FILE="40b"
  wget --quiet $WEIGHT_URL
  unzip g170*.zip 
  mv ./g170*/*.bin.gz "./data/weights/"$WEIGHT_FILE".bin.gz" 
else
  wget --quiet $WEIGHT_URL -O "./data/weights/"$WEIGHT_FILE".bin.gz" 
fi


chmod +x ./change-config.sh
./change-config.sh $WEIGHT_FILE "./data/weights/"$WEIGHT_FILE".bin.gz"

chmod +x ./ikatago-server

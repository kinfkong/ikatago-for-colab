#!/bin/bash
echo "running env setup..."

KATAGO_BACKEND=$1
WEIGHT_FILE=$2

GPU_NAME=`nvidia-smi -q | grep "Product Name" | cut -d":" -f2 | tr -cd '[:alnum:]._-'`
echo "Using GPU: " $GPU_NAME
if [ "$KATAGO_BACKEND" == "AUTO" ]
then
  if [ "$GPU_NAME" == "TeslaT4" ]
  then
    KATAGO_BACKEND="CUDA"
  else
    KATAGO_BACKEND="OPENCL"
fi

if [ "$WEIGHT_FILE" == "AUTO" ]
then
  if [ "$GPU_NAME" == "TeslaK80" ]
  then
    WEIGHT_FILE="20b"
  elif [ "$GPU_NAME" == "TeslaP4" ]
  then
    WEIGHT_FILE="20b"
  else
    WEIGHT_FILE="40b"
fi

echo "Using GPU: " $GPU_NAME
echo "Using Katago Backend: " $KATAGO_BACKEND
echo "Using Katago Weight: " $WEIGHT_FILE

cd /content
apt install --yes libzip4 1>/dev/null
if [ ! -d work ]
then
    wget https://github.com/kinfkong/ikatago-for-colab/releases/download/1.0.0/work.zip -O work.zip
    unzip work.zip
fi

cd /content/work
WEIGHT_URL=`grep $WEIGHT_FILE ./weight_urls.txt | cut -d ' ' -f2`
echo "Using Weight URL: " $WEIGHT_URL

#download the binarires
wget --quiet https://github.com/kinfkong/katago-colab/releases/download/v1.4.5/katago-$KATAGO_BACKEND -O ./data/bins/katago
chmod +x ./data/bins/katago

mkdir -p /root/.katago/
cp -r ./opencltuning /root/.katago/

#download the weights
wget --quiet $WEIGHT_URL -O "./data/weights/"$WEIGHT_FILE".bin.gz" 

chmod +x ./change-config.sh
./change-config.sh $WEIGHT_FILE "./data/weights/"$WEIGHT_FILE".bin.gz"

chmod +x ./ikatago-server

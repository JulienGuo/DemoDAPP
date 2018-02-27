#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=mychannel

# remove previous crypto material and config transactions
rm -fr config/*
#rm -fr crypto-config/*
#
## generate crypto material
#cryptogen generate --config=./crypto-config.yaml
#if [ "$?" -ne 0 ]; then
#  echo "Failed to generate crypto material..."
#  exit 1
#fi

# generate genesis block for orderer
configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./config/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# generate channel configuration transaction
CHANNEL_NAME=channel1
configtxgen -profile TwoOrgsChannel1 -outputCreateChannelTx ./config/channel1.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate channel configuration transaction
CHANNEL_NAME=channel2
configtxgen -profile TwoOrgsChannel2 -outputCreateChannelTx ./config/channel2.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

#generate anchor peer transaction
CHANNEL_NAME=channel1
configtxgen -profile TwoOrgsChannel1 -outputAnchorPeersUpdate ./config/Org1MSPchannel1anchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Org1MSP..."
  exit 1
fi

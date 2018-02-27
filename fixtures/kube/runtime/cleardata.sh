#!/bin/sh

rm -rf orderer/orderer

rm org1/ca0/fabric-ca-server-config.yaml
rm org1/ca0/fabric-ca-server.db

rm -rf org1/peer0/chaincodes
rm -rf org1/peer0/couchdb-data/*
rm -rf org1/peer0/ledgersData
rm org1/peer0/peer.pid

rm -rf org1/peer1/chaincodes
rm -rf org1/peer1/couchdb-data/*
rm -rf org1/peer1/ledgersData
rm org1/peer1/peer.pid


rm org2/ca1/fabric-ca-server-config.yaml
rm org2/ca1/fabric-ca-server.db

rm -rf org2/peer0/chaincodes
rm -rf org2/peer0/couchdb-data/*
rm -rf org2/peer0/ledgersData
rm org2/peer0/peer.pid

rm -rf org2/peer1/chaincodes
rm -rf org2/peer1/couchdb-data/*
rm -rf org2/peer1/ledgersData
rm org2/peer1/peer.pid


rm org3/ca2/fabric-ca-server-config.yaml
rm org3/ca2/fabric-ca-server.db

rm -rf org3/peer0/chaincodes
rm -rf org3/peer0/couchdb-data/*
rm -rf org3/peer0/ledgersData
rm org3/peer0/peer.pid

rm -rf org3/peer1/chaincodes
rm -rf org3/peer1/couchdb-data/*
rm -rf org3/peer1/ledgersData
rm org3/peer1/peer.pid

rm -rf app/tmp/msp
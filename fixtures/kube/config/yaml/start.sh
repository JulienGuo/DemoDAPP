#!/bin/sh

sudo chmod -R 777 ../../runtime
sudo chmod 777 ../../../../app
sudo chmod +x ../../../../app/run.sh

kubectl create -f ca0.yaml
kubectl create -f ca1.yaml
kubectl create -f ca2.yaml

kubectl create -f orderer.yaml

kubectl create -f org1peer0.yaml
kubectl create -f org1peer1.yaml
kubectl create -f org2peer0.yaml
kubectl create -f org2peer1.yaml
kubectl create -f org3peer0.yaml
kubectl create -f org3peer1.yaml

kubectl create -f diapp.yaml

kubectl get all
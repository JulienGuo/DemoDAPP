#!/bin/sh

kubectl delete -f ca0.yaml
kubectl delete -f ca1.yaml
kubectl delete -f ca2.yaml

kubectl delete -f orderer.yaml

kubectl delete -f org1peer0.yaml
kubectl delete -f org1peer1.yaml
kubectl delete -f org2peer0.yaml
kubectl delete -f org2peer1.yaml
kubectl delete -f org3peer0.yaml
kubectl delete -f org3peer1.yaml

kubectl delete -f diapp.yaml

kubectl get all
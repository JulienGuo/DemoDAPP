#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
: ${CHANNEL_NAME:="channel1"}
: ${TIMEOUT:="60"}
: ${LANGUAGE:="golang"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "Channel name : "$CHANNEL_NAME

# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
		echo
   		exit 1
	fi
}

setGlobals () {

	if [ $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
		if [ $2 -eq 0 ]; then
		    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
		    CORE_PEER_ADDRESS=peer0.org1.example.com:7051
        else
            CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
            CORE_PEER_ADDRESS=peer1.org1.example.com:7051
        fi
    elif [ $1 -eq 2 ]; then
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
		if [ $2 -eq 0 ]; then
		    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
		    CORE_PEER_ADDRESS=peer0.org2.example.com:7051
        else
            CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt
            CORE_PEER_ADDRESS=peer1.org2.example.com:7051
        fi
    elif [ $1 -eq 3 ]; then
		CORE_PEER_LOCALMSPID="Org3MSP"
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
		if [ $2 -eq 0 ]; then
		    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
		    CORE_PEER_ADDRESS=peer0.org3.example.com:7051
        else
            CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls/ca.crt
            CORE_PEER_ADDRESS=peer1.org3.example.com:7051
        fi
	fi

	env |grep CORE
}

createChannel() {
	setGlobals 1 0

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx >&log.txt
	else
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

updateAnchorPeers() {
  setGlobals $1 0

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}${CHANNEL_NAME}anchors.tx >&log.txt
  else
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}${CHANNEL_NAME}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
  fi
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
  sleep $DELAY
  echo
}

## Sometimes Join takes time hence RETRY at least for 5 times
joinWithRetry () {
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep $DELAY
		joinWithRetry $1
	else
		COUNTER=1
	fi
  verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	if [ $1 -eq 1 ]; then
	for ch in 1 2; do
		setGlobals $ch 0
		joinWithRetry $ch
		echo "===================== Org$ch-PEER0 joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep 2
		setGlobals $ch 1
        joinWithRetry $ch
        echo "===================== Org$ch-PEER1 joined on the channel \"$CHANNEL_NAME\" ===================== "
        sleep 2
		echo
	done
	elif [ $1 -eq 2 ]; then
	for ch in 1 3; do
		setGlobals $ch 0
		joinWithRetry $ch
		echo "===================== Org$ch-PEER0 joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep 2
		setGlobals $ch 1
        joinWithRetry $ch
        echo "===================== Org$ch-PEER1 joined on the channel \"$CHANNEL_NAME\" ===================== "
        sleep 2
		echo
	done
	fi
}

#2 -n name [mycc]
installChaincode () {
	if [ $1 -eq 1 ]; then
	for ch in 1 2; do
		setGlobals $ch 0
		doInstallChaincode $1 $2
		sleep 2
		setGlobals $ch 1
		doInstallChaincode $1 $2
        sleep 2
		echo
	done
	elif [ $1 -eq 2 ]; then
	for ch in 1 3; do
		setGlobals $ch 0
		doInstallChaincode $1 $2
		sleep 2
		setGlobals $ch 1
		doInstallChaincode $1 $2
        sleep 2
		echo
	done
	fi
}

doInstallChaincode () {
	CHANNEL_ID=$1
	CHAINCODE_NAME=$2
	peer chaincode install -n $CHAINCODE_NAME -v 1.0 -p github.com/hyperledger/fabric/peer/chaincode/src/com/pingan/chaincode/channel$CHANNEL_ID >&log.txt
	res=$?
	cat log.txt
        verifyResult $res "Chaincode[$CHAINCODE_NAME] installation on remote peer $CORE_PEER_ADDRESS has Failed"
	echo "===================== Chaincode[$CHAINCODE_NAME] is installed on remote peer $CORE_PEER_ADDRESS ===================== "
	echo
}

instantiateChaincode () {
	if [ $1 -eq 1 ]; then
	for ch in 1 2; do
		setGlobals $ch 0
		doInstantiateChaincode $2 $3
		sleep 2
		echo
	done
	elif [ $1 -eq 2 ]; then
	for ch in 1 3; do
		setGlobals $ch 0
		doInstantiateChaincode $2 $3
		sleep 2
		echo
	done
	fi
}


#2 -n name [mycc]
doInstantiateChaincode () {
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n $1 -l golang -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('Org1MSP.member')"
	else
		peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n $1 -l ${LANGUAGE} -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('Org1MSP.member','Org$2MSP.member')" --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on $CORE_PEER_ADDRESS on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on $CORE_PEER_ADDRESS on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

chaincodeQuery () {
  echo "===================== Querying on Org$1-PEER0 PEER$PEER on channel '$CHANNEL_NAME'... ===================== "
  setGlobals $1 $4
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query Org$1 ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n $3 -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

chaincodeInvoke () {
	setGlobals $1 $3
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n $2 -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $2 -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

# Create channel
echo "Creating channel..."
CHANNEL_NAME="channel1"
createChannel 1
CHANNEL_NAME="channel2"
createChannel 2

## Join all the peers to the channel
echo " join the channel..."
CHANNEL_NAME="channel1"
joinChannel 1
CHANNEL_NAME="channel2"
joinChannel 2

## Set the anchor peers for each org in the channel
CHANNEL_NAME="channel1"
echo "Updating anchor peers for org1..."
updateAnchorPeers 1
echo "Updating anchor peers for org2..."
updateAnchorPeers 2
CHANNEL_NAME="channel2"
echo "Updating anchor peers for org1..."
updateAnchorPeers 1
echo "Updating anchor peers for org3..."
updateAnchorPeers 3

echo "Installing chaincode on channel1..."
installChaincode 1 "example1"
echo "Install chaincode on channel2..."
installChaincode 2 "example2"

echo "Instantiating chaincode on channel1..."
CHANNEL_NAME="channel1"
instantiateChaincode 1 "example1" 2
echo "Instantiating chaincode on channel2..."
CHANNEL_NAME="channel2"
instantiateChaincode 2 "example2" 3

echo "Querying chaincode on channel1..."
CHANNEL_NAME="channel1"
#Query on chaincode on Org1
chaincodeQuery 1 100 "example1" 0
chaincodeQuery 1 100 "example1" 1
#Query on chaincode on Org2
chaincodeQuery 2 100 "example1" 0
chaincodeQuery 2 100 "example1" 1
echo "Querying chaincode on channel2..."
CHANNEL_NAME="channel2"
#Query on chaincode on Org1
chaincodeQuery 1 100 "example2" 0
chaincodeQuery 1 100 "example2" 1
#Query on chaincode on Org3
chaincodeQuery 3 100 "example2" 0
chaincodeQuery 3 100 "example2" 1

#Invoke on chaincode
echo "Sending invoke transaction on channel1..."
CHANNEL_NAME="channel1"
chaincodeInvoke 1 "example1" 0
chaincodeInvoke 1 "example1" 1
chaincodeInvoke 2 "example1" 0
chaincodeInvoke 2 "example1" 1
echo "Sending invoke transaction on channel2..."
CHANNEL_NAME="channel2"
chaincodeInvoke 1 "example2" 0
chaincodeInvoke 1 "example2" 1
chaincodeInvoke 3 "example2" 0
chaincodeInvoke 3 "example2" 1


echo
echo "===================== All GOOD, End-2-End execution completed ===================== "
echo

echo
echo " _____   _   _   ____            _____   ____    _____ "
echo "| ____| | \ | | |  _ \          | ____| |___ \  | ____|"
echo "|  _|   |  \| | | | | |  _____  |  _|     __) | |  _|  "
echo "| |___  | |\  | | |_| | |_____| | |___   / __/  | |___ "
echo "|_____| |_| \_| |____/          |_____| |_____| |_____|"
echo

exit 0

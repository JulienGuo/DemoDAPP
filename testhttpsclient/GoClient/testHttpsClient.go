package main

import (
	"time"
	"github.com/op/go-logging"
	"io/ioutil"
	"fmt"
	"net/http"
	"crypto/x509"
	"crypto/tls"
)

var (
	logger = logging.MustGetLogger("DelayInsurance.app")
	httpsClient = &http.Client{}
)

func initHttpsClient() {
	pool := x509.NewCertPool()
	caCertPath := "ca.crt"

	caCrt, err := ioutil.ReadFile(caCertPath)
	if err != nil {
		fmt.Println("ReadFile err:", err)
		return
	}
	pool.AppendCertsFromPEM(caCrt)

	cliCrt, err := tls.LoadX509KeyPair("client.crt", "client.key")
	if err != nil {
		fmt.Println("Loadx509keypair err:", err)
		return
	}

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			RootCAs:            pool,
			InsecureSkipVerify: true,
			Certificates:       []tls.Certificate{cliCrt},
		},
	}
	httpsClient.Transport = tr
}
func main() {
	initHttpsClient()
	sendTestDelay()
	startLog()
	time.Sleep(time.Second * 9999)
}
func sendTestDelay() {
	resp, err := httpsClient.Get("https://localhost:8088/v1/channel1peerorg1/claim/adfasd")
	if err != nil {
		fmt.Println("Get error:", err)
		return
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	fmt.Println(string(body))
}

func startLog() {
	logger.Info("startLog start")
	txLogsChan = make(chan interface{}, 6000)
	bLogsChan = make(chan interface{}, 6000)

	for i := 0; i < 6000; i++ {
		go CollectTxLog(txLogsChan, "postPolicy", "success", 5566)
		go CollectBlockLog(bLogsChan, 135, 5)
	}
	go createLog(txLogsChan, true)
	go createLog(bLogsChan, false)
	go postLog(txLogsChan)
	go postLog(bLogsChan)
	logger.Info("startLog end")
}
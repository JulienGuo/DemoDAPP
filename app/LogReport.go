package main

import (
	"time"
	"net/http"
	"runtime"
	"encoding/json"
	"bytes"
	"strconv"
	"io/ioutil"
	"github.com/spf13/viper"
)

type TransactionLog struct {
	AppId      string `protobuf:"bytes,1,opt,name=appId" json:"appId"`
	ChainId    string `protobuf:"bytes,2,opt,name=chainId" json:"chainId"`
	DataType   string `protobuf:"bytes,3,opt,name=dataType" json:"dataType"`
	ChannelId  string `protobuf:"bytes,4,opt,name=channelId" json:"channelId"`
	Times      int64 `protobuf:"bytes,5,opt,name=time" json:"times"`
	Timestamp  int64 `protobuf:"bytes,6,opt,name=timestamp" json:"timestamp"`
	TranStatus string `protobuf:"bytes,7,opt,name=tranStatus" json:"tranStatus"`
	UserId     string `protobuf:"bytes,8,opt,name=userId" json:"userId"`
}

type LogResponseData struct {
	Data       interface{}
	Msg        string
	StatusCode int
}

type BlockLog struct {
	AppId       string `protobuf:"bytes,1,opt,name=appId" json:"appId"`
	BlockNumber uint64 `protobuf:"bytes,2,opt,name=blockNumber" json:"blockNumber"`
	ChainId     string `protobuf:"bytes,3,opt,name=chainId" json:"chainId"`
	DataType    string `protobuf:"bytes,4,opt,name=dataType" json:"dataType"`
	ChannelId   string `protobuf:"bytes,5,opt,name=channelId" json:"channelId"`
	Timestamp   int64 `protobuf:"bytes,6,opt,name=timestamp" json:"timestamp"`
	TranNumber  int64 `protobuf:"bytes,7,opt,name=tranNumber" json:"tranNumber"`
	UserId      string `protobuf:"bytes,8,opt,name=userId" json:"userId"`
}

var (
	txLogsChan chan interface{}
	bLogsChan chan interface{}
)


//生产者:只管在业务中写入Log，无论何时何地，缓冲区写满则等待
func CollectTxLog(ch chan interface{}, functionName string, status string, costTime int64) {
	ch <- TransactionLog{
		AppId:"myappId",
		ChainId:        viper.GetString("reportlog.network"),
		DataType:"fabric" + functionName,
		ChannelId:viper.GetString("reportlog.channelid"),
		Times:costTime,
		Timestamp:time.Now().UnixNano(),
		TranStatus:status,
		UserId:        viper.GetString("reportlog.userid"),
	}
}

func CollectBlockLog(ch chan interface{}, height uint64, number int64) {
	ch <- BlockLog{
		AppId:"myappId",
		BlockNumber:height,
		ChainId:        viper.GetString("reportlog.network"),
		DataType:"fabric",
		ChannelId:viper.GetString("reportlog.channelid"),
		Timestamp:time.Now().UnixNano(),
		TranNumber:number,
		UserId:        viper.GetString("reportlog.userid"),
	}
}

func postLog(ch chan interface{}) {
	logger.Info("postLog start")
	//消费者：
	for {
		for len(ch) > 0 {
			txlogs := make([]TransactionLog, 0)
			blogs := make([]BlockLog, 0)
			for i := 0; i < 1000&&len(ch) > 0; i++ {
				log := <-ch
				switch value := log.(type) {
				default:
				case TransactionLog:
					txlogs = append(txlogs, value)
				case BlockLog:
					blogs = append(blogs, value)

				}
			}
			if len(txlogs) > 0 {
				go postOnceTxLog(txlogs)
			}
			if len(blogs) > 0 {
				go postOnceBLog(blogs)
			}
		}

		times := 0
		logger.Info("sending log..." + strconv.Itoa(int(time.Now().UnixNano())))
		for len(ch) > 5000 || times < 15 {
			runtime.Gosched()
			times++
			time.Sleep(time.Second * 1)
		}
	}
}

func createLog(ch chan interface{}, isTxLog bool) {
	logger.Info("createLog start")
	//消费者：
	for {
		logger.Info("create log..." + strconv.Itoa(int(time.Now().UnixNano())))
		for i := 0; i < 5; i++ {
			if isTxLog {
				CollectTxLog(ch, "postPolicy", "success", 5566)
			} else {
				CollectBlockLog(ch, 135, 5)
			}

		}
		runtime.Gosched()
		time.Sleep(time.Second * 5)
	}
}

func postOnceBLog(blogs []BlockLog) {

	var resp *http.Response
	var err error
	jsonb, _ := json.Marshal(blogs)
	resp, err = http.Post("http://10.25.50.50:8099/baas/api/v1/influxdb/insertBlockData", "application/json", bytes.NewReader(jsonb))
	//resp, err = httpsClient.Post("https://localhost:8088/v1/channel1peerorg1/insertBlockData", "application/json", bytes.NewReader(jsonb))

	if err != nil {
		// 处理错误
		return
	}
	if resp.StatusCode != http.StatusOK {
		// 处理错误
		return
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	logger.Info(string(body))
}

func postOnceTxLog(txlogs []TransactionLog) {

	var resp *http.Response
	var err error
	jsont, _ := json.Marshal(txlogs)
	resp, err = http.Post("http://10.25.50.50:8099/baas/api/v1/influxdb/insertTranData", "application/json", bytes.NewReader(jsont))
	//resp, err = httpsClient.Post("https://localhost:8088/v1/channel1peerorg1/insertTranData", "application/json", bytes.NewReader(jsont))

	if err != nil {
		// 处理错误
		return
	}
	if resp.StatusCode != http.StatusOK {
		// 处理错误
		return
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	logger.Info(string(body))
}
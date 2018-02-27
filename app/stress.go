package main

import (
	"fmt"
	"github.com/spf13/cobra"
	"sync"
	"time"
	"strconv"
)

// --------------- AppCmd ---------------

// AppCmd returns the cobra command for APP
func testCmd() *cobra.Command {
	return testStartCmd
}

var (
	testStartCmd = &cobra.Command{
		Use:   "test",
		Short: "Starts to test fabric.",
		Long:  `Starts to test the network.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			return testmain(args)
		},
	}
)

func testinvoke() {
	body := `{
		"openId": "123",
		"policyInfo": {
			"policyNo":"保单号",
			"insuranceBeginDate":"保险起期",
			"insuranceEndDate":"保险止期"
		},
		"orderInfo": {
			"orderNo":"订单号",
			"productId":"云产品Id",
			"planId":"产险产品Id",
			"packageId":"套餐Id",
			"applicantName":"投保人姓名",
			"applicantPhone":"投保人电话",
			"applicantCertificateNo":"123145646"
		}
	}`

	args := []string{"postPolicy", string(body)}
	adapter := ContextMap["channel1peerorg1"]
	_, err := adapter.Invoke(args)
	//_, err := org1channel1.Invoke(chainCodeID, args)
	if err != nil {
		logger.Errorf("testinvoke Error: %s", err)
	}
}

func testquery() {
	args := []string{"getPolicy", "123"}
	adapter := ContextMap["channel1peerorg1"]
	_, err := adapter.Query(args)
	if err != nil {
		logger.Errorf("testquery Error: %s", err)
	}
}

func testmain(args []string) error {
	loops := 10

	if len(args) == 1 {
		if args[0] != "" {
			loop, err := strconv.Atoi(args[0])
			if err != nil {
				fmt.Println("loop err in args conv: ", err)
			} else {
				loops = loop
			}
		}
	}
	logger.Infof("Starting test...")
	var wg sync.WaitGroup
	wg.Add(loops)
	t1 := time.Now()
	for i := 0; i < loops; i ++ {
		fmt.Print(i)
		fmt.Print(" ")
		go func() {
			defer wg.Done()
			testinvoke()
		}()
	}
	fmt.Println()
	wg.Wait()
	elapsed := time.Since(t1)
	fmt.Println("test invoke elapsed: ", elapsed)

	wg.Add(loops)
	t1 = time.Now()
	for i := 0; i < loops; i ++ {
		fmt.Print(i)
		fmt.Print(" ")
		go func() {
			defer wg.Done()
			testquery()
		}()
	}
	fmt.Println()
	wg.Wait()
	elapsed = time.Since(t1)
	fmt.Println("test query elapsed: ", elapsed)

	return nil

}
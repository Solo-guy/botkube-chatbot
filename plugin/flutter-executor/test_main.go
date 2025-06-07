package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strings"
	"time"
)

type TestEvent struct {
	Type      string `json:"type"`
	Resource  string `json:"resource"`
	Name      string `json:"name"`
	Namespace string `json:"namespace"`
	Cluster   string `json:"cluster"`
}

type TestAIResponse struct {
	Analysis string   `json:"analysis"`
	Workflow []string `json:"workflow"`
	Error    string   `json:"error,omitempty"`
}

func TestMain() {
	// Command line flags for testing
	model := flag.String("model", "grok", "AI model to use for analysis")
	eventType := flag.String("event-type", "error", "Type of event to simulate")
	resource := flag.String("resource", "pod", "Resource type for the event")
	name := flag.String("name", "test-pod", "Name of the resource")
	namespace := flag.String("namespace", "default", "Namespace of the resource")
	cluster := flag.String("cluster", "local", "Cluster name")
	flag.Parse()

	// Create a test event
	testEvent := TestEvent{
		Type:      *eventType,
		Resource:  *resource,
		Name:      *name,
		Namespace: *namespace,
		Cluster:   *cluster,
	}

	// Convert event to JSON
	eventJSON, err := json.Marshal(testEvent)
	if err != nil {
		log.Fatalf("Không thể chuyển đổi sự kiện sang JSON: %v", err)
	}

	fmt.Printf("Đang gửi sự kiện thử nghiệm: %s\n", string(eventJSON))

	// Step 1: Send event to AI Manager for analysis
	aiResponse, err := sendToAIManager(eventJSON, *model)
	if err != nil {
		log.Fatalf("Lỗi khi gửi sự kiện đến AI Manager: %v", err)
	}

	fmt.Printf("Phản hồi từ AI (%s):\n", *model)
	fmt.Printf("Phân tích: %s\n", aiResponse.Analysis)
	if len(aiResponse.Workflow) > 0 {
		fmt.Printf("Workflow đề xuất:\n")
		for i, step := range aiResponse.Workflow {
			fmt.Printf("  %d. %s\n", i+1, step)
		}
	}
	if aiResponse.Error != "" {
		fmt.Printf("Lỗi: %s\n", aiResponse.Error)
	}

	// Step 2: If workflow contains commands, test execution via flutter-executor
	if len(aiResponse.Workflow) > 0 {
		for _, cmd := range aiResponse.Workflow {
			if strings.HasPrefix(cmd, "kubectl") {
				fmt.Printf("\nĐang thử nghiệm thực thi lệnh: %s\n", cmd)
				execResponse, err := sendCommandToExecutor(cmd)
				if err != nil {
					fmt.Printf("Lỗi khi thực thi lệnh: %v\n", err)
				} else {
					fmt.Printf("Kết quả thực thi: %s\n", execResponse)
				}
			}
		}
	}

	// Step 3: Additional test cases for AI response accuracy
	testCases := []TestEvent{
		{
			Type:      "error",
			Resource:  "deployment",
			Name:      "test-deployment",
			Namespace: "default",
			Cluster:   "local",
		},
		{
			Type:      "warning",
			Resource:  "service",
			Name:      "test-service",
			Namespace: "kube-system",
			Cluster:   "local",
		},
	}

	for i, tc := range testCases {
		fmt.Printf("\nTest case %d: %v\n", i+1, tc)
		eventJSON, err := json.Marshal(tc)
		if err != nil {
			log.Printf("Không thể chuyển đổi test case sang JSON: %v", err)
			continue
		}

		aiResponse, err := sendToAIManager(eventJSON, *model)
		if err != nil {
			log.Printf("Lỗi khi gửi test case đến AI Manager: %v", err)
			continue
		}

		fmt.Printf("Phản hồi từ AI cho test case %d:\n", i+1)
		fmt.Printf("Phân tích: %s\n", aiResponse.Analysis)
		if len(aiResponse.Workflow) > 0 {
			fmt.Printf("Workflow đề xuất:\n")
			for j, step := range aiResponse.Workflow {
				fmt.Printf("  %d. %s\n", j+1, step)
			}
		}
	}
}

func sendToAIManager(eventData []byte, model string) (TestAIResponse, error) {
	var response TestAIResponse

	// Create HTTP request to AI Manager
	req, err := http.NewRequest("POST", "http://localhost:8081/ai/analyze", bytes.NewBuffer(eventData))
	if err != nil {
		return response, fmt.Errorf("Không thể tạo yêu cầu đến AI Manager: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-AI-Model", model)
	// Add JWT token if needed
	req.Header.Set("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InVzZXIxIiwicm9sZSI6ImFkbWluIn0.8Ni1kE_9P10RogeX1nxJzTUzkXMXUmyWx0CME_VN8OM")

	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	resp, err := client.Do(req)
	if err != nil {
		return response, fmt.Errorf("Không thể gửi yêu cầu đến AI Manager: %v", err)
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return response, fmt.Errorf("Không thể đọc phản hồi từ AI Manager: %v", err)
	}

	if resp.StatusCode != 200 {
		return response, fmt.Errorf("AI Manager trả về lỗi %d: %s", resp.StatusCode, string(body))
	}

	err = json.Unmarshal(body, &response)
	if err != nil {
		return response, fmt.Errorf("Không thể parse phản hồi JSON từ AI Manager: %v", err)
	}

	return response, nil
}

func sendCommandToExecutor(command string) (string, error) {
	cmdData := map[string]string{
		"command": command,
	}
	cmdJSON, err := json.Marshal(cmdData)
	if err != nil {
		return "", fmt.Errorf("Không thể chuyển đổi lệnh sang JSON: %v", err)
	}

	req, err := http.NewRequest("POST", "http://localhost:8080/execute", bytes.NewBuffer(cmdJSON))
	if err != nil {
		return "", fmt.Errorf("Không thể tạo yêu cầu đến Executor: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	// Add JWT token if needed
	req.Header.Set("Authorization", "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InVzZXIxIiwicm9sZSI6ImFkbWluIn0.8Ni1kE_9P10RogeX1nxJzTUzkXMXUmyWx0CME_VN8OM")

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("Không thể gửi yêu cầu đến Executor: %v", err)
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("Không thể đọc phản hồi từ Executor: %v", err)
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("Executor trả về lỗi %d: %s", resp.StatusCode, string(body))
	}

	var execResponse map[string]string
	err = json.Unmarshal(body, &execResponse)
	if err != nil {
		return string(body), nil
	}

	return execResponse["output"], nil
}

package main

import (
	"fmt"
	"log"
	"time"
)

// TestAIService dùng để kiểm tra và xác minh hoạt động của AI Manager
func TestAIService() {
	fmt.Println("Bắt đầu kiểm thử AI Service...")

	// Khởi tạo AI Manager
	aiManager, err := NewAIManager()
	if err != nil {
		log.Fatalf("Không thể khởi tạo AI Manager: %v", err)
	}
	defer aiManager.Close()

	// Kiểm tra kết nối đến cơ sở dữ liệu
	err = aiManager.db.Ping()
	if err != nil {
		fmt.Printf("Kiểm tra kết nối DB thất bại: %v\n", err)
	} else {
		fmt.Println("Kết nối DB thành công!")
	}

	// Tạo sự kiện thử nghiệm
	testEvent := Event{
		Type:      "TEST",
		Resource:  "pod",
		Name:      "test-pod",
		Namespace: "default",
		Cluster:   "local",
	}

	// Thử lưu sự kiện vào DB
	err = aiManager.saveEventToDB(testEvent)
	if err != nil {
		fmt.Printf("Lưu sự kiện vào DB thất bại: %v\n", err)
	} else {
		fmt.Println("Lưu sự kiện vào DB thành công!")
	}

	// Kiểm tra khởi tạo mô hình AI
	fmt.Println("Khởi tạo mô hình AI...")

	aiModel, err := GetAIModel(aiManager.config)
	if err != nil {
		fmt.Printf("Khởi tạo AI thất bại: %v\n", err)
	} else {
		fmt.Println("Khởi tạo AI thành công!")

		// Thử phân tích sự kiện
		fmt.Println("Thử phân tích sự kiện...")
		startTime := time.Now()

		response, err := aiModel.Analyze(testEvent)
		if err != nil {
			fmt.Printf("Phân tích sự kiện thất bại: %v\n", err)
		} else {
			duration := time.Since(startTime)
			fmt.Printf("Phân tích sự kiện thành công! (Thời gian: %v)\n", duration)
			fmt.Printf("Phân tích: %s\n", response.Analysis)

			if len(response.Workflow) > 0 {
				fmt.Println("Quy trình đề xuất:")
				for i, step := range response.Workflow {
					fmt.Printf("  %d. %s\n", i+1, step)
				}
			}
		}
	}

	fmt.Println("Kiểm thử AI Service hoàn thành!")
}

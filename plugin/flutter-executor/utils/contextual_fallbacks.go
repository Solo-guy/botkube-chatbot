package utils

import (
	"fmt"
	"strings"
	"time"
)

// GenerateContextualFallback creates a context-appropriate fallback response based on the message content
func GenerateContextualFallback(message string) map[string]interface{} {
	lowerMsg := strings.ToLower(message)

	// For spiritual/supernatural topics
	if strings.Contains(lowerMsg, "ma") ||
		strings.Contains(lowerMsg, "quỷ") ||
		strings.Contains(lowerMsg, "tâm linh") ||
		strings.Contains(lowerMsg, "thần thánh") {

		return map[string]interface{}{
			"response": "Câu hỏi của bạn liên quan đến chủ đề tâm linh hoặc siêu nhiên. Đây là một chủ đề mà nhiều nền văn hóa và tín ngưỡng có quan điểm khác nhau. Tôi có thể cung cấp thông tin về niềm tin văn hóa, góc nhìn lịch sử, hoặc cách tiếp cận từ góc độ khoa học khi dịch vụ hoạt động trở lại.",
			"workflow": []interface{}{
				"Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
				"Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
				"Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần.",
			},
		}
	}

	// For weather-related queries
	if strings.Contains(lowerMsg, "thời tiết") ||
		strings.Contains(lowerMsg, "nhiệt độ") ||
		strings.Contains(lowerMsg, "mưa") {

		return map[string]interface{}{
			"response": "Để có thông tin thời tiết chính xác nhất, bạn nên tham khảo các dịch vụ dự báo thời tiết chuyên nghiệp. Tôi có thể giải thích các hiện tượng thời tiết, nhưng không cung cấp được dự báo thời tiết theo thời gian thực khi dịch vụ hoạt động trở lại.",
			"workflow": []interface{}{
				"Kiểm tra dự báo thời tiết từ các nguồn đáng tin cậy.",
				"Theo dõi các cập nhật thời tiết theo thời gian thực.",
				"Lập kế hoạch dựa trên các xu hướng thời tiết đã dự báo.",
			},
		}
	}

	// For time-related queries
	if strings.Contains(lowerMsg, "thời gian") ||
		strings.Contains(lowerMsg, "ngày") ||
		strings.Contains(lowerMsg, "giờ") ||
		strings.Contains(lowerMsg, "hôm nay") {

		now := time.Now()
		vietnameseDate := fmt.Sprintf("%d/%d/%d", now.Day(), now.Month(), now.Year())

		return map[string]interface{}{
			"response": fmt.Sprintf("Hôm nay là ngày %s. Tôi sẽ cung cấp thông tin chi tiết hơn khi dịch vụ AI hoạt động trở lại.", vietnameseDate),
			"workflow": []interface{}{
				"Kiểm tra thời gian từ thiết bị của bạn hoặc dịch vụ thời gian trực tuyến.",
				"Đồng bộ hóa thiết bị của bạn với máy chủ thời gian chính xác.",
				"Cài đặt thông báo cho các sự kiện quan trọng.",
			},
		}
	}

	// Default fallback
	return map[string]interface{}{
		"response": "Xin lỗi, tôi không thể xử lý câu hỏi của bạn ngay bây giờ. Dịch vụ AI có thể đang tạm thời không khả dụng. Vui lòng thử lại sau.",
		"workflow": []interface{}{
			"Kiểm tra kết nối mạng của bạn.",
			"Đảm bảo dịch vụ AI Manager đang chạy.",
			"Thử lại sau một vài phút.",
		},
	}
}

// GetImprovedWorkflow provides a better workflow for common query types
// when the default Kubernetes workflows are not appropriate
func GetImprovedWorkflow(message string, isDefaultK8sWorkflow bool) []interface{} {
	if !isDefaultK8sWorkflow {
		return nil // Return nil if the workflow is already good
	}

	lowerMsg := strings.ToLower(message)

	// Time-related queries
	if strings.Contains(lowerMsg, "ngày") ||
		strings.Contains(lowerMsg, "thời gian") ||
		strings.Contains(lowerMsg, "hôm nay") {
		return []interface{}{
			"Kiểm tra thời gian từ thiết bị của bạn hoặc dịch vụ thời gian trực tuyến.",
			"Đồng bộ hóa thiết bị của bạn với máy chủ thời gian chính xác.",
			"Cài đặt thông báo cho các sự kiện quan trọng.",
		}
	}

	// Spiritual topics
	if strings.Contains(lowerMsg, "ma") ||
		strings.Contains(lowerMsg, "quỷ") ||
		strings.Contains(lowerMsg, "tâm linh") {
		return []interface{}{
			"Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
			"Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
			"Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần.",
		}
	}

	// Default generic workflow for other topics
	return []interface{}{
		"Tìm kiếm thêm thông tin về chủ đề này trên internet.",
		"Tham khảo ý kiến của chuyên gia nếu cần thiết.",
		"Ghi chú lại thông tin hữu ích để tham khảo sau.",
	}
}

// IsDefaultKubernetesWorkflow checks if a workflow is the default one for Kubernetes
func IsDefaultKubernetesWorkflow(workflow []interface{}) bool {
	if len(workflow) != 3 {
		return false
	}

	workflowStr := fmt.Sprintf("%v", workflow)
	return strings.Contains(strings.ToLower(workflowStr), "log pod") &&
		strings.Contains(strings.ToLower(workflowStr), "tài nguyên") &&
		strings.Contains(strings.ToLower(workflowStr), "lịch sử")
}

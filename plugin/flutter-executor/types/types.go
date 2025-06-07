package types

import "time"

// FlutterCommandRequest định nghĩa cấu trúc cho yêu cầu lệnh
type FlutterCommandRequest struct {
	Command string `json:"command"`
}

// FlutterCommandResponse định nghĩa cấu trúc cho phản hồi lệnh
type FlutterCommandResponse struct {
	Output string `json:"output"`
	Error  string `json:"error,omitempty"`
}

// FlutterEvent định nghĩa cấu trúc cho sự kiện
type FlutterEvent struct {
	Type      string `json:"type"`
	Resource  string `json:"resource"`
	Name      string `json:"name"`
	Namespace string `json:"namespace"`
	Cluster   string `json:"cluster"`
}

// AIResponse định nghĩa cấu trúc cho phản hồi AI
type AIResponse struct {
	Analysis string   `json:"analysis"`
	Workflow []string `json:"workflow"`
	Error    string   `json:"error,omitempty"`
}

// HistoryEntry định nghĩa cấu trúc cho một mục lịch sử chat
type HistoryEntry struct {
	ID        int       `json:"id"`
	UserID    string    `json:"user_id"`
	Message   string    `json:"message"`
	Response  string    `json:"response"`
	Timestamp time.Time `json:"timestamp"`
	Cost      float64   `json:"cost"`
}

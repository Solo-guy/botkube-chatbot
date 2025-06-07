package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/kubeshop/botkube/pkg/api"
	"github.com/kubeshop/botkube/pkg/api/source"
	_ "github.com/lib/pq"
	"gopkg.in/yaml.v2"
)

type Event struct {
	Type      string `json:"type"`
	Resource  string `json:"resource"`
	Name      string `json:"name"`
	Namespace string `json:"namespace"`
	Cluster   string `json:"cluster"`
}

type AIResponse struct {
	Analysis string   `json:"analysis"`
	Workflow []string `json:"workflow"`
	Error    string   `json:"error,omitempty"`
}

var Metadata = api.MetadataOutput{
	Version:     "0.1.0",
	Description: "Plugin AI để phân tích sự kiện Botkube và hỗ trợ nhập liệu",
}

type Config struct {
	JWTToken      string `yaml:"jwtToken"`
	DBHost        string `yaml:"dbHost"`
	DBPort        int    `yaml:"dbPort"`
	DBUser        string `yaml:"dbUser"`
	DBPassword    string `yaml:"dbPassword"`
	DBName        string `yaml:"dbName"`
	SelectedModel string `yaml:"selectedModel"`
	APIKey        string `yaml:"apiKey"`
	Endpoint      string `yaml:"endpoint"`
}

func loadConfig() (*Config, error) {
	configData, err := os.ReadFile("config.yaml")
	if err != nil {
		return nil, fmt.Errorf("Không thể đọc file config.yaml: %v", err)
	}

	var rawConfig map[string]interface{}
	err = yaml.Unmarshal(configData, &rawConfig)
	if err != nil {
		return nil, fmt.Errorf("Không thể phân tích file config.yaml: %v", err)
	}

	cockroachConfig, ok := rawConfig["cockroach"].(map[interface{}]interface{})
	if !ok {
		return nil, fmt.Errorf("Không thể đọc cấu hình CockroachDB từ config.yaml")
	}

	host, _ := cockroachConfig["host"].(string)
	port, _ := cockroachConfig["port"].(int)
	user, _ := cockroachConfig["user"].(string)
	password, _ := cockroachConfig["password"].(string)
	database, _ := cockroachConfig["database"].(string)

	config := &Config{
		DBHost:     host,
		DBPort:     port,
		DBUser:     user,
		DBPassword: password,
		DBName:     database,
	}

	if aiConfig, ok := rawConfig["ai"].(map[interface{}]interface{}); ok {
		if selectedModel, ok := aiConfig["selectedModel"].(string); ok {
			config.SelectedModel = selectedModel

			// Extract the API key for the selected model
			if modelConfig, ok := aiConfig[selectedModel].(map[interface{}]interface{}); ok {
				if apiKey, ok := modelConfig["apiKey"].(string); ok {
					config.APIKey = apiKey
					log.Printf("Đã tải API key cho model %s", selectedModel)
				}
			}
		}

		if minipcmConfig, ok := aiConfig["minipcm"].(map[interface{}]interface{}); ok {
			if endpoint, ok := minipcmConfig["endpoint"].(string); ok {
				config.Endpoint = endpoint
			}
		}
	}

	if jwtConfig, ok := rawConfig["jwt"].(map[interface{}]interface{}); ok {
		if token, ok := jwtConfig["token"].(string); ok {
			config.JWTToken = token
		}
	}

	// Log extracted configuration
	log.Printf("Đã tải cấu hình: Model %s, Database: %s, JWT Token loaded: %v",
		config.SelectedModel,
		config.DBName,
		config.JWTToken != "")

	if config.APIKey != "" {
		// Mask the API key for logging (show first 4 and last 4 chars)
		apiKeyLen := len(config.APIKey)
		maskedKey := ""
		if apiKeyLen <= 8 {
			maskedKey = "****"
		} else {
			maskedKey = config.APIKey[:4] + "..." + config.APIKey[apiKeyLen-4:]
		}
		log.Printf("API key cho model %s đã được tải: %s", config.SelectedModel, maskedKey)
	} else {
		log.Printf("CẢNH BÁO: Không tìm thấy API key cho model %s", config.SelectedModel)
	}

	return config, nil
}

type AIManager struct {
	client *http.Client
	db     *sql.DB
	config *Config
}

func NewAIManager() (*AIManager, error) {
	config, err := loadConfig()
	if err != nil {
		return nil, fmt.Errorf("Không thể tải cấu hình: %v", err)
	}

	db, err := sql.Open("postgres", fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", config.DBHost, config.DBPort, config.DBUser, config.DBPassword, config.DBName))
	if err != nil {
		return nil, fmt.Errorf("Không thể kết nối tới cơ sở dữ liệu CockroachDB: %v", err)
	}

	err = db.Ping()
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("Không thể kiểm tra kết nối cơ sở dữ liệu: %v", err)
	}

	log.Println("Kết nối thành công tới CockroachDB")
	return &AIManager{
		client: &http.Client{
			Timeout: time.Second * 90,
		},
		db:     db,
		config: config,
	}, nil
}

func (e *AIManager) HandleEvent(ctx source.SourceContext, event []byte) error {
	var evt Event
	if err := json.Unmarshal(event, &evt); err != nil {
		return fmt.Errorf("Không thể phân tích sự kiện: %v", err)
	}

	// Gửi sự kiện tới plugin REST API của flutter-executor cục bộ
	req, err := http.NewRequest("POST", "http://localhost:8080/events", bytes.NewBuffer(event))
	if err != nil {
		return fmt.Errorf("Không thể tạo yêu cầu: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", e.config.JWTToken))

	resp, err := e.client.Do(req)
	if err != nil {
		return fmt.Errorf("Không thể gửi sự kiện tới flutter-executor: %v", err)
	}
	defer resp.Body.Close()

	// Lưu sự kiện vào cơ sở dữ liệu
	err = e.saveEventToDB(evt)
	if err != nil {
		log.Printf("Không thể lưu sự kiện vào cơ sở dữ liệu: %v", err)
	}

	// Phân tích sự kiện bằng AI
	aiModel, err := GetAIModel(e.config)
	if err != nil {
		log.Printf("Không thể lấy mô hình AI: %v", err)
		return fmt.Errorf("Không thể lấy mô hình AI: %v", err)
	}

	aiResponse, err := aiModel.Analyze(evt)
	if err != nil {
		log.Printf("Không thể phân tích sự kiện bằng AI: %v", err)
		return fmt.Errorf("Không thể phân tích sự kiện bằng AI: %v", err)
	}

	// Lưu phản hồi AI vào cơ sở dữ liệu
	err = e.saveAIResponseToDB(evt, aiResponse)
	if err != nil {
		log.Printf("Không thể lưu phản hồi AI vào cơ sở dữ liệu: %v", err)
	}

	log.Printf("Gửi sự kiện thành công: %+v", evt)
	log.Printf("Phản hồi AI: %s", aiResponse.Analysis)
	return nil
}

func (e *AIManager) saveEventToDB(evt Event) error {
	query := `INSERT INTO chat_history (event_type, resource, name, namespace, cluster, timestamp) VALUES ($1, $2, $3, $4, $5, NOW())`
	_, err := e.db.Exec(query, evt.Type, evt.Resource, evt.Name, evt.Namespace, evt.Cluster)
	if err != nil {
		return fmt.Errorf("Lỗi khi lưu sự kiện vào cơ sở dữ liệu: %v", err)
	}
	log.Println("Đã lưu sự kiện vào cơ sở dữ liệu")
	return nil
}

func (e *AIManager) saveAIResponseToDB(evt Event, response AIResponse) error {
	// Convert event information to a more generic format
	eventSummary := fmt.Sprintf("Event Type: %s, Resource: %s, Name: %s, Namespace: %s, Cluster: %s",
		evt.Type, evt.Resource, evt.Name, evt.Namespace, evt.Cluster)

	// Convert workflow to JSON
	workflowJSON, err := json.Marshal(response.Workflow)
	if err != nil {
		return fmt.Errorf("Lỗi khi chuyển đổi workflow sang JSON: %v", err)
	}

	// Use a transaction to ensure atomicity
	tx, err := e.db.Begin()
	if err != nil {
		return fmt.Errorf("Lỗi khi bắt đầu transaction: %v", err)
	}

	// Check if appropriate columns exist
	var hasWorkflow, hasEventTypeColumn, hasNameColumn, hasNamespaceColumn, hasClusterColumn bool

	// Check for workflow column
	err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_history' AND column_name = 'workflow')").Scan(&hasWorkflow)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("Lỗi khi kiểm tra tồn tại cột workflow: %v", err)
	}

	// Check for other event columns
	err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_history' AND column_name = 'event_type')").Scan(&hasEventTypeColumn)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("Lỗi khi kiểm tra tồn tại cột event_type: %v", err)
	}

	err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_history' AND column_name = 'name')").Scan(&hasNameColumn)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("Lỗi khi kiểm tra tồn tại cột name: %v", err)
	}

	err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_history' AND column_name = 'namespace')").Scan(&hasNamespaceColumn)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("Lỗi khi kiểm tra tồn tại cột namespace: %v", err)
	}

	err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_history' AND column_name = 'cluster')").Scan(&hasClusterColumn)
	if err != nil {
		tx.Rollback()
		return fmt.Errorf("Lỗi khi kiểm tra tồn tại cột cluster: %v", err)
	}

	// Choose query based on which columns exist
	var insertQuery string
	var args []interface{}

	if hasWorkflow && hasEventTypeColumn && hasNameColumn && hasNamespaceColumn && hasClusterColumn {
		// All columns exist - use full insert
		log.Println("Tất cả các cột tồn tại, sử dụng cấu trúc bảng đầy đủ")

		insertQuery = `
			INSERT INTO chat_history (
				user_id, 
				message, 
				response, 
				timestamp, 
				cost,
				event_type,
				resource,
				name,
				namespace,
				cluster,
				workflow
			) VALUES (
				'ai-system', 
				$1, 
				$2, 
				NOW(), 
				0.0,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8
			)
		`
		args = []interface{}{
			eventSummary,
			response.Analysis,
			evt.Type,
			evt.Resource,
			evt.Name,
			evt.Namespace,
			evt.Cluster,
			string(workflowJSON),
		}
	} else if hasWorkflow && hasEventTypeColumn {
		// Has workflow and event_type but not name/namespace/cluster
		log.Println("Có cột workflow và event_type nhưng thiếu các cột name/namespace/cluster")

		insertQuery = `
			INSERT INTO chat_history (
				user_id, 
				message, 
				response, 
				timestamp, 
				cost,
				event_type,
				resource,
				workflow
			) VALUES (
				'ai-system', 
				$1, 
				$2, 
				NOW(), 
				0.0,
				$3,
				$4,
				$5
			)
		`
		args = []interface{}{
			eventSummary,
			response.Analysis,
			evt.Type,
			evt.Resource,
			string(workflowJSON),
		}
	} else if hasWorkflow {
		// Has workflow but not event columns
		log.Println("Chỉ có cột workflow, không có các cột sự kiện")

		insertQuery = `
			INSERT INTO chat_history (
				user_id, 
				message, 
				response, 
				timestamp, 
				cost,
				workflow
			) VALUES (
				'ai-system', 
				$1, 
				$2, 
				NOW(), 
				0.0,
				$3
			)
		`
		args = []interface{}{
			eventSummary,
			response.Analysis,
			string(workflowJSON),
		}
	} else {
		// Basic structure - just store message/response
		log.Println("Sử dụng cấu trúc bảng cơ bản")

		insertQuery = `
			INSERT INTO chat_history (
				user_id, 
				message, 
				response, 
				timestamp, 
				cost
			) VALUES (
				'ai-system', 
				$1, 
				$2, 
				NOW(), 
				0.0
			)
		`
		args = []interface{}{
			eventSummary,
			response.Analysis,
		}
	}

	// Execute the query with the appropriate arguments
	_, err = tx.Exec(insertQuery, args...)

	if err != nil {
		tx.Rollback()
		return fmt.Errorf("Lỗi khi lưu phản hồi AI vào cơ sở dữ liệu: %v", err)
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("Lỗi khi commit transaction: %v", err)
	}

	log.Println("Đã lưu phản hồi AI vào cơ sở dữ liệu")
	return nil
}

func (e *AIManager) Close() {
	if e.db != nil {
		e.db.Close()
		log.Println("Đã đóng kết nối cơ sở dữ liệu")
	}
}

// Helper function to get model from request or return default
func getModelFromRequest(requestModel string) string {
	if requestModel == "" {
		return "grok" // Default model
	}

	// Validate the model is one we support
	supportedModels := map[string]bool{
		"grok":    true,
		"gemini":  true,
		"claude":  true,
		"llama":   true,
		"mistral": true,
		"cohere":  true,
		"openai":  true,
		"a2":      true,
		"minipcm": true,
	}

	if supportedModels[requestModel] {
		return requestModel
	}

	return "grok" // Fallback to default
}

// AnalyzeEvent processes a Kubernetes event and returns an AI response
func (m *AIManager) AnalyzeEvent(event Event) (AIResponse, error) {
	// Placeholder for actual AI analysis logic
	log.Printf("Analyzing event: %+v", event)
	return AIResponse{
		Analysis: fmt.Sprintf("Phân tích sự kiện: %s", event.Name),
		Workflow: []string{
			"Bước 1: Kiểm tra trạng thái",
			"Bước 2: Xem log",
			"Bước 3: Khởi động lại nếu cần",
		},
	}, nil
}

// ProcessNaturalLanguage handles natural language queries and returns a response
func (m *AIManager) ProcessNaturalLanguage(query string, model string) (struct {
	Response string
	Workflow []string
}, error) {
	log.Printf("Processing natural language query: %s with model: %s", query, model)

	// Create a generic AI response struct to hold the result
	response := struct {
		Response string
		Workflow []string
	}{
		Response: "I'm sorry, I couldn't process your query at this time.",
		Workflow: []string{},
	}

	// Check if the query is empty or too short
	if len(strings.TrimSpace(query)) < 2 {
		response.Response = "Xin lỗi, câu hỏi của bạn quá ngắn. Vui lòng cung cấp thêm thông tin."
		return response, nil
	}

	// Create an event-like structure to reuse the AI model's analysis capability
	event := Event{
		Type:      "user_query",
		Resource:  "chat",
		Name:      query,
		Namespace: "",
		Cluster:   "",
	}

	// Get an AI model instance
	aiModel, err := GetAIModel(m.config)
	if err != nil {
		log.Printf("Error getting AI model: %v", err)
		response.Response = fmt.Sprintf("Lỗi khi khởi tạo mô hình AI: %v. Vui lòng kiểm tra cấu hình API key.", err)
		response.Workflow = []string{
			"Kiểm tra cấu hình API key trong file config.yaml",
			"Đảm bảo dịch vụ AI đang hoạt động",
			"Kiểm tra log để tìm lỗi",
		}
		return response, nil // Return response with error message but don't propagate error
	}

	// Analyze the query using the AI model with timeout handling
	aiResponseChan := make(chan AIResponse, 1)
	errChan := make(chan error, 1)

	go func() {
		aiResponse, err := aiModel.Analyze(event)
		if err != nil {
			errChan <- err
			return
		}
		aiResponseChan <- aiResponse
	}()

	// Wait for either result or timeout
	select {
	case aiResponse := <-aiResponseChan:
		// Check if response is empty
		if aiResponse.Analysis == "" || strings.TrimSpace(aiResponse.Analysis) == "" {
			log.Printf("AI model returned empty analysis")
			response.Response = "Xin lỗi, AI không trả về phản hồi cụ thể. Hãy thử lại với một câu hỏi khác."
			response.Workflow = []string{
				"Đặt câu hỏi cụ thể hơn",
				"Cung cấp thêm ngữ cảnh cho câu hỏi",
				"Thử lại sau vài phút",
			}
			return response, nil
		}

		// Convert the AI response to our return format
		response.Response = aiResponse.Analysis
		response.Workflow = aiResponse.Workflow

		// Log the response for debugging
		log.Printf("Response from %s API: %s", model, truncateString(response.Response, 100))
		if len(response.Workflow) > 0 {
			log.Printf("Workflow proposed from %s: %v", model, response.Workflow)
		}

		return response, nil

	case err := <-errChan:
		log.Printf("Error analyzing query: %v", err)

		// Provide a more helpful error message based on error type
		errorMsg := fmt.Sprintf("Lỗi khi phân tích truy vấn: %v.", err)

		// Create specific messages for common error types
		if strings.Contains(strings.ToLower(err.Error()), "api key") {
			errorMsg = "Lỗi xác thực API key. Vui lòng kiểm tra lại cấu hình API key trong file config.yaml."
		} else if strings.Contains(strings.ToLower(err.Error()), "timeout") ||
			strings.Contains(strings.ToLower(err.Error()), "deadline") {
			errorMsg = "Máy chủ AI mất quá nhiều thời gian để phản hồi. Vui lòng thử lại sau."
		} else if strings.Contains(strings.ToLower(err.Error()), "connection") ||
			strings.Contains(strings.ToLower(err.Error()), "network") {
			errorMsg = "Lỗi kết nối đến máy chủ AI. Vui lòng kiểm tra kết nối mạng và thử lại."
		}

		response.Response = errorMsg
		response.Workflow = []string{
			"Thử đặt câu hỏi theo cách khác",
			"Kiểm tra kết nối mạng",
			"Kiểm tra trạng thái của API AI",
		}
		return response, nil

	case <-time.After(30 * time.Second):
		log.Printf("Timeout while processing query with model %s", model)
		response.Response = "Quá thời gian xử lý câu hỏi. Máy chủ AI có thể đang bận. Vui lòng thử lại sau."
		response.Workflow = []string{
			"Thử lại sau một vài phút",
			"Sử dụng một mô hình AI khác",
			"Đặt câu hỏi ngắn gọn hơn",
		}
		return response, nil
	}
}

func AIHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request struct {
		Type      string `json:"type"`
		Resource  string `json:"resource"`
		Name      string `json:"name"`
		Namespace string `json:"namespace"`
		Cluster   string `json:"cluster"`
		Model     string `json:"model"`
	}

	// Parse request body
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		log.Printf("Error parsing AI request: %v", err)
		json.NewEncoder(w).Encode(map[string]string{
			"error": fmt.Sprintf("Invalid request format: %v", err),
		})
		return
	}

	// Get or fallback to default model
	model := getModelFromRequest(request.Model)
	log.Printf("Processing AI analysis with model: %s", model)

	// Get the AI manager instance from context
	ctx := r.Context()
	aiManager, ok := ctx.Value("aiManager").(*AIManager)
	if !ok || aiManager == nil {
		log.Printf("AI Manager not found in context")
		json.NewEncoder(w).Encode(map[string]string{
			"error": "AI Manager not available",
		})
		return
	}

	event := Event{
		Type:      request.Type,
		Resource:  request.Resource,
		Name:      request.Name,
		Namespace: request.Namespace,
		Cluster:   request.Cluster,
	}

	log.Printf("Nhận yêu cầu phân tích AI cho sự kiện: %+v", event)

	// Analyze the event
	response, err := aiManager.AnalyzeEvent(event)
	if err != nil {
		log.Printf("Error analyzing event: %v", err)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error":    fmt.Sprintf("Analysis failed: %v", err),
			"analysis": "",
			"workflow": []string{},
		})
		return
	}

	log.Printf("Đã trả về phản hồi AI cho sự kiện: %+v", event)

	// Return the response
	json.NewEncoder(w).Encode(map[string]interface{}{
		"analysis": response.Analysis,
		"workflow": response.Workflow,
	})
}

// ChatHandler handles natural language queries without Kubernetes context
func ChatHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Read the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		log.Printf("Error reading chat request body: %v", err)
		json.NewEncoder(w).Encode(map[string]string{
			"error": fmt.Sprintf("Cannot read request: %v", err),
		})
		return
	}

	// Parse the request to get the message and model
	var request struct {
		Message string `json:"message"`
		Query   string `json:"query"` // Support both 'message' and 'query' fields
		Model   string `json:"model"`
	}

	if err := json.Unmarshal(body, &request); err != nil {
		log.Printf("Error parsing chat request: %v", err)
		json.NewEncoder(w).Encode(map[string]string{
			"error": fmt.Sprintf("Invalid request format: %v", err),
		})
		return
	}

	// Use message field or query field if message is empty
	message := request.Message
	if message == "" {
		message = request.Query
	}

	if message == "" {
		log.Printf("Error: Empty message in chat request")
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Message cannot be empty",
		})
		return
	}

	// Get or fallback to default model
	model := getModelFromRequest(request.Model)
	log.Printf("Processing natural language query: %s with model: %s", message, model)

	// Get the AI manager instance from context
	ctx := r.Context()
	aiManager, ok := ctx.Value("aiManager").(*AIManager)
	if !ok || aiManager == nil {
		// For backward compatibility or if AI manager is not in context, create one
		var err error
		aiManager, err = NewAIManager()
		if err != nil {
			log.Printf("Error creating AI Manager: %v", err)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "AI Manager not available",
			})
			return
		}
		defer aiManager.Close()
	}

	// Process the natural language query
	response, err := aiManager.ProcessNaturalLanguage(message, model)
	if err != nil {
		log.Printf("Error processing natural language query: %v", err)
		json.NewEncoder(w).Encode(map[string]string{
			"error": fmt.Sprintf("Processing failed: %v", err),
		})
		return
	}

	// Return the response with workflow
	json.NewEncoder(w).Encode(map[string]interface{}{
		"response": response.Response,
		"workflow": response.Workflow,
	})
}

func main() {
	log.Println("Starting AI Manager...")

	aiManager, err := NewAIManager()
	if err != nil {
		log.Fatalf("Không thể khởi tạo AI Manager: %v", err)
	}
	defer aiManager.Close()

	router := mux.NewRouter()

	// Attach AIManager to the request context for all handlers
	router.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := context.WithValue(r.Context(), "aiManager", aiManager)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	})

	router.HandleFunc("/ai/analyze", AIHandler).Methods("POST")
	router.HandleFunc("/chat", ChatHandler).Methods("POST")

	log.Println("Khởi động server AI trên :8081")
	if err := http.ListenAndServe(":8081", router); err != nil {
		log.Fatalf("Server thất bại: %v", err)
	}
}

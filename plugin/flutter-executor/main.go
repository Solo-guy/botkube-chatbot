package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"database/sql"

	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/kubeshop/botkube/pkg/api"
	"github.com/kubeshop/botkube/pkg/api/executor"
	_ "github.com/lib/pq"
	"github.com/rs/cors"
	"gopkg.in/yaml.v2"

	"github.com/lansingaudio/fluter-botkube/plugin/flutter-executor/types"
	"github.com/lansingaudio/fluter-botkube/plugin/flutter-executor/utils"
)

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
	UserID    string    `json:"user_id"`
	Message   string    `json:"message"`
	Response  string    `json:"response"`
	Timestamp time.Time `json:"timestamp"`
	Cost      float64   `json:"cost"`
}

// Metadata cho plugin Flutter Executor
var Metadata = api.MetadataOutput{
	Version:     "0.1.0",
	Description: "Plugin để kết nối Flutter với Botkube qua REST API",
}

type ExecutorConfig struct {
	Port        int    `yaml:"serverPort"`
	DBHost      string `yaml:"host"`
	DBPort      int    `yaml:"port"`
	DBUser      string `yaml:"user"`
	DBPassword  string `yaml:"password"`
	DBName      string `yaml:"dbname"`
	JWTSecret   string `yaml:"jwtSecret"`
	AutoExecute bool   `yaml:"autoExecute"`
}

func loadExecutorConfig() (*ExecutorConfig, error) {
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

	config := &ExecutorConfig{
		DBHost:     host,
		DBPort:     port,
		DBUser:     user,
		DBPassword: password,
		DBName:     database,
	}

	if jwtConfig, ok := rawConfig["jwt"].(map[interface{}]interface{}); ok {
		if secret, ok := jwtConfig["secret"].(string); ok {
			config.JWTSecret = secret
		}
	}

	if serverConfig, ok := rawConfig["server"].(map[interface{}]interface{}); ok {
		if serverPort, ok := serverConfig["port"].(int); ok {
			config.Port = serverPort
		}
	}

	if autoExecute, ok := rawConfig["autoExecute"].(bool); ok {
		config.AutoExecute = autoExecute
	}

	return config, nil
}

type FlutterExecutor struct {
	db *sql.DB
}

func NewFlutterExecutor() (*FlutterExecutor, error) {
	config, err := loadExecutorConfig()
	if err != nil {
		return nil, fmt.Errorf("Không thể tải cấu hình: %v", err)
	}

	db, err := sql.Open("postgres", fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", config.DBHost, config.DBPort, config.DBUser, config.DBPassword, config.DBName))
	if err != nil {
		return nil, fmt.Errorf("Không thể kết nối tới CockroachDB: %v", err)
	}

	err = db.Ping()
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("Không thể kiểm tra kết nối CockroachDB: %v", err)
	}

	log.Println("Kết nối thành công tới CockroachDB")
	return &FlutterExecutor{db: db}, nil
}

func (e *FlutterExecutor) Close() {
	if e.db != nil {
		e.db.Close()
		log.Println("Đã đóng kết nối CockroachDB")
	}
}

func (e *FlutterExecutor) Execute(ctx executor.ExecuteInput) (executor.ExecuteOutput, error) {
	var req types.FlutterCommandRequest
	if err := json.Unmarshal([]byte(ctx.Command), &req); err != nil {
		return executor.ExecuteOutput{}, fmt.Errorf("Định dạng lệnh không hợp lệ: %v", err)
	}

	// Parse command to determine type
	cmdType, cmdArgs := parseCommand(req.Command)

	// Validate command against whitelist
	if !isCommandWhitelisted(cmdType) {
		return executor.ExecuteOutput{
			Message: api.NewPlaintextMessage(fmt.Sprintf("Lệnh %s không được phép thực thi. Vui lòng liên hệ quản trị viên.", cmdType), true),
		}, nil
	}

	// Log command attempt to database
	err := e.logCommandAttempt(cmdType, cmdArgs, "pending")
	if err != nil {
		log.Printf("Không thể ghi log lệnh: %v", err)
	}

	// Check if auto-execution is enabled
	config, err := loadExecutorConfig()
	if err != nil {
		log.Printf("Không thể tải cấu hình: %v", err)
		return executor.ExecuteOutput{
			Message: api.NewPlaintextMessage("Lỗi cấu hình server", true),
		}, err
	}

	if !config.AutoExecute {
		log.Printf("Auto-execution is disabled. Command requires user confirmation.")
		return executor.ExecuteOutput{
			Message: api.NewPlaintextMessage("Lệnh yêu cầu xác nhận từ người dùng trước khi thực thi.", true),
		}, nil
	}

	// Execute command via Botkube
	output, err := e.executeBotkubeCommand(cmdType, cmdArgs)
	if err != nil {
		e.logCommandAttempt(cmdType, cmdArgs, "failed")
		return executor.ExecuteOutput{
			Message: api.NewPlaintextMessage(fmt.Sprintf("Lỗi khi thực thi lệnh %s: %v", cmdType, err), true),
		}, err
	}

	// Log successful execution
	e.logCommandAttempt(cmdType, cmdArgs, "success")

	return executor.ExecuteOutput{
		Message: api.NewPlaintextMessage(fmt.Sprintf("Kết quả lệnh %s: %s", cmdType, output), true),
	}, nil
}

// parseCommand extracts command type and arguments
func parseCommand(cmd string) (string, string) {
	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return "unknown", ""
	}

	// Handle kubectl commands
	if parts[0] == "kubectl" && len(parts) > 1 {
		if parts[1] == "get" {
			return "get", strings.Join(parts[2:], " ")
		} else if parts[1] == "describe" {
			return "describe", strings.Join(parts[2:], " ")
		} else if parts[1] == "logs" {
			return "logs", strings.Join(parts[2:], " ")
		} else if parts[1] == "delete" {
			return "delete", strings.Join(parts[2:], " ")
		} else if parts[1] == "exec" {
			return "exec", strings.Join(parts[2:], " ")
		}
	}

	return parts[0], strings.Join(parts[1:], " ")
}

// isCommandWhitelisted checks if a command type is allowed
func isCommandWhitelisted(cmdType string) bool {
	allowedCommands := map[string]bool{
		"get":      true,
		"describe": true,
		"logs":     true,
		// "delete": false by default for safety
		// "exec":   false by default for safety
	}
	return allowedCommands[cmdType]
}

// logCommandAttempt logs command execution attempts to database
func (e *FlutterExecutor) logCommandAttempt(cmdType, cmdArgs, status string) error {
	query := `INSERT INTO command_history (command_type, command_args, status, timestamp) VALUES ($1, $2, $3, NOW())`
	_, err := e.db.Exec(query, cmdType, cmdArgs, status)
	if err != nil {
		return fmt.Errorf("Lỗi khi lưu lệnh vào cơ sở dữ liệu: %v", err)
	}
	return nil
}

// executeBotkubeCommand executes commands via Botkube
func (e *FlutterExecutor) executeBotkubeCommand(cmdType, cmdArgs string) (string, error) {
	// In a real implementation, this would call Botkube APIs
	// Construct the full command
	fullCommand := fmt.Sprintf("kubectl %s %s", cmdType, cmdArgs)
	log.Printf("Thực thi lệnh Botkube: %s", fullCommand)

	// For now, simulate the interaction with Botkube
	// In a production environment, this would be replaced with actual Botkube API calls
	// Example: Use Botkube SDK or HTTP client to send command to Botkube
	// botkubeClient := botkube.NewClient()
	// result, err := botkubeClient.ExecuteCommand(fullCommand)
	// if err != nil {
	//     return "", fmt.Errorf("Lỗi khi gửi lệnh tới Botkube: %v", err)
	// }
	// return result.Output, nil

	// Simulated response for testing
	return fmt.Sprintf("Đã thực thi thành công lệnh: %s", fullCommand), nil
}

// FlutterClaims định nghĩa cấu trúc cho JWT claims
type FlutterClaims struct {
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.StandardClaims
}

// ValidateFlutterUser xác thực người dùng từ cơ sở dữ liệu
func ValidateFlutterUser(username string) (bool, string) {
	config, err := loadExecutorConfig()
	if err != nil {
		log.Printf("Lỗi khi đọc cấu hình: %v", err)
		return false, ""
	}

	db, err := sql.Open("postgres", fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", config.DBHost, config.DBPort, config.DBUser, config.DBPassword, config.DBName))
	if err != nil {
		log.Printf("Không thể kết nối tới CockroachDB: %v", err)
		return false, ""
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Printf("Không thể kiểm tra kết nối CockroachDB: %v", err)
		return false, ""
	}

	var role string
	err = db.QueryRow("SELECT role FROM users WHERE username = $1", username).Scan(&role)
	if err == sql.ErrNoRows {
		log.Printf("Không tìm thấy người dùng %s trong cơ sở dữ liệu", username)
		return false, ""
	}
	if err != nil {
		log.Printf("Lỗi khi truy vấn người dùng %s: %v", username, err)
		return false, ""
	}

	log.Printf("Đã xác thực người dùng %s với vai trò %s", username, role)
	return true, role
}

// GenerateFlutterJWT tạo token JWT cho người dùng
func GenerateFlutterJWT(username string) (string, error) {
	var role string
	if username == "user1" {
		role = "admin" // Gán vai trò admin cho user1 với đầy đủ quyền
	} else if username == "user2" {
		role = "user" // Gán vai trò user cho user2 chỉ được chat với AI
	} else {
		role = "user" // Vai trò mặc định cho các user khác
	}
	claims := &FlutterClaims{
		Username: username,
		Role:     role,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: time.Now().Add(time.Hour * 24).Unix(),
			IssuedAt:  time.Now().Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	config, err := loadExecutorConfig()
	if err != nil {
		return "", fmt.Errorf("Không thể đọc cấu hình: %v", err)
	}
	signedToken, err := token.SignedString([]byte(config.JWTSecret))
	if err != nil {
		return "", fmt.Errorf("Không thể ký token JWT: %v", err)
	}

	log.Printf("Đã tạo token JWT cho người dùng %s", username)
	return signedToken, nil
}

// FlutterUpgrader for WebSocket
var FlutterUpgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for now
	},
}

// WebSocket clients management
var (
	flutterClients    = make(map[*websocket.Conn]bool)
	flutterClientsMux sync.Mutex
)

// sendFlutterEventToClients gửi dữ liệu JSON sự kiện đến tất cả các client đã kết nối
func sendFlutterEventToClients(eventJSON []byte) {
	flutterClientsMux.Lock()
	defer flutterClientsMux.Unlock()

	for client := range flutterClients {
		err := client.WriteMessage(websocket.TextMessage, eventJSON)
		if err != nil {
			log.Printf("Error sending event to client: %v", err)
			client.Close()
			delete(flutterClients, client)
		}
	}
}

func FlutterRoleMiddleware(allowedRoles []string) func(http.HandlerFunc) http.HandlerFunc {
	return func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			tokenStr := r.Header.Get("Authorization")
			if tokenStr == "" {
				http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
				log.Printf("Yêu cầu bị từ chối do thiếu token tại %s", r.URL.Path)
				return
			}
			tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")
			claims := &FlutterClaims{}
			config, err := loadExecutorConfig()
			if err != nil {
				http.Error(w, "Lỗi cấu hình server", http.StatusInternalServerError)
				log.Printf("Lỗi khi đọc cấu hình: %v", err)
				return
			}
			token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
				return []byte(config.JWTSecret), nil
			})
			if err != nil || !token.Valid {
				http.Error(w, "Token không hợp lệ. Vui lòng kiểm tra lại thông tin đăng nhập.", http.StatusUnauthorized)
				log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại %s: %v", r.URL.Path, err)
				return
			}

			hasRole := false
			for _, role := range allowedRoles {
				if claims.Role == role {
					hasRole = true
					break
				}
			}
			if !hasRole {
				http.Error(w, fmt.Sprintf("Không có quyền truy cập vào endpoint %s. Vai trò yêu cầu: %v", r.URL.Path, allowedRoles), http.StatusForbidden)
				log.Printf("Yêu cầu bị từ chối do không có quyền tại %s, vai trò của người dùng: %s", r.URL.Path, claims.Role)
				return
			}
			next(w, r)
		}
	}
}

func FlutterAPIHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		return
	}

	var req types.FlutterCommandRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Dữ liệu yêu cầu không hợp lệ", http.StatusBadRequest)
		return
	}

	response := types.FlutterCommandResponse{
		Output: fmt.Sprintf("Nhận lệnh: %s (chuyển tới k8s-manager)", req.Command),
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

func FlutterEventHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		return
	}

	var event FlutterEvent
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		http.Error(w, "Dữ liệu sự kiện không hợp lệ", http.StatusBadRequest)
		return
	}

	log.Printf("Nhận sự kiện: %+v", event)

	// Gửi sự kiện đến tất cả các client WebSocket
	go ProcessFlutterEvent(event)

	w.WriteHeader(http.StatusOK)
}

func AIProxyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		return
	}

	// Đọc body của request để không làm mất nó khi gửi lại
	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Không thể đọc body của request", http.StatusInternalServerError)
		log.Printf("Không thể đọc body của request: %v", err)
		return
	}
	r.Body.Close()

	// Parse body để lấy thông tin model
	var requestData map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &requestData); err != nil {
		http.Error(w, "Không thể parse JSON request", http.StatusBadRequest)
		log.Printf("Không thể parse JSON request: %v", err)
		return
	}

	// Kiểm tra xem có thông tin model trong request không
	model, modelExists := requestData["model"].(string)
	if !modelExists || model == "" {
		model = "grok" // Mặc định là grok nếu không được chỉ định
	}
	log.Printf("Model được yêu cầu: %s", model)

	// Tạo body mới để gửi đến AI Manager với model được chỉ định rõ
	bodyBytes = append([]byte{}, bodyBytes...)

	req, err := http.NewRequest("POST", "http://localhost:8081/ai/analyze", bytes.NewBuffer(bodyBytes))
	if err != nil {
		http.Error(w, "Không thể tạo yêu cầu AI", http.StatusInternalServerError)
		log.Printf("Không thể tạo yêu cầu AI: %v", err)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", r.Header.Get("Authorization"))

	// Thêm header đặc biệt để chỉ định model và API key cần sử dụng
	req.Header.Set("X-AI-Model", model)

	// Sử dụng timeout để tránh treo request quá lâu
	client := &http.Client{
		Timeout: 60 * time.Second,
	}

	log.Printf("Gửi yêu cầu phân tích đến AI Manager với model: %s", model)
	resp, err := client.Do(req)
	if err != nil {
		// Trả về phản hồi giả lập nếu không thể kết nối tới dịch vụ AI
		log.Printf("Không thể gọi dịch vụ AI: %v", err)
		mockResponse := AIResponse{
			Analysis: "Đây là phản hồi giả lập từ AI vì dịch vụ AI không khả dụng.",
			Workflow: []string{
				"Bước 1: Kiểm tra trạng thái pod",
				"Bước 2: Xem log của pod",
				"Bước 3: Khởi động lại pod nếu cần",
			},
		}
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(mockResponse)
		return
	}
	defer resp.Body.Close()

	// Đọc toàn bộ response
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Không thể đọc phản hồi từ AI Manager", http.StatusInternalServerError)
		log.Printf("Không thể đọc phản hồi từ AI Manager: %v", err)
		return
	}

	// Log phản hồi nhận được (chỉ log một phần để tránh log quá dài)
	responseSummary := string(responseBody)
	if len(responseSummary) > 100 {
		responseSummary = responseSummary[:100] + "..."
	}
	log.Printf("Nhận phản hồi từ AI Manager: %s", responseSummary)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Write(responseBody)
}

func HistoryHandler(w http.ResponseWriter, r *http.Request) {
	// Handle both GET and DELETE methods
	if r.Method != http.MethodGet && r.Method != http.MethodDelete {
		http.Error(w, "Chỉ cho phép phương thức GET hoặc DELETE. Vui lòng kiểm tra lại yêu cầu của bạn.", http.StatusMethodNotAllowed)
		log.Printf("Yêu cầu không hợp lệ tại /history, phương thức không được hỗ trợ: %s", r.Method)
		return
	}

	// Lấy thông tin user từ token
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /history")
		return
	}
	tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")
	claims := &FlutterClaims{}
	config, err := loadExecutorConfig()
	if err != nil {
		http.Error(w, "Lỗi cấu hình server", http.StatusInternalServerError)
		log.Printf("Lỗi khi đọc cấu hình: %v", err)
		return
	}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "Token không hợp lệ. Vui lòng kiểm tra lại thông tin đăng nhập.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /history: %v", err)
		return
	}

	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	// Process DELETE request
	if r.Method == http.MethodDelete {
		log.Printf("Xóa toàn bộ lịch sử cho người dùng: %s", claims.Username)

		// Chỉ xóa lịch sử của người dùng hiện tại (không xóa của người khác)
		result, err := fe.db.Exec(`DELETE FROM chat_history WHERE user_id = $1`, claims.Username)

		if err != nil {
			http.Error(w, fmt.Sprintf("Lỗi khi xóa toàn bộ lịch sử: %v", err), http.StatusInternalServerError)
			log.Printf("Lỗi khi xóa toàn bộ lịch sử cho người dùng %s: %v", claims.Username, err)
			return
		}

		// Kiểm tra số hàng bị ảnh hưởng
		rowsAffected, err := result.RowsAffected()
		if err != nil {
			rowsAffected = 0 // Nếu không thể lấy được số hàng
		}

		log.Printf("Đã xóa %d mục lịch sử của người dùng %s", rowsAffected, claims.Username)

		// Trả về phản hồi thành công
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		response := map[string]string{
			"message":       fmt.Sprintf("Đã xóa %d mục lịch sử thành công", rowsAffected),
			"success":       "true",
			"affected_rows": fmt.Sprintf("%d", rowsAffected),
		}
		json.NewEncoder(w).Encode(response)
		return
	}

	// Process GET request
	// Truy vấn lịch sử chat chỉ cho user đang đăng nhập
	rows, err := fe.db.Query(`
		SELECT 
			id,
			user_id, 
			message, 
			response, 
			timestamp, 
			cost 
		FROM chat_history 
		WHERE user_id = $1 
		ORDER BY timestamp DESC LIMIT 50
	`, claims.Username)
	if err != nil {
		http.Error(w, "Không thể truy vấn lịch sử chat. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Printf("Lỗi khi truy vấn lịch sử chat cho user %s: %v", claims.Username, err)
		return
	}
	defer rows.Close()

	history := []types.HistoryEntry{}
	for rows.Next() {
		var entry types.HistoryEntry
		if err := rows.Scan(&entry.ID, &entry.UserID, &entry.Message, &entry.Response, &entry.Timestamp, &entry.Cost); err != nil {
			http.Error(w, "Không thể đọc dữ liệu lịch sử chat. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Printf("Lỗi khi đọc dữ liệu lịch sử chat: %v", err)
			return
		}
		history = append(history, entry)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(history)
	log.Printf("Đã trả về %d bản ghi lịch sử chat cho user %s", len(history), claims.Username)
}

// UsersHandler xử lý các yêu cầu quản lý người dùng (thêm, xóa, cập nhật vai trò)
func UsersHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		// Lấy danh sách người dùng
		fe, ok := r.Context().Value("executor").(*FlutterExecutor)
		if !ok {
			http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Println("Không thể truy cập FlutterExecutor từ context")
			return
		}

		rows, err := fe.db.Query("SELECT username, role FROM users")
		if err != nil {
			http.Error(w, "Không thể truy vấn danh sách người dùng. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Printf("Lỗi khi truy vấn danh sách người dùng: %v", err)
			return
		}
		defer rows.Close()

		users := []map[string]string{}
		for rows.Next() {
			var username, role string
			if err := rows.Scan(&username, &role); err != nil {
				http.Error(w, "Không thể đọc dữ liệu người dùng. Vui lòng thử lại sau.", http.StatusInternalServerError)
				log.Printf("Lỗi khi đọc dữ liệu người dùng: %v", err)
				return
			}
			users = append(users, map[string]string{"username": username, "role": role})
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(users)
		log.Printf("Đã trả về danh sách %d người dùng", len(users))
		return
	}

	if r.Method == http.MethodPost {
		// Thêm hoặc cập nhật người dùng
		var req struct {
			Username string `json:"username"`
			Role     string `json:"role"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Dữ liệu yêu cầu không hợp lệ", http.StatusBadRequest)
			log.Printf("Lỗi khi giải mã dữ liệu yêu cầu thêm người dùng: %v", err)
			return
		}

		if req.Username == "" || req.Role == "" {
			http.Error(w, "Thiếu thông tin người dùng hoặc vai trò", http.StatusBadRequest)
			return
		}

		fe, ok := r.Context().Value("executor").(*FlutterExecutor)
		if !ok {
			http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Println("Không thể truy cập FlutterExecutor từ context")
			return
		}

		// Kiểm tra xem người dùng đã tồn tại chưa
		var count int
		err := fe.db.QueryRow("SELECT COUNT(*) FROM users WHERE username = $1", req.Username).Scan(&count)
		if err != nil {
			http.Error(w, "Không thể kiểm tra người dùng. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Printf("Lỗi khi kiểm tra người dùng: %v", err)
			return
		}

		var query string
		if count > 0 {
			// Cập nhật vai trò nếu người dùng đã tồn tại
			query = "UPDATE users SET role = $2 WHERE username = $1"
			log.Printf("Cập nhật vai trò cho người dùng %s thành %s", req.Username, req.Role)
		} else {
			// Thêm người dùng mới
			query = "INSERT INTO users (username, role) VALUES ($1, $2)"
			log.Printf("Thêm người dùng mới %s với vai trò %s", req.Username, req.Role)
		}

		_, err = fe.db.Exec(query, req.Username, req.Role)
		if err != nil {
			http.Error(w, "Không thể lưu thông tin người dùng. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Printf("Lỗi khi lưu thông tin người dùng: %v", err)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(map[string]string{"message": "Đã lưu thông tin người dùng thành công"})
		return
	}

	if r.Method == http.MethodDelete {
		// Xóa người dùng
		username := r.URL.Query().Get("username")
		if username == "" {
			http.Error(w, "Thiếu thông tin người dùng để xóa", http.StatusBadRequest)
			return
		}

		fe, ok := r.Context().Value("executor").(*FlutterExecutor)
		if !ok {
			http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Println("Không thể truy cập FlutterExecutor từ context")
			return
		}

		result, err := fe.db.Exec("DELETE FROM users WHERE username = $1", username)
		if err != nil {
			http.Error(w, "Không thể xóa người dùng. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Printf("Lỗi khi xóa người dùng: %v", err)
			return
		}

		rowsAffected, err := result.RowsAffected()
		if err != nil {
			http.Error(w, "Không thể xác định số hàng bị ảnh hưởng. Vui lòng thử lại sau.", http.StatusInternalServerError)
			log.Printf("Lỗi khi xác định số hàng bị ảnh hưởng: %v", err)
			return
		}

		if rowsAffected == 0 {
			http.Error(w, "Không tìm thấy người dùng để xóa", http.StatusNotFound)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(map[string]string{"message": "Đã xóa người dùng thành công"})
		log.Printf("Đã xóa người dùng %s", username)
		return
	}

	http.Error(w, "Phương thức không được hỗ trợ. Vui lòng kiểm tra lại yêu cầu của bạn.", http.StatusMethodNotAllowed)
	log.Printf("Yêu cầu không hợp lệ tại /users, phương thức không được hỗ trợ: %s", r.Method)
}

func FlutterLoginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		return
	}

	var loginReq struct {
		Username string `json:"username"`
	}
	if err := json.NewDecoder(r.Body).Decode(&loginReq); err != nil {
		http.Error(w, "Dữ liệu yêu cầu không hợp lệ", http.StatusBadRequest)
		return
	}

	// Chỉ cho phép user1 và user2
	if loginReq.Username != "user1" && loginReq.Username != "user2" {
		http.Error(w, "Username không hợp lệ. Chỉ chấp nhận user1 hoặc user2.", http.StatusUnauthorized)
		return
	}

	token, err := GenerateFlutterJWT(loginReq.Username)
	if err != nil {
		http.Error(w, "Lỗi tạo token", http.StatusInternalServerError)
		return
	}

	// Vì chúng ta không thể thay đổi backend một cách an toàn, giả sử vai trò mặc định:
	// user1 là admin, user2 là user thông thường
	var role string
	if loginReq.Username == "user1" {
		role = "admin"
	} else {
		role = "user"
	}

	response := map[string]string{
		"token": token,
		"role":  role,
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

// ChatHandler xử lý tin nhắn chat từ người dùng và lưu vào cơ sở dữ liệu
func ChatHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		log.Printf("Yêu cầu không hợp lệ tại /chat, phương thức không được hỗ trợ: %s", r.Method)
		return
	}

	var req struct {
		UserID   string `json:"user_id"`
		Message  string `json:"message"`
		Response string `json:"response"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Dữ liệu yêu cầu không hợp lệ", http.StatusBadRequest)
		log.Printf("Lỗi khi giải mã dữ liệu yêu cầu chat: %v", err)
		return
	}

	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /chat")
		return
	}
	tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")
	claims := &FlutterClaims{}
	config, err := loadExecutorConfig()
	if err != nil {
		http.Error(w, "Lỗi cấu hình server", http.StatusInternalServerError)
		log.Printf("Lỗi khi đọc cấu hình: %v", err)
		return
	}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "Token không hợp lệ. Vui lòng kiểm tra lại thông tin đăng nhập.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /chat: %v", err)
		return
	}

	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	// Lưu tin nhắn vào cơ sở dữ liệu sử dụng các cột user_id, message, và response
	_, err = fe.db.Exec(`
		INSERT INTO chat_history (
			user_id, 
			message, 
			response, 
			timestamp, 
			cost
		) VALUES (
			$1, $2, $3, NOW(), $4
		)`,
		req.UserID,
		req.Message,
		req.Response,
		0.0)
	if err != nil {
		http.Error(w, "Không thể lưu tin nhắn chat. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Printf("Lỗi khi lưu tin nhắn chat: %v", err)
		return
	}

	// Trả về phản hồi cho người dùng
	response := map[string]string{"message": "Tin nhắn đã được nhận và lưu trữ."}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
	log.Printf("Đã lưu tin nhắn từ người dùng %s", req.UserID)
}

// ProcessFlutterEvent gửi sự kiện đến tất cả các client WebSocket đã kết nối
func ProcessFlutterEvent(event FlutterEvent) {
	eventJSON, err := json.Marshal(event)
	if err != nil {
		log.Printf("Error marshaling event to JSON: %v", err)
		return
	}
	log.Printf("Xử lý sự kiện: %s", string(eventJSON))

	// Gửi sự kiện đến tất cả các client đã kết nối
	sendFlutterEventToClients(eventJSON)
}

// DeleteHistoryHandler xử lý yêu cầu xóa một mục lịch sử cụ thể
func DeleteHistoryHandler(w http.ResponseWriter, r *http.Request) {
	// Thiết lập CORS headers cho preflight requests
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Allow-Credentials", "true")

	// Xử lý OPTIONS preflight request
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodDelete {
		http.Error(w, "Chỉ chấp nhận phương thức DELETE", http.StatusMethodNotAllowed)
		return
	}

	// Lấy ID từ URL
	vars := mux.Vars(r)
	historyID := vars["id"]
	log.Printf("Nhận yêu cầu xóa lịch sử với ID: %s", historyID)

	if historyID == "" {
		http.Error(w, "Thiếu ID lịch sử", http.StatusBadRequest)
		return
	}

	// Kiểm tra token
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /history/%s", historyID)
		return
	}
	tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")
	claims := &FlutterClaims{}
	config, err := loadExecutorConfig()
	if err != nil {
		http.Error(w, "Lỗi cấu hình server", http.StatusInternalServerError)
		log.Printf("Lỗi khi đọc cấu hình: %v", err)
		return
	}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "Token không hợp lệ. Vui lòng kiểm tra lại thông tin đăng nhập.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /history/%s: %v", historyID, err)
		return
	}

	log.Printf("Yêu cầu xóa lịch sử từ user: %s với vai trò: %s", claims.Username, claims.Role)

	// Lấy FlutterExecutor từ context
	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	// Debug: Hiển thị tất cả các ID hiện có trong bảng để giúp debug
	rows, err := fe.db.Query("SELECT id FROM chat_history WHERE user_id = $1 LIMIT 30", claims.Username)
	if err != nil {
		log.Printf("Lỗi khi truy vấn các ID: %v", err)
	} else {
		defer rows.Close()
		log.Printf("Các ID của user %s trong bảng chat_history:", claims.Username)
		var id interface{}
		for rows.Next() {
			if err := rows.Scan(&id); err == nil {
				log.Printf("- ID: %v (type: %T)", id, id)
			}
		}
	}

	// Số hàng bị ảnh hưởng
	var rowsAffected int64 = 0
	var resultMsg string

	// Thử nhiều cách xóa khác nhau
	// 1. Thử xóa bằng ID chính xác (dạng int)
	var historyIDInt int64
	historyIDInt, err = strconv.ParseInt(historyID, 10, 64)
	if err == nil {
		// Nếu chuyển đổi thành công sang int64
		log.Printf("Thử xóa với ID số: %d", historyIDInt)
		result, err := fe.db.Exec(`DELETE FROM chat_history WHERE id = $1 AND user_id = $2`,
			historyIDInt, claims.Username)
		if err == nil {
			affected, _ := result.RowsAffected()
			rowsAffected += affected
			log.Printf("Số hàng bị ảnh hưởng khi xóa ID số %d: %d", historyIDInt, affected)
		} else {
			log.Printf("Lỗi khi xóa với ID số %d: %v", historyIDInt, err)
		}
	}

	// 2. Thử với ID dạng chuỗi chính xác
	if rowsAffected == 0 {
		log.Printf("Thử xóa với ID dạng chuỗi chính xác: %s", historyID)
		result, err := fe.db.Exec(`DELETE FROM chat_history WHERE id::text = $1 AND user_id = $2`,
			historyID, claims.Username)
		if err == nil {
			affected, _ := result.RowsAffected()
			rowsAffected += affected
			log.Printf("Số hàng bị ảnh hưởng khi xóa ID chuỗi %s: %d", historyID, affected)
		} else {
			log.Printf("Lỗi khi xóa với ID chuỗi %s: %v", historyID, err)
		}
	}

	// 3. Thử với LIKE để bắt ID một phần
	if rowsAffected == 0 {
		log.Printf("Thử xóa với LIKE: %%%s%%", historyID)
		result, err := fe.db.Exec(`DELETE FROM chat_history WHERE id::text LIKE $1 AND user_id = $2`,
			"%"+historyID+"%", claims.Username)
		if err == nil {
			affected, _ := result.RowsAffected()
			rowsAffected += affected
			log.Printf("Số hàng bị ảnh hưởng khi xóa với LIKE %%%s%%: %d", historyID, affected)
		} else {
			log.Printf("Lỗi khi xóa với LIKE %%%s%%: %v", historyID, err)
		}
	}

	// 4. Kiểm tra xem có phải ID này thực sự bị lỗi format không
	if rowsAffected == 0 {
		// Lấy danh sách ID gần nhất từ bảng
		rows, err := fe.db.Query(`
			SELECT id FROM chat_history 
			WHERE user_id = $1 
			ORDER BY timestamp DESC LIMIT 5`, claims.Username)

		if err == nil {
			defer rows.Close()
			log.Println("5 ID gần nhất của user trong db:")
			var latestIds []interface{}
			for rows.Next() {
				var id interface{}
				if err := rows.Scan(&id); err == nil {
					latestIds = append(latestIds, id)
					log.Printf("- ID gần nhất: %v (type: %T)", id, id)
				}
			}

			// Nếu có ID gần nhất, thử xóa ID gần nhất
			if len(latestIds) > 0 {
				log.Printf("Thử xóa ID gần nhất: %v", latestIds[0])
				result, err := fe.db.Exec(`DELETE FROM chat_history WHERE id = $1 AND user_id = $2`,
					latestIds[0], claims.Username)
				if err == nil {
					affected, _ := result.RowsAffected()
					rowsAffected += affected
					resultMsg = fmt.Sprintf("Không tìm thấy ID %s, đã xóa ID gần nhất thay thế: %v", historyID, latestIds[0])
					log.Printf("Xóa thành công ID gần nhất: %v, số hàng ảnh hưởng: %d", latestIds[0], affected)
				}
			}
		}
	}

	if rowsAffected == 0 {
		http.Error(w, "Không tìm thấy mục lịch sử để xóa hoặc bạn không có quyền xóa mục này", http.StatusNotFound)
		log.Printf("Không tìm thấy mục lịch sử để xóa với ID: %s", historyID)
		return
	}

	// Trả về phản hồi thành công
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	if resultMsg == "" {
		resultMsg = "Đã xóa mục lịch sử thành công"
	}

	response := map[string]string{
		"message":       resultMsg,
		"id":            historyID,
		"affected_rows": fmt.Sprintf("%d", rowsAffected),
	}
	json.NewEncoder(w).Encode(response)
	log.Printf("Đã xóa lịch sử với ID %s của người dùng %s, số hàng bị ảnh hưởng: %d", historyID, claims.Username, rowsAffected)
}

// DeleteAllHistoryHandler xử lý yêu cầu xóa toàn bộ lịch sử chat của người dùng
func DeleteAllHistoryHandler(w http.ResponseWriter, r *http.Request) {
	// Lấy thông tin user từ token
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /history/delete-all")
		return
	}
	tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")
	claims := &FlutterClaims{}
	config, err := loadExecutorConfig()
	if err != nil {
		http.Error(w, "Lỗi cấu hình server", http.StatusInternalServerError)
		log.Printf("Lỗi khi đọc cấu hình: %v", err)
		return
	}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "Token không hợp lệ. Vui lòng kiểm tra lại thông tin đăng nhập.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /history/delete-all: %v", err)
		return
	}

	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	log.Printf("Xóa toàn bộ lịch sử cho người dùng: %s", claims.Username)

	// Chỉ xóa lịch sử của người dùng hiện tại (không xóa của người khác)
	result, err := fe.db.Exec(`DELETE FROM chat_history WHERE user_id = $1`, claims.Username)

	if err != nil {
		http.Error(w, fmt.Sprintf("Lỗi khi xóa toàn bộ lịch sử: %v", err), http.StatusInternalServerError)
		log.Printf("Lỗi khi xóa toàn bộ lịch sử cho người dùng %s: %v", claims.Username, err)
		return
	}

	// Kiểm tra số hàng bị ảnh hưởng
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		rowsAffected = 0 // Nếu không thể lấy được số hàng
	}

	log.Printf("Đã xóa %d mục lịch sử của người dùng %s", rowsAffected, claims.Username)

	// Trả về phản hồi thành công
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	response := map[string]interface{}{
		"success":       true,
		"message":       fmt.Sprintf("Đã xóa %d mục lịch sử thành công", rowsAffected),
		"affected_rows": rowsAffected,
	}
	json.NewEncoder(w).Encode(response)
}

// isKubernetesQuery determines if the query is related to Kubernetes
func isKubernetesQuery(query string) bool {
	if query == "" {
		return false
	}

	lowerQuery := strings.ToLower(query)

	// Common patterns that clearly indicate this is NOT a kubernetes query
	// These take precedence over other patterns
	naturalLanguagePatterns := []string{
		"who are you", "what is your name", "tell me about", "explain", "how do i",
		"can you help", "what do you think", "what's your opinion", "do you know",
		"tell me a joke", "sing a song", "write a", "what time", "weather",
		"translate", "meaning of", "definition of", "what does", "summarize",
		"what happened", "history of", "when was", "who is", "who was",
		"how many", "calculate", "compute", "what color", "why do", "give me",
		"recommend", "suggest", "difference between", "compare", "hello world",
	}

	for _, pattern := range naturalLanguagePatterns {
		if strings.Contains(lowerQuery, pattern) {
			return false // Definitely a natural language query
		}
	}

	// Check for kubectl commands - strong indicators of Kubernetes queries
	if strings.HasPrefix(lowerQuery, "kubectl ") ||
		strings.HasPrefix(lowerQuery, "get ") ||
		strings.HasPrefix(lowerQuery, "describe ") ||
		strings.HasPrefix(lowerQuery, "delete ") ||
		strings.HasPrefix(lowerQuery, "apply ") {
		return true
	}

	// Check for Kubernetes specific terms
	kubeTerms := []string{"pod", "pods", "deployment", "service", "namespace", "cluster", "node", "configmap", "secret", "daemonset", "statefulset", "cronjob", "job", "ingress", "persistent", "volume", "helm"}

	kubeTermCount := 0
	for _, term := range kubeTerms {
		// Check for whole words only using word boundaries
		pattern := "\\b" + term + "\\b"
		match, _ := regexp.MatchString(pattern, lowerQuery)
		if match {
			kubeTermCount++
		}
	}

	// If we have more than one Kubernetes term, it's likely a Kubernetes query
	if kubeTermCount > 1 {
		return true
	}

	// Detect common greeting patterns
	greetings := []string{"hi", "hello", "hey", "chào", "xin chào", "help me", "help", "what", "why", "how", "when", "where"}

	for _, greeting := range greetings {
		if strings.HasPrefix(lowerQuery, greeting) {
			return false
		}
	}

	// For queries that contain just one kube term, look for additional context
	if kubeTermCount == 1 {
		// If it's a short query with a single kube term, it might be Kubernetes-related
		// For longer, more complex queries with just one term, treat as natural language
		wordCount := len(strings.Fields(lowerQuery))
		if wordCount <= 5 {
			return true
		}
	}

	// Default to natural language query if uncertain
	return false
}

// ChatEndpointHandler forwards natural language queries to the AI Manager
func ChatEndpointHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		log.Printf("Yêu cầu không hợp lệ tại /chat, phương thức không được hỗ trợ: %s", r.Method)
		return
	}

	// Read and parse the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Không thể đọc dữ liệu từ request", http.StatusBadRequest)
		log.Printf("Lỗi khi đọc body của request: %v", err)
		return
	}
	r.Body.Close()

	// Log request for debugging
	log.Printf("Chat request received: %s", string(body))

	// Parse the request to determine message type
	var request map[string]interface{}
	if err := json.Unmarshal(body, &request); err != nil {
		http.Error(w, "Dữ liệu request không hợp lệ", http.StatusBadRequest)
		log.Printf("Không thể parse JSON request: %v", err)
		return
	}

	// Check if this is a simple message or a Kubernetes query
	// Support both "message" (from web) and "prompt" (from mobile) fields
	var message string
	var hasMessage bool

	// First try to get from message field
	messageVal, hasMessageField := request["message"].(string)
	if hasMessageField && messageVal != "" {
		message = messageVal
		hasMessage = true
	}

	// If not found, try to get from prompt field (for mobile compatibility)
	if !hasMessage {
		promptVal, hasPromptField := request["prompt"].(string)
		if hasPromptField && promptVal != "" {
			message = promptVal
			hasMessage = true
		}
	}

	if !hasMessage || message == "" {
		http.Error(w, "Thiếu tin nhắn trong request", http.StatusBadRequest)
		log.Printf("Không tìm thấy trường 'message' hoặc 'prompt' trong request")
		return
	}

	// Check for explicit natural language patterns first
	isNaturalLanguage := false
	isKubernetes := false

	// Explicit natural language patterns
	naturalLanguagePatterns := []string{
		"who are you", "what is your name", "tell me about", "explain", "how do i",
		"can you help", "what do you think", "what's your opinion", "do you know",
		"tell me a joke", "sing a song", "write a", "what time", "weather",
		"translate", "meaning of", "definition of", "what does", "summarize",
		"what happened", "history of", "when was", "who is", "who was",
		"how many", "calculate", "compute", "what color", "why do", "give me",
		"recommend", "suggest", "difference between", "compare", "hello world",
		"ma", "quỷ", "tâm linh", "thời tiết", "ngày", "hôm nay", "giờ",
	}

	for _, pattern := range naturalLanguagePatterns {
		if strings.Contains(strings.ToLower(message), pattern) {
			isNaturalLanguage = true
			log.Printf("Detected explicit natural language pattern: %s", pattern)
			break
		}
	}

	// If not an explicit natural language query, check if it's Kubernetes-related
	if !isNaturalLanguage {
		isKubernetes = isKubernetesQuery(message)
		log.Printf("Detected message type: %s (Kubernetes: %v, Natural Language: %v)", message, isKubernetes, isNaturalLanguage)
	}

	// Create a new request to the AI Manager
	var endpoint string

	// If it's natural language or not explicitly Kubernetes, use natural language endpoint
	if isNaturalLanguage || !isKubernetes {
		// Use natural language endpoint
		endpoint = "http://localhost:8081/chat"
		log.Printf("Forwarding as natural language query to: %s", endpoint)
	} else {
		// Convert to Kubernetes event format for AI/analyze endpoint
		kubernetesEvent := map[string]interface{}{
			"type":      "user_query",
			"resource":  "kubernetes",
			"name":      message,
			"namespace": "",
			"cluster":   "",
			"model":     request["model"],
		}

		newBody, err := json.Marshal(kubernetesEvent)
		if err != nil {
			http.Error(w, "Không thể tạo request Kubernetes", http.StatusInternalServerError)
			log.Printf("Không thể tạo request Kubernetes: %v", err)
			return
		}

		endpoint = "http://localhost:8081/ai/analyze"
		body = newBody

		log.Printf("Forwarding as Kubernetes query to: %s", endpoint)
	}

	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(body))
	if err != nil {
		http.Error(w, "Không thể tạo yêu cầu đến AI Manager", http.StatusInternalServerError)
		log.Printf("Không thể tạo yêu cầu đến AI Manager: %v", err)
		return
	}

	// Forward the headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", r.Header.Get("Authorization"))

	// Send the request to AI Manager with increased timeout
	client := &http.Client{
		Timeout: 60 * time.Second, // Increased timeout to 60 seconds
	}

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Không thể gửi yêu cầu đến AI Manager: %v", err)

		// Get the token from the request
		tokenStr := r.Header.Get("Authorization")
		tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")

		// Parse the token to get the user ID
		claims := &FlutterClaims{}
		config, _ := loadExecutorConfig()
		token, tokenErr := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.JWTSecret), nil
		})

		// Generate a context-appropriate fallback response using the utility function
		fallbackResponse := utils.GenerateContextualFallback(message)

		// Save to history if token is valid
		if tokenErr == nil && token.Valid {
			// Extract the username
			userID := claims.Username

			// Get chat history entry
			historyEntry := HistoryEntry{
				UserID:    userID,
				Message:   message,
				Response:  fallbackResponse["response"].(string),
				Timestamp: time.Now(),
				Cost:      0.0,
			}

			// Access the database
			fe, ok := r.Context().Value("executor").(*FlutterExecutor)
			if ok {
				// Insert into database
				_, dbErr := fe.db.Exec(`
					INSERT INTO chat_history (
						user_id, 
						message, 
						response, 
						timestamp, 
						cost
					) VALUES (
						$1, $2, $3, NOW(), $4
					)`,
					historyEntry.UserID,
					historyEntry.Message,
					historyEntry.Response,
					historyEntry.Cost)

				if dbErr != nil {
					log.Printf("Error saving fallback response to history: %v", dbErr)
				} else {
					log.Printf("Successfully saved fallback response to history for user: %s", userID)
				}
			}
		}

		// Return the fallback response
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(fallbackResponse)
		return
	}
	defer resp.Body.Close()

	// Read the response body
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Không thể đọc phản hồi từ AI Manager", http.StatusInternalServerError)
		log.Printf("Không thể đọc phản hồi từ AI Manager: %v", err)
		return
	}

	// Log the response for debugging
	log.Printf("Response from AI Manager: %s", string(responseBody))

	// Check if response is empty or has error format
	if len(responseBody) == 0 || strings.TrimSpace(string(responseBody)) == "{}" {
		log.Printf("AI Manager returned empty response")

		// Return a context-specific fallback response using the utility function
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		fallbackResponse := utils.GenerateContextualFallback(message)
		json.NewEncoder(w).Encode(fallbackResponse)
		return
	}

	// Parse the response for further processing
	var responseObj map[string]interface{}
	if err := json.Unmarshal(responseBody, &responseObj); err == nil {
		if errorMsg, hasError := responseObj["error"].(string); hasError && errorMsg != "" {
			// There's an error message in the response
			log.Printf("AI Manager returned error: %s", errorMsg)

			// Return a context-specific error response using the utility function
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			fallbackResponse := utils.GenerateContextualFallback(message)
			json.NewEncoder(w).Encode(fallbackResponse)
			return
		}

		// If this was a Kubernetes query, transform the response format for consistency
		if isKubernetes {
			analysis, hasAnalysis := responseObj["analysis"].(string)
			var workflow []interface{}

			if hasAnalysis {
				// Get workflow if available
				if workflowArr, ok := responseObj["workflow"].([]interface{}); ok {
					workflow = workflowArr
				}

				// Convert from AI/analyze format to chat format
				transformedResponse := map[string]interface{}{
					"response": analysis,
					"workflow": workflow,
				}

				responseObj = transformedResponse
			}
		} else {
			// For natural language queries, check if we got the default Kubernetes workflow
			// when asking about non-Kubernetes topics
			if workflow, hasWorkflow := responseObj["workflow"].([]interface{}); hasWorkflow && len(workflow) > 0 {
				// Use the utility to check for default workflows and get better ones
				isDefaultK8sWorkflow := utils.IsDefaultKubernetesWorkflow(workflow)

				if isDefaultK8sWorkflow {
					// Get improved workflow based on the query content
					improvedWorkflow := utils.GetImprovedWorkflow(message, isDefaultK8sWorkflow)
					if improvedWorkflow != nil {
						responseObj["workflow"] = improvedWorkflow
					}
				}
			}
		}
	} else {
		log.Printf("Không thể parse JSON response: %v", err)
	}

	// Forward the response back to the client
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(responseObj)

	// Check if the client wants the server to save the chat history or if they'll handle it
	// Client can set a header 'X-Handle-History: client' to indicate they'll save history themselves
	historyHandler := r.Header.Get("X-Handle-History")

	// Only save history on server side if client isn't handling it
	if historyHandler != "client" {
		// Extract user info from token and save to history
		tokenStr := r.Header.Get("Authorization")
		if tokenStr != "" {
			tokenStr = strings.TrimPrefix(tokenStr, "Bearer ")
			claims := &FlutterClaims{}
			config, err := loadExecutorConfig()
			if err == nil {
				token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
					return []byte(config.JWTSecret), nil
				})
				if err == nil && token.Valid {
					userID := claims.Username
					response := ""

					if resp, ok := responseObj["response"].(string); ok {
						response = resp
					} else if resp, ok := responseObj["analysis"].(string); ok {
						response = resp
					}

					// Create chat history request
					chatRequest := struct {
						UserID   string `json:"user_id"`
						Message  string `json:"message"`
						Response string `json:"response"`
					}{
						UserID:   userID,
						Message:  message,
						Response: response,
					}

					// Save to history
					fe, ok := r.Context().Value("executor").(*FlutterExecutor)
					if ok {
						_, err := fe.db.Exec(`
							INSERT INTO chat_history (
								user_id, 
								message, 
								response, 
								timestamp, 
								cost
							) VALUES (
								$1, $2, $3, NOW(), $4
							)`,
							chatRequest.UserID,
							chatRequest.Message,
							chatRequest.Response,
							0.0)

						if err != nil {
							log.Printf("Error saving chat message to history: %v", err)
						} else {
							log.Printf("Successfully saved chat history for user: %s", userID)
						}
					}
				}
			}
		}
	} else {
		log.Printf("Client is handling chat history, skipping server-side storage")
	}
}

func main() {
	fe, err := NewFlutterExecutor()
	if err != nil {
		log.Fatalf("Không thể khởi tạo Flutter Executor: %v", err)
	}
	defer fe.Close()

	router := mux.NewRouter()
	// Attach FlutterExecutor to the request context for all handlers
	router.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := context.WithValue(r.Context(), "executor", fe)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	})

	// Basic API endpoints
	router.HandleFunc("/execute", FlutterRoleMiddleware([]string{"admin"})(FlutterAPIHandler)).Methods("POST")
	router.HandleFunc("/events", FlutterRoleMiddleware([]string{"admin", "user"})(FlutterEventHandler)).Methods("POST")
	router.HandleFunc("/ai/analyze", FlutterRoleMiddleware([]string{"admin", "user"})(AIProxyHandler)).Methods("POST")
	router.HandleFunc("/history", HistoryHandler).Methods("GET")
	router.HandleFunc("/history/{id}", DeleteHistoryHandler).Methods("DELETE")
	router.HandleFunc("/history/delete-all", DeleteAllHistoryHandler).Methods("POST")
	router.HandleFunc("/login", FlutterLoginHandler).Methods("POST")
	router.HandleFunc("/users", FlutterRoleMiddleware([]string{"admin"})(UsersHandler)).Methods("GET", "POST", "DELETE")

	// Key endpoints for Flutter mobile app compatibility
	router.HandleFunc("/chat", FlutterRoleMiddleware([]string{"admin", "user"})(ChatEndpointHandler)).Methods("POST")
	router.HandleFunc("/process-kubernetes", FlutterRoleMiddleware([]string{"admin", "user"})(ChatEndpointHandler)).Methods("POST")
	router.HandleFunc("/query", FlutterRoleMiddleware([]string{"admin", "user"})(ChatEndpointHandler)).Methods("POST")

	// Định nghĩa endpoint WebSocket trực tiếp
	router.HandleFunc("/events/ws", func(w http.ResponseWriter, r *http.Request) {
		// Sử dụng upgrader từ main.go, không phải từ events.go
		ws, err := FlutterUpgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Printf("Error upgrading to WebSocket: %v", err)
			return
		}
		defer ws.Close()

		log.Println("WebSocket client connected")

		// Giữ kết nối và xử lý ngắt kết nối
		for {
			_, _, err := ws.ReadMessage()
			if err != nil {
				log.Printf("Error reading from WebSocket: %v", err)
				break
			}
		}
		log.Println("WebSocket client disconnected")
	}).Methods("GET")

	// WebSocket shortcut for mobile
	router.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/events/ws", http.StatusTemporaryRedirect)
	}).Methods("GET")

	// Thêm middleware CORS
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})
	handler := c.Handler(router)

	config, err := loadExecutorConfig()
	if err != nil {
		log.Fatalf("Không thể tải cấu hình: %v", err)
	}
	// Log a portion of JWTSecret to verify (first 5 characters for security)
	if len(config.JWTSecret) > 5 {
		log.Printf("Sử dụng JWTSecret (đầu 5 ký tự): %s...", config.JWTSecret[:5])
	} else {
		log.Printf("Sử dụng JWTSecret: (độ dài không đủ để hiển thị một phần)")
	}
	log.Printf("Máy chủ đang chạy trên cổng %d", config.Port)

	// Gửi một sự kiện test sau 5 giây để kiểm tra kết nối WebSocket
	go func() {
		time.Sleep(5 * time.Second)
		testEvent := FlutterEvent{
			Type:      "test",
			Resource:  "server",
			Name:      "startup",
			Namespace: "default",
			Cluster:   "local",
		}
		eventJSON, _ := json.Marshal(testEvent)
		sendFlutterEventToClients(eventJSON)
	}()

	// Khởi động máy chủ
	if err := http.ListenAndServe(fmt.Sprintf(":%d", config.Port), handler); err != nil {
		log.Fatalf("Không thể khởi động máy chủ: %v", err)
	}
}

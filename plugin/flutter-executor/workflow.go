package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gorilla/mux"
)

// GetWorkflowsHandler retrieves all workflows for the current user
func GetWorkflowsHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user from JWT token
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /workflows")
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
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /workflows: %v", err)
		return
	}

	// Get database connection from context
	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	// Query for workflows
	rows, err := fe.db.Query(`
		SELECT id, title, description, steps, created_at, is_custom
		FROM workflows
		WHERE user_id = $1
		ORDER BY created_at DESC
	`, claims.Username)

	if err != nil {
		http.Error(w, "Lỗi khi truy vấn quy trình làm việc", http.StatusInternalServerError)
		log.Printf("Lỗi khi truy vấn workflows từ database: %v", err)
		return
	}
	defer rows.Close()

	var workflows []WorkflowData
	for rows.Next() {
		var workflow WorkflowData
		var stepsJSON string
		var createdAt sql.NullTime

		err := rows.Scan(
			&workflow.ID,
			&workflow.Title,
			&workflow.Description,
			&stepsJSON,
			&createdAt,
			&workflow.IsCustom,
		)

		if err != nil {
			log.Printf("Lỗi khi đọc workflow từ database: %v", err)
			continue
		}

		// Parse steps JSON
		err = json.Unmarshal([]byte(stepsJSON), &workflow.Steps)
		if err != nil {
			log.Printf("Lỗi khi parse steps JSON: %v", err)
			workflow.Steps = []string{"Error: Không thể đọc các bước quy trình"}
		}

		// Set user ID
		workflow.UserID = claims.Username

		// Format created_at
		if createdAt.Valid {
			workflow.CreatedAt = createdAt.Time.Format(time.RFC3339)
		}

		workflows = append(workflows, workflow)
	}

	// Add default workflows if user has no workflows
	if len(workflows) == 0 {
		defaultWorkflows := getDefaultWorkflows(claims.Username)
		workflows = append(workflows, defaultWorkflows...)
	}

	// Return workflows as JSON
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(workflows)
}

// SaveWorkflowHandler saves a workflow to the database
func SaveWorkflowHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user from JWT token
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /workflows")
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
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /workflows: %v", err)
		return
	}

	// Parse request body
	var workflow WorkflowData
	if err := json.NewDecoder(r.Body).Decode(&workflow); err != nil {
		http.Error(w, "Dữ liệu quy trình không hợp lệ", http.StatusBadRequest)
		log.Printf("Lỗi khi parse JSON workflow: %v", err)
		return
	}

	// Set user ID
	workflow.UserID = claims.Username

	// Get database connection from context
	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	// Convert steps to JSON
	stepsJSON, err := json.Marshal(workflow.Steps)
	if err != nil {
		http.Error(w, "Lỗi khi xử lý các bước quy trình", http.StatusInternalServerError)
		log.Printf("Lỗi khi convert steps to JSON: %v", err)
		return
	}

	// Insert workflow into database
	var id string
	err = fe.db.QueryRow(`
		INSERT INTO workflows 
		(title, description, steps, user_id, is_custom, created_at) 
		VALUES ($1, $2, $3, $4, $5, NOW()) 
		RETURNING id
	`, workflow.Title, workflow.Description, stepsJSON, workflow.UserID, workflow.IsCustom).Scan(&id)

	if err != nil {
		http.Error(w, "Lỗi khi lưu quy trình làm việc", http.StatusInternalServerError)
		log.Printf("Lỗi khi lưu workflow vào database: %v", err)
		return
	}

	// Set the ID in the response
	workflow.ID = id
	workflow.CreatedAt = time.Now().Format(time.RFC3339)

	// Return success
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(workflow)
}

// DeleteWorkflowHandler deletes a workflow from the database
func DeleteWorkflowHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user from JWT token
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /workflows")
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
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /workflows: %v", err)
		return
	}

	// Get workflow ID from URL
	vars := mux.Vars(r)
	workflowID := vars["id"]

	// Get database connection from context
	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	// Delete workflow
	result, err := fe.db.Exec(`
		DELETE FROM workflows 
		WHERE id = $1 AND user_id = $2
	`, workflowID, claims.Username)

	if err != nil {
		http.Error(w, "Lỗi khi xóa quy trình làm việc", http.StatusInternalServerError)
		log.Printf("Lỗi khi xóa workflow từ database: %v", err)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Không tìm thấy quy trình hoặc bạn không có quyền xóa", http.StatusNotFound)
		return
	}

	// Return success
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Đã xóa quy trình làm việc thành công",
		"id":      workflowID,
	})
}

// ExecuteWorkflowHandler executes all steps in a workflow
func ExecuteWorkflowHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user from JWT token
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		http.Error(w, "Thiếu token xác thực. Vui lòng đăng nhập để tiếp tục.", http.StatusUnauthorized)
		log.Printf("Yêu cầu bị từ chối do thiếu token tại /workflows/execute")
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
		log.Printf("Yêu cầu bị từ chối do token không hợp lệ tại /workflows/execute: %v", err)
		return
	}

	// Get workflow ID from URL
	vars := mux.Vars(r)
	workflowID := vars["id"]

	// Get database connection from context
	fe, ok := r.Context().Value("executor").(*FlutterExecutor)
	if !ok {
		http.Error(w, "Không thể truy cập cơ sở dữ liệu. Vui lòng thử lại sau.", http.StatusInternalServerError)
		log.Println("Không thể truy cập FlutterExecutor từ context")
		return
	}

	// Retrieve workflow
	var stepsJSON string
	err = fe.db.QueryRow(`
		SELECT steps FROM workflows 
		WHERE id = $1 AND user_id = $2
	`, workflowID, claims.Username).Scan(&stepsJSON)

	if err != nil {
		if err == sql.ErrNoRows {
			// Try to retrieve from default workflows if not found in database
			workflow := getDefaultWorkflowByID(workflowID)
			if workflow.ID == "" {
				http.Error(w, "Không tìm thấy quy trình hoặc bạn không có quyền thực thi", http.StatusNotFound)
				return
			} // Convert the marshaled bytes to string			stepBytes, _ := json.Marshal(workflow.Steps)			stepsJSON = string(stepBytes)
		} else {
			http.Error(w, "Lỗi khi truy vấn quy trình làm việc", http.StatusInternalServerError)
			log.Printf("Lỗi khi query workflow từ database: %v", err)
			return
		}
	}

	// Parse steps
	var steps []string
	if err := json.Unmarshal([]byte(stepsJSON), &steps); err != nil {
		http.Error(w, "Lỗi khi xử lý các bước quy trình", http.StatusInternalServerError)
		log.Printf("Lỗi khi parse steps JSON: %v", err)
		return
	}

	// Execute each step
	results := make([]map[string]string, 0)
	for _, step := range steps {
		// Extract actual command (remove explanatory text after first occurrence of "-")
		executionStep := step
		if dashIndex := strings.Index(step, " - "); dashIndex > 0 {
			executionStep = step[:dashIndex]
		}

		// Prepare command - clean up any kubectl prefix text
		command := strings.TrimSpace(executionStep)

		// Log the execution
		log.Printf("Thực thi lệnh: %s", command)

		// Execute command
		output, err := fe.executeBotkubeCommand("kubectl", command)

		stepResult := map[string]string{
			"step":   step,
			"output": output,
		}

		if err != nil {
			stepResult["error"] = err.Error()
			log.Printf("Lỗi khi thực thi: %v", err)
		}

		results = append(results, stepResult)
	}

	// Return results
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"workflow_id": workflowID,
		"results":     results,
	})
}

// Helper function to get default workflows
func getDefaultWorkflows(userID string) []WorkflowData {
	return []WorkflowData{
		{
			ID:          "kubernetes_debugging",
			Title:       "Quy trình gỡ lỗi Kubernetes",
			Description: "Các bước chi tiết để gỡ lỗi Pod trong Kubernetes",
			Steps: []string{
				"kubectl get pods -n <namespace> - Liệt kê tất cả các pods trong namespace",
				"kubectl describe pod <pod-name> -n <namespace> - Xem thông tin chi tiết về pod cụ thể",
				"kubectl logs <pod-name> -n <namespace> - Xem logs của pod",
				"kubectl exec -it <pod-name> -n <namespace> -- /bin/bash - Kết nối vào pod để gỡ lỗi trực tiếp",
			},
			UserID:    userID,
			CreatedAt: time.Now().Format(time.RFC3339),
			IsCustom:  false,
		},
		{
			ID:          "health_checks",
			Title:       "Kiểm tra sức khỏe hệ thống",
			Description: "Các lệnh quan trọng để đánh giá trạng thái của cụm Kubernetes",
			Steps: []string{
				"kubectl get nodes - Kiểm tra trạng thái của tất cả các nodes",
				"kubectl top nodes - Xem mức sử dụng tài nguyên của các nodes",
				"kubectl get pods -A | grep -v Running - Tìm các pods không ở trạng thái Running",
				"kubectl describe events --sort-by=.metadata.creationTimestamp - Xem các sự kiện gần đây",
			},
			UserID:    userID,
			CreatedAt: time.Now().Format(time.RFC3339),
			IsCustom:  false,
		},
	}
}

// Helper function to get a default workflow by ID
func getDefaultWorkflowByID(id string) WorkflowData {
	defaultWorkflows := getDefaultWorkflows("")

	for _, workflow := range defaultWorkflows {
		if workflow.ID == id {
			return workflow
		}
	}

	return WorkflowData{}
}

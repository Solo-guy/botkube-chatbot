package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

type CommandRequest struct {
	Command string `json:"command"`
}

type CommandResponse struct {
	Output string `json:"output"`
	Error  string `json:"error,omitempty"`
}

type Event struct {
	Type      string `json:"type"`
	Resource  string `json:"resource"`
	Name      string `json:"name"`
	Namespace string `json:"namespace"`
	Cluster   string `json:"cluster"`
}

// WorkflowData represents a saved workflow
type WorkflowData struct {
	ID          string   `json:"id"`
	Title       string   `json:"title"`
	Description string   `json:"description,omitempty"`
	Steps       []string `json:"steps"`
	UserID      string   `json:"user_id"`
	CreatedAt   string   `json:"created_at,omitempty"`
	IsCustom    bool     `json:"is_custom"`
}

func SetupRouter() *mux.Router {
	router := mux.NewRouter()
	router.HandleFunc("/execute", APIHandler).Methods("POST")
	router.HandleFunc("/events", EventHandler).Methods("POST")
	router.HandleFunc("/login", FlutterLoginHandler).Methods("POST")
	router.HandleFunc("/history", HistoryHandler).Methods("GET")
	router.HandleFunc("/chat", ChatHandler).Methods("POST")

	// Add new workflow-related endpoints
	router.HandleFunc("/workflows", GetWorkflowsHandler).Methods("GET")
	router.HandleFunc("/workflows", SaveWorkflowHandler).Methods("POST")
	router.HandleFunc("/workflows/{id}", DeleteWorkflowHandler).Methods("DELETE")
	router.HandleFunc("/workflows/{id}/execute", ExecuteWorkflowHandler).Methods("POST")

	// Thêm middleware CORS
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "OPTIONS", "DELETE"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})
	handler := c.Handler(router)

	return handler.(*mux.Router)
}

func APIHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		return
	}

	var req CommandRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Dữ liệu yêu cầu không hợp lệ", http.StatusBadRequest)
		return
	}

	response := CommandResponse{
		Output: fmt.Sprintf("Nhận lệnh: %s (chuyển tới k8s-manager)", req.Command),
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(response)
}

func EventHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Chỉ cho phép phương thức POST", http.StatusMethodNotAllowed)
		return
	}

	var event Event
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		http.Error(w, "Dữ liệu sự kiện không hợp lệ", http.StatusBadRequest)
		return
	}

	log.Printf("Nhận sự kiện: %+v", event)
	w.WriteHeader(http.StatusOK)
}

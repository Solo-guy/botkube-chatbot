package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestFlutterAPIHandler(t *testing.T) {
	reqBody := `{"command": "test command"}`
	req, err := http.NewRequest("POST", "/execute", strings.NewReader(reqBody))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	// Giả lập token JWT hợp lệ (tạm thời bỏ qua middleware validateJWT để test handler)
	req.Header.Set("Authorization", "Bearer dummy_token")

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(APIHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	expected := `"output": "Nhận lệnh: test command (chuyển tới k8s-manager)"`
	if !strings.Contains(rr.Body.String(), expected) {
		t.Errorf("Handler returned unexpected body: got %v want containing %v", rr.Body.String(), expected)
	}
}

func TestFlutterEventHandler(t *testing.T) {
	reqBody := `{"type": "create", "resource": "pod", "name": "test-pod", "namespace": "default", "cluster": "test-cluster"}`
	req, err := http.NewRequest("POST", "/events", strings.NewReader(reqBody))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	// Giả lập token JWT hợp lệ (tạm thời bỏ qua middleware validateJWT để test handler)
	req.Header.Set("Authorization", "Bearer dummy_token")

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(EventHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}
}

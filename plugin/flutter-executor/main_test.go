package main

// Import các package cần thiết
import (
    "bytes"       // Xử lý buffer cho dữ liệu byte
    "encoding/json" // Xử lý mã hóa/giải mã JSON
    "net/http"     // Xử lý HTTP request/response
    "net/http/httptest" // Tạo server và request giả lập để test
    "testing"      // Framework testing của Go

    "github.com/kubeshop/botkube/pkg/api" // API của Botkube để định nghĩa plugin
    "github.com/stretchr/testify/assert"   // Thư viện assert để kiểm tra kết quả test
)

// TestAPIHandler kiểm tra chức năng của APIHandler
func TestAPIHandler(t *testing.T) {
    // Định nghĩa các test case
    tests := []struct {
        name           string        // Tên của test case
        request        CommandRequest // Dữ liệu request gửi đến API
        expectedStatus int           // Mã trạng thái HTTP mong đợi
        expectedOutput string        // Kết quả đầu ra mong đợi
    }{
        {
            name:           "Valid command",                  // Test case 1: Lệnh hợp lệ
            request:        CommandRequest{Command: Got an error: invalid character 'g' looking for beginning of object key string
            expectedStatus: http.StatusOK,                    // Mong đợi status 200
            expectedOutput: "Executing command: get pods",    // Mong đợi output đúng
        },
        {
            name:           "Invalid JSON",                   // Test case 2: JSON không hợp lệ
            request:        CommandRequest{},                 // Sẽ gửi JSON sai
            expectedStatus: http.StatusBadRequest,            // Mong đợi status 400
            expectedOutput: "Invalid request body",           // Mong đợi thông báo lỗi
        },
    }

    // Chạy từng test case
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            var body []byte
            // Chuẩn bị body cho request
            if tt.name != "Invalid JSON" {
                body, _ = json.Marshal(tt.request) // Mã hóa request thành JSON nếu hợp lệ
            } else {
                body = []byte("{invalid}") // Gửi JSON sai cho trường hợp lỗi
            }

            // Tạo HTTP request giả lập
            req, err := http.NewRequest("POST", "/execute", bytes.NewBuffer(body))
            assert.NoError(t, err) // Kiểm tra không có lỗi khi tạo request
            req.Header.Set("Content-Type", "application/json") // Đặt header Content-Type

            // Tạo response recorder để ghi lại response
            rr := httptest.NewRecorder()
            // Gọi APIHandler với request giả lập
            handler := http.HandlerFunc(APIHandler)
            handler.ServeHTTP(rr, req)

            // Kiểm tra mã trạng thái HTTP
            assert.Equal(t, tt.expectedStatus, rr.Code)
            // Nếu status là 200, kiểm tra nội dung response
            if tt.expectedStatus == http.StatusOK {
                var resp CommandResponse
                err = json.Unmarshal(rr.Body.Bytes(), &resp)
                assert.NoError(t, err) // Kiểm tra không có lỗi khi giải mã response
                assert.Equal(t, tt.expectedOutput, resp.Output) // Kiểm tra output đúng
            }
        })
    }
}

// TestExecute kiểm tra chức năng của phương thức Execute
func TestExecute(t *testing.T) {
    // Tạo instance của FlutterExecutor
    executor := NewFlutterExecutor()
    // Chuẩn bị context với input JSON
    ctx := api.ExecuteContext{
        Input: `{"command":"get pods"}`,
    }

    // Gọi phương thức Execute
    resp, err := executor.Execute(ctx)
    assert.NoError(t, err) // Kiểm tra không có lỗi
    assert.Equal(t, "Executing command: get pods", resp.Data) // Kiểm tra output đúng
}
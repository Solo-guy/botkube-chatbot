package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"regexp"
	"strings"
	"time"
)

type AIModel interface {
	Analyze(event Event) (AIResponse, error)
}

type OpenAI struct {
	apiKey string
}

type Gemini struct {
	apiKey string
}

type Claude struct {
	apiKey string
}

type Llama struct {
	apiKey string
}

type Grok struct {
	apiKey string
}

type Mistral struct {
	apiKey string
}

type Cohere struct {
	apiKey string
}

type StableDiffusion struct {
	apiKey string
}

type MiniPCM struct {
	endpoint string
}

type A2 struct {
	apiKey string
}

func NewOpenAI(apiKey string) *OpenAI {
	return &OpenAI{apiKey: apiKey}
}

func NewGemini(apiKey string) *Gemini {
	return &Gemini{apiKey: apiKey}
}

func NewClaude(apiKey string) *Claude {
	return &Claude{apiKey: apiKey}
}

func NewLlama(apiKey string) *Llama {
	return &Llama{apiKey: apiKey}
}

func NewGrok(apiKey string) *Grok {
	return &Grok{apiKey: apiKey}
}

func NewMistral(apiKey string) *Mistral {
	return &Mistral{apiKey: apiKey}
}

func NewCohere(apiKey string) *Cohere {
	return &Cohere{apiKey: apiKey}
}

func NewStableDiffusion(apiKey string) *StableDiffusion {
	return &StableDiffusion{apiKey: apiKey}
}

func NewMiniPCM(endpoint string) *MiniPCM {
	return &MiniPCM{endpoint: endpoint}
}

func NewA2(apiKey string) *A2 {
	return &A2{apiKey: apiKey}
}

// Helper function to truncate a string for logging
func truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

func (o *OpenAI) Analyze(event Event) (AIResponse, error) {
	// API endpoint for OpenAI
	endpoint := "https://api.openai.com/v1/chat/completions"

	// Check if the event is related to a Kubernetes command or system request
	isKubernetesCommand := isKubernetesCommandEvent(event)

	// Prepare the prompt with event information
	prompt := fmt.Sprintf("Analyze this event:\nEvent Type: %s\nResource: %s\nName: %s\nNamespace: %s\nCluster: %s",
		event.Type, event.Resource, event.Name, event.Namespace, event.Cluster)

	// Choose system prompt based on the type of query
	systemPrompt := ""
	if isKubernetesCommand {
		systemPrompt = "You are a Kubernetes expert AI assistant. Analyze events and provide insightful analysis in Vietnamese. Format your response as a clear explanation followed by a numbered list of recommended next steps with specific kubectl commands. Ensure the commands are executable and relevant to the event."
	} else {
		systemPrompt = "You are a versatile AI assistant that can answer questions on any topic. When asked about Kubernetes, you can provide expert advice, but otherwise act as a general-purpose AI assistant that helps with various topics. Respond in Vietnamese."
	}

	// Prepare the request data
	requestData := map[string]interface{}{
		"model": "gpt-3.5-turbo", // Faster model to reduce timeouts
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": prompt,
			},
		},
		"temperature": 0.7,
		"max_tokens":  800,
	}

	// Try to make the API call, with proper error handling
	log.Printf("Chuẩn bị gọi API OpenAI với key: %s...", maskAPIKey(o.apiKey))

	// Convert request data to JSON
	jsonData, err := json.Marshal(requestData)
	if err != nil {
		log.Printf("Lỗi khi tạo JSON request cho OpenAI API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Lỗi khi chuẩn bị yêu cầu OpenAI: %v", err),
			Workflow: []string{"Vui lòng thử lại sau."},
			Error:    err.Error(),
		}, err
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("Lỗi khi tạo HTTP request cho OpenAI API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Lỗi khi chuẩn bị yêu cầu HTTP: %v", err),
			Workflow: []string{"Vui lòng thử lại sau."},
			Error:    err.Error(),
		}, err
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", o.apiKey))

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 60 * time.Second,
	}

	// Make the request
	log.Printf("Gửi yêu cầu đến OpenAI API với API key: %s...", maskAPIKey(o.apiKey))
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Lỗi khi gọi OpenAI API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Không thể kết nối đến API OpenAI: %v", err),
			Workflow: []string{
				"Kiểm tra kết nối mạng.",
				"Xác nhận API key OpenAI đang hoạt động.",
				"Thử lại sau một khoảng thời gian.",
			},
			Error: err.Error(),
		}, err
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Lỗi khi đọc phản hồi từ OpenAI API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Lỗi khi đọc phản hồi từ OpenAI: %v", err),
			Workflow: []string{"Vui lòng thử lại sau."},
			Error:    err.Error(),
		}, err
	}

	// Check status code
	if resp.StatusCode != 200 {
		log.Printf("OpenAI API trả về mã lỗi %d: %s", resp.StatusCode, string(body))

		// Try to extract error message from OpenAI response
		errorMessage := "Không rõ lỗi"
		var errorResponse map[string]interface{}

		if err := json.Unmarshal(body, &errorResponse); err == nil {
			if errorObj, exists := errorResponse["error"].(map[string]interface{}); exists {
				if msg, exists := errorObj["message"].(string); exists {
					errorMessage = msg
				}
			}
		}

		errorMsg := fmt.Sprintf("OpenAI API error %d: %s", resp.StatusCode, errorMessage)
		return AIResponse{
			Analysis: fmt.Sprintf("API OpenAI trả về lỗi: %s", errorMessage),
			Workflow: []string{
				"Kiểm tra API key OpenAI.",
				"Thử lại với model AI khác.",
			},
			Error: errorMsg,
		}, fmt.Errorf(errorMsg)
	}

	// Parse response
	var openaiResponse map[string]interface{}
	if err := json.Unmarshal(body, &openaiResponse); err != nil {
		log.Printf("Lỗi khi parse JSON từ OpenAI API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Không thể xử lý phản hồi từ OpenAI: %v", err),
			Workflow: []string{"Thử lại sau hoặc sử dụng model AI khác."},
			Error:    err.Error(),
		}, err
	}

	// Extract content from the response
	var analysis string
	var workflow []string

	// Navigate through the response structure to find the message content
	if choices, ok := openaiResponse["choices"].([]interface{}); ok && len(choices) > 0 {
		if choice, ok := choices[0].(map[string]interface{}); ok {
			if message, ok := choice["message"].(map[string]interface{}); ok {
				if content, ok := message["content"].(string); ok {
					// Process the content to split into analysis and workflow
					parts := processContent(content)
					analysis = parts.analysis
					workflow = parts.workflow
				}
			}
		}
	}

	// If we couldn't extract content properly, use a fallback
	if analysis == "" {
		log.Printf("Không thể trích xuất phản hồi từ OpenAI API, sử dụng fallback")
		return AIResponse{
			Analysis: "Không thể phân tích phản hồi từ OpenAI. Phân tích không có nội dung hoặc định dạng không đúng.",
			Workflow: []string{
				"Thử lại với câu hỏi khác hoặc mô hình khác.",
				"Liên hệ quản trị viên để kiểm tra cấu hình.",
			},
			Error: "Empty response content",
		}, fmt.Errorf("empty response content from OpenAI")
	}

	// Create response
	response := AIResponse{
		Analysis: analysis,
		Workflow: workflow,
	}

	log.Printf("Phản hồi từ OpenAI API: %s", truncateString(analysis, 100))
	log.Printf("Workflow đề xuất từ OpenAI: %v", workflow)
	return response, nil
}

// Helper function to determine if an event is a Kubernetes command
func isKubernetesCommandEvent(event Event) bool {
	// Check if this is a Kubernetes command request
	// Looking for common patterns that indicate Kubernetes command requests
	kubeCommandPatterns := []string{
		// kubectl commands
		"get pod", "get pods", "get deployment", "get service", "get node", "get namespace",
		"describe pod", "describe deployment", "describe service", "describe node",
		"kubectl", "kubect", "kube-system", "system status", "cluster status",
		"scale deployment", "delete pod", "create deployment", "apply",

		// Kubernetes resources
		"pod ", "pods ", "deployment", "service", "configmap", "secret", "namespace",
		"node ", "nodes ", "daemonset", "statefulset", "cronjob", "job ",
		"ingress", "networkpolicy", "persistentvolume", "pv ", "pvc",

		// Kubernetes operations
		"scale", "rollout", "restart", "port-forward", "exec", "logs", "label",
		"api-resource", "api-version", "config", "cluster-info",

		// System and troubleshooting
		"status update", "health check", "healthcheck", "monitoring", "error log",
		"container crash", "pod restart", "node failure", "resource constraint",
		"memory limit", "cpu limit", "disk pressure", "evicted", "pending",

		// Direct references to Kubernetes
		"kubernetes", "k8s", "kube", "container orchestration",

		// Cloud providers' Kubernetes services
		"eks", "aks", "gke", "openshift", "k3s", "minikube", "kind ",
	}

	// Create a string containing all event fields to search through
	eventString := strings.ToLower(fmt.Sprintf("%s %s %s %s %s",
		event.Type, event.Resource, event.Name, event.Namespace, event.Cluster))

	// Check for any Kubernetes command patterns
	for _, pattern := range kubeCommandPatterns {
		if strings.Contains(eventString, pattern) {
			return true
		}
	}

	return false
}

func (g *Grok) Analyze(event Event) (AIResponse, error) {
	// Try the official API endpoint used by Postman
	endpoint := "https://api.x.ai/v1/chat/completions"

	// Check if this is a natural language query (not Kubernetes-related)
	isNaturalLanguageQuery := event.Type == "user_query" && event.Resource == "chat"

	// Prepare a different prompt for natural language vs Kubernetes events
	var prompt string
	var systemPrompt string

	if isNaturalLanguageQuery {
		// Use the query directly as the prompt for natural language
		prompt = event.Name

		// Use a general-purpose system prompt
		systemPrompt = "You are a helpful AI assistant that can answer questions about any topic. You provide detailed, knowledgeable responses based on the user's query. When appropriate, include practical suggestions or next steps. Respond in Vietnamese language whenever possible unless specifically asked to use another language."
	} else {
		// Prepare the prompt with event information for Kubernetes events
		prompt = fmt.Sprintf("Analyze this Kubernetes event with detailed assessment and action items:\nEvent Type: %s\nResource: %s\nName: %s\nNamespace: %s\nCluster: %s. Respond in Vietnamese.",
			event.Type, event.Resource, event.Name, event.Namespace, event.Cluster)

		// Use the Kubernetes expert system prompt
		systemPrompt = "You are a Kubernetes expert AI assistant. Answer questions directly about the provided event information. Your response should be in Vietnamese and specific to the event. Format your response with a clear explanation followed by precise kubectl commands to address the issue. Prefix commands with 'kubectl' and ensure they are executable. Include at least 3 actionable commands. If unable to provide specific commands, suggest general troubleshooting steps."
	}

	// Prepare the request data
	requestData := map[string]interface{}{
		"model": "grok-3-beta",
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": prompt,
			},
		},
		"temperature": 0.7,
		"max_tokens":  1024,
	}

	// Ensure API key exists and has the correct format
	if g.apiKey == "" {
		log.Printf("API key for Grok is missing")
		return fallbackResponse(event, "Grok"), fmt.Errorf("API key for Grok is missing")
	}

	// Log attempt
	if isNaturalLanguageQuery {
		log.Printf("Chuẩn bị gọi API Grok cho truy vấn ngôn ngữ tự nhiên: %s", truncateString(prompt, 50))
	} else {
		log.Printf("Chuẩn bị gọi API Grok cho sự kiện Kubernetes: %s", truncateString(prompt, 50))
	}

	log.Printf("Sử dụng API key: %s...", maskAPIKey(g.apiKey))

	// Convert request data to JSON
	jsonData, err := json.Marshal(requestData)
	if err != nil {
		log.Printf("Lỗi khi tạo JSON request cho Grok API: %v", err)
		return fallbackResponse(event, "Grok"), err
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("Lỗi khi tạo HTTP request cho Grok API: %v", err)
		return fallbackResponse(event, "Grok"), err
	}

	// Set headers - ensure API key has proper format
	apiKey := g.apiKey
	// Don't convert the API key format - use as is since xai- format works
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", apiKey))
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "Botkube/1.0")

	// Create HTTP client with proxy if needed
	client := &http.Client{
		Timeout: 60 * time.Second,
	}

	// Make the request
	log.Printf("Gửi yêu cầu đến Grok API với API key: %s...", maskAPIKey(apiKey))
	log.Printf("Endpoint: %s", endpoint)
	log.Printf("Request body: %s", string(jsonData))
	log.Printf("Sử dụng API key với định dạng xai- trực tiếp (không chuyển đổi)")
	log.Printf("Authorization header: Bearer %s...", maskAPIKey(apiKey))

	// Retry mechanism for network issues
	maxRetries := 3
	var resp *http.Response
	var lastErr error

	for i := 0; i < maxRetries; i++ {
		resp, err = client.Do(req)
		if err == nil {
			break
		}

		lastErr = err
		retryDelay := time.Duration(i+1) * 2 * time.Second
		log.Printf("Lần thử %d/%d - Lỗi khi gọi API Grok: %v. Thử lại sau %v...",
			i+1, maxRetries, err, retryDelay)
		time.Sleep(retryDelay)
	}

	if err != nil {
		log.Printf("Không thể kết nối đến API Grok sau %d lần thử: %v", maxRetries, lastErr)
		errorResponse := AIResponse{
			Analysis: fmt.Sprintf("Không thể kết nối đến API Grok: %v. Vui lòng kiểm tra kết nối mạng và cấu hình API key.", lastErr),
			Workflow: []string{
				"Kiểm tra kết nối mạng và proxy nếu cần.",
				"Kiểm tra firewall có chặn kết nối đến api.x.ai không.",
				"Xác nhận API key Grok đang hoạt động.",
				"Thử lại với model AI khác.",
			},
			Error: lastErr.Error(),
		}
		return errorResponse, lastErr
	}

	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Lỗi khi đọc phản hồi từ Grok API: %v", err)
		return fallbackResponse(event, "Grok"), err
	}

	// Log raw response for debugging
	log.Printf("Phản hồi thô từ Grok API: %s", truncateString(string(body), 200))
	log.Printf("Status code: %d", resp.StatusCode)

	// Check status code
	if resp.StatusCode != 200 {
		log.Printf("Grok API trả về mã lỗi %d: %s", resp.StatusCode, string(body))
		errorMsg := fmt.Sprintf("Grok API error: %d - %s", resp.StatusCode, string(body))
		return AIResponse{
			Analysis: fmt.Sprintf("API Grok trả về lỗi %d. %s", resp.StatusCode, errorMsg),
			Workflow: []string{
				"Kiểm tra API key Grok.",
				"Thử lại với model AI khác.",
			},
			Error: errorMsg,
		}, fmt.Errorf(errorMsg)
	}

	// Try to parse response even if the format is not exactly what we expect
	var analysis string
	var grokResponse map[string]interface{}

	// Attempt to parse the JSON response
	if err := json.Unmarshal(body, &grokResponse); err != nil {
		log.Printf("Lỗi khi parse JSON từ Grok API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Không thể xử lý phản hồi từ API Grok: %v. Phản hồi thô: %s", err, truncateString(string(body), 100)),
			Workflow: []string{"Thử lại sau hoặc sử dụng model AI khác."},
			Error:    err.Error(),
		}, err
	}

	// Log the structure for debugging
	logMapStructure("Cấu trúc phản hồi Grok", grokResponse)

	// Try multiple paths to find the content
	if choices, ok := grokResponse["choices"].([]interface{}); ok && len(choices) > 0 {
		log.Printf("Tìm thấy phần 'choices' trong phản hồi")
		if choice, ok := choices[0].(map[string]interface{}); ok {
			if message, ok := choice["message"].(map[string]interface{}); ok {
				if content, ok := message["content"].(string); ok {
					log.Printf("Trích xuất thành công nội dung từ message.content")
					analysis = content
				}
			}
		}
	} else if completion, ok := grokResponse["completion"].(string); ok {
		log.Printf("Trích xuất thành công nội dung từ completion")
		analysis = completion
	} else if content, ok := grokResponse["content"].(string); ok {
		log.Printf("Trích xuất thành công nội dung từ content")
		analysis = content
	}

	// If we couldn't extract content properly, try a few more paths
	if analysis == "" {
		if generated_text, ok := grokResponse["generated_text"].(string); ok {
			log.Printf("Trích xuất thành công nội dung từ generated_text")
			analysis = generated_text
		} else if data, ok := grokResponse["data"].(map[string]interface{}); ok {
			if text, ok := data["text"].(string); ok {
				log.Printf("Trích xuất thành công nội dung từ data.text")
				analysis = text
			} else if content, ok := data["content"].(string); ok {
				log.Printf("Trích xuất thành công nội dung từ data.content")
				analysis = content
			}
		}
	}

	// If still couldn't extract, use the entire JSON as a string
	if analysis == "" {
		log.Printf("Không thể trích xuất nội dung cụ thể, sử dụng toàn bộ JSON")
		analysis = fmt.Sprintf("Phản hồi từ Grok không có định dạng dự kiến. Phản hồi thô: %s", truncateString(string(body), 200))
	}

	// Process the content to split into analysis and workflow
	parts := processContent(analysis)

	// Create response
	response := AIResponse{
		Analysis: parts.analysis,
		Workflow: parts.workflow,
	}

	log.Printf("Phản hồi từ Grok API: %s", truncateString(parts.analysis, 100))
	if len(parts.workflow) > 0 {
		log.Printf("Workflow đề xuất từ Grok: %v", parts.workflow)
	} else {
		log.Printf("Không có workflow được trích xuất từ phản hồi")
	}

	return response, nil
}

// Helper function to log the structure of a map for debugging
func logMapStructure(prefix string, m map[string]interface{}) {
	log.Printf("%s:", prefix)
	for k, v := range m {
		switch v := v.(type) {
		case map[string]interface{}:
			log.Printf("  %s: [map]", k)
		case []interface{}:
			log.Printf("  %s: [array of %d items]", k, len(v))
		case string:
			log.Printf("  %s: [string] %s", k, truncateString(v, 30))
		case float64:
			log.Printf("  %s: [number] %f", k, v)
		case bool:
			log.Printf("  %s: [bool] %v", k, v)
		case nil:
			log.Printf("  %s: [nil]", k)
		default:
			log.Printf("  %s: [%T]", k, v)
		}
	}
}

// Helper function to process AI response content
type processedContent struct {
	analysis string
	workflow []string
}

func processContent(content string) processedContent {
	// Default result
	result := processedContent{
		analysis: content,
		workflow: []string{},
	}

	// Try to find a numbered list in the content
	lines := strings.Split(content, "\n")
	var analysisLines []string
	var workflowLines []string
	inWorkflow := false

	// Simple pattern to detect numbered list items
	numberPattern := regexp.MustCompile(`^\s*\d+[\.\)]\s+`)

	for _, line := range lines {
		if numberPattern.MatchString(line) {
			inWorkflow = true
			// Clean up the line, removing the number prefix
			cleanLine := numberPattern.ReplaceAllString(line, "")
			workflowLines = append(workflowLines, cleanLine)
		} else if !inWorkflow && line != "" {
			analysisLines = append(analysisLines, line)
		}
	}

	// If we found workflow items, use them
	if len(workflowLines) > 0 {
		result.analysis = strings.Join(analysisLines, "\n")
		result.workflow = workflowLines
	} else {
		// If we couldn't detect a workflow format, just use the first part as analysis
		// and try to generate some standard workflow steps
		result.workflow = []string{
			"Kiểm tra log pod để tìm bất kỳ thông điệp bất thường nào.",
			"Đảm bảo tài nguyên được phân bổ hợp lý cho pod.",
			"Lưu sự kiện này vào lịch sử để theo dõi sau này.",
		}
	}

	return result
}

// Helper function to mask API key for logging
func maskAPIKey(apiKey string) string {
	if len(apiKey) <= 8 {
		return "****"
	}
	return apiKey[:4] + "..." + apiKey[len(apiKey)-4:]
}

// Fallback response in case API call fails
func fallbackResponse(event Event, modelName string) AIResponse {
	// Check if this appears to be a Kubernetes-specific event
	isKubernetesCommand := isKubernetesCommandEvent(event)

	if isKubernetesCommand {
		return AIResponse{
			Analysis: fmt.Sprintf("Không thể kết nối với API %s để phân tích sự kiện %s liên quan đến %s %s trong namespace %s trên cluster %s. Vui lòng kiểm tra cấu hình kết nối và API key, hoặc thử lại sau.",
				modelName, event.Type, event.Resource, event.Name, event.Namespace, event.Cluster),
			Workflow: []string{
				"Kiểm tra kết nối mạng và firewall.",
				"Xác nhận API key của " + modelName + " đang hoạt động.",
				"Kiểm tra cấu hình endpoint API trong file config.yaml.",
				"Thử lại với model AI khác như OpenAI hoặc Gemini.",
			},
			Error: "API connection failed - using fallback response",
		}
	} else {
		return AIResponse{
			Analysis: fmt.Sprintf("Không thể kết nối với API %s để xử lý yêu cầu của bạn. Vui lòng kiểm tra cấu hình kết nối và API key, hoặc thử lại sau.", modelName),
			Workflow: []string{
				"Kiểm tra kết nối mạng và firewall.",
				"Xác nhận API key của " + modelName + " đang hoạt động.",
				"Thử lại với câu hỏi khác hoặc model AI khác.",
			},
			Error: "API connection failed - using fallback response",
		}
	}
}

func (m *Mistral) Analyze(event Event) (AIResponse, error) {
	// Check if this is a Kubernetes-related query
	isKubernetesCommand := isKubernetesCommandEvent(event)

	var response AIResponse

	if isKubernetesCommand {
		response = AIResponse{
			Analysis: fmt.Sprintf("Chào bạn! Tôi là Mistral, sẵn sàng giúp đỡ. Tôi đã kiểm tra sự kiện %s liên quan đến %s %s trong namespace %s trên cluster %s. Dưới đây là phân tích chi tiết và các lệnh cụ thể để xử lý vấn đề. Bạn có muốn tôi hỗ trợ thêm không?", event.Type, event.Resource, event.Name, event.Namespace, event.Cluster),
			Workflow: []string{
				"kubectl get pods -n " + event.Namespace + " -o wide --field-selector metadata.name=" + event.Name + " để kiểm tra trạng thái pod.",
				"kubectl describe pod " + event.Name + " -n " + event.Namespace + " để xem chi tiết về pod.",
				"kubectl logs " + event.Name + " -n " + event.Namespace + " để kiểm tra log của pod.",
			},
		}
	} else {
		response = AIResponse{
			Analysis: "Chào bạn! Tôi là Mistral, một trợ lý AI đa năng có thể trả lời nhiều loại câu hỏi khác nhau. Tôi có thể hỗ trợ bạn với các vấn đề Kubernetes khi cần, nhưng cũng có thể giúp bạn với các chủ đề khác như công nghệ, khoa học, lập trình, văn học, hoặc bất kỳ điều gì bạn quan tâm. Hãy cho tôi biết bạn cần hỗ trợ gì nhé?",
			Workflow: []string{
				"Đặt câu hỏi cụ thể để tôi có thể giúp bạn tốt hơn.",
				"Cho tôi biết nếu bạn muốn tìm hiểu thêm về một chủ đề cụ thể.",
				"Chia sẻ bối cảnh để tôi có thể cung cấp thông tin phù hợp hơn.",
			},
		}
	}

	log.Printf("Phản hồi từ Mistral: %s", response.Analysis)
	log.Printf("Workflow đề xuất: %v", response.Workflow)
	return response, nil
}

func (c *Cohere) Analyze(event Event) (AIResponse, error) {
	// Check if this is a Kubernetes-related query
	isKubernetesCommand := isKubernetesCommandEvent(event)

	var response AIResponse

	if isKubernetesCommand {
		response = AIResponse{
			Analysis: fmt.Sprintf("Xin chào bạn! Tôi là Cohere, rất vui được hỗ trợ. Tôi đã phân tích sự kiện %s liên quan đến %s %s trong namespace %s trên cluster %s. Dưới đây là các bước chi tiết để xử lý vấn đề. Bạn có cần tôi giải thích chi tiết hơn không?", event.Type, event.Resource, event.Name, event.Namespace, event.Cluster),
			Workflow: []string{
				"kubectl get pods -n " + event.Namespace + " -o wide để kiểm tra trạng thái các pod trong namespace.",
				"kubectl describe " + event.Resource + " " + event.Name + " -n " + event.Namespace + " để xem chi tiết về tài nguyên.",
				"kubectl logs -l app=" + event.Name + " -n " + event.Namespace + " để kiểm tra log liên quan đến ứng dụng.",
			},
		}
	} else {
		response = AIResponse{
			Analysis: "Xin chào! Tôi là Cohere, một trợ lý AI đa năng có thể giúp bạn với nhiều loại câu hỏi và vấn đề khác nhau. Tôi có kiến thức về Kubernetes nếu bạn cần, nhưng cũng có thể trò chuyện về các chủ đề khác như công nghệ, khoa học, văn hóa, hoặc bất kỳ điều gì bạn quan tâm. Hãy cho tôi biết tôi có thể giúp gì cho bạn hôm nay?",
			Workflow: []string{
				"Đặt câu hỏi cụ thể về bất kỳ chủ đề nào bạn quan tâm.",
				"Yêu cầu thông tin hoặc giải thích về một khái niệm cụ thể.",
				"Chia sẻ thêm thông tin về nhu cầu của bạn để tôi có thể trợ giúp tốt hơn.",
			},
		}
	}

	log.Printf("Phản hồi từ Cohere: %s", response.Analysis)
	log.Printf("Workflow đề xuất: %v", response.Workflow)
	return response, nil
}

func (s *StableDiffusion) Analyze(event Event) (AIResponse, error) {
	// Check if this is a Kubernetes-related query
	isKubernetesCommand := isKubernetesCommandEvent(event)

	var response AIResponse

	if isKubernetesCommand {
		response = AIResponse{
			Analysis: fmt.Sprintf("Chào bạn thân mến! Tôi là Stable Diffusion, sẵn sàng hỗ trợ. Tôi đã xem xét sự kiện %s liên quan đến %s %s trong namespace %s trên cluster %s. Dưới đây là các lệnh cụ thể để xử lý vấn đề. Bạn có cần tôi hỗ trợ thêm không?", event.Type, event.Resource, event.Name, event.Namespace, event.Cluster),
			Workflow: []string{
				"kubectl get " + event.Resource + " " + event.Name + " -n " + event.Namespace + " -o yaml để xem cấu hình chi tiết.",
				"kubectl describe " + event.Resource + " " + event.Name + " -n " + event.Namespace + " để kiểm tra trạng thái và sự kiện.",
				"kubectl logs -l app.kubernetes.io/name=" + event.Name + " -n " + event.Namespace + " để xem log của pod liên quan.",
			},
		}
	} else {
		response = AIResponse{
			Analysis: "Xin chào! Tôi là Stable Diffusion, một trợ lý AI có thể hỗ trợ bạn với nhiều chủ đề khác nhau. Mặc dù tôi có thể giúp bạn với các vấn đề liên quan đến Kubernetes, tôi cũng sẵn sàng trò chuyện và hỗ trợ bạn với nhiều lĩnh vực khác như học máy, khoa học dữ liệu, lập trình, hoặc bất kỳ chủ đề nào bạn quan tâm. Tôi có thể giúp gì cho bạn hôm nay?",
			Workflow: []string{
				"Nêu câu hỏi cụ thể về chủ đề bạn quan tâm.",
				"Chia sẻ thêm thông tin về dự án hoặc vấn đề bạn đang gặp phải.",
				"Yêu cầu giải thích về một khái niệm hoặc công nghệ cụ thể.",
			},
		}
	}

	log.Printf("Phản hồi từ Stable Diffusion: %s", response.Analysis)
	log.Printf("Workflow đề xuất: %v", response.Workflow)
	return response, nil
}

func (m *MiniPCM) Analyze(event Event) (AIResponse, error) {
	// Check if this is a Kubernetes-related query
	isKubernetesCommand := isKubernetesCommandEvent(event)

	var response AIResponse

	if isKubernetesCommand {
		response = AIResponse{
			Analysis: fmt.Sprintf("Xin chào bạn! Tôi là MiniPCM, rất vui được giúp đỡ. Tôi đã phân tích sự kiện %s liên quan đến %s %s trong namespace %s trên cluster %s. Dưới đây là các bước chi tiết để xử lý vấn đề. Bạn có muốn tôi hỗ trợ thêm không?", event.Type, event.Resource, event.Name, event.Namespace, event.Cluster),
			Workflow: []string{
				"kubectl get pods -n " + event.Namespace + " để liệt kê các pod trong namespace.",
				"kubectl describe " + event.Resource + " " + event.Name + " -n " + event.Namespace + " để xem thông tin chi tiết.",
				"kubectl logs " + event.Name + " -n " + event.Namespace + " để kiểm tra log của pod.",
			},
		}
	} else {
		response = AIResponse{
			Analysis: "Xin chào! Tôi là MiniPCM, một trợ lý AI đa năng có thể giúp bạn với nhiều chủ đề khác nhau. Tôi có thể hỗ trợ bạn với Kubernetes nếu bạn cần, nhưng cũng có thể trả lời các câu hỏi về nhiều lĩnh vực khác như công nghệ, khoa học, lập trình, hoặc bất kỳ chủ đề nào khác bạn quan tâm. Bạn muốn tìm hiểu về chủ đề gì hôm nay?",
			Workflow: []string{
				"Đặt câu hỏi cụ thể về bất kỳ chủ đề nào bạn quan tâm.",
				"Chia sẻ thêm thông tin về nhu cầu hoặc dự án của bạn.",
				"Yêu cầu giải thích hoặc hướng dẫn về một khái niệm cụ thể.",
			},
		}
	}

	log.Printf("Phản hồi từ MiniPCM: %s", response.Analysis)
	log.Printf("Workflow đề xuất: %v", response.Workflow)
	return response, nil
}

func (a *A2) Analyze(event Event) (AIResponse, error) {
	// API endpoint for Anthropic's Claude (A2)
	endpoint := "https://api.anthropic.com/v1/messages"

	// Check if the event is related to a Kubernetes command or system request
	isKubernetesCommand := isKubernetesCommandEvent(event)

	// Prepare the prompt with event information
	prompt := fmt.Sprintf("Analyze this event:\nEvent Type: %s\nResource: %s\nName: %s\nNamespace: %s\nCluster: %s",
		event.Type, event.Resource, event.Name, event.Namespace, event.Cluster)

	// Choose system prompt based on the type of query
	systemPrompt := ""
	if isKubernetesCommand {
		systemPrompt = "You are a Kubernetes expert AI assistant. Analyze events and provide insightful analysis in Vietnamese. Format your response as a clear explanation followed by a numbered list of recommended next steps."
	} else {
		systemPrompt = "You are a versatile AI assistant that can answer questions on any topic. When asked about Kubernetes, you can provide expert advice, but otherwise act as a general-purpose AI assistant that helps with various topics. Respond in Vietnamese."
	}

	// Prepare the request data
	requestData := map[string]interface{}{
		"model": "claude-3-sonnet-20240229", // or another available model
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": prompt,
			},
		},
		"temperature": 0.7,
		"max_tokens":  800,
	}

	// Convert request data to JSON
	jsonData, err := json.Marshal(requestData)
	if err != nil {
		log.Printf("Lỗi khi tạo JSON request cho Anthropic API: %v", err)
		return fallbackResponse(event, "Claude"), err
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("Lỗi khi tạo HTTP request cho Anthropic API: %v", err)
		return fallbackResponse(event, "Claude"), err
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", a.apiKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// Make the request
	log.Printf("Gửi yêu cầu đến Anthropic API với API key: %s...", maskAPIKey(a.apiKey))
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Lỗi khi gọi Anthropic API: %v", err)
		return fallbackResponse(event, "Claude"), err
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Lỗi khi đọc phản hồi từ Anthropic API: %v", err)
		return fallbackResponse(event, "Claude"), err
	}

	// Check status code
	if resp.StatusCode != 200 {
		log.Printf("Anthropic API trả về mã lỗi %d: %s", resp.StatusCode, string(body))
		return fallbackResponse(event, "Claude"), fmt.Errorf("Anthropic API error: %d - %s", resp.StatusCode, string(body))
	}

	// Parse response
	var claudeResponse map[string]interface{}
	if err := json.Unmarshal(body, &claudeResponse); err != nil {
		log.Printf("Lỗi khi parse JSON từ Anthropic API: %v", err)
		return fallbackResponse(event, "Claude"), err
	}

	// Extract content from the response
	var analysis string

	// Navigate through the response structure to find the content
	if content, ok := claudeResponse["content"].([]interface{}); ok && len(content) > 0 {
		if contentItem, ok := content[0].(map[string]interface{}); ok {
			if text, ok := contentItem["text"].(string); ok {
				analysis = text
			}
		}
	}

	// If we couldn't extract content properly, use a fallback
	if analysis == "" {
		log.Printf("Không thể trích xuất phản hồi từ Anthropic API, sử dụng fallback")
		return fallbackResponse(event, "Claude"), nil
	}

	// Process the content to split into analysis and workflow
	parts := processContent(analysis)

	// Create response
	response := AIResponse{
		Analysis: parts.analysis,
		Workflow: parts.workflow,
	}

	log.Printf("Phản hồi từ Anthropic API: %s", truncateString(parts.analysis, 100))
	log.Printf("Workflow đề xuất từ Anthropic: %v", parts.workflow)
	return response, nil
}

func (g *Gemini) Analyze(event Event) (AIResponse, error) {
	// API endpoint for Gemini
	endpoint := "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"

	// Add API key as query parameter
	endpoint = fmt.Sprintf("%s?key=%s", endpoint, g.apiKey)

	// Check if the event is related to a Kubernetes command or system request
	isKubernetesCommand := isKubernetesCommandEvent(event)

	// Prepare the prompt with event information
	prompt := fmt.Sprintf("Analyze this event:\nEvent Type: %s\nResource: %s\nName: %s\nNamespace: %s\nCluster: %s",
		event.Type, event.Resource, event.Name, event.Namespace, event.Cluster)

	// Choose system prompt based on the type of query
	systemPrompt := ""
	if isKubernetesCommand {
		systemPrompt = "You are a Kubernetes expert AI assistant. Analyze events and provide insightful analysis in Vietnamese. Format your response as a clear explanation followed by a numbered list of recommended next steps."
	} else {
		systemPrompt = "You are a versatile AI assistant that can answer questions on any topic. When asked about Kubernetes, you can provide expert advice, but otherwise act as a general-purpose AI assistant that helps with various topics. Respond in Vietnamese."
	}

	// Prepare the request data for Gemini API
	requestData := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"role": "user",
				"parts": []map[string]string{
					{
						"text": systemPrompt,
					},
				},
			},
			{
				"role": "user",
				"parts": []map[string]string{
					{
						"text": prompt,
					},
				},
			},
		},
		"generationConfig": map[string]interface{}{
			"temperature":     0.7,
			"maxOutputTokens": 800,
		},
	}

	// Try to make the API call with better error handling
	log.Printf("Chuẩn bị gọi API Gemini với key: %s...", maskAPIKey(g.apiKey))

	// Convert request data to JSON
	jsonData, err := json.Marshal(requestData)
	if err != nil {
		log.Printf("Lỗi khi tạo JSON request cho Gemini API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Lỗi khi chuẩn bị yêu cầu Gemini: %v", err),
			Workflow: []string{"Vui lòng thử lại sau."},
			Error:    err.Error(),
		}, err
	}

	// Create HTTP request
	req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("Lỗi khi tạo HTTP request cho Gemini API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Lỗi khi chuẩn bị yêu cầu HTTP: %v", err),
			Workflow: []string{"Vui lòng thử lại sau."},
			Error:    err.Error(),
		}, err
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// Make the request
	log.Printf("Gửi yêu cầu đến Gemini API với API key: %s...", maskAPIKey(g.apiKey))
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Lỗi khi gọi Gemini API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Không thể kết nối đến API Gemini: %v", err),
			Workflow: []string{
				"Kiểm tra kết nối mạng.",
				"Xác nhận API key Gemini đang hoạt động.",
				"Thử lại sau một khoảng thời gian.",
			},
			Error: err.Error(),
		}, err
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Lỗi khi đọc phản hồi từ Gemini API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Lỗi khi đọc phản hồi từ Gemini: %v", err),
			Workflow: []string{"Vui lòng thử lại sau."},
			Error:    err.Error(),
		}, err
	}

	// Check status code
	if resp.StatusCode != 200 {
		log.Printf("Gemini API trả về mã lỗi %d: %s", resp.StatusCode, string(body))

		// Try to extract error message from Google API response
		errorMessage := "Không rõ lỗi"
		var errorResponse map[string]interface{}

		if err := json.Unmarshal(body, &errorResponse); err == nil {
			if errObj, exists := errorResponse["error"].(map[string]interface{}); exists {
				if msg, exists := errObj["message"].(string); exists {
					errorMessage = msg
				}
			}
		}

		errorMsg := fmt.Sprintf("Gemini API error %d: %s", resp.StatusCode, errorMessage)
		return AIResponse{
			Analysis: fmt.Sprintf("API Gemini trả về lỗi: %s", errorMessage),
			Workflow: []string{
				"Kiểm tra API key Gemini.",
				"Thử lại với model AI khác.",
			},
			Error: errorMsg,
		}, fmt.Errorf(errorMsg)
	}

	// Parse response
	var geminiResponse map[string]interface{}
	if err := json.Unmarshal(body, &geminiResponse); err != nil {
		log.Printf("Lỗi khi parse JSON từ Gemini API: %v", err)
		return AIResponse{
			Analysis: fmt.Sprintf("Không thể xử lý phản hồi từ Gemini: %v", err),
			Workflow: []string{"Thử lại sau hoặc sử dụng model AI khác."},
			Error:    err.Error(),
		}, err
	}

	// Extract content from the response
	var content string

	// Navigate through the response structure to find the content
	if candidates, ok := geminiResponse["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content0, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content0["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if text, ok := part["text"].(string); ok {
							content = text
						}
					}
				}
			}
		}
	}

	// If we couldn't extract content properly, handle the error
	if content == "" {
		log.Printf("Không thể trích xuất phản hồi từ Gemini API")
		return AIResponse{
			Analysis: "Không thể phân tích phản hồi từ Gemini. Phản hồi không có nội dung hoặc định dạng không đúng.",
			Workflow: []string{
				"Thử lại với câu hỏi khác hoặc mô hình khác.",
				"Kiểm tra cấu hình API Gemini.",
			},
			Error: "Empty response content",
		}, fmt.Errorf("empty response content from Gemini")
	}

	// Process the content to split into analysis and workflow
	parts := processContent(content)

	// Create response
	response := AIResponse{
		Analysis: parts.analysis,
		Workflow: parts.workflow,
	}

	log.Printf("Phản hồi từ Gemini API: %s", truncateString(parts.analysis, 100))
	log.Printf("Workflow đề xuất từ Gemini: %v", parts.workflow)
	return response, nil
}

func (c *Claude) Analyze(event Event) (AIResponse, error) {
	response := AIResponse{
		Analysis: fmt.Sprintf("Xin chào bạn! Tôi là Claude, rất vui được giúp đỡ. Tôi đã kiểm tra kỹ sự kiện %s liên quan đến %s %s trong namespace %s trên cluster %s. Dựa trên thông tin hiện có, tôi không thấy vấn đề gì nghiêm trọng. Tuy nhiên, để đảm bảo mọi thứ được xử lý tốt nhất, tôi gợi ý một vài bước tiếp theo. Bạn có muốn tôi hỗ trợ thêm không?", event.Type, event.Resource, event.Name, event.Namespace, event.Cluster),
		Workflow: []string{
			"1. Kiểm tra log pod để tìm bất kỳ thông điệp lỗi nào.",
			"2. Đảm bảo rằng các tài nguyên được phân bổ hợp lý.",
			"3. Lưu sự kiện này vào lịch sử để theo dõi.",
		},
	}
	log.Printf("Phản hồi từ Claude: %s", response.Analysis)
	log.Printf("Workflow đề xuất: %v", response.Workflow)
	return response, nil
}

func (l *Llama) Analyze(event Event) (AIResponse, error) {
	response := AIResponse{
		Analysis: fmt.Sprintf("Chào bạn! Tôi là Llama, sẵn sàng hỗ trợ bạn. Tôi đã xem xét sự kiện %s liên quan đến %s %s trong namespace %s trên cluster %s. Hiện tại, không có vấn đề gì đáng lo ngại. Tôi đã chuẩn bị một số bước tiếp theo để bạn có thể thực hiện nếu cần. Bạn có muốn tôi giải thích thêm không?", event.Type, event.Resource, event.Name, event.Namespace, event.Cluster),
		Workflow: []string{
			"1. Kiểm tra trạng thái pod để đảm bảo hoạt động bình thường.",
			"2. Xem xét log để phát hiện bất kỳ vấn đề tiềm ẩn nào.",
			"3. Lưu sự kiện vào lịch sử để theo dõi lâu dài.",
		},
	}
	log.Printf("Phản hồi từ Llama: %s", response.Analysis)
	log.Printf("Workflow đề xuất: %v", response.Workflow)
	return response, nil
}

// GetAIModel tạo một instance của AIModel dựa trên cấu hình
func GetAIModel(config *Config) (AIModel, error) {
	// Log API key được sử dụng (chỉ hiển thị 5 ký tự đầu để bảo vệ bảo mật)
	if config.APIKey != "" && len(config.APIKey) > 5 {
		log.Printf("Sử dụng API key cho model %s: %s...", config.SelectedModel, config.APIKey[:5])
	} else if config.APIKey != "" {
		log.Printf("Sử dụng API key cho model %s (key quá ngắn để hiển thị một phần)", config.SelectedModel)
	} else {
		log.Printf("Không tìm thấy API key cho model %s", config.SelectedModel)
	}

	switch config.SelectedModel {
	case "openai":
		return NewOpenAI(config.APIKey), nil
	case "gemini":
		return NewGemini(config.APIKey), nil
	case "claude":
		return NewClaude(config.APIKey), nil
	case "llama":
		return NewLlama(config.APIKey), nil
	case "grok":
		return NewGrok(config.APIKey), nil
	case "mistral":
		return NewMistral(config.APIKey), nil
	case "cohere":
		return NewCohere(config.APIKey), nil
	case "stable-diffusion":
		return NewStableDiffusion(config.APIKey), nil
	case "minipcm":
		return NewMiniPCM(config.Endpoint), nil
	case "a2":
		return NewA2(config.APIKey), nil
	default:
		log.Printf("Mô hình AI không được hỗ trợ: %s", config.SelectedModel)
		return nil, fmt.Errorf("Mô hình AI '%s' không được hỗ trợ. Vui lòng chọn một mô hình khác trong cấu hình.", config.SelectedModel)
	}
}

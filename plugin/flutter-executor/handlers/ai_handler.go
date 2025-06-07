package handlers

import (
	"fmt"
	"log"
	"regexp"
	"strings"
)

// ProcessKubernetesEvent handles Kubernetes-related queries
func (h *AIHandler) ProcessKubernetesEvent(event Event) (*Response, error) {
	// Get AI analysis of the command
	analysis, err := h.aiClient.Analyze(event.Name)
	if err != nil {
		log.Printf("Warning: Error getting AI analysis: %v", err)
		return &Response{
			Success: false,
			Error:   fmt.Sprintf("Lỗi khi phân tích lệnh: %v", err),
		}, nil
	}

	// Generate workflow steps based on the command type
	workflow, err := h.generateKubernetesWorkflow(event.Name)
	if err != nil {
		log.Printf("Warning: Error generating workflow: %v", err)
		workflow = []string{}
	}

	// Return the AI analysis directly
	return &Response{
		Success:  true,
		Response: analysis,
		Workflow: workflow,
	}, nil
}

// generateKubernetesWorkflow creates appropriate workflow steps
func (h *AIHandler) generateKubernetesWorkflow(query string) ([]string, error) {
	// Get command-specific steps from AI
	specificSteps, err := h.aiClient.GenerateWorkflow(query)
	if err != nil {
		return nil, fmt.Errorf("error generating workflow: %v", err)
	}

	// Filter out empty or generic steps
	var filteredSteps []string
	for _, step := range specificSteps {
		if step = strings.TrimSpace(step); step != "" {
			filteredSteps = append(filteredSteps, step)
		}
	}

	// If no specific steps were returned or they're too generic,
	// provide helpful Kubernetes commands with proper formatting
	if len(filteredSteps) == 0 || isGenericWorkflow(filteredSteps) {
		queryLower := strings.ToLower(query)

		// Create specific workflow based on the query type
		if strings.Contains(queryLower, "pod") ||
			strings.Contains(queryLower, "pods") ||
			strings.Contains(queryLower, "kiểm tra pod") {
			return []string{
				"# Liệt kê tất cả pods trong namespace hiện tại\nkubectl get pods",
				"# Xem chi tiết về một pod cụ thể\nkubectl describe pod pod-name",
				"# Xem logs của pod (thêm -f để theo dõi logs trong thời gian thực)\nkubectl logs pod-name -f",
				"# Thực thi shell trong pod\nkubectl exec -it pod-name -- /bin/bash",
				"# Kiểm tra sử dụng tài nguyên của pod\nkubectl top pod pod-name",
				"# Xóa pod khi cần thiết\nkubectl delete pod pod-name",
			}, nil
		} else if strings.Contains(queryLower, "deployment") ||
			strings.Contains(queryLower, "deploy") ||
			strings.Contains(queryLower, "triển khai") {
			return []string{
				"# Liệt kê tất cả deployments\nkubectl get deployments",
				"# Xem chi tiết về một deployment\nkubectl describe deployment deployment-name",
				"# Cập nhật deployment với image mới\nkubectl set image deployment/deployment-name container-name=new-image:tag",
				"# Xem lịch sử rollout\nkubectl rollout history deployment/deployment-name",
				"# Rollback về phiên bản trước\nkubectl rollout undo deployment/deployment-name",
				"# Scale deployment lên hoặc xuống\nkubectl scale deployment/deployment-name --replicas=3",
			}, nil
		} else if strings.Contains(queryLower, "service") ||
			strings.Contains(queryLower, "svc") ||
			strings.Contains(queryLower, "dịch vụ") {
			return []string{
				"# Liệt kê tất cả services\nkubectl get services",
				"# Xem chi tiết về một service\nkubectl describe service service-name",
				"# Tạo service mới từ deployment\nkubectl expose deployment deployment-name --port=80 --target-port=8080 --type=ClusterIP",
				"# Port forward để truy cập service cục bộ\nkubectl port-forward service/service-name 8080:80",
				"# Kiểm tra endpoints của service\nkubectl get endpoints service-name",
				"# Kiểm tra pods được liên kết với service\nkubectl get pods -l app=app-label",
			}, nil
		} else if strings.Contains(queryLower, "namespace") ||
			strings.Contains(queryLower, "ns") {
			return []string{
				"# Liệt kê tất cả namespaces\nkubectl get namespaces",
				"# Tạo namespace mới\nkubectl create namespace namespace-name",
				"# Xem tất cả tài nguyên trong namespace\nkubectl get all -n namespace-name",
				"# Chuyển namespace mặc định\nkubectl config set-context --current --namespace=namespace-name",
				"# Xóa namespace (xóa tất cả tài nguyên trong namespace)\nkubectl delete namespace namespace-name",
				"# Hiển thị resource quota của namespace\nkubectl get resourcequota -n namespace-name",
			}, nil
		} else if strings.Contains(queryLower, "log") ||
			strings.Contains(queryLower, "logs") {
			return []string{
				"# Xem logs của pod\nkubectl logs pod-name",
				"# Theo dõi logs theo thời gian thực\nkubectl logs -f pod-name",
				"# Xem logs của container cụ thể trong pod\nkubectl logs pod-name -c container-name",
				"# Xem logs trước đó\nkubectl logs --previous pod-name",
				"# Xem logs với timestamp\nkubectl logs pod-name --timestamps=true",
				"# Lọc logs với grep\nkubectl logs pod-name | grep 'error'",
			}, nil
		} else if strings.Contains(queryLower, "node") ||
			strings.Contains(queryLower, "nodes") {
			return []string{
				"# Liệt kê tất cả nodes\nkubectl get nodes",
				"# Xem chi tiết về một node\nkubectl describe node node-name",
				"# Xem trạng thái sử dụng tài nguyên của node\nkubectl top node node-name",
				"# Đánh dấu node để không lập lịch pods mới\nkubectl cordon node-name",
				"# Xóa tất cả pods khỏi node (để bảo trì)\nkubectl drain node-name --ignore-daemonsets",
				"# Đánh dấu node để có thể lập lịch pods\nkubectl uncordon node-name",
			}, nil
		} else if strings.Contains(queryLower, "ingress") {
			return []string{
				"# Liệt kê tất cả ingress\nkubectl get ingress",
				"# Xem chi tiết về một ingress\nkubectl describe ingress ingress-name",
				"# Tạo ingress từ file YAML\nkubectl apply -f ingress.yaml",
				"# Kiểm tra rules của ingress\nkubectl get ingress ingress-name -o yaml",
				"# Kiểm tra trạng thái ingress controller\nkubectl get pods -n ingress-nginx",
				"# Xem logs của ingress controller\nkubectl logs -n ingress-nginx deployment/ingress-nginx-controller",
			}, nil
		} else if strings.Contains(queryLower, "config") ||
			strings.Contains(queryLower, "configmap") {
			return []string{
				"# Liệt kê tất cả configmaps\nkubectl get configmaps",
				"# Xem chi tiết về một configmap\nkubectl describe configmap configmap-name",
				"# Tạo configmap từ file\nkubectl create configmap configmap-name --from-file=config.json",
				"# Tạo configmap từ literal\nkubectl create configmap configmap-name --from-literal=key1=value1 --from-literal=key2=value2",
				"# Xem nội dung của configmap\nkubectl get configmap configmap-name -o yaml",
				"# Chỉnh sửa configmap\nkubectl edit configmap configmap-name",
			}, nil
		} else if strings.Contains(queryLower, "secret") {
			return []string{
				"# Liệt kê tất cả secrets\nkubectl get secrets",
				"# Xem chi tiết về một secret\nkubectl describe secret secret-name",
				"# Tạo secret từ literal\nkubectl create secret generic secret-name --from-literal=key1=value1",
				"# Tạo secret từ file\nkubectl create secret generic secret-name --from-file=ssh-privatekey=~/.ssh/id_rsa",
				"# Giải mã nội dung secret\nkubectl get secret secret-name -o jsonpath='{.data.key}' | base64 --decode",
				"# Xóa secret\nkubectl delete secret secret-name",
			}, nil
		} else {
			// Default Kubernetes commands for general queries
			return []string{
				"# Liệt kê tất cả tài nguyên trong namespace hiện tại\nkubectl get all",
				"# Xem chi tiết về một pod\nkubectl describe pod pod-name",
				"# Xem logs của pod\nkubectl logs pod-name -f",
				"# Thực thi lệnh trong pod\nkubectl exec -it pod-name -- bash",
				"# Kiểm tra trạng thái health của cluster\nkubectl get componentstatuses",
				"# Xem thông tin nodes trong cluster\nkubectl get nodes -o wide",
				"# Xem metrics của pods và nodes\nkubectl top pods && kubectl top nodes",
			}, nil
		}
	}

	return filteredSteps, nil
}

// isGenericWorkflow checks if the workflow steps are too generic
func isGenericWorkflow(steps []string) bool {
	// Check if all workflow steps match common generic patterns
	genericPatterns := []string{
		"kiểm tra", "check", "xem", "view", "thực hiện", "execute",
		"bước 1", "bước 2", "bước 3", "step 1", "step 2", "step 3",
		"kiểm tra trạng thái", "xem log", "khởi động lại",
	}

	genericCount := 0
	for _, step := range steps {
		stepLower := strings.ToLower(step)
		for _, pattern := range genericPatterns {
			if strings.Contains(stepLower, pattern) {
				genericCount++
				break
			}
		}
	}

	// If most steps are generic, consider it a generic workflow
	return genericCount >= len(steps)/2
}

// ProcessNaturalLanguage handles both Kubernetes and general queries
func (h *AIHandler) ProcessNaturalLanguage(query string, model string, queryType string) (*Response, error) {
	log.Printf("Processing natural language query of type %s with AI model %s: %s", queryType, model, query)

	// Check if this is explicitly a Kubernetes query or if we should auto-detect
	isKubernetesQuery := queryType == "kubernetes"
	if queryType == "auto" || queryType == "" {
		// Auto-detect if it's a Kubernetes query
		isKubernetesQuery = h.isKubernetesQuery(query)
	}

	// Process differently based on query type
	if isKubernetesQuery {
		// For Kubernetes queries, use specialized processing
		log.Printf("Detected as Kubernetes query, using specialized processing")
		return h.ProcessKubernetesEvent(Event{Name: query})
	} else {
		// For general knowledge questions
		log.Printf("Processing as general knowledge query")
		
		// Get AI response with specified model if available
		analysis, err := h.aiClient.GetResponse(query, model)
		if err != nil {
			log.Printf("Error processing query: %v", err)
			return &Response{
				Success: false,
				Error:   fmt.Sprintf("Error: %v", err),
			}, nil
		}

		// Extract or generate workflow from response, but maintain original response
		workflow, _ := h.generateWorkflowFromQuery(query, analysis)

		// Return AI's response directly without processing
		return &Response{
			Success:  true,
			Response: analysis,
			Workflow: workflow,
		}, nil
	}
}

// isKubernetesQuery determines if a query is related to Kubernetes
func (h *AIHandler) isKubernetesQuery(query string) bool {
	// Keywords that strongly indicate a Kubernetes query
	kubernetesKeywords := []string{
		"kubernetes", "k8s", "kubectl", "pod", "deployment", "service", 
		"namespace", "ingress", "configmap", "secret", "pv", "pvc",
		"statefulset", "daemonset", "node", "cluster", "kube", "helm",
		"kubeadm", "minikube", "k3s", "rancher", "istio", "knative",
		"containerd", "cri-o", "cni", "kubelet", "kube-proxy",
		// Common operations
		"port-forward", "exec", "scale", "rollout", "apply", "delete",
		"create", "run", "expose", "explain", "describe", "logs"
	}

	queryLower := strings.ToLower(query)
	for _, keyword := range kubernetesKeywords {
		// Check for whole words to avoid false positives
		wordPattern := fmt.Sprintf("\\b%s\\b", keyword)
		match, _ := regexp.MatchString(wordPattern, queryLower)
		if match {
			return true
		}
	}

	// Also check for command patterns
	commandPatterns := []string{
		"kubectl .*", 
		"helm .*", 
		"kubect* .*", // Handle common typos
		"get pod", 
		"describe pod"
	}

	for _, pattern := range commandPatterns {
		match, _ := regexp.MatchString(pattern, queryLower)
		if match {
			return true
		}
	}

	return false
}

// generateWorkflowFromQuery extracts or generates a workflow from a query and its response
func (h *AIHandler) generateWorkflowFromQuery(query string, response string) ([]string, error) {
	// Try to extract workflow steps from response
	steps := extractNumberedListFromText(response)

	// If we found steps, return them
	if len(steps) > 0 {
		return steps, nil
	}

	// Otherwise, use AI to generate a workflow
	if h.shouldGenerateWorkflow(query) {
		return h.aiClient.GenerateWorkflow(query)
	}

	// If all else fails, return a generic workflow
	return []string{
		"Tìm hiểu thêm thông tin từ các nguồn đáng tin cậy",
		"Tham khảo ý kiến từ chuyên gia hoặc người có kinh nghiệm",
		"Áp dụng kiến thức vào tình huống cụ thể",
	}, nil
}

// extractNumberedListFromText extracts a numbered list from text
func extractNumberedListFromText(text string) []string {
	var steps []string

	// Match numbered list items like "1. Step one" or "1) Step one"
	numberPattern := `^\s*\d+[\.\)]\s+(.+)$`

	// Split by lines and look for matches
	lines := strings.Split(text, "\n")
	for _, line := range lines {
		re := regexp.MustCompile(numberPattern)
		matches := re.FindStringSubmatch(line)
		if len(matches) > 1 {
			steps = append(steps, matches[1])
		}
	}

	return steps
}

// shouldGenerateWorkflow determines if a workflow would be helpful
func (h *AIHandler) shouldGenerateWorkflow(query string) bool {
	// Categories that typically need workflows
	workflowCategories := []string{
		// Common workflow phrases
		"how to", "làm thế nào", "hướng dẫn", "cách", "steps", "quy trình",
		"setup", "configure", "install", "create", "build", "deploy",
		"procedure", "tutorial", "guide", "walkthrough", "step by step",

		// Kubernetes-specific actions
		"kubectl", "helm", "k8s", "minikube", "kubernetes", "pod", "deployment",
		"check", "kiểm tra", "xem", "get", "describe", "apply", "delete",
		"scale", "port-forward", "exec", "cp", "logs", "attach", "label",
		"debug", "diagnose", "troubleshoot", "solve", "fix", "resolve",

		// General technology processes
		"configure", "set up", "install", "deploy", "migrate", "update",
		"backup", "restore", "implement", "integrate", "connect", "secure",
	}

	// Common verbs that often indicate actions requiring steps
	workflowVerbs := []string{
		"create", "setup", "configure", "deploy", "install", "migrate",
		"build", "test", "debug", "monitor", "optimize", "secure",
		"integrate", "connect", "scale", "upgrade", "backup", "restore",
	}

	queryLower := strings.ToLower(query)

	// Check for specific category keywords
	for _, category := range workflowCategories {
		if strings.Contains(queryLower, category) {
			return true
		}
	}

	// Check if the query starts with a verb that indicates an action
	for _, verb := range workflowVerbs {
		if strings.HasPrefix(queryLower, verb) || strings.HasPrefix(queryLower, verb+" a") || strings.HasPrefix(queryLower, verb+" the") {
			return true
		}
	}

	// Check for question structures that usually imply processes
	if strings.HasPrefix(queryLower, "how do i") ||
		strings.HasPrefix(queryLower, "how can i") ||
		strings.HasPrefix(queryLower, "what is the best way to") ||
		strings.HasPrefix(queryLower, "what steps") {
		return true
	}

	// Let AI decide for other cases
	return false
}

// executeKubernetesCommand executes the actual command
func (h *AIHandler) executeKubernetesCommand(command string) (string, error) {
	// TODO: Implement actual Kubernetes command execution
	// This should integrate with Botkube's existing command execution system
	return fmt.Sprintf("Kết quả thực thi lệnh: %s", command), nil
}

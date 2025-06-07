package handlers

// Event represents a Kubernetes event to be processed
type Event struct {
	Type      string `json:"type"`
	Resource  string `json:"resource"`
	Name      string `json:"name"`
	Namespace string `json:"namespace"`
	Cluster   string `json:"cluster"`
}

// Response represents the AI handler's response
type Response struct {
	Success  bool     `json:"success"`
	Response string   `json:"response"`
	Workflow []string `json:"workflow,omitempty"`
	Error    string   `json:"error,omitempty"`
}

// AIHandler handles AI-related operations
type AIHandler struct {
	aiClient AIClient
}

// AIClient interface defines methods required for AI operations
type AIClient interface {
	Analyze(query string) (string, error)
	GenerateWorkflow(query string) ([]string, error)
	GetResponse(query string, model string) (string, error)
}

// NewAIHandler creates a new instance of AIHandler
func NewAIHandler(client AIClient) *AIHandler {
	return &AIHandler{
		aiClient: client,
	}
}

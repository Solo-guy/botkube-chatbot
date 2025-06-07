package handlers

import (
	"bytes"
	"fmt"
	"log"
	"os/exec"
	"runtime"
	"strings"
)

// KubernetesExecutor handles the execution of kubernetes commands
type KubernetesExecutor struct {
	DefaultNamespace string
}

// NewKubernetesExecutor creates a new kubernetes executor
func NewKubernetesExecutor() *KubernetesExecutor {
	return &KubernetesExecutor{
		DefaultNamespace: "default",
	}
}

// ExecuteCommand executes a kubernetes command and returns the result
func (k *KubernetesExecutor) ExecuteCommand(command string) (string, error) {
	// Split the command into parts
	parts := strings.Fields(command)
	if len(parts) == 0 {
		return "", fmt.Errorf("empty command")
	}

	// Ensure the command is kubectl
	if parts[0] != "kubectl" {
		parts = append([]string{"kubectl"}, parts...)
	}

	// Create the command based on the platform
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("powershell", append([]string{"-Command"}, strings.Join(parts, " "))...)
	} else {
		cmd = exec.Command(parts[0], parts[1:]...)
	}

	// Capture stdout and stderr
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Execute the command
	err := cmd.Run()
	if err != nil {
		// Return stderr as the error
		errMsg := stderr.String()
		if errMsg == "" {
			errMsg = err.Error()
		}
		return "", fmt.Errorf("error executing command: %s", errMsg)
	}

	// Return the result
	result := stdout.String()
	if result == "" {
		result = "Command executed successfully with no output."
	}

	log.Printf("Executed Kubernetes command: %s", command)
	return result, nil
}

// ValidateCommand checks if a command is safe to execute
func (k *KubernetesExecutor) ValidateCommand(command string) error {
	// List of allowed kubectl commands
	allowedCommands := []string{
		"get", "describe", "logs", "top", "exec", "port-forward",
		"cp", "auth", "config", "expose", "run", "set", "explain",
		"edit", "apply", "diff", "rollout", "scale", "autoscale",
		"certificate", "cluster-info", "cordon", "uncordon", "drain",
	}

	// Split the command into parts
	parts := strings.Fields(command)
	if len(parts) == 0 {
		return fmt.Errorf("empty command")
	}

	// Remove kubectl if it's the first part
	if parts[0] == "kubectl" {
		if len(parts) == 1 {
			return fmt.Errorf("incomplete kubectl command")
		}
		parts = parts[1:]
	}

	// Check if the command is allowed
	commandAllowed := false
	for _, allowed := range allowedCommands {
		if parts[0] == allowed {
			commandAllowed = true
			break
		}
	}

	if !commandAllowed {
		return fmt.Errorf("command '%s' not allowed for security reasons", parts[0])
	}

	// Block delete commands for safety
	if parts[0] == "delete" {
		return fmt.Errorf("delete commands are not allowed for safety reasons")
	}

	return nil
}

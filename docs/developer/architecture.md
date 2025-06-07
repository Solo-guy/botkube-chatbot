# Botkube Flutter Application - Technical Architecture

## Overview

This document details the architecture of the Botkube Flutter Application for developers. The system is designed as a modern, cross-platform client for Kubernetes interaction with AI capabilities.

## Component Architecture

### Frontend (Flutter App)

The Flutter application follows a Provider-based architecture for state management:

- **Screens**: UI layouts for different app sections

  - `ChatScreen`: Main chat interface with AI
  - `EventScreen`: Kubernetes event monitoring
  - `HistoryScreen`: Chat history viewer
  - `WorkflowsScreen`: Workflow management interface

- **Providers**: State management

  - `ChatProvider`: Manages chat messages and AI responses
  - `EventProvider`: Manages Kubernetes events

- **Models**: Data structures

  - `ChatMessage`: Chat message structure
  - `Event`: Kubernetes event structure
  - `Workflow`: Workflow step structure
  - `History`: Chat history structure

- **Services**:

  - `ApiService`: Handles communication with the backend APIs

- **Widgets**: Reusable UI components
  - `ModernChatWidget`: Modern chat interface with message bubbles
  - `WorkflowSuggestionWidget`: Displays and manages workflow suggestions

### Backend (Go Services)

#### Flutter Executor

The Flutter Executor is a Go service that handles command execution and provides the API for the Flutter frontend.

- **API Handlers**:

  - `/execute`: Executes Kubernetes commands
  - `/events`: Handles Kubernetes events
  - `/login`: Manages authentication
  - `/history`: Manages chat history
  - `/chat`: Processes chat messages
  - `/workflows`: Manages workflows

- **Key Components**:
  - `KubernetesExecutor`: Executes Kubernetes commands across platforms
  - `AIHandler`: Processes AI requests
  - `WorkflowHandler`: Manages workflow operations

#### AI Manager

Manages AI model interactions and provides natural language processing capabilities.

- **Key Components**:
  - `AIClient`: Abstracts communications with AI models
  - `ResponseProcessor`: Processes AI responses
  - `WorkflowGenerator`: Generates workflow suggestions

### Database

CockroachDB is used for storing chat history, user data, and workflows:

- **Tables**:
  - `chat_history`: Stores chat messages and responses
  - `users`: User account information
  - `workflows`: Saved workflow data

## Data Flow

### Chat Message Processing

1. User sends a message via the Flutter UI
2. Message is sent to the Flutter Executor via the API
3. If it's a Kubernetes query, the message is processed by the KubernetesExecutor
4. Otherwise, it's sent to the AI Manager for processing
5. The AI response and workflow suggestions are returned to the Flutter app
6. Results are displayed in the chat interface

### Workflow Execution

1. User selects a workflow step to execute
2. Request is sent to the Flutter Executor
3. KubernetesExecutor validates and executes the command
4. Results are returned to the Flutter app
5. Results are displayed in the chat or workflow interface

## Authentication

The application uses JWT (JSON Web Tokens) for authentication:

1. User logs in with a username
2. Server generates a JWT token
3. Token is stored in SharedPreferences on the client
4. Token is sent with each API request
5. Server validates the token for each request

## Cross-Platform Support

The application is designed to work across multiple platforms:

- **Flutter UI**: Works on Windows, macOS, Linux, Android, iOS, and web
- **KubernetesExecutor**: Detects platform and uses appropriate command execution strategy
- **API Communication**: Platform-agnostic HTTP/WebSocket communication

## Development Environment

### Prerequisites

- Flutter SDK (3.0.0 or later)
- Go (1.18 or later)
- Docker and Docker Compose
- CockroachDB

### Local Development Setup

1. Run backend services using Docker Compose:

   ```bash
   docker-compose up -d
   ```

2. Run Flutter app in debug mode:

   ```bash
   cd flutter_app
   flutter run
   ```

3. For hot reload during Go development, use tools like Air:
   ```bash
   air -c .air.toml
   ```

## Key Code Locations

- Flutter UI: `flutter_app/lib/`
- Flutter API Service: `flutter_app/lib/api_service.dart`
- Kubernetes Executor: `plugin/flutter-executor/handlers/kubernetes_executor.go`
- AI Handler: `plugin/flutter-executor/handlers/ai_handler.go`
- Workflow Management: `plugin/flutter-executor/workflow.go`

## Extension Points

The application is designed with several extension points:

1. **Adding new AI models**: Extend the AI client with new model providers
2. **New workflow types**: Add new workflow generators in the AI handler
3. **Custom commands**: Extend the Kubernetes executor with additional commands
4. **UI customization**: Modify the Flutter themes and widgets

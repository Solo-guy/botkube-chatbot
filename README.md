# Botkube Flutter Application

<div align="center">
  <img src="flutter_app/images/logo.png" alt="Botkube Logo" width="200">
  <h3>Modern AI-powered Kubernetes Assistant</h3>
</div>

## Overview

Botkube Flutter Application is a cross-platform client for interacting with Kubernetes clusters through natural language. It combines the power of AI with Kubernetes expertise to provide an intuitive interface for managing and troubleshooting Kubernetes environments.

## Key Features

### AI-Powered Assistance

- **Natural Language Processing**: Ask questions about Kubernetes in plain language
- **Smart Suggestions**: Get contextual workflow suggestions for common tasks
- **Multi-Model Support**: Choose between different AI models (Grok, OpenAI, Claude, Gemini)

### Modern Chat Interface

- **ChatGPT-Style UI**: Clean, intuitive chat interface with message bubbles
- **Code Highlighting**: Automatic syntax highlighting for commands and code snippets
- **Workflow Integration**: Execute suggested commands directly from the chat

### Workflow Management

- **Save & Reuse**: Save common workflows for future use
- **Step-by-Step Execution**: Run workflows one step at a time
- **Cross-Platform Support**: Execute commands on Windows, macOS, and Linux

### Event Monitoring

- **Real-time Updates**: Monitor Kubernetes events as they happen
- **Event Analysis**: AI-powered analysis of Kubernetes events

### Offline Capabilities

- **Fallback Responses**: Get useful responses even when offline
- **Local Workflow Storage**: Access your saved workflows anytime

## System Architecture

The application consists of several components:

1. **Flutter Frontend**: Cross-platform UI built with Flutter
2. **Flutter Executor**: Go service that handles command execution
3. **AI Manager**: Manages AI model interactions
4. **Database**: Stores chat history and workflows

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│  Flutter App    │─────▶│  Flutter        │─────▶│  AI Manager     │
│  (UI)           │◀─────│  Executor       │◀─────│                 │
│                 │      │                 │      │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
                                 │                         │
                                 ▼                         ▼
                          ┌─────────────────┐      ┌─────────────────┐
                          │                 │      │                 │
                          │  Database       │      │  Kubernetes     │
                          │                 │      │  API            │
                          │                 │      │                 │
                          └─────────────────┘      └─────────────────┘
```

## Getting Started

### Prerequisites

- Flutter SDK
- Docker and Docker Compose (for backend services)
- Kubernetes cluster (optional, for full functionality)

### Quick Start

1. Clone the repository

   ```bash
   git clone https://github.com/your-org/botkube-flutter-clean.git
   cd botkube-flutter-clean
   ```

2. Create `.env` file in the root directory (see [Installation Guide](docs/user/installation.md))

3. Start backend services

   ```bash
   docker-compose up -d
   ```

4. Run the Flutter application
   ```bash
   cd flutter_app
   flutter pub get
   flutter run
   ```

### Detailed Documentation

- [Installation Guide](docs/user/installation.md)
- [User Guide](docs/user/usage.md)
- [AI Capabilities](docs/user/ai-capabilities.md)
- [Developer Documentation](docs/developer/architecture.md)

## Technical Stack

- **Frontend**: Flutter
- **Backend**: Go
- **Database**: CockroachDB
- **Additional Technologies**:
  - WebSockets for real-time communication
  - JWT for authentication
  - Docker for containerization

## Contributing

Contributions are welcome! Please see our [Contributing Guide](docs/developer/contributing.md) for more information.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- Kubernetes community
- Flutter team
- AI model providers

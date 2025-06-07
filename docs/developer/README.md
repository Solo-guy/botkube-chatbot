# Developer Documentation

This documentation is intended for developers who want to contribute to or extend the BotKube Flutter Application.

## Project Architecture

The project is divided into three main components:

```
botkube-flutter-clean/
├── flutter_app/           # Flutter UI application
├── plugin/
│   ├── flutter-executor/  # Plugin connecting Flutter to Botkube
│   ├── ai-manager/        # AI processing plugin
│   └── test-client/       # Testing utilities
└── docs/                  # Documentation
```

### Flutter App

The Flutter UI application follows the Provider Pattern architecture:

```
flutter_app/
├── lib/
│   ├── models/           # Data models
│   ├── providers/        # State management providers
│   ├── screens/          # Main application screens
│   ├── widgets/          # Reusable UI widgets
│   ├── workflows/        # Logic workflows
│   ├── utils/            # Utility functions and helpers
│   ├── l10n/             # Internationalization
│   ├── api_service.dart  # API communication service
│   └── main.dart         # Entry point
```

### Flutter Executor

This plugin provides a REST API to connect Flutter with Botkube:

```
plugin/flutter-executor/
├── types/       # Type definitions
├── db-scripts/  # Database scripts
├── main.go      # Entry point
├── api.go       # API handling
├── auth.go      # Authentication
└── config.yaml  # Configuration
```

### AI Manager

This plugin handles AI analysis and natural language processing:

```
plugin/ai-manager/
├── main.go      # Entry point
├── ai.go        # AI processing
└── config.yaml  # Configuration
```

## Development Workflow

### Development Environment Setup

1. Fork the project from GitHub
2. Clone your fork
3. Install required tools (Flutter, Go, CockroachDB)
4. Start CockroachDB
5. Start the services as described in the [Usage Guide](../user/usage.md)

### Contribution Process

1. Create a new branch for your feature/fix
2. Write code and test thoroughly
3. Update documentation as needed
4. Create a Pull Request

## Coding Standards

### Flutter/Dart

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for errors
- Write unit tests for critical components

```bash
cd flutter_app
flutter analyze
flutter test
```

### Go

- Follow [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- Use `go fmt` and `go vet` to format code and check for errors
- Write unit tests for important functions

```bash
cd plugin/flutter-executor
go fmt ./...
go vet ./...
go test ./...
```

## Extending the Application

### Adding a New AI Model

1. Update `plugin/ai-manager/ai.go`
2. Add a new interface for your AI model
3. Update the configuration in `config.yaml`

Example:

```go
type NewAIModel struct {
    // required fields
}

func (m *NewAIModel) Analyze(event Event) (AIResponse, error) {
    // Implementation of analysis
}
```

### Adding a New UI Feature

1. Create a new provider in `flutter_app/lib/providers/`
2. Create new widgets in `flutter_app/lib/widgets/`
3. Update routing in `main.dart`

### Adding a New API Endpoint

1. Update `plugin/flutter-executor/api.go`
2. Add a new handler
3. Register the route in `main.go`

## Deployment

### Docker Containers

The project supports deployment with Docker:

```bash
# Build Flutter App
cd flutter_app
docker build -t botkube-flutter-app .

# Build Flutter Executor
cd ../plugin/flutter-executor
docker build -t botkube-flutter-executor .

# Build AI Manager
cd ../ai-manager
docker build -t botkube-ai-manager .
```

### Docker Compose

Use docker-compose to run all services:

```bash
docker-compose up -d
```

### Kubernetes Deployment

Create Kubernetes manifest files in the `k8s/` directory:

1. `cockroachdb.yaml`: CockroachDB StatefulSet
2. `flutter-executor.yaml`: Flutter Executor Deployment
3. `ai-manager.yaml`: AI Manager Deployment
4. `flutter-app.yaml`: Flutter App Deployment
5. `ingress.yaml`: Ingress for external access

Deploy with:

```bash
kubectl apply -f k8s/
```

## Performance Considerations

### Database Optimization

- Use indexes for frequently queried fields
- Implement connection pooling
- Consider adding caching for frequently accessed data

### Flutter App Optimization

- Use const constructors where possible
- Implement pagination for large data sets
- Use efficient state management practices

## Security Best Practices

- Use JWT for authentication and authorization
- Implement proper input validation
- Secure API endpoints with rate limiting
- Handle sensitive data securely
- Use HTTPS for all communications

## Continuous Integration

The project uses GitHub Actions for CI/CD:

1. On push to main branch: Run tests and linting
2. On PR: Run tests, linting, and build validation
3. On release tag: Build and push Docker images

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Go Documentation](https://golang.org/doc/)
- [Botkube Documentation](https://docs.botkube.io/)
- [CockroachDB Documentation](https://www.cockroachlabs.com/docs/)

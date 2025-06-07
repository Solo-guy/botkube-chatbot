# Botkube Flutter Application - Installation Guide

## System Requirements

- **Operating System**: Windows, macOS, or Linux
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 1GB free space minimum
- **Kubernetes**: For full functionality, access to a Kubernetes cluster is recommended

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/botkube-flutter-clean.git
cd botkube-flutter-clean
```

### 2. Configure Environment

Create a `.env` file in the root directory with the following content:

```
SERVER_IP=<your-server-ip>
API_URL=http://<your-server-ip>:8080
WS_URL=ws://<your-server-ip>:8080/events/ws
API_TIMEOUT=30000
DEBUG_MODE=false
DEFAULT_USERNAME=user1
```

Replace `<your-server-ip>` with your actual server IP address.

### 3. Start the Backend Services

```bash
docker-compose up -d
```

This will start the following services:

- Botkube API service
- AI Manager
- Flutter Executor
- Database

### 4. Install Flutter Dependencies

```bash
cd flutter_app
flutter pub get
```

### 5. Run the Application

#### Desktop Application

```bash
flutter run -d windows  # For Windows
flutter run -d macos    # For macOS
flutter run -d linux    # For Linux
```

#### Web Application

```bash
flutter run -d chrome
```

#### Mobile Application

```bash
flutter run -d android  # For Android devices
flutter run -d ios      # For iOS devices
```

## First-time Login

1. When you first run the application, you'll be presented with a login screen
2. Enter the username `user1` for admin access or `user2` for regular user access
3. Click "Log In"

## Verifying Installation

After logging in, you should see the main dashboard with three tabs:

- **Chat**: AI chat interface to ask questions and get responses
- **Events**: Real-time Kubernetes events (if connected to a cluster)
- **History**: History of previous conversations

You can also access "Workflows" from the side menu to see saved workflows.

## Troubleshooting

### Connection Issues

If you're having trouble connecting to the backend services:

1. Check that the services are running with `docker-compose ps`
2. Verify that your `.env` file has the correct IP address
3. Ensure that ports 8080 is not blocked by a firewall

### UI Issues

If the UI displays incorrectly:

1. Try running `flutter clean` followed by `flutter pub get`
2. Restart the application

## Updating

To update to the latest version:

```bash
git pull
docker-compose down
docker-compose up -d --build
cd flutter_app
flutter pub get
```

## Uninstallation

To completely remove the application:

```bash
docker-compose down -v
cd ..
rm -rf botkube-flutter-clean
```

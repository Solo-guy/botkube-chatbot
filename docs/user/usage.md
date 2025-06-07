# Botkube Flutter Application - User Guide

## Getting Started

### Logging In

1. Start the application
2. Enter your username on the login screen (use `user1` for admin access or `user2` for regular user access)
3. Click "Log In"

### Main Interface

After logging in, you'll see the main interface with three tabs:

1. **Chat**: Interact with the AI assistant
2. **Events**: View Kubernetes events
3. **History**: Access chat history

You can also access additional features through the side menu (click the menu icon in the top-left corner).

## Chat Interface

The chat interface is the primary way to interact with Botkube's AI assistant.

### Asking Questions

1. Type your question in the input field at the bottom
2. Press Enter or click the Send button
3. The AI will process your question and provide a response

### Types of Questions

#### Kubernetes-Related Questions

You can ask about Kubernetes concepts, commands, or troubleshooting:

- "How do I check logs for a pod?"
- "What's the command to scale a deployment?"
- "How can I troubleshoot pod startup issues?"

#### General Knowledge Questions

The AI can also answer general questions:

- "What is container orchestration?"
- "Explain microservices architecture"
- "What are the best practices for cloud security?"

### Understanding Responses

AI responses include:

- Text explanations
- Code blocks with syntax highlighting
- Workflow suggestions when appropriate

### Code Blocks

Code blocks are highlighted for better readability. You can:

1. Copy code by clicking the copy icon
2. Execute commands by copying them to your terminal

## Workflow Suggestions

For many Kubernetes-related queries, the AI will suggest workflows - sequences of commands that can help you accomplish tasks.

### Using Workflow Suggestions

1. When a workflow appears, review the suggested steps
2. Click "Execute" next to any step to run it directly
3. Click "Execute All" to run all steps in sequence
4. Click "Save Workflow" to save for future use

### Managing Workflows

Access the Workflows screen from the side menu to:

1. View all saved workflows
2. Execute saved workflows
3. Delete custom workflows

## Event Monitoring

The Events tab shows real-time Kubernetes events from your connected clusters.

### Viewing Events

1. Navigate to the Events tab
2. Events are displayed in chronological order
3. Click on an event to see details

### Analyzing Events

1. Select an event
2. Click "Analyze" to get AI insights
3. Review the analysis and suggested actions

## Chat History

The History tab allows you to review past conversations.

### Accessing History

1. Navigate to the History tab
2. Scroll through previous conversations
3. Click on any entry to expand it

### Managing History

1. Delete individual entries by clicking the trash icon
2. Clear all history using the "Clear All" button in the menu

## Customizing the Experience

### Choosing AI Models

You can select different AI models for responses:

1. Click on the model selector dropdown
2. Choose from available models (Grok, OpenAI, Claude, Gemini)

### Theme Settings

The application automatically adjusts to your system's light/dark mode settings.

## Troubleshooting

### Connection Issues

If you experience connection problems:

1. Check your network connection
2. Verify that backend services are running
3. Try logging out and back in

### AI Response Issues

If AI responses are not helpful:

1. Try rephrasing your question to be more specific
2. Try a different AI model
3. Check that you have the latest application version

## Best Practices

1. **Be Specific**: Ask clear, specific questions for better responses
2. **Use Keywords**: Include relevant Kubernetes terms in your questions
3. **Save Workflows**: Save commonly used workflows for quick access
4. **Review Commands**: Always review suggested commands before execution
5. **Regular Updates**: Keep the application updated for the latest features

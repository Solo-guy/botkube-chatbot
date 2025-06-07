# Project Ignore Files Guide

This document explains the `.gitignore` and `.dockerignore` files used in the Botkube Flutter project to help developers understand which files are excluded from version control and Docker builds.

## Overview

The project uses a hierarchical approach to ignore files:

1. **Root-level ignore files**: Define global patterns that apply to the entire project
2. **Directory-specific ignore files**: Define patterns specific to a particular component (Flutter app, plugins, etc.)

## `.gitignore` Files

### Purpose

`.gitignore` files tell Git which files and directories to exclude from version control. This helps to:

- Keep repositories clean and focused on source code
- Prevent platform-specific, generated, or temporary files from being committed
- Avoid committing sensitive information like credentials or environment variables

### Root-level `.gitignore`

The root-level `.gitignore` defines global patterns for:

- Build and runtime data (CockroachDB files, compiled files)
- Flutter/Dart specific files (cache, generated code)
- Go specific files (executables, build artifacts)
- Environment and configuration files
- IDE and editor files
- Logs and temporary files
- Build artifacts and dependencies
- Testing and coverage files

### Directory-specific `.gitignore` files

- **`flutter_app/`**: Platform-specific ignores for Flutter mobile/desktop builds
- **`plugin/`**: Go-specific ignores for the Botkube plugins

## `.dockerignore` Files

### Purpose

`.dockerignore` files specify which files and directories should be excluded when building Docker images. This helps to:

- Reduce build context size and improve build speed
- Prevent unnecessary or sensitive files from being included in Docker images
- Create smaller, more secure Docker images

### Root-level `.dockerignore`

The root-level `.dockerignore` defines patterns to exclude:

- Version control files
- Documentation and non-build assets
- Development and test files
- Environment and configuration files
- IDE and editor files
- OS-specific files
- Logs and debugging information
- Temporary files

### Directory-specific `.dockerignore` files

- **`flutter_app/`**: Flutter-specific patterns, primarily to exclude platform-specific code not needed for web builds
- **`plugin/`**: Go-specific patterns for the backend services
- **`plugin/flutter-executor/`**: Specific patterns for the Flutter Executor plugin
- **`plugin/ai-manager/`**: Specific patterns for the AI Manager plugin

## Best Practices

1. When developing, be aware of which files are ignored to avoid confusion about missing files.
2. If you need to force-add an ignored file, use `git add -f filename`.
3. For Docker builds, consider which platform you're targeting (web, specific mobile platform) and modify `.dockerignore` files accordingly.
4. When adding new dependency types or utilizing new tools, update the ignore files to exclude their temporary/generated files.

## Customizing Ignore Files

If you need to customize the ignore patterns for your specific development environment or deployment scenario:

1. Do not modify the shared ignore files in the repository.
2. Instead, use Git's personal ignore feature:
   - Create a file at `.git/info/exclude` with your personal ignore patterns
   - Use a global ignore file: `git config --global core.excludesfile ~/.gitignore_global`

## Platform-Specific Notes

### Mobile Development

When working on mobile-specific features, you may need to temporarily comment out certain patterns in the Flutter app's `.dockerignore` file to include platform-specific code in your Docker builds.

### Web Development

For web-focused development, the default `.dockerignore` files are already optimized to exclude mobile and desktop platform-specific code.

### Backend Development

For plugin/backend development, pay attention to the Go-specific ignore patterns that exclude binaries and build artifacts.

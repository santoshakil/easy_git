# Easy Git - Project Context

## Project Purpose
Flutter desktop app for managing nested git repositories, particularly for projects with multiple sub-repos.

## Technology Stack

### Rust Core
- git2 0.20: Git operations
- tokio 1.47: Async runtime
- rayon 1.11: Parallel processing
- serde 1.0: Serialization
- flutter_rust_bridge 2.11.1: FFI bridge

### Flutter UI
- flutter_riverpod 2.6.1: State management
- riverpod_annotation 2.6.1: Code generation
- freezed 2.5.8: Immutable models
- go_router 14.6.2: Navigation
- flutter_hooks 0.20.5: Hooks

## Architecture
- **Rust**: All git operations, scanning, data processing
- **Dart**: UI only, state management with Riverpod
- **Clean Architecture**: Features folder with presentation/domain layers

## Key Features
1. Recursive repository scanning
2. Multi-repo status overview
3. Batch operations (commit, push, pull)
4. Real-time status updates
5. Theme-based UI (no hardcoded colors)

## Code Style (from global CLAUDE.md)
- NO comments in code
- var for locals
- const everywhere possible
- Expression bodies (=> expr)
- Tearoffs over lambdas
- NO unwrap()/expect() in Rust

## Commands
```bash
# Generate Dart code
dart run build_runner build --delete-conflicting-outputs

# Generate Rust bindings
flutter_rust_bridge_codegen generate

# Run app
flutter run -d macos

# Check Rust
cargo check --manifest-path=rust/Cargo.toml

# Analyze Dart
flutter analyze
```

## Important Paths
- Rust core: `rust/src/`
- Flutter features: `lib/features/`
- Generated code: `lib/src/rust/`
- Docs: `docs/`
- Temp notes: `tmp/`

## Testing
Test with any project containing nested git repositories.

## Current Focus
Building MVP with:
- Repository list screen
- Status indicators
- Commit/push functionality
- Theme system

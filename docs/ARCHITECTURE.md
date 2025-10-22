# Easy Git - Architecture

## Technology Stack

### Rust Core (native/)
- **git2**: Libgit2 bindings for git operations
- **tokio**: Async runtime for concurrent operations
- **serde**: Serialization/deserialization
- **anyhow**: Error handling
- **thiserror**: Custom error types
- **notify**: File system watching
- **flutter_rust_bridge**: FFI communication
- **parking_lot**: High-performance synchronization

### Flutter UI (lib/)
- **flutter_riverpod**: State management
- **riverpod_annotation**: Code generation for providers
- **freezed**: Immutable models
- **freezed_annotation**: Code generation
- **json_serializable**: JSON handling
- **build_runner**: Code generation runner
- **flutter_rust_bridge**: FFI communication
- **go_router**: Navigation
- **flutter_hooks**: React-style hooks
- **path_provider**: System paths
- **shared_preferences**: Settings persistence
- **material**: Material Design 3

## SOLID Principles Application

### Single Responsibility
- RepositoryScanner: Only discovers repos
- GitRepository: Only git operations
- RepositoryCache: Only caching
- Each UI widget: Single purpose

### Open/Closed
- Git operations behind traits
- Theme system extensible
- Provider pattern for data

### Liskov Substitution
- GitOperations trait
- Multiple implementations possible
- Mock implementations for testing

### Interface Segregation
- Focused traits (ReadRepo, WriteRepo, RemoteRepo)
- UI components don't depend on unused methods

### Dependency Inversion
- Depend on traits, not concrete types
- Riverpod for dependency injection
- Repository pattern abstracts data layer

## Architecture Layers

### Rust Layer

```
native/
├── Cargo.toml
└── src/
    ├── lib.rs              # Library entry
    ├── api.rs              # FRB API surface
    │
    ├── git/                # Git operations
    │   ├── mod.rs
    │   ├── repository.rs   # Core repo operations
    │   ├── status.rs       # Status & diff
    │   ├── commit.rs       # Commit operations
    │   ├── branch.rs       # Branch management
    │   ├── remote.rs       # Push/pull/fetch
    │   ├── log.rs          # History & logs
    │   └── stash.rs        # Stash operations
    │
    ├── scanner/            # Repository discovery
    │   ├── mod.rs
    │   ├── discover.rs     # Recursive scanning
    │   ├── cache.rs        # Result caching
    │   └── watcher.rs      # FS monitoring
    │
    ├── models/             # Data models
    │   ├── mod.rs
    │   ├── repository.rs
    │   ├── commit.rs
    │   ├── status.rs
    │   ├── branch.rs
    │   └── diff.rs
    │
    ├── error/              # Error types
    │   └── mod.rs
    │
    └── utils/              # Utilities
        ├── mod.rs
        └── path.rs
```

### Flutter Layer

```
lib/
├── main.dart               # Entry point
├── app.dart                # App widget
│
├── features/
│   ├── repositories/       # Repo list & details
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   └── domain/
│   │       ├── models/
│   │       └── repositories/
│   │
│   ├── commits/            # Commit management
│   │   ├── presentation/
│   │   └── domain/
│   │
│   ├── branches/           # Branch management
│   │   ├── presentation/
│   │   └── domain/
│   │
│   ├── changes/            # Changes & diffs
│   │   ├── presentation/
│   │   └── domain/
│   │
│   └── settings/           # App settings
│       ├── presentation/
│       └── domain/
│
└── core/
    ├── theme/              # Theme system
    │   ├── app_theme.dart
    │   └── colors.dart
    │
    ├── router/             # Navigation
    │   └── app_router.dart
    │
    ├── widgets/            # Shared widgets
    │   ├── loading.dart
    │   └── error.dart
    │
    └── utils/              # Utilities
        └── extensions.dart
```

## Data Flow

```
UI Widget
  ↓ (reads state)
Riverpod Provider
  ↓ (calls)
Repository Interface
  ↓ (calls)
Rust FFI Bridge
  ↓ (executes)
Rust Core Logic
  ↓ (uses)
git2 / libgit2
```

## State Management Strategy

### Riverpod Patterns
- **StateNotifierProvider**: Mutable state (repo list, selections)
- **FutureProvider**: Async data loading (scan repos, fetch commits)
- **StreamProvider**: Real-time updates (FS watcher)
- **Provider**: Immutable state (settings, theme)

### State Flow
1. UI triggers action
2. Provider method called
3. Rust FFI invoked
4. Result returned
5. State updated
6. UI rebuilds

## Error Handling

### Rust Side
```rust
#[derive(Debug, thiserror::Error)]
enum GitError {
    #[error("Repository not found: {0}")]
    NotFound(String),

    #[error("Invalid repository: {0}")]
    Invalid(String),

    #[error("Git operation failed: {0}")]
    OperationFailed(String),
}
```

### Flutter Side
- Catch FFI errors
- Display user-friendly messages
- Log for debugging
- Retry mechanisms for transient failures

## Performance Optimizations

### Rust
- Parallel repo scanning with rayon
- Lazy loading of git data
- Efficient caching with LRU
- Arc for shared data
- RwLock for concurrent access

### Flutter
- Lazy loading lists
- Virtual scrolling
- Image caching
- Debounced search
- Memoization with Riverpod

## Testing Strategy

### Rust
- Unit tests for each module
- Integration tests for git operations
- Mock git repositories
- Property-based tests

### Flutter
- Widget tests for UI components
- Provider tests for state logic
- Integration tests for flows
- Golden tests for UI consistency

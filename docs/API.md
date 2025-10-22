# Easy Git API Documentation

This document provides complete API reference for Easy Git's Rust backend functions and Flutter state providers.

## Table of Contents

- [Overview](#overview)
- [Rust FFI API](#rust-ffi-api)
  - [Repository Scanning](#repository-scanning)
  - [Repository Information](#repository-information)
  - [Commit Operations](#commit-operations)
  - [Remote Operations](#remote-operations)
  - [Destructive Operations](#destructive-operations)
- [Flutter State Providers](#flutter-state-providers)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [Usage Examples](#usage-examples)

## Overview

Easy Git's architecture separates concerns between Rust (backend) and Flutter (frontend):

- **Rust**: All git operations, file I/O, and business logic
- **Flutter**: UI rendering and user interaction
- **Communication**: Type-safe FFI bridge via flutter_rust_bridge

All Rust functions are exposed through the FFI boundary with the `#[flutter_rust_bridge::frb]` attribute.

## Rust FFI API

All FFI functions return `anyhow::Result<T>` which is automatically converted to Dart exceptions by flutter_rust_bridge.

### Repository Scanning

#### `scan_repositories`

Recursively scans a directory for git repositories.

```rust
pub fn scan_repositories(root_path: String) -> anyhow::Result<Vec<String>>
```

**Parameters:**
- `root_path` - Absolute or relative path to start scanning from

**Returns:**
- `Vec<String>` - List of absolute paths to discovered git repositories

**Behavior:**
- Uses parallel scanning with Rayon for performance
- Default max depth: 10 levels
- Skips `.git`, `node_modules`, `target`, and hidden directories
- Only returns directories containing a `.git` folder

**Errors:**
- `PathError` - If root_path doesn't exist or is inaccessible
- `IoError` - If permission denied or other I/O error

**Performance:** O(n) where n is number of directories, parallelized across CPU cores

**Example:**
```dart
final repos = await rust_api.scanRepositories(rootPath: '/Users/dev/projects');
print('Found ${repos.length} repositories');
```

**Security Considerations:**
- ⚠️ **Path Traversal Vulnerability** (CRITICAL-3): Currently accepts any path
- TODO: Add validation to prevent scanning system directories

---

### Repository Information

#### `get_repository_info`

Retrieves detailed information about a single repository.

```rust
pub fn get_repository_info(path: String) -> anyhow::Result<RepositoryInfo>
```

**Parameters:**
- `path` - Path to git repository

**Returns:**
- `RepositoryInfo` - Struct containing:
  - `path`: Repository path
  - `name`: Repository name (directory name)
  - `current_branch`: Current branch name
  - `head_commit_hash`: Latest commit hash
  - `head_commit_message`: Latest commit message
  - `head_commit_author`: Latest commit author
  - `head_commit_timestamp`: Unix timestamp of latest commit
  - `uncommitted_changes`: Count of modified files
  - `untracked_files`: Count of untracked files
  - `ahead_count`: Commits ahead of remote
  - `behind_count`: Commits behind remote

**Errors:**
- `RepositoryNotFound` - Path is not a valid git repository
- `GitError` - libgit2 operation failed

**Performance:** O(1) - Single git operation

**Example:**
```dart
final info = await rust_api.getRepositoryInfo(path: '/path/to/repo');
print('${info.name} is on ${info.currentBranch}');
print('${info.uncommittedChanges} uncommitted changes');
```

---

#### `get_multiple_repository_info`

Retrieves information for multiple repositories in parallel.

```rust
pub fn get_multiple_repository_info(paths: Vec<String>) -> anyhow::Result<Vec<RepositoryInfo>>
```

**Parameters:**
- `paths` - List of repository paths

**Returns:**
- `Vec<RepositoryInfo>` - List of repository information (filters out errors)

**Behavior:**
- Uses Rayon for parallel processing
- Failed repositories are silently filtered out
- Order is not guaranteed to match input order

**Performance:** O(n) parallelized - completes in time of slowest repository

**Example:**
```dart
final infos = await rust_api.getMultipleRepositoryInfo(
  paths: ['/repo1', '/repo2', '/repo3'],
);
```

**Known Issues:**
- ⚠️ **Silent Error Swallowing**: Failed repos are dropped without notification
- ⚠️ **Race Condition** (HIGH-2): No deduplication if same path appears multiple times

---

#### `get_repository_status`

Gets detailed status of files in a repository.

```rust
pub fn get_repository_status(path: String) -> anyhow::Result<RepoStatus>
```

**Parameters:**
- `path` - Path to repository

**Returns:**
- `RepoStatus` - Struct containing:
  - `files`: Vec<FileStatus> with path and status for each file
  - `is_clean`: Boolean indicating if working directory is clean

**File Status Types:**
- `Modified` - File has uncommitted changes
- `New` - File is not tracked
- `Deleted` - File was deleted
- `Renamed` - File was renamed
- `Typechange` - File type changed (regular → symlink, etc.)

**Performance:** O(n) where n is number of files in working directory

**Example:**
```dart
final status = await rust_api.getRepositoryStatus(path: '/path/to/repo');
if (status.isClean) {
  print('Working directory is clean');
} else {
  print('${status.files.length} files have changes');
}
```

---

### Commit Operations

#### `commit_repository`

Commits staged changes in a single repository.

```rust
pub fn commit_repository(path: String, message: String) -> anyhow::Result<String>
```

**Parameters:**
- `path` - Path to repository
- `message` - Commit message

**Returns:**
- `String` - Full commit hash (40 characters)

**Behavior:**
- Commits all staged changes
- Uses git config user.name and user.email
- Creates commit on current HEAD
- Does NOT stage files automatically

**Errors:**
- `GitError` - If no changes staged or git operation fails
- `ConfigError` - If user.name or user.email not configured

**Security:**
- ⚠️ **Unvalidated Input** (CRITICAL-4): No commit message validation
- TODO: Add length limits and sanitization

**Example:**
```dart
try {
  final hash = await rust_api.commitRepository(
    path: '/path/to/repo',
    message: 'feat: add new feature',
  );
  print('Committed: ${hash.substring(0, 7)}');
} catch (e) {
  print('Commit failed: $e');
}
```

---

#### `commit_multiple_repositories`

Commits changes to multiple repositories in parallel.

```rust
pub fn commit_multiple_repositories(
  paths: Vec<String>,
  message: String
) -> anyhow::Result<Vec<String>>
```

**Parameters:**
- `paths` - List of repository paths
- `message` - Commit message (same for all repos)

**Returns:**
- `Vec<String>` - List of paths successfully committed

**Behavior:**
- Uses Rayon for parallel execution
- Failed commits are logged to stderr and filtered out
- All successful commits use the same message

**Errors:**
- Individual errors are caught and logged, not propagated

**Known Issues:**
- ⚠️ **Silent Failure** (CRITICAL-3): Failed commits only logged, not reported to user
- TODO: Return structured result with successes and failures

**Example:**
```dart
final committed = await rust_api.commitMultipleRepositories(
  paths: selectedRepos,
  message: 'chore: bulk update',
);
print('Committed ${committed.length} of ${selectedRepos.length} repos');
```

---

### Remote Operations

#### `push_repository`

Pushes current branch to remote origin.

```rust
pub fn push_repository(path: String) -> anyhow::Result<()>
```

**Parameters:**
- `path` - Path to repository

**Returns:**
- `()` - Success (no return value)

**Behavior:**
- Pushes current branch to origin
- Uses git credential helper for authentication
- Follows remote tracking branch

**Errors:**
- `GitError` - If no remote, authentication fails, or push rejected
- `NetworkError` - If network unavailable

**Security:**
- ⚠️ **Certificate Bypass** (CRITICAL-1): SSL validation disabled
- ⚠️ **Credential Leakage** (CRITICAL-5): Uses external process for credentials
- TODO: Implement proper certificate validation

**Example:**
```dart
try {
  await rust_api.pushRepository(path: '/path/to/repo');
  print('Push successful');
} catch (e) {
  print('Push failed: $e');
}
```

---

#### `fetch_repository`

Fetches updates from remote origin.

```rust
pub fn fetch_repository(path: String) -> anyhow::Result<()>
```

**Parameters:**
- `path` - Path to repository

**Returns:**
- `()` - Success

**Behavior:**
- Fetches all branches from origin
- Does NOT merge or update working directory
- Updates remote tracking branches

**Known Issues:**
- ⚠️ **External Process** (HIGH-6): Uses `git fetch` command instead of libgit2
- TODO: Replace with git2::Remote::fetch

**Example:**
```dart
await rust_api.fetchRepository(path: '/path/to/repo');
```

---

#### `pull_repository`

Pulls and merges updates from remote.

```rust
pub fn pull_repository(path: String) -> anyhow::Result<()>
```

**Parameters:**
- `path` - Path to repository

**Returns:**
- `()` - Success

**Behavior:**
- Fetches from remote
- Attempts fast-forward merge only
- Fails if merge required

**Limitations:**
- ⚠️ **No Merge Support** (HIGH-9): Only fast-forward merges supported
- Fails with error if diverged from remote

**Example:**
```dart
try {
  await rust_api.pullRepository(path: '/path/to/repo');
} catch (e) {
  if (e.toString().contains('merge')) {
    print('Manual merge required');
  }
}
```

---

#### `fetch_multiple_repositories`

Fetches updates for multiple repositories.

```rust
pub fn fetch_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>>
```

**Parameters:**
- `paths` - List of repository paths

**Returns:**
- `Vec<String>` - Paths successfully fetched

**Known Issues:**
- ⚠️ **Sequential Execution** (CRITICAL-4): Not parallelized like other batch operations
- TODO: Use rayon for parallel fetching

**Example:**
```dart
final fetched = await rust_api.fetchMultipleRepositories(paths: repos);
```

---

#### `push_multiple_repositories`

Pushes multiple repositories in parallel.

```rust
pub fn push_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>>
```

**Parameters:**
- `paths` - List of repository paths

**Returns:**
- `Vec<String>` - Paths successfully pushed

**Performance:** Parallelized with Rayon

**Example:**
```dart
final pushed = await rust_api.pushMultipleRepositories(paths: selectedRepos);
print('Pushed ${pushed.length} repositories');
```

---

#### `pull_multiple_repositories`

Pulls multiple repositories in parallel.

```rust
pub fn pull_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>>
```

**Parameters:**
- `paths` - List of repository paths

**Returns:**
- `Vec<String>` - Paths successfully pulled

**Performance:** Parallelized with Rayon

---

### Destructive Operations

#### `discard_repository_changes`

⚠️ **DANGEROUS**: Permanently discards all uncommitted changes.

```rust
pub fn discard_repository_changes(path: String) -> anyhow::Result<()>
```

**Parameters:**
- `path` - Path to repository

**Returns:**
- `()` - Success

**Behavior:**
- Resets all tracked files to HEAD
- **PERMANENTLY DELETES** all untracked files
- No confirmation, no undo

**Security:**
- ⚠️ **Data Loss** (HIGH-4): Irreversible operation with no backup
- TODO: Add confirmation flag, create stash backup

**Example:**
```dart
await rust_api.discardRepositoryChanges(path: '/path/to/repo');
```

---

#### `discard_multiple_repositories`

⚠️ **DANGEROUS**: Discards changes in multiple repositories.

```rust
pub fn discard_multiple_repositories(paths: Vec<String>) -> anyhow::Result<Vec<String>>
```

**Parameters:**
- `paths` - List of repository paths

**Returns:**
- `Vec<String>` - Paths successfully discarded

**Performance:** Parallelized with Rayon

---

## Flutter State Providers

All providers use Riverpod 2.x code generation.

### `SelectedPathProvider`

Manages the currently selected folder path.

```dart
@riverpod
class SelectedPath extends _$SelectedPath {
  String? build() => null;
  void set(String? path) => state = path;
}
```

**Usage:**
```dart
final path = ref.watch(selectedPathProvider);
ref.read(selectedPathProvider.notifier).set('/new/path');
```

---

### `RepositoriesProvider`

Manages scanned repository paths.

```dart
@riverpod
class Repositories extends _$Repositories {
  AsyncValue<List<String>> build() => const AsyncValue.data([]);
  Future<void> scan(String path) async { ... }
}
```

**State:** `AsyncValue<List<String>>`
- `AsyncData<List<String>>` - Scan complete
- `AsyncLoading` - Scanning in progress
- `AsyncError` - Scan failed

**Methods:**
- `scan(String path)` - Scans directory for repositories

**Usage:**
```dart
final reposAsync = ref.watch(repositoriesProvider);
reposAsync.when(
  data: (repos) => Text('${repos.length} repositories'),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);

await ref.read(repositoriesProvider.notifier).scan('/path');
```

---

### `RepositoriesInfoProvider`

Provides detailed information for all scanned repositories.

```dart
@riverpod
Future<List<RepositoryInfo>> repositoriesInfo(Ref ref) async { ... }
```

**Dependencies:** Watches `repositoriesProvider`

**Behavior:**
- Automatically refetches when repository list changes
- Calls `get_multiple_repository_info` FFI function
- Swallows errors and returns empty list

**Known Issues:**
- ⚠️ **Race Condition** (CRITICAL-2): Async closure inside `when()` creates Future<Future<T>>
- TODO: Use `maybeWhen` with async closure

**Usage:**
```dart
final infosAsync = ref.watch(repositoriesInfoProvider);
```

---

### `SelectionModeProvider`

Toggles between view mode and selection mode.

```dart
@riverpod
class SelectionMode extends _$SelectionMode {
  bool build() => false;
  void toggle() => state = !state;
  void set(bool value) => state = value;
}
```

**Usage:**
```dart
final selectionMode = ref.watch(selectionModeProvider);
if (selectionMode) {
  // Show checkboxes
}
```

---

### `SelectedRepositoriesProvider`

Manages set of selected repository paths.

```dart
@riverpod
class SelectedRepositories extends _$SelectedRepositories {
  Set<String> build() => {};
  void toggle(String path) { ... }
  void clear() => state = {};
  void selectAll(List<String> paths) => state = Set.from(paths);
}
```

**Methods:**
- `toggle(String path)` - Add/remove from selection
- `clear()` - Clear all selections
- `selectAll(List<String> paths)` - Select all provided paths

**Usage:**
```dart
final selected = ref.watch(selectedRepositoriesProvider);
ref.read(selectedRepositoriesProvider.notifier).toggle('/path');
ref.read(selectedRepositoriesProvider.notifier).clear();
```

---

## Data Models

### RepositoryInfo

```rust
pub struct RepositoryInfo {
    pub path: String,
    pub name: String,
    pub current_branch: String,
    pub head_commit_hash: String,
    pub head_commit_message: String,
    pub head_commit_author: String,
    pub head_commit_timestamp: i64,
    pub uncommitted_changes: i32,
    pub untracked_files: i32,
    pub ahead_count: i32,
    pub behind_count: i32,
}
```

### RepoStatus

```rust
pub struct RepoStatus {
    pub files: Vec<FileStatus>,
    pub is_clean: bool,
}
```

### FileStatus

```rust
pub struct FileStatus {
    pub path: String,
    pub status: FileStatusKind,
}

pub enum FileStatusKind {
    Modified,
    New,
    Deleted,
    Renamed,
    Typechange,
}
```

---

## Error Handling

All Rust functions return `anyhow::Result<T>` which is converted to Dart exceptions.

### Error Types (Rust)

```rust
pub enum GitError {
    RepositoryNotFound(String),
    PathError(String),
    OperationFailed(String),
    IoError(String),
}
```

### Handling Errors (Dart)

```dart
try {
  await rust_api.commitRepository(path: path, message: msg);
} on Exception catch (e) {
  if (e.toString().contains('RepositoryNotFound')) {
    // Handle not found
  } else if (e.toString().contains('OperationFailed')) {
    // Handle operation failure
  }
}
```

**Best Practice:** Always wrap FFI calls in try-catch blocks.

---

## Usage Examples

### Complete Workflow Example

```dart
class RepositoryManager {
  final Ref ref;

  Future<void> scanAndCommitAll(String rootPath, String message) async {
    // 1. Scan for repositories
    await ref.read(repositoriesProvider.notifier).scan(rootPath);

    // 2. Wait for repository info to load
    final infos = await ref.read(repositoriesInfoProvider.future);

    // 3. Filter repos with uncommitted changes
    final reposToCommit = infos
        .where((info) => info.uncommittedChanges > 0)
        .map((info) => info.path)
        .toList();

    // 4. Commit all
    final committed = await rust_api.commitMultipleRepositories(
      paths: reposToCommit,
      message: message,
    );

    print('Committed ${committed.length} repositories');
  }

  Future<void> syncAll(String rootPath) async {
    // Scan
    await ref.read(repositoriesProvider.notifier).scan(rootPath);
    final repos = await ref.read(repositoriesProvider.future);

    // Fetch all
    await rust_api.fetchMultipleRepositories(paths: repos);

    // Pull all
    final pulled = await rust_api.pullMultipleRepositories(paths: repos);

    // Push all
    final pushed = await rust_api.pushMultipleRepositories(paths: pulled);

    print('Synced ${pushed.length} repositories');
  }
}
```

### Widget Integration Example

```dart
class RepositoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reposAsync = ref.watch(repositoriesInfoProvider);

    return reposAsync.when(
      data: (repos) => ListView.builder(
        itemCount: repos.length,
        itemBuilder: (context, index) {
          final repo = repos[index];
          return ListTile(
            title: Text(repo.name),
            subtitle: Text(repo.currentBranch),
            trailing: repo.uncommittedChanges > 0
                ? Badge(label: Text('${repo.uncommittedChanges}'))
                : null,
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (e, stack) => ErrorWidget(e),
    );
  }
}
```

---

## Performance Characteristics

| Operation | Time Complexity | Parallelized | Typical Time (100 repos) |
|-----------|----------------|--------------|--------------------------|
| `scan_repositories` | O(n) | ✅ Yes | 1-2 seconds |
| `get_multiple_repository_info` | O(n) | ✅ Yes | 2-3 seconds |
| `commit_multiple_repositories` | O(n) | ✅ Yes | 5-10 seconds |
| `push_multiple_repositories` | O(n) | ✅ Yes | 30-60 seconds |
| `fetch_multiple_repositories` | O(n) | ❌ No | 60-120 seconds |
| `pull_multiple_repositories` | O(n) | ✅ Yes | 30-60 seconds |

---

## Security Considerations

See [SECURITY.md](../SECURITY.md) for full security documentation.

**Critical Issues:**
1. Certificate validation disabled (CRITICAL-1)
2. Hardcoded paths (CRITICAL-2)
3. Path traversal vulnerability (CRITICAL-3)
4. Unvalidated commit messages (CRITICAL-4)
5. Credential leakage (CRITICAL-5)

**Before using in production:** All critical security issues must be resolved.

---

**Last Updated:** October 22, 2025
**API Version:** 0.1.0-alpha

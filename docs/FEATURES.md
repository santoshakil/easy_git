# Easy Git - Feature Specification

## Core Problem
Managing multiple nested git repositories is painful. Need centralized view and control.

## Core Features

### 1. Repository Discovery
- Recursive scan for nested .git directories
- Cache repository list for performance
- Real-time monitoring for new repos
- Handle deep nesting efficiently

### 2. Repository Overview Dashboard
- List all discovered repositories
- Show per repo:
  - Path (relative to root)
  - Current branch
  - Uncommitted changes count
  - Untracked files count
  - Unpushed commits count
  - Ahead/behind remote status
  - Last commit (hash, message, author, date)
  - Dirty/clean state

### 3. Change Management
- View all uncommitted changes across repos
- Per-file diff viewer
- Stage/unstage files
- Discard changes
- Interactive staging
- Filter changes by repo

### 4. Commit Operations
- Single repo commit
- Bulk commit (same message to multiple dirty repos)
- Commit message templates
- Amend last commit
- View commit before pushing

### 5. Push/Pull Operations
- Push single repo
- Bulk push all repos with unpushed commits
- Pull single repo
- Bulk pull all repos
- Fetch all remotes
- Force push (with confirmation)

### 6. History & Logs
- Per-repo commit history
- Combined timeline across all repos
- Filter by:
  - Date range
  - Author
  - Commit message
  - Repository
- View commit details:
  - Full diff
  - Changed files
  - Stats
- Graph view of branches

### 7. Branch Management
- View all branches per repo
- Current branch indicator
- Switch branches
- Create new branch from current
- Delete local/remote branches
- Track remote branches
- Show branch relationships

### 8. Advanced Operations
- Stash save/apply/list/drop
- Cherry-pick commits
- Merge branches
- Rebase interactive
- Conflict resolution UI
- Tag create/list/delete
- Submodule support

### 9. UI/UX Features
- Material Design 3
- Dark/Light theme auto-switch
- Custom theme colors via settings
- Search repositories
- Filter by status (dirty, ahead, behind)
- Sort by name, path, last commit
- Pin favorite repositories
- Bulk select for operations
- Keyboard shortcuts
- Toast notifications
- Progress indicators for long operations
- Error dialogs with details

### 10. Settings
- Root directory selection
- Scan depth limit
- Cache duration
- Git author config
- Default commit message format
- Theme preferences
- Keyboard shortcuts customization

## Non-Functional Requirements

### Performance
- Scan 100+ repos in <2s
- UI responds in <100ms
- Cache invalidation strategy
- Lazy loading for large lists
- Efficient diff computation

### Reliability
- Handle git command failures gracefully
- Validate operations before execution
- Backup before destructive operations
- Error recovery mechanisms

### Maintainability
- SOLID principles
- Clean architecture
- Comprehensive error types
- Logging for debugging
- Unit tests for core logic
- Integration tests for git operations

### Usability
- Intuitive navigation
- Minimal clicks for common tasks
- Clear status indicators
- Helpful error messages
- Undo for safe operations

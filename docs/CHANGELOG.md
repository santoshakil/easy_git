# Changelog

All notable changes to Easy Git will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- ⚠️ **CRITICAL**: Certificate validation bypass identified (CRITICAL-1) - FIX IN PROGRESS
- ⚠️ **CRITICAL**: Hardcoded user path vulnerability (CRITICAL-2) - FIX IN PROGRESS
- ⚠️ **CRITICAL**: Path traversal vulnerability (CRITICAL-3) - FIX IN PROGRESS
- ⚠️ **CRITICAL**: Unvalidated commit messages (CRITICAL-4) - FIX IN PROGRESS
- ⚠️ **CRITICAL**: Credential leakage risk (CRITICAL-5) - FIX IN PROGRESS

### Known Issues
- Test coverage is 0% (target: 70%+)
- 4 Rust clippy warnings need resolution
- Memory leak in Flutter recentFoldersProvider
- Async race condition in repositoriesInfoProvider
- 47 hardcoded colors should use theme
- Missing error boundaries in Flutter widgets

## [0.1.0-alpha] - 2025-10-22

### ⚠️ Security Notice
This is an **alpha release** with **known critical security vulnerabilities**.
**DO NOT USE IN PRODUCTION.** See [SECURITY.md](SECURITY.md) for details.

### Added

#### Core Features
- Repository discovery with parallel recursive scanning
- Multi-repository status overview with visual indicators
- Batch commit across multiple repositories
- Batch push/pull/fetch operations
- Real-time repository status refresh
- Selective repository operations (checkbox selection)
- Recent folders tracking

#### User Interface
- Material Design 3 adaptive theme (dark/light modes)
- Repository list with status badges
- Repository detail panel with file changes
- Commit dialog with validation
- Bulk commit dialog for multiple repos
- Folder picker integration
- Status indicators (ahead/behind, uncommitted, untracked)
- Last commit information display

#### Architecture
- Clean Architecture with Rust backend + Flutter frontend
- Type-safe FFI bridge with flutter_rust_bridge 2.11.1
- Reactive state management with Riverpod 2.6.1
- Parallel processing with Rayon 1.11
- Git operations via libgit2 (git2-rs 0.20)
- Go Router declarative navigation
- SharedPreferences storage for settings

#### Developer Experience
- Comprehensive project documentation
- Development setup guides
- Architecture documentation
- Claude Code integration (.claude/CLAUDE.md)
- Build configuration for macOS

### Technical Details

#### Rust Backend (2,334 LOC)
- 18 modules organized by responsibility
- 20 public FFI functions
- GitRepository wrapper around git2
- Parallel scanner with configurable depth
- Structured error handling with thiserror
- Zero unsafe code blocks

#### Flutter Frontend (4,808 LOC)
- 21 components following feature-based structure
- 8 Riverpod providers for state management
- Material 3 theme extensions
- Custom color scheme system
- Responsive desktop layouts

### Dependencies

#### Rust
- git2 0.20.2 (libgit2 bindings)
- tokio 1.47.1 (async runtime)
- rayon 1.11.0 (parallel processing)
- thiserror 2.0.11 (error handling)
- anyhow 1.0.97 (error context)
- flutter_rust_bridge 2.11.1 (FFI)

#### Flutter
- flutter_riverpod 2.6.1 (state management)
- freezed 2.5.8 (immutable models)
- go_router 14.6.2 (navigation)
- flutter_hooks 0.20.5 (composition)
- shared_preferences 2.3.5 (storage)

### Platform Support
- ✅ macOS (native build)
- ❌ Windows (scaffolded, not tested)
- ❌ Linux (scaffolded, not tested)

### Performance
- Parallel repository scanning with Rayon
- Efficient status checking (single git call per repo)
- Batch operations processed in parallel
- Reactive UI updates via Riverpod streams

### Documentation
- README.md with quick start guide
- ARCHITECTURE.md with technical details
- FEATURES.md with specifications
- SECURITY.md with vulnerability disclosure
- CONTRIBUTING.md with development guidelines
- LICENSE (MIT)
- This CHANGELOG.md

### Known Limitations
- No merge conflict resolution UI
- No branch management beyond viewing current branch
- No stash operations
- No diff viewer for changed files
- No git history viewer
- Pull only supports fast-forward merges
- Fetch uses external git process (should use libgit2)
- No SSH key management
- No credential manager integration
- macOS only (Windows/Linux not implemented)

## Project Milestones

### v0.1.0-beta (Target: 4-6 weeks)
**Goal**: Production-ready security and stability

Planned:
- [ ] Fix all 5 critical security vulnerabilities
- [ ] Achieve 70%+ test coverage
- [ ] Resolve all clippy warnings
- [ ] Fix Flutter memory leaks and race conditions
- [ ] Replace hardcoded colors with theme
- [ ] Add error boundaries
- [ ] External security audit
- [ ] Performance testing with 100+ repositories
- [ ] User acceptance testing

### v0.2.0 (Target: Q1 2026)
**Goal**: Enhanced features and cross-platform support

Planned:
- [ ] Repository details screen with file browser
- [ ] Diff viewer for changed files
- [ ] Branch management (create, switch, delete)
- [ ] Stash operations
- [ ] Git history viewer with graph visualization
- [ ] Windows support
- [ ] Linux support
- [ ] Improved error handling and recovery

### v1.0.0 (Target: Q2 2026)
**Goal**: Production release with full feature set

Planned:
- [ ] Merge conflict resolution UI
- [ ] SSH key management
- [ ] Credential manager integration
- [ ] 80%+ test coverage
- [ ] Comprehensive documentation
- [ ] CI/CD pipeline
- [ ] Auto-update mechanism
- [ ] Analytics (opt-in)
- [ ] Crash reporting
- [ ] Performance benchmarks

## Release Process

### Versioning
- **MAJOR.MINOR.PATCH** (Semantic Versioning)
- **Alpha**: 0.x.0-alpha (unstable, breaking changes)
- **Beta**: 0.x.0-beta (feature complete, stabilizing)
- **RC**: 0.x.0-rc.N (release candidate)
- **Stable**: 1.0.0+ (production ready)

### Release Checklist
- [ ] All tests passing
- [ ] Security audit completed
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Version bumped in pubspec.yaml and Cargo.toml
- [ ] Git tag created
- [ ] GitHub release published
- [ ] Binaries built for all platforms

## Upgrade Guide

### From: Nothing (Initial Release)
This is the first release. No upgrade necessary.

### Future Upgrades
Upgrade instructions will be provided here for each major version.

## Contributors

### Core Team
- Initial Development: Claude Code assisted project

### Community Contributors
*Contributors will be listed here as the project grows*

### Security Researchers
*Security researchers who responsibly disclose vulnerabilities will be recognized here*

## Links

- **Repository**: https://github.com/yourusername/easy_git
- **Issue Tracker**: https://github.com/yourusername/easy_git/issues
- **Documentation**: https://github.com/yourusername/easy_git/tree/main/docs
- **Security**: [SECURITY.md](SECURITY.md)

---

**Legend:**
- ✅ Implemented
- 🚧 In Progress
- ❌ Not Implemented
- ⚠️ Security Issue
- 🐛 Bug Fix
- 🔒 Security Fix
- ⚡ Performance
- 📚 Documentation
- 🎨 UI/UX

**Last Updated**: October 22, 2025

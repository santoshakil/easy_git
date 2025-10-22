# Easy Git

A Flutter desktop application for managing multiple nested git repositories, built with Rust for high-performance git operations.

[![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos/)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.4+-02569B.svg)](https://flutter.dev/)
[![Rust](https://img.shields.io/badge/Rust-1.89.0+-orange.svg)](https://www.rust-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> **⚠️ SECURITY WARNING**: This project is in active development and is **NOT PRODUCTION READY**. A comprehensive security audit identified 30 vulnerabilities - the **3 CRITICAL issues have been FIXED** in v0.1.0, but HIGH priority issues remain. Use with caution. See [docs/SECURITY.md](docs/SECURITY.md) for details.

## Overview

Easy Git simplifies managing projects with multiple nested git repositories by providing a unified interface for viewing status, committing changes, and performing batch operations across all repositories simultaneously.

### Why Easy Git?

Traditional git tools require managing each repository individually, making it painful to work with monorepos or projects with multiple sub-repositories. Easy Git provides:

- **Unified Dashboard**: View all repositories in a single interface
- **Batch Operations**: Commit, push, pull across multiple repos at once
- **Visual Status**: Instant overview of which repos need attention
- **High Performance**: Rust-powered parallel processing for fast scanning
- **Native Desktop**: First-class desktop experience with system integration

## Quick Start

```bash
# Install Flutter dependencies
flutter pub get

# Run the application
flutter run -d macos
```

**First-time setup**: See [Development](#development) section for prerequisites.

## Features

### ✅ Implemented
- **Repository Discovery**: Parallel recursive scanning for nested git repositories
- **Status Overview**: Uncommitted changes, untracked files, ahead/behind counts
- **Branch Display**: Current branch for each repository
- **Commit History**: View last commit with timestamp
- **Batch Commit**: Commit to multiple repositories simultaneously
- **Batch Push/Pull**: Synchronize multiple repositories
- **Material Design 3 UI**: Modern, adaptive interface with dark/light themes
- **Real-time Refresh**: Update repository status on demand
- **Selective Operations**: Choose which repositories to operate on

### 🚧 In Progress
- **Security Hardening**: Fixing 30 identified vulnerabilities (3 CRITICAL)
- **Test Coverage**: Currently ~5% (10 Flutter tests, 0 Rust tests) - targeting 70%+ for v1.0
- **Code Quality**: Addressing 10 critical code issues
- **Essential Features**: Implementing diff viewer (BLOCKER for production)

### 📋 Planned (v0.2.0+)
- Repository details screen with full file diff viewer
- Branch management (create, switch, delete)
- Stash operations
- Git history viewer
- Merge conflict resolution UI
- SSH key management
- Windows and Linux support

## How to Use

1. **Launch the app**: `flutter run -d macos`
2. **Click "Open Folder"**: Choose a directory with git repositories
3. **View Status**: See all nested repos with their current status
4. **Refresh**: Update repository information anytime

## Architecture

Easy Git uses a **Clean Architecture** approach with clear separation between Rust backend and Flutter frontend:

### Rust Core (Backend)
- **git2** (0.20): All git operations via libgit2
- **tokio** (1.47): Async runtime for I/O operations
- **rayon** (1.11): Parallel repository scanning and batch operations
- **thiserror** (2.0): Structured error handling
- **flutter_rust_bridge** (2.11.1): Type-safe FFI boundary

### Flutter UI (Frontend)
- **flutter_riverpod** (2.6.1): Reactive state management
- **freezed** (2.5.8): Immutable data models
- **go_router** (14.6.2): Declarative routing
- **flutter_hooks** (0.20.5): React-style composition
- **Material Design 3**: Adaptive theming system

### Communication Flow
```
┌─────────────┐        FFI         ┌──────────────┐
│   Flutter   │ ◄─────────────────► │     Rust     │
│  (Dart UI)  │   Type-safe calls  │  (git2 ops)  │
└─────────────┘                     └──────────────┘
      │                                     │
      ├─ Riverpod State Management         ├─ Git Repository
      ├─ Material 3 Components             ├─ Parallel Scanner
      └─ Go Router Navigation              └─ Error Handling
```

## Project Structure

```
easy_git/
├── rust/
│   ├── src/
│   │   ├── api/          # FFI-exposed functions
│   │   ├── git/          # Git operations (GitRepository)
│   │   ├── scanner/      # Parallel repository discovery
│   │   ├── models/       # Data structures
│   │   ├── error/        # Error types
│   │   └── utils/        # Path utilities
│   └── tests/            # Rust unit/integration tests (TODO)
├── lib/
│   ├── features/
│   │   ├── repositories/ # Main repository list screen
│   │   └── commits/      # Commit dialogs
│   ├── core/
│   │   ├── theme/        # ColorScheme extensions
│   │   ├── router/       # Go Router configuration
│   │   └── storage/      # SharedPreferences wrapper
│   └── src/rust/         # Generated FFI bindings
├── docs/                 # Architecture & design docs
├── test/                 # Flutter widget tests
└── .claude/              # AI-assisted development context
```

**Key Design Decisions:**
- Rust handles ALL git operations for performance and safety
- Flutter is UI-only, no business logic
- Riverpod providers bridge Rust async operations to reactive UI
- Generated code excluded from version control

See `docs/ARCHITECTURE.md` for detailed technical architecture.

## Development

### Prerequisites

- **Flutter SDK**: 3.35.4 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Rust Toolchain**: 1.89.0 or higher ([Install Rust](https://rustup.rs/))
- **Xcode Command Line Tools** (macOS): `xcode-select --install`
- **Git**: 2.0+ (should be pre-installed on macOS)

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/easy_git.git
cd easy_git

# Install Flutter dependencies
flutter pub get

# Verify Rust toolchain
cargo --version

# Run the app
flutter run -d macos
```

### Development Workflow

```bash
# Run app in debug mode
flutter run -d macos

# Run tests (Rust)
cargo test --manifest-path=rust/Cargo.toml

# Run tests (Flutter)
flutter test

# Code quality checks
flutter analyze                              # Dart linting
cargo clippy --manifest-path=rust/Cargo.toml # Rust linting
cargo check --manifest-path=rust/Cargo.toml  # Rust type checking

# Format code
dart format lib/ test/
cargo fmt --manifest-path=rust/Cargo.toml

# Clean build artifacts
flutter clean
cargo clean --manifest-path=rust/Cargo.toml
```

### Code Generation

When modifying Rust FFI functions or adding new ones:

```bash
# Regenerate Rust ↔ Flutter bindings
flutter_rust_bridge_codegen generate

# This updates:
# - lib/src/rust/api/*.dart
# - lib/src/rust/frb_generated.dart
# - rust/src/frb_generated.rs
```

When modifying Riverpod providers or Freezed models:

```bash
# Regenerate Dart code
dart run build_runner build --delete-conflicting-outputs
```

### Project Conventions

- **NO comments** in code (self-documenting code preferred)
- **NO unwrap()/expect()** in Rust code (use `?` or pattern matching)
- Use `const` constructors wherever possible in Flutter
- Prefix unused variables with `_`
- Expression bodies (`=> expr`) for single-line functions
- All Rust code must pass clippy with zero warnings

## Troubleshooting

### Build Fails with "Undefined symbols for architecture x86_64"

This is fixed by the `.cargo/config.toml` file which links zlib and iconv. If you still have issues:

```bash
# Clean and rebuild
flutter clean
flutter run -d macos
```

### No Repositories Found
- Ensure the selected directory contains `.git` folders
- Check repositories aren't too deeply nested
- Verify git is initialized in those directories

## Documentation

- **[docs/API.md](docs/API.md)** - Complete API reference for FFI functions and providers
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Technical architecture details
- **[docs/FEATURES.md](docs/FEATURES.md)** - Complete feature specification
- **[docs/SECURITY.md](docs/SECURITY.md)** - Security policy and vulnerability disclosure
- **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)** - Contribution guidelines and standards
- **[docs/CHANGELOG.md](docs/CHANGELOG.md)** - Version history and roadmap

## Project Status

**Development Phase**: v0.1.0-alpha (Pre-Beta)
**Production Ready**: ❌ **NOT READY** - HIGH priority security issues and missing features remain
**Security Status**: 3 CRITICAL fixed, 27 remaining (7 HIGH, 12 MEDIUM, 8 LOW)
**Test Coverage**: ~5% (10 Flutter tests, 0 Rust tests) - Target: 70% for v1.0
**Code Quality**: B- (Good architecture, critical fixes needed)
**Overall Score**: 35/100

### Comprehensive Audit Results

**✅ Strengths:**
- ✅ Core Architecture (92/100 - Excellent Clean Architecture)
- ✅ Repository Scanner (Parallel processing implemented)
- ✅ Status Display (Material 3 UI working)
- ✅ Batch Operations (Functional but need hardening)
- ✅ **Documentation**: Comprehensive and well-organized

**✅ Fixed in v0.1.0:**
- ✅ **VULN-001**: Command Injection (CVSS 9.8) - Fixed with URL sanitization
- ✅ **VULN-002**: Sensitive Data Exposure (CVSS 9.1) - Fixed with error sanitization
- ✅ **VULN-003**: Path Traversal (CVSS 8.6) - Fixed with path validation
- ✅ **Integer Overflow**: Fixed with safe type conversion

**❌ Remaining Blockers (MUST FIX):**
- ❌ **Test Coverage**: 0 Rust tests, minimal Flutter tests
- ❌ **Missing Diff Viewer**: Cannot review changes before commit
- ❌ **47 Hardcoded Colors**: Breaks dark theme
- ❌ **Mega File**: 1041-line file needs refactoring

**⚠️ High Priority Issues:**
- ⚠️ Missing TLS certificate validation
- ⚠️ Insecure credential storage in memory
- ⚠️ Race conditions in parallel operations
- ⚠️ Missing input validation
- ⚠️ Memory leak risk (missing autodispose)
- ⚠️ Performance issues (inefficient list rendering)

### Required Before ANY Production Use

1. **✅ Fix CRITICAL Security** (COMPLETED in v0.1.0):
   - ✅ Command injection vulnerability - FIXED
   - ✅ Error message sanitization - FIXED
   - ✅ Path traversal validation - FIXED
   - ✅ Integer overflow fixes - FIXED

2. **Build Test Suite** (Week 1-3):
   - Rust unit tests (0 → 100+ tests)
   - Flutter widget tests expansion
   - Integration tests
   - Security regression tests
   - Target: 70%+ coverage

3. **Essential Features** (Week 4-5):
   - Implement diff viewer
   - Add keyboard shortcuts
   - Settings screen
   - Error logging

4. **Code Quality** (Week 6):
   - Extract 1041-line mega file
   - Replace 47 hardcoded colors
   - Add autodispose to providers
   - Optimize list rendering

5. **Final Hardening** (Week 7):
   - External security audit
   - Performance testing
   - User acceptance testing
   - Bug fixes

**Realistic timeline to v1.0**: 5-7 weeks with focused development

## Roadmap

### v0.1.0-alpha (Current - In Progress)
- [x] Repository scanning with parallel processing
- [x] Status overview with Material 3 UI
- [x] Folder picker integration
- [x] Batch commit functionality
- [x] Push/pull/fetch operations
- [x] **Complete API documentation**
- [ ] **Security hardening** (30 vulnerabilities to fix)
- [ ] **Build test suite** (0 → 70%+ coverage)
- [ ] **Implement diff viewer**
- [ ] **Fix code quality issues**

### v0.1.0-beta (Target: 6-8 weeks)
- [ ] All CRITICAL security vulnerabilities fixed (3)
- [ ] All HIGH priority security issues fixed (7)
- [ ] Test coverage reaches 70%+ minimum
- [ ] Diff viewer implemented
- [ ] Code refactoring complete
- [ ] Beta testing with real users
- [ ] Bug fixes from testing

### v0.2.0 - Enhanced Features
- [ ] Repository details screen with file browser
- [ ] Diff viewer for changed files
- [ ] Branch management (create, switch, delete)
- [ ] Stash operations
- [ ] Git history viewer with graph
- [ ] Merge conflict resolution UI

### v1.0.0 - Production Release
- [ ] All security audits passed
- [ ] 80%+ test coverage
- [ ] Performance benchmarks met
- [ ] Windows support
- [ ] Linux support
- [ ] User documentation complete
- [ ] CI/CD pipeline established

## Contributing

Contributions are welcome! Please see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

**Areas needing help:**
- Test coverage expansion (Rust integration tests, Flutter widget tests)
- Windows and Linux support
- UI/UX enhancements
- Performance optimization
- Additional git features

**Before contributing**, please:
1. Read [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)
2. Check [open issues](https://github.com/yourusername/easy_git/issues)
3. Review [docs/SECURITY.md](docs/SECURITY.md) for security guidelines

## Security

**⚠️ SECURITY WARNING**: A comprehensive security audit identified **30 vulnerabilities** in v0.1.0-pre-alpha. The **3 CRITICAL issues** (CVSS 9.8, 9.1, 8.6) have been **FIXED** in v0.1.0. However, **HIGH priority issues remain** (TLS validation, credential security, race conditions).

**⚠️ USE WITH CAUTION**: While critical vulnerabilities are fixed, this software still requires comprehensive security testing and additional hardening before production use.

### Critical Vulnerabilities (Fixed in v0.1.0)

1. **✅ VULN-001**: Command Injection (CVSS 9.8) - FIXED with URL sanitization
2. **✅ VULN-002**: Sensitive Data Exposure (CVSS 9.1) - FIXED with error message sanitization
3. **✅ VULN-003**: Path Traversal (CVSS 8.6) - FIXED with proper path validation

**Note**: While critical vulnerabilities have been fixed, the project still has HIGH priority security issues (TLS validation, credential security, race conditions) and requires comprehensive testing before production use.

If you discover additional security vulnerabilities, please see [docs/SECURITY.md](docs/SECURITY.md) for responsible disclosure guidelines.

**DO NOT create public issues for security vulnerabilities.**

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgments

Built with:
- [Flutter](https://flutter.dev/) - Beautiful cross-platform UI framework
- [Rust](https://www.rust-lang.org/) - Safe, fast systems programming
- [git2-rs](https://github.com/rust-lang/git2-rs) - libgit2 bindings for Rust
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) - Seamless Rust ↔ Flutter integration

Special thanks to the open-source community for these amazing tools.

---

<div align="center">

**Status**: 🚧 Active Development (Alpha)
**Platform**: macOS (Windows/Linux planned)
**Last Updated**: October 22, 2025

Made with Flutter + Rust

[Report Bug](https://github.com/yourusername/easy_git/issues) · [Request Feature](https://github.com/yourusername/easy_git/issues) · [Documentation](docs/)

</div>

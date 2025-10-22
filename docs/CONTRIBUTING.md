# Contributing to Easy Git

Thank you for your interest in contributing to Easy Git! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Security](#security)

## Code of Conduct

Be respectful, constructive, and professional. We aim to maintain a welcoming environment for all contributors.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Environment details** (OS, Flutter version, Rust version)
- **Screenshots** (if applicable)
- **Error messages or logs**

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

- Check if the enhancement has already been suggested
- Provide a clear use case
- Explain why this would be useful
- Consider implementation complexity

### Areas Needing Help

Priority areas where contributions are especially welcome:

1. **Security Fixes** - See [SECURITY.md](SECURITY.md) for known vulnerabilities
2. **Test Coverage** - Currently 0%, targeting 70%+
3. **Platform Support** - Windows and Linux implementations
4. **Documentation** - User guides, API docs, tutorials
5. **UI/UX Improvements** - Accessibility, polish, refinements

### Pull Requests

We actively welcome pull requests for:

- Bug fixes
- Documentation improvements
- Test coverage additions
- Performance optimizations
- UI/UX enhancements
- Platform support (Windows, Linux)

## Development Setup

### Prerequisites

- Flutter SDK 3.35.4+
- Rust toolchain 1.89.0+
- Git 2.0+
- Xcode Command Line Tools (macOS)

### Setup Steps

```bash
# Fork and clone the repository
git clone https://github.com/yourusername/easy_git.git
cd easy_git

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
cargo --version

# Run the app
flutter run -d macos
```

### Project Structure

```
easy_git/
├── rust/src/          # Rust backend (all git operations)
├── lib/               # Flutter frontend (UI only)
├── test/              # Flutter tests
├── docs/              # Documentation
└── .claude/           # AI development context
```

## Coding Standards

### General Principles

- **Clean Code**: Self-documenting code preferred over comments
- **KISS**: Keep it simple and straightforward
- **DRY**: Don't repeat yourself
- **SOLID**: Follow SOLID principles

### Rust Code Style

**REQUIRED**:
- ✅ Zero `unwrap()` or `expect()` calls (use `?` or pattern matching)
- ✅ All code must pass `cargo clippy` with zero warnings
- ✅ Use `thiserror` for error types
- ✅ Proper error context with `anyhow`
- ✅ All public APIs must be `#[frb]` annotated for FFI

**Preferred**:
- Use `&str` over `String` in function parameters
- Pre-allocate `Vec` capacity when size is known
- Leverage iterators over index loops
- Use `Arc` for shared immutable data
- Leverage rayon for parallelization where appropriate

**Example**:
```rust
pub fn get_status(&self) -> Result<RepositoryStatus> {
    let statuses = self.repo.statuses(None)?;

    let files: Vec<FileStatus> = statuses
        .iter()
        .filter_map(|entry| {
            Some(FileStatus {
                path: entry.path()?.to_string(),
                status: Self::convert_status(entry.status()),
            })
        })
        .collect();

    Ok(RepositoryStatus { files })
}
```

### Dart/Flutter Code Style

**REQUIRED**:
- ✅ All code must pass `flutter analyze` with zero errors
- ✅ Use `const` constructors wherever possible
- ✅ Dispose all controllers and streams
- ✅ Use Riverpod for state management
- ✅ Follow Material Design 3 guidelines

**Preferred**:
- Use `var` for local variables
- Expression bodies (`=> expr`) for single-line methods
- Tearoffs over lambdas: `setUpAll(init)` not `setUpAll(() => init())`
- Cascades for multiple operations: `obj..a = 1..b = 2`
- Prefix unused variables with `_`

**Example**:
```dart
@riverpod
class Repositories extends _$Repositories {
  @override
  Future<List<String>> build() async => [];

  Future<void> scan(String path) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await rust_api.scanRepositories(rootPath: path);
    });
  }
}
```

### Code Comments

**Philosophy**: Code should be self-documenting. Only add comments when:

- Explaining **WHY** (not what) for non-obvious logic
- Documenting public APIs (Rust doc comments)
- Noting security considerations
- Referencing external resources (RFCs, Stack Overflow, etc.)

**DO NOT** add comments for:
- Obvious code behavior
- Restating what the code does
- Commented-out code (delete it)

## Commit Guidelines

### Commit Message Format

```
type(scope): brief description

Detailed explanation of what changed and why.

Fixes #123
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `security`: Security fix
- `perf`: Performance improvement
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `docs`: Documentation changes
- `chore`: Build process, dependencies, etc.

### Examples

```
feat(scanner): add max depth configuration for repository scanning

Users can now limit how deep the scanner searches for repositories.
This prevents stack overflow on deeply nested directories.

Fixes #45
```

```
security(git): fix certificate validation bypass

Certificate validation was completely disabled, allowing MITM attacks.
This commit implements proper certificate checking with user override
options for self-signed certificates.

Fixes CRITICAL-1
```

## Pull Request Process

### Before Submitting

1. **Fork the repository** and create a feature branch
2. **Write or update tests** for your changes
3. **Run all checks**:
   ```bash
   flutter analyze
   flutter test
   cargo clippy --manifest-path=rust/Cargo.toml
   cargo test --manifest-path=rust/Cargo.toml
   ```
4. **Update documentation** if needed
5. **Follow commit guidelines** above

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Security fix
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All tests passing

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] All CI checks passing

## Screenshots (if applicable)
Add screenshots here

## Related Issues
Closes #123
```

### Review Process

1. **Automated checks** must pass (CI/CD)
2. **Code review** by at least one maintainer
3. **Security review** for security-sensitive changes
4. **Testing verification** - all tests must pass
5. **Approval** and merge by maintainer

### After Merge

- Your contribution will be included in the next release
- You'll be credited in CHANGELOG.md
- Security contributions recognized in SECURITY.md Hall of Fame

## Testing Requirements

### Minimum Requirements

All PRs must include tests unless they are documentation-only changes.

### Test Coverage Goals

- **Rust**: 70%+ line coverage for new code
- **Flutter**: 70%+ line coverage for new code
- **Critical paths**: 100% coverage (security, data integrity)

### Writing Tests

**Rust Tests**:
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_repository_scan() {
        let scanner = RepositoryScanner::default();
        let result = scanner.scan("/test/path");
        assert!(result.is_ok());
    }
}
```

**Flutter Tests**:
```dart
void main() {
  testWidgets('Repository list shows repositories', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: App()),
    );

    expect(find.text('Repositories'), findsOneWidget);
  });
}
```

### Running Tests

```bash
# Run all Rust tests
cargo test --manifest-path=rust/Cargo.toml

# Run all Flutter tests
flutter test

# Run with coverage
cargo tarpaulin --manifest-path=rust/Cargo.toml
flutter test --coverage
```

## Security

### Security-Sensitive Changes

If your PR touches security-sensitive code:

1. **Review [SECURITY.md](SECURITY.md)** first
2. **Document security implications** in PR description
3. **Add security tests** to verify the fix
4. **Request security review** from maintainers
5. **Consider threat model** implications

### Security-Sensitive Areas

- Git credential handling
- Network operations (fetch, push, pull)
- Path handling and file operations
- FFI boundary between Rust and Dart
- User input validation
- Error messages (avoid information leakage)

### Reporting Security Issues

**DO NOT** open public PRs for security vulnerabilities. Instead:

1. Email security@yourproject.com
2. Follow coordinated disclosure process
3. Allow time for patch development
4. See [SECURITY.md](SECURITY.md) for full process

## Documentation

### What Needs Documentation

- Public APIs (Rust doc comments)
- Architecture decisions (docs/ARCHITECTURE.md)
- User-facing features (docs/ or README.md)
- Complex algorithms or logic
- Security considerations

### Documentation Style

- **Clear and concise**
- **Examples for complex features**
- **Code samples that work**
- **Keep up-to-date** with code changes

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue
- **Security**: Email security@yourproject.com
- **Chat**: [Discord/Slack link] (if available)

## Recognition

Contributors are recognized in:

- CHANGELOG.md for each release
- GitHub contributors page
- SECURITY.md Hall of Fame (for security contributions)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Easy Git! 🎉

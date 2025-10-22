# Security Policy

## Current Security Status

⚠️ **IMPORTANT**: Easy Git is currently in **alpha development** and has **known security vulnerabilities** that must be resolved before production use.

**DO NOT USE IN PRODUCTION ENVIRONMENTS**

### Known Critical Vulnerabilities

As of October 22, 2025, the following critical security issues have been identified:

1. **CRITICAL-1**: Certificate validation disabled - MITM attack vulnerability
2. **CRITICAL-2**: Hardcoded user paths - Information disclosure
3. **CRITICAL-3**: Path traversal vulnerability - Unauthorized file access
4. **CRITICAL-4**: Unvalidated commit messages - Potential command injection
5. **CRITICAL-5**: Credential leakage via external process - Credential theft risk

**Status**: All vulnerabilities are documented and tracked. Fixes are in progress.

**ETA for fixes**: 4-6 weeks

## Supported Versions

| Version | Supported | Security Status |
| ------- | --------- | --------------- |
| 0.1.0-alpha | ❌ | Known vulnerabilities - development only |
| < 0.1.0 | ❌ | Not supported |

**Production-ready versions**: None yet. First secure release will be v0.1.0-beta.

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow responsible disclosure practices.

### DO:
- Email security reports to: **[security@yourproject.com]** (update with actual email)
- Provide detailed information about the vulnerability
- Allow 90 days for coordinated disclosure
- Encrypt sensitive details using our PGP key (if available)

### DO NOT:
- Open public GitHub issues for security vulnerabilities
- Disclose vulnerabilities publicly before patches are available
- Exploit vulnerabilities maliciously

### What to Include

When reporting a vulnerability, please include:

1. **Description**: Clear description of the vulnerability
2. **Impact**: Potential security impact and severity
3. **Reproduction**: Step-by-step instructions to reproduce
4. **Affected versions**: Which versions are affected
5. **Suggested fix**: If you have one (optional but appreciated)
6. **Disclosure timeline**: Your preferred disclosure timeline

### Example Report

```
Subject: [SECURITY] Potential XSS vulnerability in commit message display

Description:
User-supplied commit messages are rendered without sanitization, potentially
allowing JavaScript execution.

Impact:
An attacker could craft a malicious commit message containing JavaScript
that executes when viewed by other users.

Reproduction:
1. Create commit with message: <img src=x onerror=alert(1)>
2. View commit in Easy Git
3. JavaScript executes

Affected Versions:
v0.1.0-alpha and earlier

Suggested Fix:
Sanitize HTML entities before rendering commit messages.

Contact: researcher@example.com
PGP: [key fingerprint]
```

## Response Timeline

We aim to respond to security reports according to this timeline:

- **Initial Response**: Within 48 hours
- **Vulnerability Assessment**: Within 7 days
- **Fix Development**: 14-30 days (depending on severity)
- **Coordinated Disclosure**: 90 days from initial report

For critical vulnerabilities, we will expedite patches and may issue emergency releases.

## Security Best Practices for Users

While using Easy Git (development versions):

1. **Never use with sensitive repositories** containing proprietary code, secrets, or credentials
2. **Review all git operations** before confirming, especially batch operations
3. **Avoid untrusted networks** when performing push/pull operations
4. **Keep software updated** - install security patches immediately
5. **Use SSH keys** instead of passwords for git authentication
6. **Review permissions** - only grant access to directories you trust

## Security Measures in Development

We implement the following security practices:

### Code Review
- All changes reviewed before merging
- Security-focused code reviews for sensitive areas
- Automated static analysis (clippy, dart analyze)

### Testing
- Unit tests for security-critical functions
- Integration tests for git operations
- Fuzzing for path handling and input validation

### Dependencies
- Regular dependency updates
- Automated vulnerability scanning with `cargo audit`
- Minimal dependency footprint

### Development Process
- Secure coding guidelines enforced
- No hardcoded secrets or credentials
- Comprehensive error handling
- Input validation on all user inputs

## Security Roadmap

### Before v0.1.0-beta (BLOCKING)
- [ ] Fix all 5 critical vulnerabilities
- [ ] Implement certificate validation
- [ ] Add path traversal protection
- [ ] Secure credential handling
- [ ] Input validation and sanitization

### Before v1.0.0
- [ ] External security audit
- [ ] Penetration testing
- [ ] Fuzzing infrastructure
- [ ] Automated security scanning in CI
- [ ] Security documentation complete

### Ongoing
- Monthly dependency updates
- Quarterly security reviews
- Continuous monitoring for new vulnerabilities
- Community security feedback incorporation

## Security Hall of Fame

We recognize security researchers who responsibly disclose vulnerabilities:

*List will be maintained here once we start receiving reports*

## PGP Key

*PGP key for encrypted security reports will be added here*

## Contact

- **Security Email**: [security@yourproject.com] (create this)
- **Response Time**: 48 hours maximum
- **Coordinated Disclosure**: 90 days standard

## Additional Resources

- [OWASP Desktop Security Guide](https://owasp.org/)
- [Rust Security Guidelines](https://anssi-fr.github.io/rust-guide/)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)

---

**Last Updated**: October 22, 2025
**Next Review**: November 22, 2025

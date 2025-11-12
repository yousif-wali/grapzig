# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in Grapzig, please report it by:

1. **DO NOT** open a public issue
2. Email: [your-email@example.com] (replace with your email)
3. Or use GitHub's private vulnerability reporting:
   - Go to https://github.com/yousif-wali/grapzig/security/advisories
   - Click "New draft security advisory"

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Time

- We aim to respond within 48 hours
- We will provide a fix within 7 days for critical issues
- You will be credited in the security advisory (unless you prefer to remain anonymous)

## Security Best Practices

When using Grapzig:

1. **Use ArenaAllocator** for request-scoped memory management
2. **Validate all input** before passing to Grapzig
3. **Limit query depth** to prevent DoS attacks
4. **Set query timeouts** in your application
5. **Rate limit** GraphQL endpoints
6. **Sanitize error messages** before returning to clients

## Disclosure Policy

- Security issues will be disclosed publicly after a fix is released
- We follow responsible disclosure practices
- Critical vulnerabilities will be patched before public disclosure

---

**Thank you for helping keep Grapzig secure!**

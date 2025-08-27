# Vulnerabilities Guide (Go Web App)

This application contains intentionally introduced security vulnerabilities for educational purposes.

## Authentication & Authorization
- **No Authentication Required**: Admin and file endpoints accessible without login
- **Weak Session Management**: Hardcoded secret keys, no session validation
- **No CSRF Protection**: All endpoints vulnerable to CSRF attacks
- **No Role-Based Access Control**: Admin functions accessible to any user

## Input Validation & Sanitization
- **SQL Injection**: Direct string concatenation in database queries
- **No Input Validation**: Username, email, and file parameters not sanitized
- **Path Traversal**: File operations vulnerable to directory traversal attacks
- **No File Type Validation**: Uploads accept any file type without restrictions

## Security Headers & Configuration
- **No Security Headers**: Missing HSTS, CSP, X-Frame-Options, etc.
- **No CORS Protection**: Cross-origin requests not restricted
- **No Rate Limiting**: Endpoints vulnerable to brute force attacks
- **No TLS/HTTPS**: Application runs over HTTP only

## Password Security
- **Weak Hashing**: Uses MD5 (cryptographically broken)
- **No Salt**: Passwords stored without unique salts
- **Weak Validation**: Only checks minimum length (3 characters)
- **Timing Attacks**: Password comparison vulnerable to timing attacks

## File Security
- **Unrestricted Uploads**: No file size limits enforced
- **Path Traversal**: Can access files outside upload directory
- **No Access Control**: Users can access/modify any uploaded files
- **Dangerous Permissions**: Upload directory has 755 permissions

## Database Security
- **No Prepared Statements**: SQL queries vulnerable to injection
- **No Input Sanitization**: User input directly used in queries
- **Weak Error Handling**: Database errors may leak sensitive information

## Session Security
- **Predictable Session IDs**: Weak random generation
- **No Expiration**: Sessions don't expire properly
- **Insecure Cookies**: Missing secure, httpOnly, and sameSite flags
- **Session Fixation**: No session regeneration after login

## API Security
- **No Rate Limiting**: Endpoints can be abused for DoS
- **No Input Validation**: JSON payloads not validated
- **No Output Encoding**: Response data not properly encoded
- **Information Disclosure**: Error messages reveal internal details

## Recommendations for Production
1. Implement proper authentication and authorization
2. Use prepared statements for all database queries
3. Validate and sanitize all user inputs
4. Implement CSRF protection
5. Use strong password hashing (bcrypt, Argon2)
6. Add security headers and HTTPS
7. Implement rate limiting and input validation
8. Use secure session management
9. Add file upload restrictions and validation
10. Implement proper error handling without information disclosure 

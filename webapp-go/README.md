# Go Web Application

Deliberately vulnerable Go web application for security testing and education.

## Features
- User authentication (register/login/logout)
- Admin panel (user management)
- File upload/download system
- Session management

## Vulnerabilities
This application contains multiple intentional security vulnerabilities including:
- SQL injection
- Path traversal
- No authentication/authorization
- Weak password hashing
- No CSRF protection
- No input validation

## Quick Start

### Prerequisites
- Go 1.21+

### Install Dependencies
```bash
go mod tidy
```

### Run
```bash
./scripts/run.sh
```

The application will start on port 8080.

## API Endpoints
- `POST /api/register` - User registration
- `POST /api/login` - User login
- `POST /api/logout` - User logout
- `GET /api/admin/users` - List all users (no auth required!)
- `GET /api/admin/search?q=<term>` - Search users (SQL injection!)
- `DELETE /api/admin/users?id=<id>` - Delete user
- `POST /api/files/upload` - Upload file (path traversal!)
- `GET /api/files/download?file=<filename>` - Download file
- `GET /api/files` - List files
- `DELETE /api/files?file=<filename>` - Delete file

## See `VULNERABILITIES.md` for detailed vulnerability information. 

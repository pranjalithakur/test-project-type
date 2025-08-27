#!/usr/bin/env bash
set -euo pipefail

echo "Starting vulnerable Go web application..."
echo "WARNING: This application contains intentional security vulnerabilities!"
echo "Do not use in production environments."

# Create uploads directory if it doesn't exist
mkdir -p uploads

# Run the application
go run cmd/server/main.go 

#!/bin/bash

# Build script for Go Lambda function
set -e

echo "Building Go Lambda function..."

# Create build directory
mkdir -p build

# Copy WIF credential files to build directory
cp ../trigger_dag/build/wif_direct_access.json build/ 2>/dev/null || echo "Warning: wif_direct_access.json not found"
cp ../trigger_dag/build/wif_sa_access.json build/ 2>/dev/null || echo "Warning: wif_sa_access.json not found"

# Build the Go binary for Linux (required for AWS Lambda)
echo "Building Go binary for Linux..."
GOOS=linux GOARCH=amd64 go build -o build/main

# Create deployment package
echo "Creating deployment package..."
cd build
zip -r ../trigger_dag_go.zip .
cd ..

echo "Build completed successfully!"
echo "Deployment package: trigger_dag_go.zip"

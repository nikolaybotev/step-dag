#!/bin/bash
#
# Build script for Python Lambda functions.
# Creates deployment packages (zip files) for AWS Lambda.
#

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_DIR="$SCRIPT_DIR"

# List of Lambda functions to build
LAMBDA_FUNCTIONS=("hello_world" "timestamp" "trigger_dag")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to clean build artifacts
clean_build_artifacts() {
    print_info "Cleaning previous build artifacts..."
    for lambda_name in "${LAMBDA_FUNCTIONS[@]}"; do
        artifact="$lambda_name.zip"
        artifact_path="$LAMBDA_DIR/$artifact"
        if [ -f "$artifact_path" ]; then
            rm "$artifact_path"
            print_info "Removed: $artifact"
        fi
    done
}

# Function to clean dependencies
clean_dependencies() {
    print_info "Cleaning installed dependencies..."
    for lambda_name in "${LAMBDA_FUNCTIONS[@]}"; do
        dir_path="$LAMBDA_DIR/$lambda_name"
        if [ -d "$dir_path" ]; then
            # Remove build directory
            build_dir="$dir_path/build"
            if [ -d "$build_dir" ]; then
                rm -rf "$build_dir"
                print_info "Cleaned: $build_dir"
            fi
            
            # Remove __pycache__ directories
            find "$dir_path" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        fi
    done
}

# Function to build a Lambda function
build_lambda_function() {
    local source_dir="$1"
    local output_zip="$2"
    
    # Convert to absolute paths
    local source_path="$LAMBDA_DIR/$source_dir"
    local output_path="$LAMBDA_DIR/$output_zip"
    
    print_info "Building $source_dir -> $output_zip"
    
    if [ ! -d "$source_path" ]; then
        print_error "Source directory $source_path does not exist"
        return 1
    fi
    
    # Create build directory
    local build_dir="$source_path/build"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    # Install dependencies if requirements.txt exists
    local requirements_file="$source_path/requirements.txt"
    if [ -f "$requirements_file" ]; then
        print_info "Installing dependencies for $source_dir"
        pip3 install -r "$requirements_file" -t "$build_dir" --platform manylinux2014_x86_64 --only-binary=:all:
    else
        print_info "No requirements.txt found, skipping dependencies"
    fi
    
    # Copy source files to build directory
    cp "$source_path/index.py" "$build_dir/"
    
    # Create zip file
    print_info "Creating zip package: $output_zip"
    cd "$build_dir"
    zip -r "$output_path" . -q
    cd - > /dev/null
    
    print_info "Successfully built: $output_zip"
}

# Main build function
main() {
    print_info "Building Python Lambda functions..."
    print_info "Working directory: $LAMBDA_DIR"
    
    # Build each Lambda function
    for lambda_name in "${LAMBDA_FUNCTIONS[@]}"; do
        build_lambda_function "$lambda_name" "$lambda_name.zip"
    done
    
    echo
    print_info "Build completed successfully!"
    print_info "Run '$(basename "$0") --clean' to remove installed dependencies."
}

# Check command line arguments
if [ "$1" = "--clean" ]; then
    clean_dependencies
    clean_build_artifacts
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $(basename "$0") [OPTION]"
    echo "Options:"
    echo "  --clean    Clean installed dependencies from source directories"
    echo "  --help     Show this help message"
    echo "  (no args)  Build all Lambda functions"
else
    main
fi

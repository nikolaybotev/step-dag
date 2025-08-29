#!/bin/bash
"""
Build script for Python Lambda functions.
Creates deployment packages (zip files) for AWS Lambda.
"""

set -e  # Exit on any error

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
    artifacts=("hello_world.zip" "timestamp.zip" "trigger_dag.zip")
    for artifact in "${artifacts[@]}"; do
        if [ -f "$artifact" ]; then
            rm "$artifact"
            print_info "Removed: $artifact"
        fi
    done
}

# Function to clean dependencies
clean_dependencies() {
    print_info "Cleaning installed dependencies..."
    dirs_to_clean=("hello_world" "timestamp" "trigger_dag")
    for dir_name in "${dirs_to_clean[@]}"; do
        if [ -d "$dir_name" ]; then
            # Remove build directory
            build_dir="$dir_name/build"
            if [ -d "$build_dir" ]; then
                rm -rf "$build_dir"
                print_info "Cleaned: $build_dir"
            fi
            
            # Remove __pycache__ directories
            find "$dir_name" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        fi
    done
}

# Function to build a Lambda function
build_lambda_function() {
    local source_dir="$1"
    local output_zip="$2"
    
    print_info "Building $source_dir -> $output_zip"
    
    if [ ! -d "$source_dir" ]; then
        print_error "Source directory $source_dir does not exist"
        return 1
    fi
    
    # Create build directory
    local build_dir="$source_dir/build"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    # Install dependencies if requirements.txt exists
    local requirements_file="$source_dir/requirements.txt"
    if [ -f "$requirements_file" ]; then
        print_info "Installing dependencies for $source_dir"
        pip3 install -r "$requirements_file" -t "$build_dir" --platform manylinux2014_x86_64 --only-binary=:all:
    else
        print_info "No requirements.txt found, skipping dependencies"
    fi
    
    # Copy source files to build directory
    cp "$source_dir/index.py" "$build_dir/"
    
    # Create zip file
    cd "$build_dir"
    zip -r "$output_zip" . > /dev/null
    cd - > /dev/null
    
    # Move zip file to parent directory
    mv "$build_dir/$output_zip" ./
    
    print_info "Successfully built: $output_zip"
}

# Main build function
main() {
    print_info "Building Python Lambda functions..."
    
    # Build each Lambda function
    build_lambda_function "hello_world" "hello_world.zip"
    build_lambda_function "timestamp" "timestamp.zip"
    build_lambda_function "trigger_dag" "trigger_dag.zip"
    
    echo
    print_info "Build completed successfully!"
    print_info "Generated files:"
    echo "  - hello_world.zip"
    echo "  - timestamp.zip"
    echo "  - trigger_dag.zip"
    echo
    print_info "Note: Dependencies are included in the zip files."
    print_info "Run './build.sh --clean' to remove installed dependencies."
}

# Check command line arguments
if [ "$1" = "--clean" ]; then
    clean_dependencies
    clean_build_artifacts
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  --clean    Clean installed dependencies from source directories"
    echo "  --help     Show this help message"
    echo "  (no args)  Build all Lambda functions"
else
    main
fi

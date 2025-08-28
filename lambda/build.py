#!/usr/bin/env python3
"""
Build script for Python Lambda functions.
Creates deployment packages (zip files) for AWS Lambda.
"""

import os
import zipfile
import shutil
from pathlib import Path

def create_lambda_package(source_dir, output_zip):
    """
    Create a zip file for Lambda deployment.
    
    Args:
        source_dir: Directory containing the Lambda function source
        output_zip: Path to the output zip file
    """
    print(f"Building {source_dir} -> {output_zip}")
    
    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, source_dir)
                zipf.write(file_path, arcname)
                print(f"  Added: {arcname}")

def clean_build_artifacts():
    """Remove existing build artifacts."""
    artifacts = ['hello_world.zip', 'timestamp.zip', 'trigger_dag.zip']
    for artifact in artifacts:
        if os.path.exists(artifact):
            os.remove(artifact)
            print(f"Removed: {artifact}")

def main():
    """Main build function."""
    print("Building Python Lambda functions...")
    
    # Clean previous builds
    clean_build_artifacts()
    
    # Build each Lambda function
    create_lambda_package('hello_world', 'hello_world.zip')
    create_lambda_package('timestamp', 'timestamp.zip')
    create_lambda_package('trigger_dag', 'trigger_dag.zip')
    
    print("\nBuild completed successfully!")
    print("Generated files:")
    print("  - hello_world.zip")
    print("  - timestamp.zip")
    print("  - trigger_dag.zip")

if __name__ == "__main__":
    main()

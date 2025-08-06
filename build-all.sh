#!/bin/bash

echo "RTMP Playback Authentication - Complete Build Script"
echo "======================================================"

# Step 1: Check prerequisites
echo "Step 1: Checking prerequisites..."

# Check Java
if ! command -v java &> /dev/null || ! command -v javac &> /dev/null; then
    echo "Error: Java JDK not found. Please install JDK 8 or later."
    exit 1
fi

# Check Wowza (using default path)
WOWZA_HOME="/usr/local/WowzaStreamingEngine"
if [ ! -d "$WOWZA_HOME" ]; then
    echo "Warning: Wowza not found at $WOWZA_HOME"
    echo "Edit set_classpath.sh to set correct WOWZA_HOME"
    echo "Continuing with compilation (deployment will require correct path)..."
fi

echo "✓ Prerequisites checked"

# Step 2: Compile
echo ""
echo "Step 2: Compiling module..."
./compile.sh

if [ $? -ne 0 ]; then
    echo "Build failed at compilation step"
    exit 1
fi

# Step 3: Create package
echo ""
echo "Step 3: Creating deployment package..."
./create-package.sh

if [ $? -ne 0 ]; then
    echo "Package creation failed"
    exit 1
fi

echo ""
echo "✓ Build completed successfully!"
echo ""
echo "Files created:"
echo "- dist/rtmp-playback-auth.jar (compiled module)"
echo "- rtmp-playback-auth-deployment.tar.gz (deployment package)"
if [ -f "rtmp-playback-auth-deployment.zip" ]; then
    echo "- rtmp-playback-auth-deployment.zip (deployment package)"
fi
echo ""
echo "Next steps:"
echo "1. Local deployment: ./deploy.sh"
echo "2. Remote deployment: copy deployment package to target server"
echo "3. Remote install: extract package and run install.sh"

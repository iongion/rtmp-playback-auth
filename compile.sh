#!/bin/bash

echo "Compiling RTMP Playback Authentication Module..."

# Set classpath
source ./set_classpath.sh

if [ $? -ne 0 ]; then
    echo "Failed to set classpath. Please check WOWZA_HOME in set_classpath.sh"
    exit 1
fi

# Compile the Java source
echo "Compiling Java source..."
javac -cp "$CLASSPATH" \
      -d build/classes \
      src/main/java/com/wowza/wms/plugin/security/ModuleRTMPPlaybackAuthentication.java

if [ $? -eq 0 ]; then
    echo "✓ Compilation successful"
    
    # Create JAR file
    echo "Creating JAR file..."
    cd build/classes
    jar cvf ../../dist/rtmp-playback-auth.jar com/
    cd ../..
    
    if [ -f "dist/rtmp-playback-auth.jar" ]; then
        echo "✓ JAR created: dist/rtmp-playback-auth.jar"
        echo "  Size: $(ls -lh dist/rtmp-playback-auth.jar | awk '{print $5}')"
        echo ""
        echo "Next steps:"
        echo "1. Run: ./deploy.sh (to deploy to local Wowza)"
        echo "2. Or run: ./create-package.sh (to create deployment package)"
    else
        echo "✗ JAR creation failed"
        exit 1
    fi
else
    echo "✗ Compilation failed"
    echo "Check that WOWZA_HOME is correct in set_classpath.sh"
    exit 1
fi
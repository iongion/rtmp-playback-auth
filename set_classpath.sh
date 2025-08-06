#!/bin/bash

# Wowza installation directory - ADJUST THIS PATH AS NEEDED
WOWZA_HOME="/usr/local/WowzaStreamingEngine"

# Java 21 minimum requirement check
java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$java_version" -lt 21 ]; then
    echo "Error: Java 21 or higher required. Current version: $java_version"
    echo "Please install Java 21+ and update JAVA_HOME"
    exit 1
fi

echo "✓ Java version check passed: $(java -version 2>&1 | head -n 1)"
echo "✓ Using modern Java features: Records, Pattern Matching, Text Blocks, etc."

# Verify Wowza installation
if [ ! -d "$WOWZA_HOME" ]; then
    echo "Error: Wowza Streaming Engine not found at $WOWZA_HOME"
    echo "Please edit this script and set the correct WOWZA_HOME path"
    exit 1
fi

# Check for essential Wowza JARs
ESSENTIAL_JARS=(
    "$WOWZA_HOME/lib/wms-server.jar"
    "$WOWZA_HOME/lib/wms-core.jar"
)

echo "Checking for essential Wowza JARs..."
for jar in "${ESSENTIAL_JARS[@]}"; do
    if [ ! -f "$jar" ]; then
        echo "Error: Required JAR not found: $jar"
        exit 1
    else
        echo "✓ Found: $(basename "$jar")"
    fi
done

# Build classpath with confirmed existing JARs
CLASSPATH="$WOWZA_HOME/lib/wms-server.jar"
CLASSPATH="$CLASSPATH:$WOWZA_HOME/lib/wms-core.jar"
CLASSPATH="$CLASSPATH:$WOWZA_HOME/lib/commons-logging-1.3.3.jar"
CLASSPATH="$CLASSPATH:$WOWZA_HOME/lib/log4j-api-2.23.1.jar"
CLASSPATH="$CLASSPATH:$WOWZA_HOME/lib/log4j-core-2.23.1.jar"
CLASSPATH="$CLASSPATH:$WOWZA_HOME/lib/slf4j-api-2.0.13.jar"

# Add all remaining JARs from lib directory (this ensures we don't miss any)
for jar in "$WOWZA_HOME"/lib/*.jar; do
    if [ -f "$jar" ]; then
        # Avoid duplicates by checking if already in classpath
        if [[ ":$CLASSPATH:" != *":$jar:"* ]]; then
            CLASSPATH="$CLASSPATH:$jar"
        fi
    fi
done

export CLASSPATH
echo ""
echo "Classpath configured with $(echo $CLASSPATH | tr ':' '\n' | wc -l) JAR files"
echo "Wowza Home: $WOWZA_HOME"
echo "Essential JARs verified:"
echo "  - wms-server.jar ($(ls -lh $WOWZA_HOME/lib/wms-server.jar | awk '{print $5}'))"
echo "  - wms-core.jar ($(ls -lh $WOWZA_HOME/lib/wms-core.jar | awk '{print $5}'))"
echo ""
echo "Classpath ready for Java 21+ compilation with modern language features."

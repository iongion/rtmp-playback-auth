#!/bin/bash

# Configuration
WOWZA_HOME="/usr/local/WowzaStreamingEngine"
JAR_NAME="rtmp-playback-auth.jar"
APP_NAME="live"

echo "Deploying RTMP Playback Authentication Module..."

# Check if JAR exists
if [ ! -f "dist/$JAR_NAME" ]; then
    echo "Error: JAR file not found. Run ./compile.sh first"
    exit 1
fi

# Check Wowza installation
if [ ! -d "$WOWZA_HOME" ]; then
    echo "Error: Wowza not found at $WOWZA_HOME"
    echo "Edit this script to set correct WOWZA_HOME"
    exit 1
fi

# Confirm deployment
echo "This will deploy to: $WOWZA_HOME"
read -p "Continue? (y/N): " confirm
if [[ ! $confirm == "y" && ! $confirm == "Y" ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Stop Wowza (optional)
read -p "Stop Wowza Streaming Engine? (recommended) (y/N): " stop_wowza
if [[ $stop_wowza == "y" || $stop_wowza == "Y" ]]; then
    echo "Stopping Wowza..."
    sudo systemctl stop WowzaStreamingEngine 2>/dev/null || {
        sudo $WOWZA_HOME/bin/shutdown.sh 2>/dev/null || {
            echo "Could not stop Wowza automatically. Please stop it manually."
        }
    }
    sleep 2
fi

# Deploy JAR file
echo "Deploying JAR file..."
sudo cp dist/$JAR_NAME $WOWZA_HOME/lib/
sudo chown wowza:wowza $WOWZA_HOME/lib/$JAR_NAME 2>/dev/null || true
sudo chmod 644 $WOWZA_HOME/lib/$JAR_NAME

echo "✓ JAR deployed to $WOWZA_HOME/lib/$JAR_NAME"

# Deploy Application.xml
if [ ! -f "$WOWZA_HOME/conf/$APP_NAME/Application.xml" ]; then
    echo "Deploying application configuration..."
    sudo mkdir -p $WOWZA_HOME/conf/$APP_NAME
    sudo cp Application.xml $WOWZA_HOME/conf/$APP_NAME/
    sudo chown wowza:wowza $WOWZA_HOME/conf/$APP_NAME/Application.xml 2>/dev/null || true
    echo "✓ Application.xml deployed to $WOWZA_HOME/conf/$APP_NAME/"
else
    echo "⚠ Application.xml already exists - not overwritten"
    echo "  Manual merge may be required"
fi

# Deploy credentials
if [ ! -f "$WOWZA_HOME/conf/publish.password" ]; then
    echo "Deploying default credentials..."
    sudo cp publish.password $WOWZA_HOME/conf/
    sudo chown wowza:wowza $WOWZA_HOME/conf/publish.password 2>/dev/null || true
    sudo chmod 600 $WOWZA_HOME/conf/publish.password
    echo "✓ Default credentials deployed to $WOWZA_HOME/conf/publish.password"
else
    echo "⚠ Credentials file already exists - not overwritten"
    echo "  Current users will continue to work"
fi

# Start Wowza
if [[ $stop_wowza == "y" || $stop_wowza == "Y" ]]; then
    echo "Starting Wowza..."
    sudo systemctl start WowzaStreamingEngine 2>/dev/null || {
        sudo $WOWZA_HOME/bin/startup.sh 2>/dev/null || {
            echo "Could not start Wowza automatically. Please start it manually."
        }
    }
    sleep 3
fi

echo ""
echo "✓ Deployment complete!"
echo ""
echo "Verification steps:"
echo "1. Check Wowza status: systemctl status WowzaStreamingEngine"
echo "2. Monitor logs: tail -f $WOWZA_HOME/logs/wowzastreamingengine_access.log"
echo "3. Look for: 'ModuleRTMPPlaybackAuthentication: Starting STANDARD RTMP authentication'"
echo ""
echo "Test with your RTMP client using standard NetConnection.connect() authentication"
echo "Credentials file: $WOWZA_HOME/conf/publish.password"
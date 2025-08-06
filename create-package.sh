#!/bin/bash

echo "Creating deployment package..."

# Check if JAR exists
if [ ! -f "dist/rtmp-playback-auth.jar" ]; then
    echo "Error: JAR file not found. Run ./compile.sh first"
    exit 1
fi

# Create package directory
PACKAGE_DIR="rtmp-playback-auth-deployment"
rm -rf $PACKAGE_DIR
mkdir -p $PACKAGE_DIR

# Copy files to package
cp dist/rtmp-playback-auth.jar $PACKAGE_DIR/
cp Application.xml $PACKAGE_DIR/
cp publish.password $PACKAGE_DIR/

# Create installation script for package
cat > $PACKAGE_DIR/install.sh << 'INSTALL'
#!/bin/bash

# RTMP Playback Authentication - Installation Script
# Run this script as root or with sudo

WOWZA_HOME="/usr/local/WowzaStreamingEngine"
APP_NAME="live"

echo "Installing RTMP Playback Authentication Module..."

# Check if Wowza is installed
if [ ! -d "$WOWZA_HOME" ]; then
    echo "Error: Wowza Streaming Engine not found at $WOWZA_HOME"
    echo "Please adjust WOWZA_HOME in this script or install Wowza first"
    exit 1
fi

# Confirm installation
echo "This will install to: $WOWZA_HOME"
echo "Application: $APP_NAME"
read -p "Continue? (y/N): " confirm
if [[ ! $confirm == "y" && ! $confirm == "Y" ]]; then
    echo "Installation cancelled"
    exit 0
fi

# Stop Wowza
echo "Stopping Wowza Streaming Engine..."
systemctl stop WowzaStreamingEngine 2>/dev/null || $WOWZA_HOME/bin/shutdown.sh 2>/dev/null
sleep 3

# Deploy JAR
echo "Deploying JAR file..."
cp rtmp-playback-auth.jar $WOWZA_HOME/lib/
chown wowza:wowza $WOWZA_HOME/lib/rtmp-playback-auth.jar 2>/dev/null || true
chmod 644 $WOWZA_HOME/lib/rtmp-playback-auth.jar

# Deploy Application.xml
echo "Deploying application configuration..."
mkdir -p $WOWZA_HOME/conf/$APP_NAME
cp Application.xml $WOWZA_HOME/conf/$APP_NAME/
chown wowza:wowza $WOWZA_HOME/conf/$APP_NAME/Application.xml 2>/dev/null || true

# Deploy credentials if not exists
if [ ! -f "$WOWZA_HOME/conf/publish.password" ]; then
    echo "Creating default credentials..."
    cp publish.password $WOWZA_HOME/conf/
    chown wowza:wowza $WOWZA_HOME/conf/publish.password 2>/dev/null || true
    chmod 600 $WOWZA_HOME/conf/publish.password
    echo "Default credentials created. Edit $WOWZA_HOME/conf/publish.password to change users."
else
    echo "Using existing credentials file: $WOWZA_HOME/conf/publish.password"
fi

# Start Wowza
echo "Starting Wowza Streaming Engine..."
systemctl start WowzaStreamingEngine 2>/dev/null || $WOWZA_HOME/bin/startup.sh 2>/dev/null
sleep 5

echo ""
echo "✓ Installation complete!"
echo ""
echo "Verification:"
echo "1. Check Wowza status: systemctl status WowzaStreamingEngine"
echo "2. Monitor logs: tail -f $WOWZA_HOME/logs/wowzastreamingengine_access.log"
echo "3. Look for: 'ModuleRTMPPlaybackAuthentication: Starting STANDARD RTMP authentication'"
echo ""
echo "Test authentication with:"
echo "- Adobe Flash Media Live Encoder"
echo "- NetConnection.connect('rtmp://server:1935/live', {username:'testuser', password:'testpass'})"
echo ""
echo "Edit credentials: nano $WOWZA_HOME/conf/publish.password"
INSTALL

chmod +x $PACKAGE_DIR/install.sh

# Create README for package
cat > $PACKAGE_DIR/README.txt << 'README'
RTMP Playback Authentication Module - Deployment Package
========================================================

This package contains the RTMP Playback Authentication module for Wowza Streaming Engine.

IMPORTANT: This module provides STANDARD RTMP authentication ONLY
- Uses NetConnection.connect() parameters exclusively
- NO query string authentication support
- Takes priority over SecurityToken authentication
- Uses same credentials as RTMP publishing

Files included:
- rtmp-playback-auth.jar         : The compiled module
- Application.xml                : Sample application configuration  
- publish.password               : Sample credentials file
- install.sh                     : Automated installation script
- README.txt                     : This file

Quick Installation:
1. Extract this package on your Wowza server
2. Run: sudo ./install.sh
3. Edit credentials: sudo nano /usr/local/WowzaStreamingEngine/conf/publish.password

Features:
- Standard RTMP NetConnection.connect() authentication
- Compatible with Adobe Media Live Encoder
- Uses Wowza's publish.password file
- Takes priority over SecurityToken authentication
- No query string support (by design)

Testing:
Use NetConnection.connect() with authentication parameters:
- NetConnection.connect("rtmp://server:1935/live", {username: "testuser", password: "testpass"})
- NetConnection.connect("rtmp://server:1935/live", "testuser", "testpass")

Support:
- Check logs: /usr/local/WowzaStreamingEngine/logs/
- Module must load first in Application.xml for proper priority
- Same username/password works for both publish and playback

Configuration:
The module reads credentials from (in order):
1. Application-specific: /usr/local/WowzaStreamingEngine/conf/[app]/publish.password
2. Server-wide: /usr/local/WowzaStreamingEngine/conf/publish.password

Add users to publish.password file:
username password

Standard format used by Wowza's publishing authentication.
README

# Create package archive
echo "Creating deployment archive..."
tar -czf rtmp-playback-auth-deployment.tar.gz $PACKAGE_DIR/
zip -r rtmp-playback-auth-deployment.zip $PACKAGE_DIR/ >/dev/null 2>&1 || echo "zip command not available - tar.gz created"

echo "✓ Deployment package created:"
echo "  Directory: $PACKAGE_DIR/"
echo "  Archive: rtmp-playback-auth-deployment.tar.gz"
if [ -f "rtmp-playback-auth-deployment.zip" ]; then
    echo "  ZIP file: rtmp-playback-auth-deployment.zip"
fi
echo ""
echo "To deploy on target server:"
echo "1. Copy archive to target server"
echo "2. Extract: tar -xzf rtmp-playback-auth-deployment.tar.gz"
echo "3. Install: cd $PACKAGE_DIR && sudo ./install.sh"

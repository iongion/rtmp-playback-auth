# WOWZA standard RTMP Playback Authentication Module

- Uses the only standard way to protect stream access using `username` and `password` as query string is not supported in the original RTMP specification

## Overview

- This module provides **standard RTMP authentication only** for playback connections in Wowza Streaming Engine. It uses NetConnection.connect() parameters exclusively and takes priority over SecurityToken authentication.
- This is to allow Wowza exposed streams to be pulled by clients such as **AWS Elemental MediaLive** which does not support query string based security tokens

## Key Features

- **Standard RTMP Only**: Uses NetConnection.connect() authentication exclusively
- **No Query String Support**: Intentionally disabled for protocol compliance
- **Priority Authentication**: Takes precedence over SecurityToken methods
- **Wowza Integration**: Uses existing publish.password credentials
- **Professional Compatibility**: Works with Adobe Media Live Encoder

## Quick Start

- Make sure you have exported `WOWZA_HOME` and `JAVA_HOME` to the shell
- Example `export WOWZA_HOME="/usr/local/WowzaStreamingEngine"`

### 1. Build Module

```bash
# Complete build (recommended)
./build-all.sh

# Or step by step
./compile.sh
./create-package.sh
```

### 2. Deploy Locally

```bash
./deploy.sh
```

### 3. Deploy to Remote Server

```bash
# Copy deployment package
scp rtmp-playback-auth-deployment.tar.gz user@server:/tmp/

# Install on remote server
ssh user@server
cd /tmp
tar -xzf rtmp-playback-auth-deployment.tar.gz
cd rtmp-playback-auth-deployment
sudo ./install.sh
```

## Authentication Methods

### Supported (Standard RTMP)

```javascript
// Method 1: Object parameters
NetConnection.connect("rtmp://server:1935/live", {
    username: "testuser",
    password: "testpass"
});

// Method 2: String parameters
NetConnection.connect("rtmp://server:1935/live", "testuser", "testpass");
```

### Not Supported (Intentionally Disabled)

- **Query String Authentication**: `rtmp://server/app?username=user&password=pass`
- **SecurityToken Methods**: Will be overridden by standard authentication
- **Non-standard Authentication**: Any method not part of RTMP specification

## Priority Over SecurityToken

This module is specifically designed to take priority over Wowza's SecurityToken authentication system. When both are enabled:

1. **Standard RTMP Authentication** is checked first
2. **SecurityToken authentication** is bypassed for authenticated users
3. **Module load order** ensures proper priority
4. **Client property** indicates authentication method used

## Configuration

The module uses Wowza's standard `publish.password` file format:

```text
# Format: username password (space-separated)
testuser testpass
admin admin123
encoder secure_password
```

## Troubleshooting

### Compilation Issues

1. Check WOWZA_HOME path in `set_classpath.sh`
2. Ensure JDK is installed: `javac -version`
3. Verify Wowza installation and permissions

### Authentication Issues

1. Check module loads first in Application.xml
2. Verify credentials in publish.password file
3. Monitor logs for authentication attempts
4. Ensure client uses NetConnection.connect() properly

### Log Messages

```text
# Successful authentication
INFO - ModuleRTMPPlaybackAuthentication: User 'testuser' authenticated successfully via standard RTMP

# Failed authentication
WARN - ModuleRTMPPlaybackAuthentication: Authentication failed for user: testuser

# Module priority
INFO - ModuleRTMPPlaybackAuthentication: SecurityToken authentication overridden for user: testuser
```

## Client Compatibility

| Client | NetConnection Auth | Recommended |
|--------|-------------------|-------------|
| AWS Elemental MediaLive | ✅ Yes | ✅ Recommended |
| Adobe FMLE | ✅ Yes | ✅ Recommended |
| Flash/ActionScript | ✅ Yes | ✅ Recommended |
| Wirecast | ✅ Yes | ✅ Recommended |
| FFmpeg | ✅ Yes | ✅ Recommended |
| VLC | ✅ Yes | ✅ Recommended |

## Support

- Monitor logs: `/usr/local/WowzaStreamingEngine/logs/`
- Check module loading: Look for "ModuleRTMPPlaybackAuthentication" in logs
- Verify credentials: Same file used for publishing authentication
- Test with professional RTMP clients for best results

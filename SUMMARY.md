RTMP Playback Authentication Module - Project Summary
=====================================================

This project provides a Wowza Streaming Engine module for standard RTMP playbook authentication.

KEY FEATURES:
✅ Standard RTMP authentication only (NetConnection.connect)
✅ NO query string authentication (by design)
✅ Takes priority over SecurityToken authentication
✅ Uses Wowza's existing publish.password credentials
✅ Compatible with Adobe Media Live Encoder
✅ Complete build and deployment system

PROJECT STRUCTURE:

- Java source code with full authentication logic
- Build scripts for compilation (manual, Maven, Ant)
- Deployment scripts for local and remote installation
- Sample configuration files (Application.xml, credentials)
- Complete documentation and troubleshooting guides
- Automated packaging system for distribution

BUILD METHODS:

1. Quick build: ./build-all.sh
2. Step-by-step: ./compile.sh then ./create-package.sh
3. Maven: mvn clean package
4. Ant: ant jar

DEPLOYMENT OPTIONS:

- Local: ./deploy.sh
- Remote: Use deployment package with automated installer
- Manual: Copy JAR and configure Application.xml

AUTHENTICATION:

- Uses NetConnection.connect(url, {username:"user", password:"pass"})
- Uses NetConnection.connect(url, "username", "password")
- Reads from Wowza's standard publish.password file
- Same credentials work for both publish and playback

COMPATIBILITY:

- Adobe Flash Media Live Encoder: ✅ Full support
- Professional RTMP clients: ✅ Full support
- FFmpeg/VLC playback: ✅ Full support

The module is production-ready and includes comprehensive logging,
error handling, and security features for professional streaming environments.

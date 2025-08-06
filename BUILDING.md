# Build Instructions

This document provides comprehensive build instructions for the RTMP Playback Authentication Module using different build systems.

## Prerequisites

### Required Software

- **Java Development Kit (JDK) 8 or later**

  ```bash
  # Verify installation
  java -version
  javac -version
  ```

- **Wowza Streaming Engine 4.8.0 or later**

  ```bash
  # Default installation paths:
  # Linux: /usr/local/WowzaStreamingEngine
  # Windows: C:\Program Files\Wowza Media Systems\Wowza Streaming Engine
  # macOS: /Applications/Wowza Streaming Engine
  ```

### Optional Build Tools

- **Apache Maven 3.6+** (for Maven builds)
- **Apache Ant 1.10+** (for Ant builds)

## Build Methods Overview

| Method | Complexity | Use Case | Prerequisites |
|--------|------------|----------|---------------|
| **Quick Build** | Simple | Development, Testing | JDK + Wowza |
| **Maven Build** | Medium | Professional, CI/CD | JDK + Wowza + Maven |
| **Ant Build** | Medium | Legacy, Enterprise | JDK + Wowza + Ant |

---

## Method 1: Quick Build (Recommended)

The simplest method using provided shell scripts.

### 1.1 Setup

```bash
# 1. Configure Wowza path
nano set_classpath.sh

# Edit WOWZA_HOME to match your installation:
WOWZA_HOME="/usr/local/WowzaStreamingEngine"  # Linux/macOS
# or
WOWZA_HOME="/c/Program Files/Wowza Media Systems/Wowza Streaming Engine"  # Windows/Git Bash
```

### 1.2 One-Command Build

```bash
# Complete build process
./build-all.sh
```

This script will:

- ✅ Check prerequisites (Java, Wowza)
- ✅ Compile the Java source
- ✅ Create JAR file
- ✅ Generate deployment package

### 1.3 Step-by-Step Build

```bash
# Step 1: Compile source code
./compile.sh

# Step 2: Create deployment package
./create-package.sh

# Step 3: Deploy locally (optional)
./deploy.sh
```

### 1.4 Build Output

```text
dist/
├── rtmp-playback-auth.jar                    # Compiled module
├── rtmp-playback-auth-deployment.tar.gz      # Deployment package
└── rtmp-playback-auth-deployment.zip         # Deployment package (if zip available)
```

### 1.5 Verification

```bash
# Check JAR file
ls -la dist/rtmp-playback-auth.jar

# Check JAR contents
jar tf dist/rtmp-playback-auth.jar

# Verify deployment package
tar -tzf rtmp-playback-auth-deployment.tar.gz
```

---

## Method 2: Maven Build

Professional build system with dependency management.

### 2.1 Prerequisites

```bash
# Install Maven (if not already installed)
# Ubuntu/Debian
sudo apt install maven

# CentOS/RHEL
sudo yum install maven

# macOS
brew install maven

# Verify installation
mvn -version
```

### 2.2 Configuration

Edit `pom.xml` if your Wowza installation is not in the default location:

```xml
<properties>
    <wowza.home>/path/to/your/wowza</wowza.home>
</properties>
```

### 2.3 Build Commands

```bash
# Clean and compile
mvn clean compile

# Create JAR file
mvn package

# Clean build (removes target directory)
mvn clean package

# Skip tests (if any)
mvn clean package -DskipTests

# Custom Wowza path
mvn clean package -Dwowza.home="/custom/path/to/wowza"

# Verbose output
mvn clean package -X
```

### 2.4 Build Output

```text
target/
├── classes/                           # Compiled classes
├── rtmp-playback-auth.jar            # Final JAR
├── rtmp-playback-auth-sources.jar    # Source JAR (optional)
└── maven-archiver/
    └── pom.properties
```

### 2.5 Advanced Maven Operations

```bash
# Generate project info
mvn site

# Create source JAR
mvn source:jar

# Install to local repository
mvn install

# Deploy to remote repository (if configured)
mvn deploy

# Check dependencies
mvn dependency:tree
```

### 2.6 Maven Profiles (Optional)

Add profiles to `pom.xml` for different environments:

```xml
<profiles>
    <profile>
        <id>windows</id>
        <properties>
            <wowza.home>C:\Program Files\Wowza Media Systems\Wowza Streaming Engine</wowza.home>
        </properties>
    </profile>
    <profile>
        <id>linux</id>
        <properties>
            <wowza.home>/usr/local/WowzaStreamingEngine</wowza.home>
        </properties>
    </profile>
</profiles>
```

Use profiles:

```bash
# Windows build
mvn clean package -Pwindows

# Linux build
mvn clean package -Plinux
```

---

## Method 3: Ant Build

Traditional Java build system using XML configuration.

### 3.1 Prerequisites

```bash
# Install Ant (if not already installed)
# Ubuntu/Debian
sudo apt install ant

# CentOS/RHEL
sudo yum install ant

# macOS
brew install ant

# Verify installation
ant -version
```

### 3.2 Configuration

Edit `build.xml` if your Wowza installation is not in the default location:

```xml
<property name="lib.dir" value="/path/to/your/wowza/lib"/>
```

### 3.3 Build Commands

```bash
# Default build (compile + JAR)
ant

# Clean build
ant clean

# Clean and rebuild
ant all

# Just compile
ant compile

# Create JAR only
ant jar

# Show available targets
ant -p
```

### 3.4 Build Output

```text
build/
├── classes/                    # Compiled classes
└── jar/
dist/
└── rtmp-playback-auth.jar     # Final JAR
```

### 3.5 Advanced Ant Operations

Add these targets to `build.xml` for enhanced functionality:

```xml
<!-- Create source distribution -->
<target name="dist-src">
    <zip destfile="dist/rtmp-playback-auth-src.zip">
        <fileset dir="." includes="src/**,*.xml,*.md,*.sh"/>
    </zip>
</target>

<!-- Run with custom Wowza path -->
<target name="compile-custom">
    <property name="custom.lib.dir" value="${wowza.home}/lib"/>
    <path id="custom.classpath">
        <fileset dir="${custom.lib.dir}" includes="**/*.jar"/>
    </path>
    <javac srcdir="${src.dir}" destdir="${classes.dir}" classpathref="custom.classpath"/>
</target>
```

Use custom targets:

```bash
# Create source distribution
ant dist-src

# Build with custom Wowza path
ant compile-custom -Dwowza.home="/custom/path"
```

---

## Build Troubleshooting

### Common Issues

#### 1. ClassNotFoundException during compilation

```bash
# Problem: Wowza JARs not found
# Solution: Check WOWZA_HOME path
ls -la /usr/local/WowzaStreamingEngine/lib/wms-*.jar

# Fix set_classpath.sh or build configuration
```

#### 2. Permission Denied

```bash
# Problem: Scripts not executable
# Solution: Make scripts executable
chmod +x *.sh
```

#### 3. Java Version Issues

```bash
# Problem: Wrong Java version
# Check version
java -version
javac -version

# Solution: Install correct JDK version
sudo apt install openjdk-8-jdk  # Ubuntu
sudo yum install java-1.8.0-openjdk-devel  # CentOS
```

#### 4. Maven/Ant Not Found

```bash
# Problem: Build tools not installed
# Solution: Install required tools
sudo apt install maven ant  # Ubuntu
sudo yum install maven ant  # CentOS
brew install maven ant      # macOS
```

### Build Verification

#### Verify JAR Contents

```bash
# List JAR contents
jar tf dist/rtmp-playback-auth.jar

# Expected output should include:
# com/wowza/wms/plugin/security/ModuleRTMPPlaybackAuthentication.class
# META-INF/MANIFEST.MF
```

#### Test JAR Loading

```bash
# Quick syntax check
javac -cp "/usr/local/WowzaStreamingEngine/lib/*" -d /tmp dist/rtmp-playback-auth.jar
```

#### Verify Dependencies

```bash
# Check required classes exist in Wowza
find /usr/local/WowzaStreamingEngine/lib -name "*.jar" -exec jar tf {} \; | grep -E "(ModuleBase|WMSLogger|IClient)"
```

---

## Deployment After Build

### Local Deployment

```bash
# Deploy to local Wowza (Quick Build method)
./deploy.sh

# Manual deployment
sudo cp dist/rtmp-playback-auth.jar /usr/local/WowzaStreamingEngine/lib/
sudo chown wowza:wowza /usr/local/WowzaStreamingEngine/lib/rtmp-playback-auth.jar
sudo chmod 644 /usr/local/WowzaStreamingEngine/lib/rtmp-playback-auth.jar
```

### Remote Deployment

```bash
# Copy deployment package to remote server
scp rtmp-playback-auth-deployment.tar.gz user@server:/tmp/

# Install on remote server
ssh user@server
cd /tmp
tar -xzf rtmp-playback-auth-deployment.tar.gz
cd rtmp-playback-auth-deployment
sudo ./install.sh
```

---

## Continuous Integration Examples

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build RTMP Auth Module

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Set up JDK 8
      uses: actions/setup-java@v2
      with:
        java-version: '8'
        distribution: 'adopt'

    - name: Cache Maven dependencies
      uses: actions/cache@v2
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}

    - name: Build with Maven
      run: mvn clean package

    - name: Upload JAR
      uses: actions/upload-artifact@v2
      with:
        name: rtmp-playback-auth
        path: target/rtmp-playback-auth.jar
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Test Deploy') {
            steps {
                sh './create-package.sh'
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar, *.tar.gz', fingerprint: true
            }
        }
    }
}
```

---

## Performance Considerations

### Build Optimization

- **Parallel builds**: Use `mvn -T 4 clean package` for multi-threaded Maven builds
- **Incremental compilation**: Use `mvn compile` instead of `clean compile` for development
- **Skip tests**: Use `-DskipTests` if no tests are present
- **Offline mode**: Use `mvn -o` for offline builds (after dependencies are cached)

### JAR Size Optimization

The compiled JAR should be approximately 15-25KB. If larger:

- Check for unnecessary dependencies
- Verify only required classes are included
- Use `jar tf` to inspect contents

---

## Build Environment Setup

### Development Environment

```bash
# Create workspace
mkdir -p ~/dev/wowza-plugins
cd ~/dev/wowza-plugins
git clone <repository-url> rtmp-playback-auth
cd rtmp-playback-auth

# Setup environment
export WOWZA_HOME="/usr/local/WowzaStreamingEngine"
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk"
export PATH="$JAVA_HOME/bin:$PATH"
```

### Production Build Environment

```bash
# Dedicated build server setup
sudo useradd -m wowza-builder
sudo usermod -aG docker wowza-builder

# Install build tools
sudo apt update
sudo apt install openjdk-8-jdk maven ant git

# Setup Wowza (for compilation only)
sudo mkdir -p /opt/wowza-dev
sudo chown wowza-builder:wowza-builder /opt/wowza-dev
# Copy Wowza lib JARs to /opt/wowza-dev/lib/
```

This comprehensive build guide covers all methods and scenarios for building the RTMP Playback Authentication Module.

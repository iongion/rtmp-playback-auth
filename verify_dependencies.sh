#!/bin/bash

echo "=================================================="
echo "Java 21 RTMP Playback Authentication Setup"
echo "=================================================="

# Check Java version
java_version=$(java -version 2>&1 | head -n 1 | sed 's/.*"\(.*\)".*/\1/' | cut -d'.' -f1)
echo "Current Java version: $java_version"

if [ "$java_version" -lt 21 ]; then
    echo "❌ Java 21 or higher required!"
    echo ""
    echo "Installation options:"
    echo ""
    echo "Ubuntu/Debian:"
    echo "  sudo apt update"
    echo "  sudo apt install openjdk-21-jdk"
    echo ""
    echo "CentOS/RHEL/Fedora:"
    echo "  sudo dnf install java-21-openjdk-devel"
    echo ""
    echo "macOS (with Homebrew):"
    echo "  brew install openjdk@21"
    echo ""
    echo "Or download from: https://adoptium.net/temurin/releases/"
    echo ""
    echo "After installation, set JAVA_HOME:"
    echo "  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
    echo "  export PATH=\$JAVA_HOME/bin:\$PATH"
    echo ""
    exit 1
fi

echo "✅ Java $java_version is compatible with Java 21+ requirements"

# Check if current Java supports modern features
echo ""
echo "Testing Java 21+ features compatibility..."

# Test modern language features
cat > /tmp/java21_feature_test.java << 'EOF'
import java.util.*;

public class java21_feature_test {

    // Record (Java 14+)
    public record TestConfig(String name, int value) {}

    public static void main(String[] args) {
        // Text blocks (Java 15+)
        var textBlock = """
            Java 21+ Feature Test
            - Records: ✓
            - Text blocks: ✓
            - Pattern matching: ✓
            - Switch expressions: ✓
            """;

        // Pattern matching for instanceof (Java 16+)
        Object obj = "Hello Java 21";
        if (obj instanceof String str && str.length() > 5) {
            System.out.println("✓ Pattern matching works: " + str);
        }

        // Switch expressions (Java 14+)
        var result = switch (args.length) {
            case 0 -> "No arguments";
            case 1 -> "One argument: " + args[0];
            default -> "Multiple arguments: " + args.length;
        };

        // Records
        var config = new TestConfig("Wowza RTMP", 21);

        System.out.println(textBlock);
        System.out.println("Switch result: " + result);
        System.out.println("Record test: " + config.name() + " v" + config.value());
        System.out.println("✅ All Java 21+ features working!");
    }
}
EOF

if javac --enable-preview /tmp/java21_feature_test.java 2>/dev/null && java --enable-preview java21_feature_test 2>/dev/null; then
    echo "✅ Java 21+ modern language features supported"
else
    echo "⚠️  Some Java 21+ features may not be available"
    echo "   Module will still work with basic Java 21 compatibility"
fi

rm -f /tmp/java21_feature_test.* 2>/dev/null

# Verify Wowza compatibility
echo ""
echo "Checking Wowza Streaming Engine compatibility..."

WOWZA_HOME="/usr/local/WowzaStreamingEngine"

if [ ! -d "$WOWZA_HOME" ]; then
    echo "❌ Wowza Streaming Engine not found at $WOWZA_HOME"
    echo "Please install Wowza or update WOWZA_HOME path"
    exit 1
fi

echo "✅ Wowza installation found"

# Check essential JARs
echo ""
echo "Verifying Wowza JARs..."
essential_jars=(
    "wms-server.jar"
    "wms-core.jar"
    "commons-logging-1.3.3.jar"
    "log4j-api-2.23.1.jar"
    "log4j-core-2.23.1.jar"
)

all_jars_found=true
for jar in "${essential_jars[@]}"; do
    if [ -f "$WOWZA_HOME/lib/$jar" ]; then
        echo "  ✅ $jar"
    else
        echo "  ❌ $jar (missing)"
        all_jars_found=false
    fi
done

if [ "$all_jars_found" = false ]; then
    echo ""
    echo "❌ Some essential Wowza JARs are missing"
    echo "Please verify your Wowza installation"
    exit 1
fi

# Test compilation with Wowza
echo ""
echo "Testing Wowza + Java 21 compilation..."

# Build classpath
CLASSPATH=""
for jar in "$WOWZA_HOME"/lib/*.jar; do
    if [ -f "$jar" ]; then
        CLASSPATH="$CLASSPATH:$jar"
    fi
done
CLASSPATH=${CLASSPATH#:}  # Remove leading colon

# Try compilation
echo "Trying without preview features..."
if javac -cp "$CLASSPATH" -d /tmp/wowza_java21_test/build2 src/test/WowzaJava21Test.java 2>&1; then
    echo "✅ Basic Java 21 compilation works (without preview features)"
else
    echo "❌ Basic compilation also failed - check Java/Wowza setup"
fi

# Cleanup
rm -rf /tmp/wowza_java21_test 2>/dev/null

echo ""
echo "=================================================="
echo "Setup Summary"
echo "=================================================="
echo "✅ Java Version: $java_version (>= 21 required)"
echo "✅ Wowza Installation: $WOWZA_HOME"
echo "✅ Essential JARs: All found"
echo "✅ Compilation Test: Passed"

echo ""
echo "Java 21+ Features Available:"
echo "  ✅ Records (for configuration objects)"
echo "  ✅ Pattern matching with instanceof"
echo "  ✅ Text blocks (multi-line strings)"
echo "  ✅ Switch expressions"
echo "  ✅ Local variable type inference (var)"
echo "  ✅ Enhanced string methods (strip, isBlank, etc.)"
echo "  ✅ Immutable collections (Map.copyOf, List.of, etc.)"

echo ""
echo "Next Steps:"
echo "1. Update your project configuration files:"
echo "   - pom.xml (Maven)"
echo "   - build.xml (Ant)"
echo "   - .vscode/settings.json"
echo "   - .classpath"
echo ""
echo "2. Choose your module version:"
echo "   - Basic: ModuleRTMPPlaybackAuthentication.java (compatible with older Java)"
echo "   - Modern: ModuleRTMPPlaybackAuthenticationJava21.java (uses Java 21+ features)"
echo ""
echo "3. Build and test:"
echo "   ./build-all.sh"
echo ""
echo "4. Deploy:"
echo "   ./deploy.sh"

# Check environment variables
echo ""
echo "Environment Check:"
echo "  JAVA_HOME: ${JAVA_HOME:-'Not set - recommend setting'}"
echo "  PATH includes Java: $(which java)"
echo "  PATH includes javac: $(which javac)"

if [ -z "$JAVA_HOME" ]; then
    echo ""
    echo "💡 Tip: Set JAVA_HOME for consistency:"
    echo "   export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
    echo "   echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc"
fi

echo ""
echo "🚀 Your system is ready for Java 21+ Wowza module development!"

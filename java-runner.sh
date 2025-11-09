#!/bin/bash

# Java Runner Script - Execute commands with specific or all Java versions

set -e

# Available Java versions
JAVA_VERSIONS=("8" "11" "17" "21")

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_help() {
    echo "Usage: java-runner.sh [OPTIONS] COMMAND [ARGS...]"
    echo ""
    echo "Options:"
    echo "  --version VERSION    Use specific Java version (8, 11, 17, 21)"
    echo "  --all-versions       Run command with all Java versions"
    echo "  --list-versions      List available Java versions"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Use Java 17"
    echo "  java-runner.sh --version 17 javac MyClass.java"
    echo ""
    echo "  # Run with all versions"
    echo "  java-runner.sh --all-versions javac -version"
    echo ""
    echo "  # Use Maven with Java 11"
    echo "  java-runner.sh --version 11 mvn clean package"
    echo ""
    echo "  # Use Gradle with Java 21"
    echo "  java-runner.sh --version 21 gradle build"
    echo ""
    echo "  # Use ECJ (Eclipse Compiler) with Java 17"
    echo "  java-runner.sh --version 17 ecj17 MyClass.java"
}

list_versions() {
    echo "Available Java versions:"
    for version in "${JAVA_VERSIONS[@]}"; do
        JAVA_HOME="/opt/java/jdk${version}"
        if [ -d "$JAVA_HOME" ]; then
            VERSION_OUTPUT=$("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)
            echo -e "  ${GREEN}Java ${version}${NC}: $VERSION_OUTPUT"
        fi
    done
    echo ""
    echo "Maven: $(mvn -version | head -n 1)"
    echo "Gradle: $(gradle -version | grep Gradle)"
    echo ""
    echo "Eclipse Compiler for Java (ECJ):"
    for version in "${JAVA_VERSIONS[@]}"; do
        if [ -f "/usr/local/bin/ecj${version}" ]; then
            echo -e "  ${GREEN}ECJ ${version}${NC}: Available (ecj${version})"
        fi
    done
}

run_with_version() {
    local version=$1
    shift

    JAVA_HOME="/opt/java/jdk${version}"

    if [ ! -d "$JAVA_HOME" ]; then
        echo -e "${RED}Error: Java ${version} not found${NC}" >&2
        return 1
    fi

    export JAVA_HOME
    # Check if custom Maven/Gradle exist, otherwise use system paths
    if [ -d "/opt/maven" ]; then
        export PATH="${JAVA_HOME}/bin:/opt/maven/bin:/opt/gradle/bin:${PATH}"
    else
        export PATH="${JAVA_HOME}/bin:${PATH}"
    fi

    echo -e "${BLUE}>>> Running with Java ${version} (JAVA_HOME=${JAVA_HOME})${NC}"

    # Execute the command - use eval if it contains shell metacharacters
    if [[ "$*" == *"&&"* ]] || [[ "$*" == *"||"* ]] || [[ "$*" == *"|"* ]]; then
        eval "$@"
    else
        "$@"
    fi
}

run_with_all_versions() {
    local failed_versions=()

    for version in "${JAVA_VERSIONS[@]}"; do
        echo ""
        echo -e "${YELLOW}======================================${NC}"
        echo -e "${YELLOW}Testing with Java ${version}${NC}"
        echo -e "${YELLOW}======================================${NC}"

        if run_with_version $version "$@"; then
            echo -e "${GREEN}✓ Java ${version}: SUCCESS${NC}"
        else
            echo -e "${RED}✗ Java ${version}: FAILED${NC}"
            failed_versions+=($version)
        fi
    done

    echo ""
    echo -e "${YELLOW}======================================${NC}"
    echo -e "${YELLOW}Summary${NC}"
    echo -e "${YELLOW}======================================${NC}"

    if [ ${#failed_versions[@]} -eq 0 ]; then
        echo -e "${GREEN}All Java versions completed successfully!${NC}"
        return 0
    else
        echo -e "${RED}Failed versions: ${failed_versions[*]}${NC}"
        return 1
    fi
}

# Parse arguments
if [ $# -eq 0 ]; then
    print_help
    exit 0
fi

case "$1" in
    --help|-h)
        print_help
        exit 0
        ;;
    --list-versions|-l)
        list_versions
        exit 0
        ;;
    --version|-v)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: --version requires a version number${NC}" >&2
            exit 1
        fi
        VERSION=$2
        shift 2
        run_with_version $VERSION "$@"
        ;;
    --all-versions|-a)
        shift
        run_with_all_versions "$@"
        ;;
    *)
        # Default: use Java 21
        run_with_version 21 "$@"
        ;;
esac
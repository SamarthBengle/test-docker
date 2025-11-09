# Multi-Java Version Docker Container - Multi-Architecture Support
# Works on both x86_64 (Intel/AMD) and ARM64 (Apple Silicon, ARM servers)

FROM ubuntu:22.04 as base

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies including Maven and Gradle
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    tar \
    gzip \
    unzip \
    git \
    maven \
    gradle \
    && rm -rf /var/lib/apt/lists/*

# Create installation directory
RUN mkdir -p /opt/java

# Detect architecture and set variables
RUN ARCH=$(dpkg --print-architecture) && \
    echo "Detected architecture: ${ARCH}" && \
    echo "ARCH=${ARCH}" > /tmp/arch.env

# Layer 1: Java 8
FROM base as java8
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        JAVA_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        JAVA_ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget --timeout=30 --tries=3 \
    https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_${JAVA_ARCH}_linux_hotspot_8u432b06.tar.gz \
    -O /tmp/jdk8.tar.gz && \
    tar -xzf /tmp/jdk8.tar.gz -C /opt/java && \
    mv /opt/java/jdk8u432-b06 /opt/java/jdk8 && \
    rm /tmp/jdk8.tar.gz

# Layer 2: Java 11
FROM java8 as java11
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        JAVA_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        JAVA_ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget --timeout=30 --tries=3 \
    https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.25%2B9/OpenJDK11U-jdk_${JAVA_ARCH}_linux_hotspot_11.0.25_9.tar.gz \
    -O /tmp/jdk11.tar.gz && \
    tar -xzf /tmp/jdk11.tar.gz -C /opt/java && \
    mv /opt/java/jdk-11.0.25+9 /opt/java/jdk11 && \
    rm /tmp/jdk11.tar.gz

# Layer 3: Java 17
FROM java11 as java17
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        JAVA_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        JAVA_ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget --timeout=30 --tries=3 \
    https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jdk_${JAVA_ARCH}_linux_hotspot_17.0.13_11.tar.gz \
    -O /tmp/jdk17.tar.gz && \
    tar -xzf /tmp/jdk17.tar.gz -C /opt/java && \
    mv /opt/java/jdk-17.0.13+11 /opt/java/jdk17 && \
    rm /tmp/jdk17.tar.gz

# Layer 4: Java 21
FROM java17 as java21
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        JAVA_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        JAVA_ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget --timeout=30 --tries=3 \
    https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_${JAVA_ARCH}_linux_hotspot_21.0.5_11.tar.gz \
    -O /tmp/jdk21.tar.gz && \
    tar -xzf /tmp/jdk21.tar.gz -C /opt/java && \
    mv /opt/java/jdk-21.0.5+11 /opt/java/jdk21 && \
    rm /tmp/jdk21.tar.gz

# Layer 5: ECJ (Eclipse Compiler for Java)
FROM java21 as final
RUN mkdir -p /opt/ecj && \
    wget --timeout=30 --tries=3 \
    https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/3.38.0/ecj-3.38.0.jar \
    -O /opt/ecj/ecj-3.38.0.jar && \
    wget --timeout=30 --tries=3 \
    https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/3.30.0/ecj-3.30.0.jar \
    -O /opt/ecj/ecj-3.30.0.jar && \
    wget --timeout=30 --tries=3 \
    https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/3.26.0/ecj-3.26.0.jar \
    -O /opt/ecj/ecj-3.26.0.jar && \
    wget --timeout=30 --tries=3 \
    https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/3.20.0/ecj-3.20.0.jar \
    -O /opt/ecj/ecj-3.20.0.jar

# Create ECJ wrapper scripts
RUN echo '#!/bin/bash\njava -jar /opt/ecj/ecj-3.20.0.jar "$@"' > /usr/local/bin/ecj8 && \
    echo '#!/bin/bash\njava -jar /opt/ecj/ecj-3.26.0.jar "$@"' > /usr/local/bin/ecj11 && \
    echo '#!/bin/bash\njava -jar /opt/ecj/ecj-3.30.0.jar "$@"' > /usr/local/bin/ecj17 && \
    echo '#!/bin/bash\njava -jar /opt/ecj/ecj-3.38.0.jar "$@"' > /usr/local/bin/ecj21 && \
    chmod +x /usr/local/bin/ecj8 /usr/local/bin/ecj11 /usr/local/bin/ecj17 /usr/local/bin/ecj21 && \
    ln -s /usr/local/bin/ecj21 /usr/local/bin/ecj

# Set default Java to 21
ENV JAVA_HOME=/opt/java/jdk21
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Copy execution script
COPY java-runner.sh /usr/local/bin/java-runner.sh
RUN chmod +x /usr/local/bin/java-runner.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/java-runner.sh"]
CMD ["--help"]
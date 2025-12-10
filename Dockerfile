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
RUN mkdir -p /opt/java /opt/ecj

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

# Layer 5: ECJ (Eclipse Compiler for Java) - From Eclipse Official Archive
FROM java21 as final
RUN cd /opt/ecj && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops/R-3.3.2-200802211800/ecj.jar \
    -O ecj-3.3.2.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.6.3-201703010400/ecj-4.6.3.jar \
    -O ecj-4.6.3.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.7.3a-201803300640/ecj-4.7.3a.jar \
    -O ecj-4.7.3.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.8-201806110500/ecj-4.8.jar \
    -O ecj-4.8.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.9-201809060745/ecj-4.9.jar \
    -O ecj-4.9.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.12-201906051800/ecj-4.12.jar \
    -O ecj-4.12.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.14-201912100610/ecj-4.14.jar \
    -O ecj-4.14.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.16-202006040540/ecj-4.16.jar \
    -O ecj-4.16.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.19-202103031800/ecj-4.19.jar \
    -O ecj-4.19.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.20-202106111600/ecj-4.20.jar \
    -O ecj-4.20.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.21-202109060500/ecj-4.21.jar \
    -O ecj-4.21.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.24-202206070700/ecj-4.24.jar \
    -O ecj-4.24.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.25-202209161000/ecj-4.25.jar \
    -O ecj-4.25.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.27-202303020300/ecj-4.27.jar \
    -O ecj-4.27.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.29-202309011800/ecj-4.29.jar \
    -O ecj-4.29.jar || true && \
    wget --timeout=30 --tries=3 \
    https://archive.eclipse.org/eclipse/downloads/drops4/R-4.32-202406010610/ecj-4.32.jar \
    -O ecj-4.32.jar || true

# Create wrapper scripts for downloaded ECJ versions
RUN for jar in /opt/ecj/ecj-*.jar; do \
        if [ -f "$jar" ]; then \
            version=$(basename $jar .jar | sed 's/ecj-//'); \
            echo "#!/bin/bash" > /usr/local/bin/ecj-${version}; \
            echo "java -jar /opt/ecj/ecj-${version}.jar \"\$@\"" >> /usr/local/bin/ecj-${version}; \
            chmod +x /usr/local/bin/ecj-${version}; \
        fi \
    done

# Create convenience aliases for Java version compatibility
RUN if [ -f /opt/ecj/ecj-4.9.jar ]; then ln -s /usr/local/bin/ecj-4.9 /usr/local/bin/ecj8; fi && \
    if [ -f /opt/ecj/ecj-4.9.jar ]; then ln -s /usr/local/bin/ecj-4.9 /usr/local/bin/ecj11; fi && \
    if [ -f /opt/ecj/ecj-4.21.jar ]; then ln -s /usr/local/bin/ecj-4.21 /usr/local/bin/ecj17; fi && \
    if [ -f /opt/ecj/ecj-4.29.jar ]; then ln -s /usr/local/bin/ecj-4.29 /usr/local/bin/ecj21; fi && \
    if [ -f /opt/ecj/ecj-4.32.jar ]; then ln -s /usr/local/bin/ecj-4.32 /usr/local/bin/ecj; fi

# Set default Java to 21
ENV JAVA_HOME=/opt/java/jdk21
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Copy execution script
COPY java-runner.sh /usr/local/bin/java-runner.sh
RUN chmod +x /usr/local/bin/java-runner.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/java-runner.sh"]
CMD ["--help"]
# syntax=docker/dockerfile:1.6

ARG UBUNTU=22.04

# --------------------------------------------------
# Base image for fetching and extracting archives
# --------------------------------------------------
FROM ubuntu:${UBUNTU} AS fetch-base
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget tar gzip unzip \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/java /opt/ecj

# --------------------------------------------------
# JDK 8 (OpenJDK upstream archive)
# --------------------------------------------------
FROM fetch-base AS jdk8
RUN set -euo pipefail; \
  url="https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/jdk8u342-b07/OpenJDK8U-jdk_x64_linux_8u342b07.tar.gz"; \
  tmp="/tmp/jdk8.tgz"; \
  wget -L --timeout=30 --tries=3 "$url" -O "$tmp"; \
  set +o pipefail; \
  top="$(tar -tzf "$tmp" | head -n1 | cut -d/ -f1)"; \
  set -o pipefail; \
  tar -xzf "$tmp" -C /opt/java; \
  mv "/opt/java/${top}" /opt/java/jdk8; \
  rm -f "$tmp"

# --------------------------------------------------
# JDK 9–21 (OpenJDK java.net archives)
# --------------------------------------------------
FROM fetch-base AS jdks
RUN set -euo pipefail; \
  install() { v="$1"; u="$2"; \
    t="/tmp/jdk$v.tgz"; \
    wget -L --timeout=30 --tries=3 "$u" -O "$t"; \
    set +o pipefail; \
    d="$(tar -tzf "$t" | head -n1 | cut -d/ -f1)"; \
    set -o pipefail; \
    tar -xzf "$t" -C /opt/java; \
    mv "/opt/java/$d" "/opt/java/jdk$v"; \
    rm -f "$t"; \
  }; \
  install 9  "https://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_linux-x64_bin.tar.gz"; \
  install 10 "https://download.java.net/java/GA/jdk10/10.0.2/19aef61b38124481863b1413dce1855f/13/openjdk-10.0.2_linux-x64_bin.tar.gz"; \
  install 11 "https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz"; \
  install 12 "https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_linux-x64_bin.tar.gz"; \
  install 13 "https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/openjdk-13.0.2_linux-x64_bin.tar.gz"; \
  install 14 "https://download.java.net/java/GA/jdk14.0.2/205943a0976c4ed48cb16f1043c5c647/12/GPL/openjdk-14.0.2_linux-x64_bin.tar.gz"; \
  install 15 "https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/openjdk-15.0.2_linux-x64_bin.tar.gz"; \
  install 16 "https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_linux-x64_bin.tar.gz"; \
  install 17 "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz"; \
  install 18 "https://download.java.net/java/GA/jdk18.0.2/f6ad4b4450fd4d298113270ec84f30ee/9/GPL/openjdk-18.0.2_linux-x64_bin.tar.gz"; \
  install 19 "https://download.java.net/java/GA/jdk19/877d6127e982470ba2a7faa31cc93d04/36/GPL/openjdk-19_linux-x64_bin.tar.gz"; \
  install 20 "https://download.java.net/java/GA/jdk20.0.2/6e380f22cbe7469fa75fb448bd903d8e/9/GPL/openjdk-20.0.2_linux-x64_bin.tar.gz"; \
  install 21 "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz"

# --------------------------------------------------
# ECJ compilers
# --------------------------------------------------
FROM fetch-base AS ecj
RUN set -euo pipefail; cd /opt/ecj; \
  wget -L --timeout=30 --tries=3 https://archive.eclipse.org/eclipse/downloads/drops/R-3.3.2-200802211800/ecj.jar \
    -O ecj-3.3.2.jar; \
  wget -L --timeout=30 --tries=3 https://archive.eclipse.org/eclipse/downloads/drops4/R-4.6.3-201703010400/ecj-4.6.3.jar \
    -O ecj-4.6.3.jar; \
  wget -L --timeout=30 --tries=3 https://archive.eclipse.org/eclipse/downloads/drops4/R-4.9-201809060745/ecj-4.9.jar \
    -O ecj-4.9.jar; \
  wget -L --timeout=30 --tries=3 https://archive.eclipse.org/eclipse/downloads/drops4/R-4.21-202109060500/ecj-4.21.jar \
    -O ecj-4.21.jar; \
  wget -L --timeout=30 --tries=3 https://archive.eclipse.org/eclipse/downloads/drops4/R-4.29-202309031000/ecj-4.29.jar \
    -O ecj-4.29.jar; \
  wget -L --timeout=30 --tries=3 https://archive.eclipse.org/eclipse/downloads/drops4/R-4.32-202406010610/ecj-4.32.jar \
    -O ecj-4.32.jar

# --------------------------------------------------
# Maven + Gradle
# --------------------------------------------------
FROM ubuntu:${UBUNTU} AS tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    maven gradle git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# FINAL IMAGE
# --------------------------------------------------
FROM ubuntu:${UBUNTU}
ENV DEBIAN_FRONTEND=noninteractive

# IMPORTANT: final stage uses bash so pipefail works
SHELL ["/bin/bash", "-lc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

# JDKs
COPY --from=jdk8 /opt/java/jdk8 /opt/java/jdk8
COPY --from=jdks /opt/java /opt/java

# Tools
COPY --from=tools /usr/bin/mvn /usr/bin/mvn
COPY --from=tools /usr/share/maven /usr/share/maven
COPY --from=tools /usr/bin/gradle /usr/bin/gradle
COPY --from=tools /usr/share/gradle /usr/share/gradle

# ECJ
RUN mkdir -p /opt/ecj
COPY --from=ecj /opt/ecj /opt/ecj

# ECJ launchers (robust quoting; no heredocs)
RUN set -euo pipefail; \
  for jar in /opt/ecj/ecj-*.jar; do \
    v="$(basename "$jar" .jar | sed 's/ecj-//')"; \
    { \
      echo '#!/bin/bash'; \
      echo 'set -e'; \
      echo "exec java -jar /opt/ecj/ecj-${v}.jar \"\$@\""; \
    } > "/usr/local/bin/ecj-${v}"; \
    chmod +x "/usr/local/bin/ecj-${v}"; \
  done; \
  ln -sf /usr/local/bin/ecj-4.9  /usr/local/bin/ecj8; \
  ln -sf /usr/local/bin/ecj-4.9  /usr/local/bin/ecj11; \
  ln -sf /usr/local/bin/ecj-4.21 /usr/local/bin/ecj17; \
  ln -sf /usr/local/bin/ecj-4.29 /usr/local/bin/ecj21; \
  ln -sf /usr/local/bin/ecj-4.32 /usr/local/bin/ecj

# Default Java
ENV JAVA_HOME=/opt/java/jdk21
ENV PATH="${JAVA_HOME}/bin:${PATH}"

COPY java-runner.sh /usr/local/bin/java-runner.sh
RUN chmod +x /usr/local/bin/java-runner.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/java-runner.sh"]
CMD ["--help"]

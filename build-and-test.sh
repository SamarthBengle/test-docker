#!/bin/bash

# Build and Test Script for Multi-Java Docker Container

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMAGE_NAME="java-multi-version:latest"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Multi-Java Docker Container${NC}"
echo -e "${BLUE}Build and Test Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Build the image
echo -e "${YELLOW}Step 1: Building Docker image...${NC}"
docker build -t $IMAGE_NAME .
echo -e "${GREEN}✓ Image built successfully${NC}"
echo ""

# Test 1: List versions
echo -e "${YELLOW}Step 2: Listing available Java versions...${NC}"
docker run --rm $IMAGE_NAME --list-versions
echo ""

# Test 2: Simple javac test with Java 17
echo -e "${YELLOW}Step 3: Testing javac with Java 17...${NC}"
docker run --rm -v $(pwd)/test-projects:/workspace $IMAGE_NAME \
  --version 17 javac HelloWorld.java
echo -e "${GREEN}✓ Compilation successful${NC}"
echo ""

# Test 3: Run the compiled program
echo -e "${YELLOW}Step 4: Running HelloWorld with Java 17...${NC}"
docker run --rm -v $(pwd)/test-projects:/workspace $IMAGE_NAME \
  --version 17 java HelloWorld
echo ""

# Test 4: Test javac with all versions
echo -e "${YELLOW}Step 5: Testing javac with ALL Java versions...${NC}"
docker run --rm -v $(pwd)/test-projects:/workspace $IMAGE_NAME \
  --all-versions javac -version
echo ""

# Test 5: Maven build with Java 11
echo -e "${YELLOW}Step 6: Testing Maven build with Java 11...${NC}"
docker run --rm -v $(pwd)/test-projects/maven-project:/workspace $IMAGE_NAME \
  --version 11 mvn clean compile
echo -e "${GREEN}✓ Maven build successful${NC}"
echo ""

# Test 6: Gradle build with Java 21
echo -e "${YELLOW}Step 7: Testing Gradle build with Java 21...${NC}"
docker run --rm -v $(pwd)/test-projects/gradle-project:/workspace $IMAGE_NAME \
  --version 21 gradle build --no-daemon
echo -e "${GREEN}✓ Gradle build successful${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All tests passed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "You can now use the container with:"
echo "  docker run --rm -v \$(pwd):/workspace $IMAGE_NAME --version <8|11|17|21> <command>"
echo ""
echo "Or test with all versions:"
echo "  docker run --rm -v \$(pwd):/workspace $IMAGE_NAME --all-versions <command>"
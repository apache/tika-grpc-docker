#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing,
#   software distributed under the License is distributed on an
#   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#   KIND, either express or implied.  See the License for the
#   specific language governing permissions and limitations
#   under the License.

# Build Docker image from a specific Tika branch
# This is useful for testing development branches before they are released

die() {
  echo "$*" >&2
  exit 1
}

print_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Build Apache Tika gRPC Docker image from source branch"
  echo ""
  echo "Options:"
  echo "  -b BRANCH       Git branch or tag to build from (default: main)"
  echo "  -r REPO         Git repository URL (default: https://github.com/apache/tika.git)"
  echo "  -t TAG          Docker image tag (default: branch-name)"
  echo "  -i              Include Ignite ConfigStore plugin"
  echo "  -p              Push to Docker registry after building"
  echo "  -h              Display this help message"
  echo ""
  echo "Examples:"
  echo "  # Build from TIKA-4583 branch with Ignite support"
  echo "  $0 -b TIKA-4583-ignite-config-store -i"
  echo ""
  echo "  # Build from fork and push to registry"
  echo "  $0 -r https://github.com/user/tika.git -b feature-branch -t myimage:latest -p"
}

# Default values
BRANCH="main"
REPO="https://github.com/apache/tika.git"
TAG=""
INCLUDE_IGNITE=false
PUSH=false

# Parse command line arguments
while getopts ":b:r:t:iph" opt; do
  case ${opt} in
    b )
      BRANCH=$OPTARG
      ;;
    r )
      REPO=$OPTARG
      ;;
    t )
      TAG=$OPTARG
      ;;
    i )
      INCLUDE_IGNITE=true
      ;;
    p )
      PUSH=true
      ;;
    h )
      print_usage
      exit 0
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      print_usage
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      print_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Set default tag if not specified
if [ -z "$TAG" ]; then
  # Convert branch name to valid Docker tag
  TAG=$(echo "$BRANCH" | sed 's/[^a-zA-Z0-9._-]/-/g' | tr '[:upper:]' '[:lower:]')
fi

echo "====================================================================================================="
echo "Building Apache Tika gRPC Docker Image"
echo "====================================================================================================="
echo "Repository: $REPO"
echo "Branch:     $BRANCH"
echo "Tag:        apache/tika-grpc:$TAG"
echo "Ignite:     $INCLUDE_IGNITE"
echo "Push:       $PUSH"
echo "====================================================================================================="

# Choose Dockerfile based on Ignite flag
if [ "$INCLUDE_IGNITE" = true ]; then
  DOCKERFILE="full/Dockerfile.ignite"
  echo "Using Dockerfile with Ignite ConfigStore support: $DOCKERFILE"
else
  DOCKERFILE="full/Dockerfile.source"
  echo "Using source-build Dockerfile: $DOCKERFILE"
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
  die "Error: Dockerfile not found at $DOCKERFILE"
fi

# Build the image
echo ""
echo "Building Docker image..."
docker build \
  --build-arg TIKA_BRANCH="$BRANCH" \
  --build-arg GIT_REPO="$REPO" \
  -t "apache/tika-grpc:$TAG" \
  -f "$DOCKERFILE" \
  . || die "Docker build failed"

echo ""
echo "====================================================================================================="
echo "Build complete: apache/tika-grpc:$TAG"
echo "====================================================================================================="

# Test the image
echo ""
echo "Testing the image..."
CONTAINER_NAME="tika-test-$$"
docker run -d --name "$CONTAINER_NAME" -p 127.0.0.1:50052:50052 "apache/tika-grpc:$TAG" || die "Failed to start container"

# Wait for container to start
echo "Waiting for container to start..."
sleep 10

# Check if container is running
if docker ps | grep -q "$CONTAINER_NAME"; then
  echo "$(tput setaf 2)✓ Container started successfully$(tput sgr0)"
else
  echo "$(tput setaf 1)✗ Container failed to start$(tput sgr0)"
  docker logs "$CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" 2>/dev/null
  exit 1
fi

# Verify user
USER=$(docker inspect "$CONTAINER_NAME" --format '{{.Config.User}}')
if [ "$USER" = "35002:35002" ]; then
  echo "$(tput setaf 2)✓ User configuration correct: $USER$(tput sgr0)"
else
  echo "$(tput setaf 1)✗ User configuration incorrect: $USER (expected 35002:35002)$(tput sgr0)"
  docker rm -f "$CONTAINER_NAME" 2>/dev/null
  exit 1
fi

# Clean up test container
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1
echo "$(tput setaf 2)✓ Tests passed$(tput sgr0)"

# Push if requested
if [ "$PUSH" = true ]; then
  echo ""
  echo "Pushing image to registry..."
  docker push "apache/tika-grpc:$TAG" || die "Failed to push image"
  echo "$(tput setaf 2)✓ Image pushed successfully$(tput sgr0)"
fi

echo ""
echo "====================================================================================================="
echo "Done! Image ready: apache/tika-grpc:$TAG"
echo "====================================================================================================="
echo ""
echo "To run the container:"
echo "  docker run -p 50052:50052 apache/tika-grpc:$TAG"
echo ""
if [ "$INCLUDE_IGNITE" = true ]; then
  echo "To run with Ignite configuration:"
  echo "  docker run -p 50052:50052 -v \$(pwd)/tika-config.json:/config/tika-config.json apache/tika-grpc:$TAG -c /config/tika-config.json"
  echo ""
fi

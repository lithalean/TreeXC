#!/bin/bash

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Tree-sitter XCFramework build without npm dependency
set -e

echo "Building Tree-sitter XCFrameworks (no npm required)..."

# Clean up previous builds
rm -rf build TreeSitter.xcframework TreeSitterSwift.xcframework
mkdir -p build

# Download Tree-sitter
echo "Downloading Tree-sitter..."
curl -L "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.20.8.tar.gz" -o tree-sitter.tar.gz
tar -xzf tree-sitter.tar.gz
rm tree-sitter.tar.gz

cd tree-sitter-0.20.8/lib

# Build Tree-sitter for each platform
echo "Building Tree-sitter libraries..."

# iOS
echo "  - iOS (arm64)"
mkdir -p ../../build/ios
for src in src/*.c; do
    xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I./include -I./src -O3 -c "$src"
done
ar rcs ../../build/ios/libtree-sitter.a *.o
rm *.o

# iOS Simulator
echo "  - iOS Simulator (arm64)"
mkdir -p ../../build/ios-sim
for src in src/*.c; do
    xcrun -sdk iphonesimulator clang -arch arm64 -I./include -I./src -O3 -c "$src"
done
ar rcs ../../build/ios-sim/libtree-sitter.a *.o
rm *.o

# macOS
echo "  - macOS (arm64)"
mkdir -p ../../build/macos
for src in src/*.c; do
    xcrun -sdk macosx clang -arch arm64 -I./include -I./src -O3 -c "$src"
done
ar rcs ../../build/macos/libtree-sitter.a *.o
rm *.o

# Copy headers
cp -r include ../../build/

cd ../..

# Create XCFramework for Tree-sitter
echo "Creating TreeSitter.xcframework..."
xcodebuild -create-xcframework \
    -library build/ios/libtree-sitter.a -headers build/include \
    -library build/ios-sim/libtree-sitter.a -headers build/include \
    -library build/macos/libtree-sitter.a -headers build/include \
    -output TreeSitterRuntime.xcframework

# End of runtime build
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
    -output TreeSitter.xcframework

# Download pre-built tree-sitter-swift
echo "Using locally generated tree-sitter-swift parser..."
cd tree-sitter-swift-generated

if [ ! -f "src/parser.c" ]; then
    echo "❌ Error: src/parser.c not found. Run 'npm run prepare-parser' in tree-sitter-swift first."
    exit 1
fi

cd src

# Build Swift grammar for each platform
echo "Building tree-sitter-swift libraries..."

# iOS
echo "  - iOS (arm64)"
mkdir -p ../../build/swift-ios
echo "⚙️ Running: xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$ROOT_DIR/build/include" -O3 -c parser.c"
xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$ROOT_DIR/build/include" -O3 -c parser.c -o parser.o
if [ -f "scanner.c" ]; then
    echo "⚙️ Running: xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$ROOT_DIR/build/include" -O3 -c scanner.c"
xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$ROOT_DIR/build/include" -O3 -c scanner.c -o scanner.o
    ar rcs ../../build/swift-ios/libtree-sitter-swift.a parser.o scanner.o
else
    ar rcs ../../build/swift-ios/libtree-sitter-swift.a parser.o
fi
rm *.o

# iOS Simulator
echo "  - iOS Simulator (arm64)"
mkdir -p ../../build/swift-ios-sim
echo "⚙️ Running: xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c parser.c"
xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c parser.c -o parser.o
if [ -f "scanner.c" ]; then
    echo "⚙️ Running: xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c scanner.c"
xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c scanner.c -o scanner.o
    ar rcs ../../build/swift-ios-sim/libtree-sitter-swift.a parser.o scanner.o
else
    ar rcs ../../build/swift-ios-sim/libtree-sitter-swift.a parser.o
fi
rm *.o

# macOS
echo "  - macOS (arm64)"
mkdir -p ../../build/swift-macos
echo "⚙️ Running: xcrun -sdk macosx clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c parser.c"
xcrun -sdk macosx clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c parser.c -o parser.o
if [ -f "scanner.c" ]; then
    echo "⚙️ Running: xcrun -sdk macosx clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c scanner.c"
xcrun -sdk macosx clang -arch arm64 -I. -I"$ROOT_DIR/build/include" -O3 -c scanner.c -o scanner.o
    ar rcs ../../build/swift-macos/libtree-sitter-swift.a parser.o scanner.o
else
    ar rcs ../../build/swift-macos/libtree-sitter-swift.a parser.o
fi
rm *.o

# Create header for Swift grammar
mkdir -p ../../build/swift-include
cat > ../../build/swift-include/tree_sitter_swift.h << 'EOF'
#ifndef TREE_SITTER_SWIFT_H_
#define TREE_SITTER_SWIFT_H_

#ifdef __cplusplus
extern "C" {
#endif

const void *tree_sitter_swift(void);

#ifdef __cplusplus
}
#endif

#endif
EOF

cd ../..

# Create XCFramework for tree-sitter-swift
echo "Creating TreeSitterSwift.xcframework..."
xcodebuild -create-xcframework \
    -library build/swift-ios/libtree-sitter-swift.a -headers build/swift-include \
    -library build/swift-ios-sim/libtree-sitter-swift.a -headers build/swift-include \
    -library build/swift-macos/libtree-sitter-swift.a -headers build/swift-include \
    -output TreeSitterSwift.xcframework

# Clean up
rm -rf tree-sitter-0.20.8 tree-sitter-swift-generated build

echo ""
echo "✅ Build complete!"
echo ""
echo "Created:"
echo "  - TreeSitter.xcframework"
echo "  - TreeSitterSwift.xcframework"
echo ""
echo "Add both to your Xcode project with 'Embed & Sign'"
#!/bin/bash

set -e

ROOT_DIR=$(pwd)
GRAMMAR_DIR="$ROOT_DIR/tree-sitter-swift-grammar"
INCLUDE_DIR="$ROOT_DIR/build/include"

echo "Using local Swift grammar from: $GRAMMAR_DIR"

# Check for required source files
if [ ! -f "$GRAMMAR_DIR/src/parser.c" ]; then
    echo "❌ Error: parser.c not found in $GRAMMAR_DIR/src"
    exit 1
fi

cd "$GRAMMAR_DIR/src"

echo "Building tree-sitter-swift libraries..."

# iOS (arm64)
echo "  - iOS (arm64)"
mkdir -p "$ROOT_DIR/build/swift-ios"
xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$INCLUDE_DIR" -O3 -c parser.c -o parser.o
if [ -f "scanner.c" ]; then
    xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$INCLUDE_DIR" -O3 -c scanner.c -o scanner.o
    ar rcs "$ROOT_DIR/build/swift-ios/libtree-sitter-swift.a" parser.o scanner.o
else
    ar rcs "$ROOT_DIR/build/swift-ios/libtree-sitter-swift.a" parser.o
fi
rm -f *.o

# iOS Simulator (arm64)
echo "  - iOS Simulator (arm64)"
mkdir -p "$ROOT_DIR/build/swift-ios-sim"
xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -c parser.c -o parser.o
if [ -f "scanner.c" ]; then
    xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -c scanner.c -o scanner.o
    ar rcs "$ROOT_DIR/build/swift-ios-sim/libtree-sitter-swift.a" parser.o scanner.o
else
    ar rcs "$ROOT_DIR/build/swift-ios-sim/libtree-sitter-swift.a" parser.o
fi
rm -f *.o

# macOS (arm64)
echo "  - macOS (arm64)"
mkdir -p "$ROOT_DIR/build/swift-macos"
xcrun -sdk macosx clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -c parser.c -o parser.o
if [ -f "scanner.c" ]; then
    xcrun -sdk macosx clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -c scanner.c -o scanner.o
    ar rcs "$ROOT_DIR/build/swift-macos/libtree-sitter-swift.a" parser.o scanner.o
else
    ar rcs "$ROOT_DIR/build/swift-macos/libtree-sitter-swift.a" parser.o
fi
rm -f *.o

# Create header file for Swift grammar
mkdir -p "$ROOT_DIR/build/swift-include"
cat > "$ROOT_DIR/build/swift-include/tree_sitter_swift.h" << 'EOF'
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

# Create XCFramework
echo "Creating TreeSitterSwift.xcframework..."
xcodebuild -create-xcframework \
    -library "$ROOT_DIR/build/swift-ios/libtree-sitter-swift.a" -headers "$ROOT_DIR/build/swift-include" \
    -library "$ROOT_DIR/build/swift-ios-sim/libtree-sitter-swift.a" -headers "$ROOT_DIR/build/swift-include" \
    -library "$ROOT_DIR/build/swift-macos/libtree-sitter-swift.a" -headers "$ROOT_DIR/build/swift-include" \
    -output "$ROOT_DIR/TreeSitterSwift.xcframework"

echo ""
echo "✅ Swift grammar build complete!"
echo "Created: TreeSitterSwift.xcframework"

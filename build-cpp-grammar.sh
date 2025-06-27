#!/bin/bash

set -e

echo "Using locally generated tree-sitter-cpp grammar..."

GRAMMAR_DIR="tree-sitter-cpp-grammar"
INCLUDE_DIR="$(pwd)/build/include"
BUILD_DIR="$(pwd)/build"

if [ ! -f "$GRAMMAR_DIR/src/parser.c" ]; then
    echo "❌ Error: $GRAMMAR_DIR/src/parser.c not found."
    exit 1
fi

mkdir -p "$BUILD_DIR/cpp-ios" "$BUILD_DIR/cpp-ios-sim" "$BUILD_DIR/cpp-macos" "$BUILD_DIR/cpp-include"

cp "$GRAMMAR_DIR/tree_sitter_cpp.h" "$BUILD_DIR/cpp-include/"

cd "$GRAMMAR_DIR/src"

echo "Building tree-sitter-cpp libraries..."

# iOS
echo "  - iOS (arm64)"
xcrun -sdk iphoneos clang++ -arch arm64 -fembed-bitcode -x c++ -I. -I"$INCLUDE_DIR" -O3 -c parser.c -o parser.o
[ -f scanner.c ] && xcrun -sdk iphoneos clang++ -arch arm64 -fembed-bitcode -x c++ -I. -I"$INCLUDE_DIR" -O3 -c scanner.c -o scanner.o
ar rcs "$BUILD_DIR/cpp-ios/libtree-sitter-cpp.a" parser.o scanner.o 2>/dev/null || ar rcs "$BUILD_DIR/cpp-ios/libtree-sitter-cpp.a" parser.o

# iOS Simulator
echo "  - iOS Simulator (arm64)"
xcrun -sdk iphonesimulator clang++ -arch arm64 -x c++ -I. -I"$INCLUDE_DIR" -O3 -c parser.c -o parser.o
[ -f scanner.c ] && xcrun -sdk iphonesimulator clang++ -arch arm64 -x c++ -I. -I"$INCLUDE_DIR" -O3 -c scanner.c -o scanner.o
ar rcs "$BUILD_DIR/cpp-ios-sim/libtree-sitter-cpp.a" parser.o scanner.o 2>/dev/null || ar rcs "$BUILD_DIR/cpp-ios-sim/libtree-sitter-cpp.a" parser.o

# macOS
echo "  - macOS (arm64)"
xcrun -sdk macosx clang++ -arch arm64 -x c++ -I. -I"$INCLUDE_DIR" -O3 -c parser.c -o parser.o
[ -f scanner.c ] && xcrun -sdk macosx clang++ -arch arm64 -x c++ -I. -I"$INCLUDE_DIR" -O3 -c scanner.c -o scanner.o
ar rcs "$BUILD_DIR/cpp-macos/libtree-sitter-cpp.a" parser.o scanner.o 2>/dev/null || ar rcs "$BUILD_DIR/cpp-macos/libtree-sitter-cpp.a" parser.o

rm -f parser.o scanner.o

cd ../..

echo "Creating TreeSitterCpp.xcframework..."
xcodebuild -create-xcframework \
    -library "$BUILD_DIR/cpp-ios/libtree-sitter-cpp.a" -headers "$BUILD_DIR/cpp-include" \
    -library "$BUILD_DIR/cpp-ios-sim/libtree-sitter-cpp.a" -headers "$BUILD_DIR/cpp-include" \
    -library "$BUILD_DIR/cpp-macos/libtree-sitter-cpp.a" -headers "$BUILD_DIR/cpp-include" \
    -output TreeSitterCpp.xcframework

echo ""
echo "✅ C++ grammar build complete!"
echo "Created: TreeSitterCpp.xcframework"

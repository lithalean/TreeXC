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

# Create proper header file for C++ grammar
cat > "$BUILD_DIR/cpp-include/tree_sitter_cpp.h" << 'EOF'
#ifndef TREE_SITTER_CPP_H_
#define TREE_SITTER_CPP_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "tree_sitter/api.h"

const TSLanguage *tree_sitter_cpp(void);

#ifdef __cplusplus
}
#endif

#endif
EOF

cd "$GRAMMAR_DIR/src"

echo "Building tree-sitter-cpp libraries with symbol filtering..."

# Create a wrapper that only exposes the language function
cat > cpp_wrapper.c << 'EOF'
#include "tree_sitter/api.h"

// Forward declare the language from the parser
extern const TSLanguage tree_sitter_cpp_language;

// Only export this function
const TSLanguage *tree_sitter_cpp(void) {
    return &tree_sitter_cpp_language;
}
EOF

# iOS
echo "  - iOS (arm64)"
xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$INCLUDE_DIR" -O3 -fvisibility=hidden -c parser.c -o parser.o
xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c cpp_wrapper.c -o wrapper.o
if [ -f "scanner.cc" ]; then
    xcrun -sdk iphoneos clang++ -arch arm64 -fembed-bitcode -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c scanner.cc -o scanner.o
    ar rcs "$BUILD_DIR/cpp-ios/libtree-sitter-cpp.a" parser.o wrapper.o scanner.o
elif [ -f "scanner.c" ]; then
    xcrun -sdk iphoneos clang -arch arm64 -fembed-bitcode -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c scanner.c -o scanner.o
    ar rcs "$BUILD_DIR/cpp-ios/libtree-sitter-cpp.a" parser.o wrapper.o scanner.o
else
    ar rcs "$BUILD_DIR/cpp-ios/libtree-sitter-cpp.a" parser.o wrapper.o
fi

# iOS Simulator
echo "  - iOS Simulator (arm64)"
xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=hidden -c parser.c -o parser.o
xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c cpp_wrapper.c -o wrapper.o
if [ -f "scanner.cc" ]; then
    xcrun -sdk iphonesimulator clang++ -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c scanner.cc -o scanner.o
    ar rcs "$BUILD_DIR/cpp-ios-sim/libtree-sitter-cpp.a" parser.o wrapper.o scanner.o
elif [ -f "scanner.c" ]; then
    xcrun -sdk iphonesimulator clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c scanner.c -o scanner.o
    ar rcs "$BUILD_DIR/cpp-ios-sim/libtree-sitter-cpp.a" parser.o wrapper.o scanner.o
else
    ar rcs "$BUILD_DIR/cpp-ios-sim/libtree-sitter-cpp.a" parser.o wrapper.o
fi

# macOS
echo "  - macOS (arm64)"
xcrun -sdk macosx clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=hidden -c parser.c -o parser.o
xcrun -sdk macosx clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c cpp_wrapper.c -o wrapper.o
if [ -f "scanner.cc" ]; then
    xcrun -sdk macosx clang++ -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c scanner.cc -o scanner.o
    ar rcs "$BUILD_DIR/cpp-macos/libtree-sitter-cpp.a" parser.o wrapper.o scanner.o
elif [ -f "scanner.c" ]; then
    xcrun -sdk macosx clang -arch arm64 -I. -I"$INCLUDE_DIR" -O3 -fvisibility=default -c scanner.c -o scanner.o
    ar rcs "$BUILD_DIR/cpp-macos/libtree-sitter-cpp.a" parser.o wrapper.o scanner.o
else
    ar rcs "$BUILD_DIR/cpp-macos/libtree-sitter-cpp.a" parser.o wrapper.o
fi

rm -f *.o cpp_wrapper.c

cd ../..

echo "Creating TreeSitterCpp.xcframework..."
xcodebuild -create-xcframework \
    -library "$BUILD_DIR/cpp-ios/libtree-sitter-cpp.a" -headers "$BUILD_DIR/cpp-include" \
    -library "$BUILD_DIR/cpp-ios-sim/libtree-sitter-cpp.a" -headers "$BUILD_DIR/cpp-include" \
    -library "$BUILD_DIR/cpp-macos/libtree-sitter-cpp.a" -headers "$BUILD_DIR/cpp-include" \
    -output TreeSitterCpp.xcframework

echo ""
echo "✅ Symbol-filtered C++ grammar build complete!"
echo "Created: TreeSitterCpp.xcframework"
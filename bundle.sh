#!/bin/bash

## Get the directory of the currently executing script
DIR="$(dirname "$0")"

# Change to that directory
cd "$DIR" || exit

obj="host.o"

# Build for macos-arm64
rm -rf zig-out/
zig build -Dtarget=aarch64-macos
cp zig-out/$obj platform/macos-arm64.o

# Build for macos-x64
rm -rf zig-out/
zig build -Dtarget=x86_64-macos
cp zig-out/$obj platform/macos-x64.o

# Build for linux-x64
rm -rf zig-out/
zig build -Dtarget=x86_64-linux
cp zig-out/$obj platform/linux-x64.o

# TEST RUN USING NATIVE

# Also works on macos when installed from https://github.com/libsdl-org/SDL/releases/tag/release-2.28.5
# Copy the SDL2.framework in the .dmg to /Library/Frameworks
# ROC_LINK_FLAGS=/Library/Frameworks/SDL2.framework/SDL2 roc run --prebuilt-platform examples/rocLovesGraphics.roc

if [ $? -ne 0 ]; then
    echo "Build failed. Exiting..."
    exit 1
fi

export ROC_LINK_FLAGS=`sdl2-config --libs`
roc run --prebuilt-platform examples/rocLovesGraphics.roc

# BUNDLE
# roc build --bundle .tar.br platform/main.roc

# TARGETS FROM roc-lang/roc/crates/compiler/roc_target/src/lib.rs
#[strum(serialize = "linux-x32")] 
#[strum(serialize = "linux-x64")]
#[strum(serialize = "linux-arm64")]
#[strum(serialize = "macos-x64")]
#[strum(serialize = "macos-arm64")]
#[strum(serialize = "windows-x32")]
#[strum(serialize = "windows-x64")]
#[strum(serialize = "windows-arm64")]
#[strum(serialize = "wasm32")]

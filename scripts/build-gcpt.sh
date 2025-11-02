#!/usr/bin/env bash
set -e

GCPT_SOURCE_DIR="$(realpath "$1")"
GCPT_BUILD_DIR="$(realpath "$2")"
BUILD_DIR="$(dirname "$GCPT_BUILD_DIR")"

# prepare OpenSBI source
mkdir -p "$BUILD_DIR"
rm -rf "$GCPT_BUILD_DIR"
cp -r "$GCPT_SOURCE_DIR" "$GCPT_BUILD_DIR"

# Build OpenSBI
make -C "$GCPT_BUILD_DIR"

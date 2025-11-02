#!/usr/bin/env bash
set -e

export WORKLOAD_DIR
export WORKLOAD_BUILD_DIR
WORKLOAD_DIR="$(realpath "$1")"
WORKLOAD_BUILD_DIR="$(realpath "$2")"
export SRC_DIR="$WORKLOAD_BUILD_DIR/source"
export PKG_DIR="$WORKLOAD_BUILD_DIR/package"

populate-src-dir() {
    mkdir -p "$WORKLOAD_BUILD_DIR"
    if [[ -e "$SRC_DIR" ]]; then
        rm -rf "$SRC_DIR"
    fi
    if [[ -d "$WORKLOAD_DIR/source" ]]; then
        cp -r "$WORKLOAD_DIR/source" "$SRC_DIR"
    else
        mkdir -p "$SRC_DIR"
    fi
}

download-files() {
    local file_list="$1"
    local target_dir="$2"

    if [[ -f "$file_list" ]]; then
        cat "$file_list" | if true; then cat; echo; fi | while read -r line; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            local file_name="${line%%::*}"
            local download_link="${line#*::}"
            local target_file="$target_dir/$file_name"
            wget -O "$target_file" "$download_link"
        done
    fi
}

pack-cpio() {
    local root_dir="$1"
    local cpio_file="$2"
    rm -f "$cpio_file"
    cd "$root_dir"
    find . | fakeroot cpio -o -H newc | zstd -3 -o "$cpio_file"
}

populate-src-dir
download-files "$WORKLOAD_DIR/links.txt" "$WORKLOAD_BUILD_DIR/source"
rm -rf "$PKG_DIR" && mkdir -p "$PKG_DIR"
bash "$WORKLOAD_DIR/build.sh"
pack-cpio "$PKG_DIR" "$WORKLOAD_BUILD_DIR/rootfs.cpio.zstd"

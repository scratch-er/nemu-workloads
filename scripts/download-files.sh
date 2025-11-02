#!/usr/bin/env bash
set -e

WORKLOAD_DIR="$(realpath "$1")"
DOWNLOAD_DIR="$(realpath "$2")"
FILE_LIST="$WORKLOAD_DIR"/links.txt

mkdir -p "$DOWNLOAD_DIR"

if [[ -f "$FILE_LIST" ]]; then
    cat "$FILE_LIST" | if true; then cat; echo; fi | while read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        file_name="$(cut -f 1 -d ' ' <<< "$line")"
        link="$(cut -f 2 -d ' ' <<< "$line")"
        sha256sum="$(cut -f 3 -d ' ' <<< "$line")"

        if ! [ -f "$DOWNLOAD_DIR/$file_name" ] ; then
            if ! wget -O "$DOWNLOAD_DIR/$file_name" "$link" ; then
                echo "Downloading $file_name failed"
                rm -f "$DOWNLOAD_DIR/$file_name"
                exit 1
            fi
        fi

        computed_sha256=$(sha256sum "$DOWNLOAD_DIR/$file_name" | cut -d ' ' -f 1)
        if [ "$computed_sha256" != "$sha256sum" ]; then
            echo "Error: SHA256 checksum mismatch for $file_name"
            rm -f "$DOWNLOAD_DIR/$file_name"
            exit 1
        fi
    done
fi

touch "$DOWNLOAD_DIR"/sentinel

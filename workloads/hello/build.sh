mkdir -p "$PKG_DIR/etc"
mkdir -p "$PKG_DIR/usr/bin"

"$CROSS_COMPILE"gcc -static -O2 "$SRC_DIR/hello.c" -o "$PKG_DIR/usr/bin/hello"
"$CROSS_COMPILE"strip -s "$PKG_DIR/usr/bin/hello"
cp "$WORKLOAD_DIR/inittab" "$PKG_DIR/etc/inittab"

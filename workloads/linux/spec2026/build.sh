#!/usr/bin/env bash
set -euo pipefail

: "${WORKLOAD_BUILD_DIR:?WORKLOAD_BUILD_DIR is required}"
: "${SPEC2026_CASE:?SPEC2026_CASE is required}"
: "${SPEC2026:?SPEC2026 is required}"
: "${SPEC2026_CFG:?SPEC2026_CFG is required}"
: "${CROSS_COMPILE:=riscv64-unknown-linux-gnu-}"
: "${SPEC2026_TUNE:=base}"
: "${SPEC2026_JOBS:=$(nproc)}"
: "${SPEC2026_JEMALLOC_REPO:=https://github.com/jemalloc/jemalloc.git}"
: "${SPEC2026_JEMALLOC_COMMIT:=1a15fe33a48c52bfe26ea83e49f0d317a47da3ea}"
: "${SPEC2026_DOWNLOAD_RETRIES:=3}"
: "${SPEC2026_ELF_ONLY:=false}"
: "${SPEC2026_LOG_DIR:=$WORKLOAD_BUILD_DIR/logs}"
: "${PKG_DIR:=$WORKLOAD_BUILD_DIR/package}"

SPEC2026_JEMALLOC_ROOT="${SPEC2026_JEMALLOC_ROOT:-${JEMALLOC_INSTALL_PATH:-}}"
jemalloc_root_is_explicit=0
if [ -n "$SPEC2026_JEMALLOC_ROOT" ]; then
  jemalloc_root_is_explicit=1
fi

jemalloc_lock_dir=""
cleanup() {
  if [ -n "$jemalloc_lock_dir" ]; then
    rmdir "$jemalloc_lock_dir" 2>/dev/null || true
  fi
}
trap cleanup EXIT

mkdir -p "$SPEC2026_LOG_DIR"

spec2026_progress_prefix() {
  local k="${SPEC2026_PROGRESS_K:-1}"
  local n="${SPEC2026_PROGRESS_N:-1}"
  printf '[spec2026 %s/%s]' "$k" "$n"
}

status() {
  printf '%s %s\n' "$(spec2026_progress_prefix)" "$*"
}

show_log_tail() {
  local log_file="$1"
  if [ -f "$log_file" ]; then
    echo "$(spec2026_progress_prefix) Last 40 lines from $log_file:" >&2
    tail -n 40 "$log_file" >&2 || true
  fi
}

retry() {
  local attempt=1
  while true; do
    if "$@"; then
      return 0
    fi
    if [ "$attempt" -ge "$SPEC2026_DOWNLOAD_RETRIES" ]; then
      return 1
    fi
    printf '%s Retrying failed command (%s/%s): %s\n' \
      "$(spec2026_progress_prefix)" \
      "$attempt" \
      "$SPEC2026_DOWNLOAD_RETRIES" \
      "$*" >&2
    sleep $((attempt * 2))
    attempt=$((attempt + 1))
  done
}

retry_git_clone() {
  local repo="$1"
  local dest="$2"
  local attempt=1
  while true; do
    rm -rf "$dest"
    if git clone "$repo" "$dest"; then
      return 0
    fi
    if [ "$attempt" -ge "$SPEC2026_DOWNLOAD_RETRIES" ]; then
      return 1
    fi
    printf '%s Retrying failed git clone (%s/%s): %s\n' \
      "$(spec2026_progress_prefix)" \
      "$attempt" \
      "$SPEC2026_DOWNLOAD_RETRIES" \
      "$repo" >&2
    sleep $((attempt * 2))
    attempt=$((attempt + 1))
  done
}

prepare_git_checkout() {
  local repo="$1"
  local commit="$2"
  local dest="$3"
  local current_commit target_commit

  if [ ! -d "$dest/.git" ]; then
    retry_git_clone "$repo" "$dest"
  else
    git -C "$dest" remote set-url origin "$repo"
  fi

  if ! git -C "$dest" cat-file -e "$commit^{commit}" 2>/dev/null; then
    retry git -C "$dest" fetch --tags origin
  fi

  current_commit="$(git -C "$dest" rev-parse HEAD 2>/dev/null || true)"
  target_commit="$(git -C "$dest" rev-parse "$commit")"
  if [ "$current_commit" != "$target_commit" ]; then
    git -C "$dest" checkout --detach "$commit"
    git -C "$dest" clean -ffdx
  fi
}

is_true() {
  case "$1" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

cfg_requires_jemalloc() {
  grep -Eq 'JEMALLOC_PATH|-ljemalloc' "$SPEC2026_CFG"
}

resolve_jemalloc_root() {
  if [ -n "$SPEC2026_JEMALLOC_ROOT" ]; then
    realpath -m "$SPEC2026_JEMALLOC_ROOT"
  else
    realpath -m "$(dirname "$WORKLOAD_BUILD_DIR")/jemalloc/install"
  fi
}

resolve_jemalloc_host() {
  if [ -n "${SPEC2026_JEMALLOC_CONFIGURE_HOST:-}" ]; then
    printf '%s\n' "$SPEC2026_JEMALLOC_CONFIGURE_HOST"
  else
    "${CROSS_COMPILE}gcc" -dumpmachine
  fi
}

jemalloc_cache_metadata() {
  local host="$1"
  printf '%s\n' \
    "repo=$SPEC2026_JEMALLOC_REPO" \
    "commit=$SPEC2026_JEMALLOC_COMMIT" \
    "cross_compile=$CROSS_COMPILE" \
    "host=$host"
}

jemalloc_cache_is_current() {
  local prefix="$1"
  local host="$2"
  local metadata_file="$prefix/.workload-builder-jemalloc-meta"

  if [ ! -f "$prefix/lib/libjemalloc.a" ]; then
    return 1
  fi
  if [ "$jemalloc_root_is_explicit" = 1 ]; then
    return 0
  fi
  [ -f "$metadata_file" ] && [ "$(cat "$metadata_file")" = "$(jemalloc_cache_metadata "$host")" ]
}

prepare_jemalloc() {
  local base_dir source_dir prefix host log_file rc
  base_dir="$(realpath -m "$(dirname "$WORKLOAD_BUILD_DIR")/jemalloc")"
  source_dir="$base_dir/source"
  prefix="$(resolve_jemalloc_root)"
  host="$(resolve_jemalloc_host)"
  log_file="$base_dir/build.log"

  if jemalloc_cache_is_current "$prefix" "$host"; then
    SPEC2026_JEMALLOC_ROOT="$prefix"
    export SPEC2026_JEMALLOC_ROOT
    status "Using cached jemalloc: $prefix"
    return
  fi

  jemalloc_lock_dir="$base_dir/.lock"
  mkdir -p "$base_dir"
  while ! mkdir "$jemalloc_lock_dir" 2>/dev/null; do
    sleep 1
  done

  if jemalloc_cache_is_current "$prefix" "$host"; then
    rmdir "$jemalloc_lock_dir"
    jemalloc_lock_dir=""
    SPEC2026_JEMALLOC_ROOT="$prefix"
    export SPEC2026_JEMALLOC_ROOT
    status "Using cached jemalloc: $prefix"
    return
  fi

  status "Preparing jemalloc (log: $log_file)"
  : > "$log_file"

  rc=0
  set +e
  (
    set -euo pipefail
    echo "# jemalloc repo: $SPEC2026_JEMALLOC_REPO"
    echo "# jemalloc commit: $SPEC2026_JEMALLOC_COMMIT"
    echo "# install prefix: $prefix"
    echo "# configure host: $host"
    prepare_git_checkout "$SPEC2026_JEMALLOC_REPO" "$SPEC2026_JEMALLOC_COMMIT" "$source_dir"

    cd "$source_dir"
    CC="${CROSS_COMPILE}gcc" \
    CXX="${CROSS_COMPILE}g++" \
    AR="${CROSS_COMPILE}ar" \
    LD="${CROSS_COMPILE}ld" \
    RANLIB="${CROSS_COMPILE}ranlib" \
    STRIP="${CROSS_COMPILE}strip" \
    ./autogen.sh --prefix="$prefix" --host="$host"
    make -j"$SPEC2026_JOBS"
    make install
  ) >>"$log_file" 2>&1
  rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    echo "$(spec2026_progress_prefix) jemalloc build failed; see $log_file" >&2
    show_log_tail "$log_file"
    return 1
  fi
  if [ ! -f "$prefix/lib/libjemalloc.a" ]; then
    echo "$(spec2026_progress_prefix) jemalloc install did not produce $prefix/lib/libjemalloc.a" >&2
    return 1
  fi
  jemalloc_cache_metadata "$host" > "$prefix/.workload-builder-jemalloc-meta"

  rmdir "$jemalloc_lock_dir"
  jemalloc_lock_dir=""

  SPEC2026_JEMALLOC_ROOT="$prefix"
  export SPEC2026_JEMALLOC_ROOT
  status "jemalloc ready: $prefix"
}

if cfg_requires_jemalloc; then
  prepare_jemalloc
fi

python_args=()
if is_true "$SPEC2026_ELF_ONLY"; then
  python_args+=(--elf-only)
fi

python3 "$WORKLOAD_DIR/spec2026-package.py" \
  --case "$SPEC2026_CASE" \
  --spec "$SPEC2026" \
  --spec-config "$SPEC2026_CFG" \
  --pkg-dir "$PKG_DIR" \
  --out-dir "$WORKLOAD_BUILD_DIR" \
  --cross-compile "$CROSS_COMPILE" \
  --jemalloc-root "${SPEC2026_JEMALLOC_ROOT:-}" \
  --log-dir "$SPEC2026_LOG_DIR" \
  --tune "$SPEC2026_TUNE" \
  --jobs "$SPEC2026_JOBS" \
  --input-set "${SPEC2026_INPUT:-ref}" \
  "${python_args[@]}"

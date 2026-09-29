#!/bin/sh
# Builds decode.wasm through IX and writes decode.wasm.zstd into the given
# directory. To move to a newer IX, change IX_REV and commit: every commit
# on main is a release.
#
#   ./build.sh OUT_DIR
#
# Needs the system build tools IX expects under all_system (clang, lld,
# llvm, cmake, ninja, make, meson, perl, python3, pkg-config, m4, ...),
# plus imagemagick (the module's tests use it) and zstd.

set -eu

IX_REV=f0b1fbeee727bb340696aa4ca28092ff7ceb9fef
IX_REPO=https://github.com/pg83/ix

if [ "$#" -ne 1 ]; then
    echo "usage: $0 OUT_DIR" >&2
    exit 2
fi

out=$(mkdir -p "$1" && cd "$1" && pwd)
here=$(cd "$(dirname "$0")" && pwd)
ix="$here/.ix"

if [ ! -f "$ix/ix" ]; then
    rm -rf "$ix"
    git init -q "$ix"
    git -C "$ix" fetch -q --depth 1 "$IX_REPO" "$IX_REV"
    git -C "$ix" checkout -q FETCH_HEAD
fi

if [ "$(git -C "$ix" rev-parse HEAD)" != "$IX_REV" ]; then
    echo "$ix is not at $IX_REV; remove it and rerun" >&2
    exit 1
fi

export IX_FLAGS="${IX_FLAGS:-all_system=1}"
export IX_ROOT="${IX_ROOT:-$here/.ix-root}"
export IX_THREADS="${IX_THREADS:-4}"

"$ix/ix" run set/wasm/decode -- sh -c '
    set -eu
    zstd -19 -f -q -o "$1/decode.wasm.zstd" "$IX_IMAGE_MAGICK_DECODE_WASM"
    sha256sum "$IX_IMAGE_MAGICK_DECODE_WASM" "$1/decode.wasm.zstd"
' sh "$out"

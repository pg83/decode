#!/bin/sh
# Builds one pure wasm module through IX and writes it, zstd-compressed,
# into the given directory. To move to a newer IX, change IX_REV and
# commit: every commit on main is a release of all five modules.
#
#   ./build.sh MODULE OUT_DIR
#
#   decode          ImageMagick's decoders, lib/image/magick/wasm
#   decode.simd128  the same with wasm simd128
#   pdf             PDFium, lib/pdf/ium/wasm
#   djvu            DjVuLibre, lib/djvulibre/wasm
#   magic           libmagic, lib/magic/wasm
#
# Needs the system build tools IX expects under all_system (clang, lld,
# llvm, cmake, ninja, make, meson, perl, python3, pkg-config, m4, ...),
# plus imagemagick (the decode module's tests use it) and zstd.

set -eu

IX_REV=17c9dada4721fe55e604e24212233fa55361e028
IX_REPO=${IX_REPO:-https://github.com/pg83/ix}

if [ "$#" -ne 2 ]; then
    echo "usage: $0 MODULE OUT_DIR" >&2
    exit 2
fi

module=$1
out=$(mkdir -p "$2" && cd "$2" && pwd)
here=$(cd "$(dirname "$0")" && pwd)
ix="$here/.ix"

# the IX set that carries the module with its target, the flags the set
# takes, and the variable the module's package exports its path in
case $module in
    decode)         set=set/wasm/decode; flags=""; path=IX_IMAGE_MAGICK_DECODE_WASM;;
    decode.simd128) set=set/wasm/decode; flags="--simd128=1"; path=IX_IMAGE_MAGICK_DECODE_WASM;;
    pdf)            set=set/wasm/pdf; flags=""; path=IX_PDFIUM_WASM;;
    djvu)           set=set/wasm/djvu; flags=""; path=IX_DJVULIBRE_WASM;;
    magic)          set=set/wasm/magic; flags=""; path=IX_MAGIC_WASM;;
    *)
        echo "$0: no module named $module" >&2
        exit 2;;
esac

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

# IX_FLAGS set but empty means no flags: a machine whose IX carries its
# own toolchain
export IX_FLAGS="${IX_FLAGS-all_system=1}"
export IX_ROOT="${IX_ROOT:-$here/.ix-root}"
export IX_THREADS="${IX_THREADS:-4}"

# shellcheck disable=SC2086
"$ix/ix" run "$set" $flags -- sh -c '
    set -eu
    eval "built=\${$3}"
    zstd -19 -f -q -o "$1/$2.wasm.zstd" "$built"
    sha256sum "$built" "$1/$2.wasm.zstd"
' sh "$out" "$module" "$path"

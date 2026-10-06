# decode

Decoders as pure WebAssembly modules, built by
[ix](https://github.com/pg83/ix) for the `wasm32-none` target: each
module imports nothing, exports `memory`, `malloc`, `free` and a few
functions, and is proven pure and run through a loader by the build
behind it. A release carries four:

| module | from | what it does |
|---|---|---|
| `decode.wasm` | `lib/image/magick/wasm` | ImageMagick and its coders, one `decode` export |
| `decode.simd128.wasm` | the same with `-msimd128` | JPEG XL decodes about three times faster on a runtime with SIMD, such as wasm2c with the generated C compiled for x86-64-v3 |
| `pdf.wasm` | `lib/pdf/ium/wasm` | PDFium: open a PDF from memory, count and measure its pages, render one |
| `djvu.wasm` | `lib/djvulibre/wasm` | DjVuLibre: the same for a DjVu |

A host keeps an instance per worker, hands it whole files through the
exported `malloc`, and reads results back out of linear memory. A trap
is a failed call; the instance is then dead, as any wasm instance, and
the host makes another. Every module links with an 8 MB wasm stack and
runs its static constructors on the first call of an instance.

## decode

    decode(data, len, name, name_len) -> image | 0
    struct image { uint32_t width; uint32_t height; uint8_t rgba[]; }

Sniffs the format, decodes, applies the EXIF orientation, converts to sRGB
and returns one block of 8-bit RGBA, to be `free`d by the host. `name` is
optional (0, 0): a file name whose extension names the format for files
without a magic number (TGA, raw RGB); a magic number in the data always
wins. 0 is a failure the library noticed itself.

Formats: PNG, JPEG, WebP, TIFF, JPEG 2000, JPEG XL, GIF, BMP, PNM/PAM,
TGA, PCX, SGI, MIFF and the other coders built into ImageMagick.

## pdf and djvu

Both speak the same page ABI under their own prefix:

    <p>_open(data, len) -> doc | 0
    <p>_pages(doc) -> count
    <p>_width(doc, page) -> points | 0
    <p>_height(doc, page) -> points | 0
    <p>_render(doc, page, width, height) -> image | 0
    <p>_close(doc)

A page's size is in points. A render is the page scaled to the asked size,
8-bit RGBA in an `image` block, to be `free`d by the host. PDFium reads the
file's bytes until `pdf_close`, so the host keeps them in memory that
long; DjVuLibre copies them in `djvu_open`. `djvu_error()` names the cause
of the last trap, as a C string.

## Building

    ./build.sh MODULE OUT_DIR

builds one of `decode`, `decode.simd128`, `pdf`, `djvu` through IX at the
revision pinned in `build.sh` and writes `OUT_DIR/MODULE.wasm.zstd`. The
release workflow runs the four in parallel and publishes them as the next
numeric tag, with their sha256 sums in the notes.

# decode

ImageMagick as one pure WebAssembly module: `decode.wasm`, built by
[ix](https://github.com/pg83/ix) as `lib/image/magick/wasm` for the
`wasm32-none` target. The module imports nothing. It exports `memory`,
`malloc`, `free` and

    decode(data, len, name, name_len) -> image | 0

which sniffs the format, decodes, applies the EXIF orientation, converts
to sRGB and returns one block in linear memory:

    struct image { uint32_t width; uint32_t height; uint8_t rgba[]; };

`name` is optional (0, 0): a file name whose extension names the format
for files without a magic number (TGA, raw RGB); a magic number in the
data always wins. The first call in a fresh instance initializes the
module; an instance serves any number of decodes. A trap is a failed
decode; 0 is one the library noticed itself. Link the host with an 8 MB
wasm stack in mind: the module is linked with `-z stack-size=8388608`.

Formats: PNG, JPEG, WebP, TIFF, JPEG 2000, JPEG XL, GIF, BMP, PNM/PAM,
TGA, PCX, SGI, MIFF and the other coders built into ImageMagick.

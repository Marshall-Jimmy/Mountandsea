"""Assemble the demo-local player animation atlas from its transparent source.

Source layout: three columns by two rows of 512x512 RGBA frames.
Reading order: idle 0, idle 1, walk 0, walk 1, walk 2, walk 3.
Output layout: one horizontal row of six 512x512 RGBA frames.

The source artwork was generated for this demo, then locally chroma-keyed. This
script only performs deterministic frame rearrangement and uses the Python
standard library.
"""

from __future__ import annotations

import struct
import zlib
from pathlib import Path


FRAME_SIZE = 512
FRAME_COUNT = 6
SOURCE_COLUMNS = 3
SOURCE_ROWS = 2
ROOT = Path(__file__).resolve().parents[1]
ASSET_DIRECTORY = ROOT / "game" / "assets" / "demo" / "placeholder_sprites"
SOURCE_PATH = ASSET_DIRECTORY / "demo_player_idle_walk_source_3x2.png"
OUTPUT_PATH = ASSET_DIRECTORY / "demo_player_idle_walk.png"


def _paeth_predictor(left: int, up: int, upper_left: int) -> int:
    prediction = left + up - upper_left
    left_distance = abs(prediction - left)
    up_distance = abs(prediction - up)
    upper_left_distance = abs(prediction - upper_left)
    if left_distance <= up_distance and left_distance <= upper_left_distance:
        return left
    if up_distance <= upper_left_distance:
        return up
    return upper_left


def _read_rgba_png(path: Path) -> tuple[int, int, bytearray]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG")

    width = 0
    height = 0
    compressed = bytearray()
    cursor = 8
    while cursor < len(data):
        chunk_length = struct.unpack(">I", data[cursor : cursor + 4])[0]
        chunk_type = data[cursor + 4 : cursor + 8]
        payload_start = cursor + 8
        payload_end = payload_start + chunk_length
        payload = data[payload_start:payload_end]
        cursor = payload_end + 4

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
            if (bit_depth, color_type, compression, filtering, interlace) != (8, 6, 0, 0, 0):
                raise ValueError(f"{path} must be a non-interlaced 8-bit RGBA PNG")
        elif chunk_type == b"IDAT":
            compressed.extend(payload)
        elif chunk_type == b"IEND":
            break

    bytes_per_pixel = 4
    row_size = width * bytes_per_pixel
    filtered_rows = zlib.decompress(bytes(compressed))
    expected_size = height * (row_size + 1)
    if len(filtered_rows) != expected_size:
        raise ValueError(f"{path} has unexpected decoded data size")

    pixels = bytearray()
    previous_row = bytearray(row_size)
    cursor = 0
    for _ in range(height):
        filter_type = filtered_rows[cursor]
        cursor += 1
        row = bytearray(filtered_rows[cursor : cursor + row_size])
        cursor += row_size

        for index in range(row_size):
            left = row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            up = previous_row[index]
            upper_left = previous_row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            if filter_type == 1:
                row[index] = (row[index] + left) & 0xFF
            elif filter_type == 2:
                row[index] = (row[index] + up) & 0xFF
            elif filter_type == 3:
                row[index] = (row[index] + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                row[index] = (row[index] + _paeth_predictor(left, up, upper_left)) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"{path} uses unsupported PNG filter {filter_type}")

        pixels.extend(row)
        previous_row = row

    return width, height, pixels


def _png_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    checksum = zlib.crc32(chunk_type)
    checksum = zlib.crc32(payload, checksum) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + chunk_type + payload + struct.pack(">I", checksum)


def _write_rgba_png(path: Path, width: int, height: int, pixels: bytearray) -> None:
    row_size = width * 4
    filtered_rows = bytearray()
    for row_index in range(height):
        filtered_rows.append(0)
        row_start = row_index * row_size
        filtered_rows.extend(pixels[row_start : row_start + row_size])

    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(
        _png_chunk(
            b"IHDR",
            struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0),
        )
    )
    png.extend(_png_chunk(b"IDAT", zlib.compress(bytes(filtered_rows), level=9)))
    png.extend(_png_chunk(b"IEND", b""))
    path.write_bytes(png)


def main() -> None:
    source_width, source_height, source_pixels = _read_rgba_png(SOURCE_PATH)
    expected_width = FRAME_SIZE * SOURCE_COLUMNS
    expected_height = FRAME_SIZE * SOURCE_ROWS
    if (source_width, source_height) != (expected_width, expected_height):
        raise ValueError(
            f"{SOURCE_PATH} must be {expected_width}x{expected_height}, "
            f"got {source_width}x{source_height}"
        )

    output_width = FRAME_SIZE * FRAME_COUNT
    output_pixels = bytearray(output_width * FRAME_SIZE * 4)
    source_row_size = source_width * 4
    output_row_size = output_width * 4
    frame_row_size = FRAME_SIZE * 4

    for frame_index in range(FRAME_COUNT):
        source_column = frame_index % SOURCE_COLUMNS
        source_row = frame_index // SOURCE_COLUMNS
        for frame_y in range(FRAME_SIZE):
            source_start = (
                (source_row * FRAME_SIZE + frame_y) * source_row_size
                + source_column * frame_row_size
            )
            output_start = frame_y * output_row_size + frame_index * frame_row_size
            output_pixels[output_start : output_start + frame_row_size] = source_pixels[
                source_start : source_start + frame_row_size
            ]

    _write_rgba_png(OUTPUT_PATH, output_width, FRAME_SIZE, output_pixels)
    print(
        f"generated {OUTPUT_PATH} "
        f"({output_width}x{FRAME_SIZE}, frames: idle=0-1 walk=2-5)"
    )


if __name__ == "__main__":
    main()

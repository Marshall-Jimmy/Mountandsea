"""Clean, align, and assemble the demo-local player animation atlas.

Source layout: three columns by two rows of 512x512 RGBA frames.
Reading order: idle 0, idle 1, walk 0, walk 1, walk 2, walk 3.
Output layout: one horizontal row of six 512x512 RGBA frames.

The source artwork was generated for this demo, then locally chroma-keyed.
Every output frame is placed on the same 512x512 transparent canvas with its
feet center aligned to TARGET_FEET_ANCHOR. The cleanup removes low-alpha matte
residue and tiny disconnected cutout specks before atlas assembly.

This script is deterministic and uses only the Python standard library.
"""

from __future__ import annotations

import struct
import zlib
from pathlib import Path


FRAME_WIDTH = 512
FRAME_HEIGHT = 512
SOURCE_COLUMNS = 3
SOURCE_ROWS = 2
FRAME_LAYOUT = (
    ("idle", 0, 0, (275, 491)),
    ("idle", 1, 0, (238, 491)),
    ("walk", 2, 0, (224, 486)),
    ("walk", 0, 1, (276, 470)),
    ("walk", 1, 1, (252, 471)),
    ("walk", 2, 1, (224, 471)),
)
FRAME_COUNT = len(FRAME_LAYOUT)
TARGET_FEET_ANCHOR = (256, 488)
EDGE_ALPHA_CUTOFF = 32
SOLID_COLOR_ALPHA = 224
COLOR_REPAIR_RADIUS = 3
MIN_ALPHA_COMPONENT_PIXELS = 32
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


def _frame_pixel_index(x: int, y: int) -> int:
    return (y * FRAME_WIDTH + x) * 4


def _extract_source_frame(
    source_width: int,
    source_pixels: bytearray,
    source_column: int,
    source_row: int,
) -> bytearray:
    frame_pixels = bytearray(FRAME_WIDTH * FRAME_HEIGHT * 4)
    source_row_size = source_width * 4
    frame_row_size = FRAME_WIDTH * 4
    for frame_y in range(FRAME_HEIGHT):
        source_start = (
            (source_row * FRAME_HEIGHT + frame_y) * source_row_size
            + source_column * frame_row_size
        )
        frame_start = frame_y * frame_row_size
        frame_pixels[frame_start : frame_start + frame_row_size] = source_pixels[
            source_start : source_start + frame_row_size
        ]
    return frame_pixels


def _remove_small_alpha_components(frame_pixels: bytearray) -> None:
    visible_pixels = {
        (x, y)
        for y in range(FRAME_HEIGHT)
        for x in range(FRAME_WIDTH)
        if frame_pixels[_frame_pixel_index(x, y) + 3] > 0
    }

    while visible_pixels:
        seed = visible_pixels.pop()
        component = [seed]
        cursor = 0
        while cursor < len(component):
            x, y = component[cursor]
            cursor += 1
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in visible_pixels:
                    visible_pixels.remove(neighbor)
                    component.append(neighbor)

        if len(component) >= MIN_ALPHA_COMPONENT_PIXELS:
            continue
        for x, y in component:
            pixel_index = _frame_pixel_index(x, y)
            frame_pixels[pixel_index : pixel_index + 4] = b"\x00\x00\x00\x00"


def _repair_semitransparent_colors(frame_pixels: bytearray) -> None:
    source_pixels = bytearray(frame_pixels)
    for y in range(FRAME_HEIGHT):
        for x in range(FRAME_WIDTH):
            pixel_index = _frame_pixel_index(x, y)
            alpha = source_pixels[pixel_index + 3]
            if alpha == 0 or alpha == 255:
                continue

            best_color: tuple[int, int, int] | None = None
            best_score: tuple[int, int] | None = None
            for sample_y in range(
                max(0, y - COLOR_REPAIR_RADIUS),
                min(FRAME_HEIGHT, y + COLOR_REPAIR_RADIUS + 1),
            ):
                for sample_x in range(
                    max(0, x - COLOR_REPAIR_RADIUS),
                    min(FRAME_WIDTH, x + COLOR_REPAIR_RADIUS + 1),
                ):
                    sample_index = _frame_pixel_index(sample_x, sample_y)
                    sample_alpha = source_pixels[sample_index + 3]
                    if sample_alpha < SOLID_COLOR_ALPHA:
                        continue
                    distance = abs(sample_x - x) + abs(sample_y - y)
                    score = (distance, -sample_alpha)
                    if best_score is None or score < best_score:
                        best_score = score
                        best_color = tuple(source_pixels[sample_index : sample_index + 3])

            if best_color is not None:
                frame_pixels[pixel_index : pixel_index + 3] = bytes(best_color)
            elif alpha < SOLID_COLOR_ALPHA:
                frame_pixels[pixel_index : pixel_index + 4] = b"\x00\x00\x00\x00"


def _clean_frame_transparency(frame_pixels: bytearray) -> bytearray:
    cleaned_pixels = bytearray(frame_pixels)
    for pixel_index in range(0, len(cleaned_pixels), 4):
        if cleaned_pixels[pixel_index + 3] < EDGE_ALPHA_CUTOFF:
            cleaned_pixels[pixel_index : pixel_index + 4] = b"\x00\x00\x00\x00"

    _remove_small_alpha_components(cleaned_pixels)
    _repair_semitransparent_colors(cleaned_pixels)
    return cleaned_pixels


def _align_frame(
    frame_pixels: bytearray,
    source_feet_anchor: tuple[int, int],
) -> bytearray:
    aligned_pixels = bytearray(FRAME_WIDTH * FRAME_HEIGHT * 4)
    offset_x = TARGET_FEET_ANCHOR[0] - source_feet_anchor[0]
    offset_y = TARGET_FEET_ANCHOR[1] - source_feet_anchor[1]

    for source_y in range(FRAME_HEIGHT):
        target_y = source_y + offset_y
        if target_y < 0 or target_y >= FRAME_HEIGHT:
            continue
        for source_x in range(FRAME_WIDTH):
            target_x = source_x + offset_x
            if target_x < 0 or target_x >= FRAME_WIDTH:
                continue
            source_index = _frame_pixel_index(source_x, source_y)
            target_index = _frame_pixel_index(target_x, target_y)
            aligned_pixels[target_index : target_index + 4] = frame_pixels[
                source_index : source_index + 4
            ]

    return aligned_pixels


def main() -> None:
    source_width, source_height, source_pixels = _read_rgba_png(SOURCE_PATH)
    expected_width = FRAME_WIDTH * SOURCE_COLUMNS
    expected_height = FRAME_HEIGHT * SOURCE_ROWS
    if (source_width, source_height) != (expected_width, expected_height):
        raise ValueError(
            f"{SOURCE_PATH} must be {expected_width}x{expected_height}, "
            f"got {source_width}x{source_height}"
        )

    output_width = FRAME_WIDTH * FRAME_COUNT
    output_pixels = bytearray(output_width * FRAME_HEIGHT * 4)
    output_row_size = output_width * 4
    frame_row_size = FRAME_WIDTH * 4

    for frame_index, (_, source_column, source_row, source_anchor) in enumerate(FRAME_LAYOUT):
        source_frame = _extract_source_frame(
            source_width,
            source_pixels,
            source_column,
            source_row,
        )
        cleaned_frame = _clean_frame_transparency(source_frame)
        aligned_frame = _align_frame(cleaned_frame, source_anchor)
        for frame_y in range(FRAME_HEIGHT):
            frame_start = frame_y * frame_row_size
            output_start = frame_y * output_row_size + frame_index * frame_row_size
            output_pixels[output_start : output_start + frame_row_size] = aligned_frame[
                frame_start : frame_start + frame_row_size
            ]

    _write_rgba_png(OUTPUT_PATH, output_width, FRAME_HEIGHT, output_pixels)
    print(
        f"generated {OUTPUT_PATH} "
        f"({output_width}x{FRAME_HEIGHT}, frames: idle=0-1 walk=2-5, "
        f"feet anchor={TARGET_FEET_ANCHOR})"
    )


if __name__ == "__main__":
    main()

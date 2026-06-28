"""Clean, align, and assemble the demo-local player animation atlas.

Source layout: three columns by two rows of 512x512 RGBA frames.
Reading order: idle 0, idle 1, then four walk key poses.
Output layout: one horizontal row with two idle frames and an eight-frame
stylized robe walk. The walk reuses one silhouette and applies small,
parameterized torso, robe, sleeve, talisman, foot-tip, and shadow motion.

The source artwork was generated for this demo, then locally chroma-keyed.
Every output frame is placed on the same 512x512 transparent canvas with its
feet center aligned to TARGET_FEET_ANCHOR. The cleanup removes low-alpha matte
residue and tiny disconnected cutout specks before atlas assembly.

This script is deterministic and uses only the Python standard library.
"""

from __future__ import annotations

import json
import math
import struct
import zlib
from collections import deque
from pathlib import Path


FRAME_WIDTH = 512
FRAME_HEIGHT = 512
SOURCE_COLUMNS = 3
SOURCE_ROWS = 2
SOURCE_FRAME_LAYOUT = (
    ("idle", 0, 0, (275, 491)),
    ("idle", 1, 0, (238, 491)),
    ("walk", 2, 0, (224, 486)),
    ("walk", 0, 1, (276, 470)),
    ("walk", 1, 1, (252, 471)),
    ("walk", 2, 1, (224, 471)),
)
IDLE_SOURCE_INDICES = (0, 1)
WALK_FRAME_PARAMETERS = (
    {
        "phase": "neutral",
        "torso_x": 0,
        "torso_y": 0,
        "torso_tilt": 0,
        "robe_sway": 0,
        "sleeve_sway": 0,
        "talisman_x": 0,
        "talisman_y": 0,
        "foot_tip_shift": 0,
        "shadow_offset": 0,
        "shadow_scale": 1.0,
    },
    {
        "phase": "slight_down",
        "torso_x": 1,
        "torso_y": 1,
        "torso_tilt": 1,
        "robe_sway": 3,
        "sleeve_sway": 2,
        "talisman_x": 1,
        "talisman_y": 1,
        "foot_tip_shift": 1,
        "shadow_offset": 1,
        "shadow_scale": 0.96,
    },
    {
        "phase": "passing",
        "torso_x": 1,
        "torso_y": 2,
        "torso_tilt": 1,
        "robe_sway": 6,
        "sleeve_sway": 4,
        "talisman_x": 2,
        "talisman_y": 2,
        "foot_tip_shift": 2,
        "shadow_offset": 2,
        "shadow_scale": 0.92,
    },
    {
        "phase": "slight_up",
        "torso_x": 0,
        "torso_y": 1,
        "torso_tilt": 1,
        "robe_sway": 3,
        "sleeve_sway": 2,
        "talisman_x": 1,
        "talisman_y": 1,
        "foot_tip_shift": 1,
        "shadow_offset": 1,
        "shadow_scale": 0.96,
    },
    {
        "phase": "neutral_opposite",
        "torso_x": 0,
        "torso_y": 0,
        "torso_tilt": 0,
        "robe_sway": 0,
        "sleeve_sway": 0,
        "talisman_x": 0,
        "talisman_y": 0,
        "foot_tip_shift": 0,
        "shadow_offset": 0,
        "shadow_scale": 1.0,
    },
    {
        "phase": "slight_down_opposite",
        "torso_x": -1,
        "torso_y": -1,
        "torso_tilt": -1,
        "robe_sway": -3,
        "sleeve_sway": -2,
        "talisman_x": -1,
        "talisman_y": -1,
        "foot_tip_shift": -1,
        "shadow_offset": -1,
        "shadow_scale": 0.96,
    },
    {
        "phase": "passing_opposite",
        "torso_x": -1,
        "torso_y": -2,
        "torso_tilt": -1,
        "robe_sway": -6,
        "sleeve_sway": -4,
        "talisman_x": -2,
        "talisman_y": -2,
        "foot_tip_shift": -2,
        "shadow_offset": -2,
        "shadow_scale": 0.92,
    },
    {
        "phase": "slight_up_opposite",
        "torso_x": 0,
        "torso_y": -1,
        "torso_tilt": -1,
        "robe_sway": -3,
        "sleeve_sway": -2,
        "talisman_x": -1,
        "talisman_y": -1,
        "foot_tip_shift": -1,
        "shadow_offset": -1,
        "shadow_scale": 0.96,
    },
)
SOURCE_FRAME_COUNT = len(SOURCE_FRAME_LAYOUT)
WALK_FRAME_COUNT = len(WALK_FRAME_PARAMETERS)
OUTPUT_FRAME_COUNT = len(IDLE_SOURCE_INDICES) + WALK_FRAME_COUNT
WALK_FPS = 8.0
TARGET_FEET_ANCHOR = (256, 488)
EDGE_ALPHA_CUTOFF = 32
SOLID_COLOR_ALPHA = 224
COLOR_REPAIR_RADIUS = 3
MIN_ALPHA_COMPONENT_PIXELS = 32
CANONICAL_WALK_BODY_SOURCE_INDEX = 2
TILT_PIVOT_Y = 170
ROBE_MASK_START_Y = 350
ROBE_TOP_Y = 292
ROBE_BOTTOM_Y = 474
ROBE_TOP_HALF_WIDTH = 70
ROBE_BOTTOM_HALF_WIDTH = 170
ROBE_EDGE_FEATHER = 6
ROBE_TEXTURE_BOUNDS = (170, 250, 380, 410)
STAFF_PRESERVE_BOUNDS = (100, 300, 128, TARGET_FEET_ANCHOR[1] + 1)
LEG_MASK_BOUNDS = (55, ROBE_MASK_START_Y, 410, TARGET_FEET_ANCHOR[1] + 1)
TALISMAN_CENTER = (256, 270)
BODY_CENTER_REGION = (180, 80, 340, 330)
MAX_BODY_CENTER_SPREAD = (8.0, 8.0)
MAX_BOUNDING_BOX_HEIGHT_SPREAD = 16
MAX_NORMALIZED_ALPHA_FRAME_DELTA = 0.08
ROOT = Path(__file__).resolve().parents[1]
ASSET_DIRECTORY = ROOT / "game" / "assets" / "demo" / "placeholder_sprites"
SOURCE_PATH = ASSET_DIRECTORY / "demo_player_idle_walk_source_3x2.png"
OUTPUT_PATH = ASSET_DIRECTORY / "demo_player_idle_walk.png"
METADATA_PATH = ASSET_DIRECTORY / "demo_player_walk_metadata.json"


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


def _normalize_blended_transparency(frame_pixels: bytearray) -> bytearray:
    normalized_pixels = bytearray(frame_pixels)
    for pixel_index in range(0, len(normalized_pixels), 4):
        if normalized_pixels[pixel_index + 3] < EDGE_ALPHA_CUTOFF:
            normalized_pixels[pixel_index : pixel_index + 4] = b"\x00\x00\x00\x00"
    _remove_small_alpha_components(normalized_pixels)
    return normalized_pixels


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


def _composite_rgba_pixel(
    target_pixels: bytearray,
    pixel_index: int,
    source_color: tuple[int, int, int],
    source_alpha: int,
) -> None:
    if source_alpha <= 0:
        return
    destination_alpha = target_pixels[pixel_index + 3]
    inverse_source_alpha = 255 - source_alpha
    output_alpha = source_alpha + round(destination_alpha * inverse_source_alpha / 255)
    if output_alpha <= 0:
        return

    for channel in range(3):
        premultiplied_channel = (
            source_color[channel] * source_alpha
            + target_pixels[pixel_index + channel]
            * destination_alpha
            * inverse_source_alpha
            / 255
        )
        target_pixels[pixel_index + channel] = min(
            255,
            round(premultiplied_channel / output_alpha),
        )
    target_pixels[pixel_index + 3] = output_alpha


def _composite_frame(target_pixels: bytearray, source_pixels: bytearray) -> None:
    for pixel_index in range(0, len(target_pixels), 4):
        source_alpha = source_pixels[pixel_index + 3]
        if source_alpha == 0:
            continue
        _composite_rgba_pixel(
            target_pixels,
            pixel_index,
            tuple(source_pixels[pixel_index : pixel_index + 3]),
            source_alpha,
        )


def _draw_ellipse(
    frame_pixels: bytearray,
    center_x: int,
    center_y: int,
    radius_x: int,
    radius_y: int,
    color: tuple[int, int, int],
    alpha: int,
) -> None:
    for y in range(max(0, center_y - radius_y), min(FRAME_HEIGHT, center_y + radius_y + 1)):
        normalized_y = (y - center_y) / radius_y
        for x in range(max(0, center_x - radius_x), min(FRAME_WIDTH, center_x + radius_x + 1)):
            normalized_x = (x - center_x) / radius_x
            distance_squared = normalized_x * normalized_x + normalized_y * normalized_y
            if distance_squared > 1.0:
                continue
            edge_fade = min(1.0, max(0.0, (1.0 - distance_squared) * 3.0))
            _composite_rgba_pixel(
                frame_pixels,
                _frame_pixel_index(x, y),
                color,
                round(alpha * edge_fade),
            )


def _transform_subject(
    canonical_frame: bytearray,
    parameters: dict[str, object],
) -> bytearray:
    transformed_pixels = bytearray(len(canonical_frame))
    torso_x = int(parameters["torso_x"])
    torso_y = int(parameters["torso_y"])
    torso_tilt = int(parameters["torso_tilt"])
    sleeve_sway = int(parameters["sleeve_sway"])

    for target_y in range(FRAME_HEIGHT):
        source_y = target_y - torso_y
        if source_y < 0 or source_y >= FRAME_HEIGHT:
            continue
        tilt_progress = (target_y - TILT_PIVOT_Y) / (ROBE_MASK_START_Y - TILT_PIVOT_Y)
        tilt_offset = round(torso_tilt * max(-1.0, min(1.0, tilt_progress)))
        for target_x in range(FRAME_WIDTH):
            sleeve_offset = 0
            if 300 <= target_x <= 470 and 170 <= target_y <= ROBE_MASK_START_Y:
                sleeve_progress = (target_x - 300) / 170
                sleeve_offset = round(sleeve_sway * sleeve_progress)
            source_x = target_x - torso_x - tilt_offset - sleeve_offset
            if source_x < 0 or source_x >= FRAME_WIDTH:
                continue
            source_index = _frame_pixel_index(source_x, source_y)
            target_index = _frame_pixel_index(target_x, target_y)
            transformed_pixels[target_index : target_index + 4] = canonical_frame[
                source_index : source_index + 4
            ]
    return transformed_pixels


def _clear_rectangle(
    frame_pixels: bytearray,
    bounds: tuple[int, int, int, int],
) -> None:
    left, top, right, bottom = bounds
    for y in range(top, bottom):
        row_start = _frame_pixel_index(left, y)
        row_end = _frame_pixel_index(right, y)
        frame_pixels[row_start:row_end] = b"\x00" * (row_end - row_start)


def _copy_region_over(
    target_pixels: bytearray,
    source_pixels: bytearray,
    bounds: tuple[int, int, int, int],
) -> None:
    left, top, right, bottom = bounds
    for y in range(top, bottom):
        for x in range(left, right):
            pixel_index = _frame_pixel_index(x, y)
            source_alpha = source_pixels[pixel_index + 3]
            if source_alpha == 0:
                continue
            _composite_rgba_pixel(
                target_pixels,
                pixel_index,
                tuple(source_pixels[pixel_index : pixel_index + 3]),
                source_alpha,
            )


def _is_robe_texture_pixel(red: int, green: int, blue: int, alpha: int) -> bool:
    if alpha < 128:
        return False
    if red > green * 1.25 and red > 48:
        return False
    if green > 150 and blue > 150:
        return False
    return green >= red * 0.72 and blue >= red * 0.72


def _build_robe_texture(
    canonical_frame: bytearray,
) -> tuple[int, int, list[tuple[int, int, int]]]:
    left, top, right, bottom = ROBE_TEXTURE_BOUNDS
    texture_width = right - left
    texture_height = bottom - top
    texture: list[tuple[int, int, int] | None] = [None] * (texture_width * texture_height)
    pending: deque[tuple[int, int]] = deque()

    for texture_y in range(texture_height):
        for texture_x in range(texture_width):
            source_index = _frame_pixel_index(left + texture_x, top + texture_y)
            red, green, blue, alpha = canonical_frame[source_index : source_index + 4]
            if not _is_robe_texture_pixel(red, green, blue, alpha):
                continue
            texture[texture_y * texture_width + texture_x] = (red, green, blue)
            pending.append((texture_x, texture_y))

    if not pending:
        raise ValueError("canonical walk frame must contain robe texture pixels")

    while pending:
        texture_x, texture_y = pending.popleft()
        color = texture[texture_y * texture_width + texture_x]
        for neighbor_x, neighbor_y in (
            (texture_x - 1, texture_y),
            (texture_x + 1, texture_y),
            (texture_x, texture_y - 1),
            (texture_x, texture_y + 1),
        ):
            if (
                neighbor_x < 0
                or neighbor_x >= texture_width
                or neighbor_y < 0
                or neighbor_y >= texture_height
            ):
                continue
            neighbor_index = neighbor_y * texture_width + neighbor_x
            if texture[neighbor_index] is not None:
                continue
            texture[neighbor_index] = color
            pending.append((neighbor_x, neighbor_y))

    return texture_width, texture_height, [
        color if color is not None else (25, 61, 63) for color in texture
    ]


def _draw_robe(
    frame_pixels: bytearray,
    robe_texture: tuple[int, int, list[tuple[int, int, int]]],
    parameters: dict[str, object],
    frame_index: int,
) -> None:
    texture_width, texture_height, texture_colors = robe_texture
    torso_x = int(parameters["torso_x"])
    robe_sway = int(parameters["robe_sway"])
    phase_angle = frame_index * math.tau / WALK_FRAME_COUNT

    for y in range(ROBE_TOP_Y, ROBE_BOTTOM_Y + 5):
        vertical_progress = (y - ROBE_TOP_Y) / (ROBE_BOTTOM_Y - ROBE_TOP_Y)
        vertical_progress = max(0.0, min(1.0, vertical_progress))
        center_x = round(
            TARGET_FEET_ANCHOR[0]
            + torso_x * (1.0 - vertical_progress)
            + robe_sway * vertical_progress
        )
        half_width = round(
            ROBE_TOP_HALF_WIDTH
            + (ROBE_BOTTOM_HALF_WIDTH - ROBE_TOP_HALF_WIDTH) * vertical_progress
        )
        texture_y = min(texture_height - 1, round(vertical_progress * (texture_height - 1)))

        for x in range(max(0, center_x - half_width), min(FRAME_WIDTH, center_x + half_width + 1)):
            horizontal_progress = (x - (center_x - half_width)) / max(1, half_width * 2)
            hem_wave = round(2.0 * math.sin((x - center_x) / 24.0 + phase_angle))
            if y > ROBE_BOTTOM_Y + hem_wave:
                continue
            edge_distance = half_width - abs(x - center_x)
            edge_alpha = min(1.0, edge_distance / ROBE_EDGE_FEATHER)
            top_alpha = min(1.0, max(0.0, (y - ROBE_TOP_Y + 1) / 12.0))
            source_alpha = round(245 * edge_alpha * top_alpha)
            if source_alpha < EDGE_ALPHA_CUTOFF:
                continue

            texture_x = min(
                texture_width - 1,
                max(0, round(horizontal_progress * (texture_width - 1))),
            )
            red, green, blue = texture_colors[texture_y * texture_width + texture_x]
            fabric_light = 0.96 + 0.04 * math.sin(horizontal_progress * math.tau + phase_angle)
            color = (
                min(255, round(red * fabric_light)),
                min(255, round(green * fabric_light)),
                min(255, round(blue * fabric_light)),
            )
            _composite_rgba_pixel(
                frame_pixels,
                _frame_pixel_index(x, y),
                color,
                source_alpha,
            )


def _render_robe_walk_frame(
    canonical_frame: bytearray,
    robe_texture: tuple[int, int, list[tuple[int, int, int]]],
    parameters: dict[str, object],
    frame_index: int,
) -> bytearray:
    frame_pixels = bytearray(FRAME_WIDTH * FRAME_HEIGHT * 4)
    shadow_scale = float(parameters["shadow_scale"])
    shadow_offset = int(parameters["shadow_offset"])
    foot_tip_shift = int(parameters["foot_tip_shift"])

    _draw_ellipse(
        frame_pixels,
        TARGET_FEET_ANCHOR[0] + shadow_offset,
        TARGET_FEET_ANCHOR[1] - 9,
        round(76 * shadow_scale),
        round(9 * shadow_scale),
        (8, 23, 25),
        76,
    )
    _draw_ellipse(
        frame_pixels,
        236 + foot_tip_shift,
        TARGET_FEET_ANCHOR[1] - 7,
        18,
        8,
        (24, 31, 32),
        230,
    )
    _draw_ellipse(
        frame_pixels,
        278 - foot_tip_shift,
        TARGET_FEET_ANCHOR[1] - 7,
        16,
        8,
        (23, 30, 31),
        220,
    )

    transformed_subject = _transform_subject(canonical_frame, parameters)
    leg_masked_subject = bytearray(transformed_subject)
    _clear_rectangle(leg_masked_subject, LEG_MASK_BOUNDS)
    _composite_frame(frame_pixels, leg_masked_subject)
    _draw_robe(frame_pixels, robe_texture, parameters, frame_index)
    _copy_region_over(
        frame_pixels,
        transformed_subject,
        STAFF_PRESERVE_BOUNDS,
    )

    _draw_ellipse(
        frame_pixels,
        TALISMAN_CENTER[0] + int(parameters["torso_x"]) + int(parameters["talisman_x"]),
        TALISMAN_CENTER[1] + int(parameters["torso_y"]) + int(parameters["talisman_y"]),
        7,
        10,
        (76, 225, 221),
        46,
    )
    _clear_rectangle(
        frame_pixels,
        (0, TARGET_FEET_ANCHOR[1] + 1, FRAME_WIDTH, FRAME_HEIGHT),
    )
    return _normalize_blended_transparency(frame_pixels)


def _build_walk_cycle(aligned_source_frames: list[bytearray]) -> list[bytearray]:
    canonical_frame = aligned_source_frames[CANONICAL_WALK_BODY_SOURCE_INDEX]
    robe_texture = _build_robe_texture(canonical_frame)
    return [
        _render_robe_walk_frame(
            canonical_frame,
            robe_texture,
            parameters,
            frame_index,
        )
        for frame_index, parameters in enumerate(WALK_FRAME_PARAMETERS)
    ]


def _visible_bounds(frame_pixels: bytearray) -> tuple[int, int, int, int]:
    visible_points = []
    for y in range(FRAME_HEIGHT):
        for x in range(FRAME_WIDTH):
            if frame_pixels[_frame_pixel_index(x, y) + 3] > 0:
                visible_points.append((x, y))
    if not visible_points:
        raise ValueError("walk frame must contain visible pixels")
    x_values = [point[0] for point in visible_points]
    y_values = [point[1] for point in visible_points]
    return min(x_values), min(y_values), max(x_values) + 1, max(y_values) + 1


def _body_center(frame_pixels: bytearray) -> tuple[float, float]:
    left, top, right, bottom = BODY_CENTER_REGION
    weighted_x = 0
    weighted_y = 0
    total_alpha = 0
    for y in range(top, bottom):
        for x in range(left, right):
            alpha = frame_pixels[_frame_pixel_index(x, y) + 3]
            weighted_x += x * alpha
            weighted_y += y * alpha
            total_alpha += alpha
    if total_alpha == 0:
        raise ValueError("walk frame body center region must contain visible pixels")
    return weighted_x / total_alpha, weighted_y / total_alpha


def _normalized_alpha_difference(first_frame: bytearray, second_frame: bytearray) -> float:
    alpha_difference = sum(
        abs(first_frame[pixel_index + 3] - second_frame[pixel_index + 3])
        for pixel_index in range(0, len(first_frame), 4)
    )
    return alpha_difference / (FRAME_WIDTH * FRAME_HEIGHT * 255)


def _cyclic_parameter_delta(frame_index: int, parameter_name: str) -> float:
    current_value = float(WALK_FRAME_PARAMETERS[frame_index][parameter_name])
    next_value = float(
        WALK_FRAME_PARAMETERS[(frame_index + 1) % WALK_FRAME_COUNT][parameter_name]
    )
    return abs(current_value - next_value)


def _validate_walk_parameters() -> None:
    if len(WALK_FRAME_PARAMETERS) != 8:
        raise ValueError("stylized robe walk must contain exactly eight parameter frames")

    if max(abs(int(frame["torso_x"])) for frame in WALK_FRAME_PARAMETERS) > 2:
        raise ValueError("walk torso_x must stay within two pixels")
    if max(abs(int(frame["torso_y"])) for frame in WALK_FRAME_PARAMETERS) > 5:
        raise ValueError("walk torso_y must stay within five pixels")
    if not any(int(frame["torso_y"]) != 0 for frame in WALK_FRAME_PARAMETERS):
        raise ValueError("walk torso must include non-zero vertical motion")
    if not any(int(frame["robe_sway"]) != 0 for frame in WALK_FRAME_PARAMETERS):
        raise ValueError("walk robe must include cyclic sway")
    if not any(int(frame["sleeve_sway"]) != 0 for frame in WALK_FRAME_PARAMETERS):
        raise ValueError("walk sleeve must include follow-through")
    if not any(
        int(frame["talisman_x"]) != 0 or int(frame["talisman_y"]) != 0
        for frame in WALK_FRAME_PARAMETERS
    ):
        raise ValueError("walk talisman must include cyclic motion")

    continuity_limits = {
        "torso_x": 1.0,
        "torso_y": 1.0,
        "torso_tilt": 1.0,
        "robe_sway": 3.0,
        "sleeve_sway": 2.0,
        "talisman_x": 1.0,
        "talisman_y": 1.0,
        "foot_tip_shift": 1.0,
        "shadow_offset": 1.0,
        "shadow_scale": 0.05,
    }
    for frame_index in range(WALK_FRAME_COUNT):
        for parameter_name, maximum_delta in continuity_limits.items():
            if _cyclic_parameter_delta(frame_index, parameter_name) > maximum_delta:
                raise ValueError(
                    f"walk parameter {parameter_name} changes too abruptly "
                    f"after frame {frame_index}"
                )


def _validate_walk_cycle(walk_cycle: list[bytearray]) -> None:
    _validate_walk_parameters()
    if len(walk_cycle) != WALK_FRAME_COUNT:
        raise ValueError(f"walk cycle must contain {WALK_FRAME_COUNT} frames")

    bounds = [_visible_bounds(frame) for frame in walk_cycle]
    body_centers = [_body_center(frame) for frame in walk_cycle]
    for frame_index, frame_bounds in enumerate(bounds):
        if frame_bounds[3] != TARGET_FEET_ANCHOR[1] + 1:
            raise ValueError(
                f"walk frame {frame_index} feet baseline must be "
                f"{TARGET_FEET_ANCHOR[1]}"
            )

    center_x_values = [center[0] for center in body_centers]
    center_y_values = [center[1] for center in body_centers]
    if max(center_x_values) - min(center_x_values) > MAX_BODY_CENTER_SPREAD[0]:
        raise ValueError("walk body center moves too far horizontally")
    if max(center_y_values) - min(center_y_values) > MAX_BODY_CENTER_SPREAD[1]:
        raise ValueError("walk body center moves too far vertically")

    frame_heights = [frame_bounds[3] - frame_bounds[1] for frame_bounds in bounds]
    if max(frame_heights) - min(frame_heights) > MAX_BOUNDING_BOX_HEIGHT_SPREAD:
        raise ValueError("walk frame bounding box height changes too much")

    frame_deltas = [
        _normalized_alpha_difference(
            walk_cycle[frame_index],
            walk_cycle[(frame_index + 1) % WALK_FRAME_COUNT],
        )
        for frame_index in range(WALK_FRAME_COUNT)
    ]
    if max(frame_deltas) > MAX_NORMALIZED_ALPHA_FRAME_DELTA:
        raise ValueError("walk cycle contains an abrupt silhouette transition")

    for frame_index, parameters in enumerate(WALK_FRAME_PARAMETERS):
        center_x, center_y = body_centers[frame_index]
        print(
            f"walk[{frame_index}] {parameters['phase']}: bounds={bounds[frame_index]}, "
            f"body_center=({center_x:.1f}, {center_y:.1f}), "
            f"next_alpha_delta={frame_deltas[frame_index]:.4f}"
        )


def _write_walk_metadata() -> None:
    metadata = {
        "design": "stylized_robe_walk",
        "robe_dominant": True,
        "leg_style": "robe_hidden_with_subtle_foot_tips",
        "frame_width": FRAME_WIDTH,
        "frame_height": FRAME_HEIGHT,
        "walk_frame_count": WALK_FRAME_COUNT,
        "walk_fps": WALK_FPS,
        "moving_elements": ["torso", "robe", "sleeve", "talisman", "shadow"],
        "frames": [
            {
                **parameters,
                "feet_anchor": list(TARGET_FEET_ANCHOR),
            }
            for parameters in WALK_FRAME_PARAMETERS
        ],
    }
    METADATA_PATH.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    source_width, source_height, source_pixels = _read_rgba_png(SOURCE_PATH)
    expected_width = FRAME_WIDTH * SOURCE_COLUMNS
    expected_height = FRAME_HEIGHT * SOURCE_ROWS
    if (source_width, source_height) != (expected_width, expected_height):
        raise ValueError(
            f"{SOURCE_PATH} must be {expected_width}x{expected_height}, "
            f"got {source_width}x{source_height}"
        )

    aligned_source_frames = []
    for _, source_column, source_row, source_anchor in SOURCE_FRAME_LAYOUT:
        source_frame = _extract_source_frame(
            source_width,
            source_pixels,
            source_column,
            source_row,
        )
        cleaned_frame = _clean_frame_transparency(source_frame)
        aligned_source_frames.append(_align_frame(cleaned_frame, source_anchor))
    if len(aligned_source_frames) != SOURCE_FRAME_COUNT:
        raise ValueError("source frame layout did not produce the expected frame count")

    walk_cycle = _build_walk_cycle(aligned_source_frames)
    _validate_walk_cycle(walk_cycle)
    output_frames = [
        aligned_source_frames[source_index] for source_index in IDLE_SOURCE_INDICES
    ] + walk_cycle

    output_width = FRAME_WIDTH * OUTPUT_FRAME_COUNT
    output_pixels = bytearray(output_width * FRAME_HEIGHT * 4)
    output_row_size = output_width * 4
    frame_row_size = FRAME_WIDTH * 4

    for frame_index, output_frame in enumerate(output_frames):
        for frame_y in range(FRAME_HEIGHT):
            frame_start = frame_y * frame_row_size
            output_start = frame_y * output_row_size + frame_index * frame_row_size
            output_pixels[output_start : output_start + frame_row_size] = output_frame[
                frame_start : frame_start + frame_row_size
            ]

    _write_rgba_png(OUTPUT_PATH, output_width, FRAME_HEIGHT, output_pixels)
    _write_walk_metadata()
    print(
        f"generated {OUTPUT_PATH} "
        f"({output_width}x{FRAME_HEIGHT}, frames: idle=0-1 walk=2-9, "
        f"feet anchor={TARGET_FEET_ANCHOR})"
    )
    print(f"generated {METADATA_PATH} (stylized robe walk metadata)")


if __name__ == "__main__":
    main()

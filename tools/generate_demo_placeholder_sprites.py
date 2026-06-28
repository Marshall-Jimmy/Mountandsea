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
SHENSHENG_OUTPUT_PATH = ASSET_DIRECTORY / "demo_shensheng_idle.png"
SHENSHENG_METADATA_PATH = ASSET_DIRECTORY / "demo_shensheng_idle_metadata.json"
SHENSHENG_FRAME_PARAMETERS = (
    {
        "phase": "neutral",
        "body_y": 0,
        "shoulder_y": 0,
        "left_ear_offset": 0,
        "right_ear_offset": 0,
        "arm_sway": 0,
        "glow_alpha": 150,
        "shadow_scale": 1.0,
    },
    {
        "phase": "inhale",
        "body_y": 1,
        "shoulder_y": -1,
        "left_ear_offset": 1,
        "right_ear_offset": 0,
        "arm_sway": 1,
        "glow_alpha": 180,
        "shadow_scale": 0.98,
    },
    {
        "phase": "breath_peak",
        "body_y": 2,
        "shoulder_y": -2,
        "left_ear_offset": 2,
        "right_ear_offset": -1,
        "arm_sway": 2,
        "glow_alpha": 220,
        "shadow_scale": 0.96,
    },
    {
        "phase": "exhale",
        "body_y": 1,
        "shoulder_y": -1,
        "left_ear_offset": 1,
        "right_ear_offset": 0,
        "arm_sway": 1,
        "glow_alpha": 185,
        "shadow_scale": 0.98,
    },
    {
        "phase": "settle",
        "body_y": 0,
        "shoulder_y": 0,
        "left_ear_offset": 0,
        "right_ear_offset": 1,
        "arm_sway": 0,
        "glow_alpha": 155,
        "shadow_scale": 1.0,
    },
    {
        "phase": "ear_follow_through",
        "body_y": -1,
        "shoulder_y": 1,
        "left_ear_offset": -1,
        "right_ear_offset": 1,
        "arm_sway": -1,
        "glow_alpha": 135,
        "shadow_scale": 1.02,
    },
)
SHENSHENG_FRAME_COUNT = len(SHENSHENG_FRAME_PARAMETERS)
SHENSHENG_IDLE_FPS = 4.0
SHENSHENG_ANCHOR = (256, 470)
SHENSHENG_MAX_NORMALIZED_ALPHA_FRAME_DELTA = 0.055


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


def _draw_rotated_ellipse(
    frame_pixels: bytearray,
    center_x: float,
    center_y: float,
    radius_x: float,
    radius_y: float,
    angle_radians: float,
    color: tuple[int, int, int],
    alpha: int,
) -> None:
    cosine = math.cos(angle_radians)
    sine = math.sin(angle_radians)
    half_width = abs(radius_x * cosine) + abs(radius_y * sine)
    half_height = abs(radius_x * sine) + abs(radius_y * cosine)
    left = max(0, math.floor(center_x - half_width - 1))
    right = min(FRAME_WIDTH, math.ceil(center_x + half_width + 1))
    top = max(0, math.floor(center_y - half_height - 1))
    bottom = min(FRAME_HEIGHT, math.ceil(center_y + half_height + 1))

    for y in range(top, bottom):
        for x in range(left, right):
            offset_x = x - center_x
            offset_y = y - center_y
            local_x = offset_x * cosine + offset_y * sine
            local_y = -offset_x * sine + offset_y * cosine
            distance_squared = (
                local_x * local_x / (radius_x * radius_x)
                + local_y * local_y / (radius_y * radius_y)
            )
            if distance_squared > 1.0:
                continue
            edge_fade = min(1.0, max(0.0, (1.0 - distance_squared) * 4.0))
            _composite_rgba_pixel(
                frame_pixels,
                _frame_pixel_index(x, y),
                color,
                round(alpha * edge_fade),
            )


def _draw_tapered_limb(
    frame_pixels: bytearray,
    start: tuple[float, float],
    end: tuple[float, float],
    start_radius: float,
    end_radius: float,
    color: tuple[int, int, int],
    alpha: int,
) -> None:
    distance = math.hypot(end[0] - start[0], end[1] - start[1])
    steps = max(2, math.ceil(distance / 4.0))
    for step in range(steps + 1):
        progress = step / steps
        center_x = start[0] + (end[0] - start[0]) * progress
        center_y = start[1] + (end[1] - start[1]) * progress
        radius = start_radius + (end_radius - start_radius) * progress
        _draw_ellipse(
            frame_pixels,
            round(center_x),
            round(center_y),
            max(1, round(radius)),
            max(1, round(radius * 0.9)),
            color,
            alpha,
        )


def _draw_shensheng_fur_strokes(
    frame_pixels: bytearray,
    body_y: int,
) -> None:
    stroke_color = (104, 120, 113)
    shadow_color = (20, 38, 40)
    for row in range(6):
        y = 260 + row * 30 + body_y
        half_width = 56 + row * 8
        for column in range(7):
            x = 256 - half_width + column * half_width / 3
            x += ((row + column) % 3 - 1) * 5
            angle = -0.52 + column * 0.17
            _draw_rotated_ellipse(
                frame_pixels,
                x,
                y,
                2.4,
                15.0,
                angle,
                stroke_color if (row + column) % 2 == 0 else shadow_color,
                92,
            )

    for side in (-1, 1):
        for stroke_index in range(5):
            x = 256 + side * (83 + stroke_index * 10)
            y = 298 + stroke_index * 28 + body_y
            _draw_rotated_ellipse(
                frame_pixels,
                x,
                y,
                2.5,
                11.0,
                side * 0.5,
                stroke_color,
                64,
            )


def _render_shensheng_idle_frame(parameters: dict[str, object]) -> bytearray:
    frame_pixels = bytearray(FRAME_WIDTH * FRAME_HEIGHT * 4)
    body_y = int(parameters["body_y"])
    shoulder_y = int(parameters["shoulder_y"])
    left_ear_offset = int(parameters["left_ear_offset"])
    right_ear_offset = int(parameters["right_ear_offset"])
    arm_sway = int(parameters["arm_sway"])
    glow_alpha = int(parameters["glow_alpha"])
    shadow_scale = float(parameters["shadow_scale"])

    outline = (15, 30, 32)
    deep_fur = (29, 48, 50)
    base_fur = (47, 69, 69)
    light_fur = (79, 96, 92)
    face_skin = (120, 113, 98)
    muzzle_skin = (91, 91, 82)
    ear_white = (218, 225, 213)
    ear_shadow = (145, 155, 149)
    cinnabar = (164, 57, 43)
    cyan = (72, 222, 216)

    _draw_ellipse(
        frame_pixels,
        SHENSHENG_ANCHOR[0],
        SHENSHENG_ANCHOR[1] - 9,
        round(111 * shadow_scale),
        round(12 * shadow_scale),
        (4, 17, 20),
        90,
    )

    # Semi-crouched haunches and planted feet keep the shared anchor stable.
    _draw_rotated_ellipse(frame_pixels, 197, 390, 65, 83, -0.48, outline, 250)
    _draw_rotated_ellipse(frame_pixels, 314, 394, 68, 84, 0.42, outline, 250)
    _draw_rotated_ellipse(frame_pixels, 199, 390, 52, 72, -0.48, base_fur, 248)
    _draw_rotated_ellipse(frame_pixels, 311, 392, 55, 73, 0.42, base_fur, 248)
    _draw_rotated_ellipse(frame_pixels, 205, 453, 47, 16, -0.12, outline, 250)
    _draw_rotated_ellipse(frame_pixels, 308, 453, 47, 16, 0.12, outline, 250)
    _draw_rotated_ellipse(frame_pixels, 207, 450, 37, 10, -0.12, light_fur, 220)
    _draw_rotated_ellipse(frame_pixels, 306, 450, 37, 10, 0.12, light_fur, 220)
    for foot_x, direction in ((205, -1), (308, 1)):
        for claw_index in range(3):
            _draw_rotated_ellipse(
                frame_pixels,
                foot_x + direction * (19 + claw_index * 7),
                457 + claw_index,
                8,
                3,
                direction * 0.1,
                (164, 171, 160),
                205,
            )

    # Forward shoulders and long arms distinguish the mythical ape silhouette.
    left_shoulder = (173, 270 + body_y + shoulder_y)
    right_shoulder = (333, 265 + body_y + shoulder_y)
    left_elbow = (129 - arm_sway, 350 + body_y)
    right_elbow = (384 + arm_sway, 347 + body_y)
    left_hand = (111 + arm_sway, 443)
    right_hand = (404 - arm_sway, 441)
    for start, elbow, hand in (
        (left_shoulder, left_elbow, left_hand),
        (right_shoulder, right_elbow, right_hand),
    ):
        _draw_tapered_limb(frame_pixels, start, elbow, 31, 22, outline, 252)
        _draw_tapered_limb(frame_pixels, elbow, hand, 23, 15, outline, 252)
        _draw_tapered_limb(frame_pixels, start, elbow, 23, 16, base_fur, 248)
        _draw_tapered_limb(frame_pixels, elbow, hand, 17, 10, deep_fur, 248)
        _draw_tapered_limb(
            frame_pixels,
            (start[0] - 4, start[1] - 3),
            (elbow[0] - 3, elbow[1] - 2),
            4,
            2,
            light_fur,
            90,
        )
    _draw_rotated_ellipse(frame_pixels, left_hand[0], left_hand[1], 23, 13, -0.14, outline, 252)
    _draw_rotated_ellipse(frame_pixels, right_hand[0], right_hand[1], 23, 13, 0.14, outline, 252)
    for side, hand_x in ((-1, left_hand[0]), (1, right_hand[0])):
        for finger in range(3):
            _draw_rotated_ellipse(
                frame_pixels,
                hand_x + side * (4 + finger * 5),
                448 + finger * 2,
                11,
                3,
                side * 0.15,
                (170, 178, 168),
                220,
            )

    # Broad hunched torso: dark teal-grey layered fur, not a flat cartoon fill.
    _draw_rotated_ellipse(frame_pixels, 258, 326 + body_y, 112, 139, -0.03, outline, 252)
    _draw_rotated_ellipse(frame_pixels, 258, 322 + body_y, 100, 127, -0.03, deep_fur, 252)
    _draw_rotated_ellipse(frame_pixels, 252, 314 + body_y, 76, 112, -0.08, base_fur, 225)
    _draw_rotated_ellipse(frame_pixels, 218, 286 + body_y, 47, 83, -0.31, light_fur, 66)
    _draw_rotated_ellipse(frame_pixels, 304, 282 + body_y, 56, 78, 0.31, (21, 39, 41), 115)
    _draw_shensheng_fur_strokes(frame_pixels, body_y)

    # Long white listening ears flank a forward, asymmetrical humanlike face.
    ear_y = 197 + body_y
    _draw_rotated_ellipse(
        frame_pixels, 169, ear_y + left_ear_offset, 27, 58, -0.62, outline, 252
    )
    _draw_rotated_ellipse(
        frame_pixels, 310, ear_y + right_ear_offset, 25, 56, 0.68, outline, 252
    )
    _draw_rotated_ellipse(
        frame_pixels, 170, ear_y + left_ear_offset, 20, 50, -0.62, ear_white, 250
    )
    _draw_rotated_ellipse(
        frame_pixels, 309, ear_y + right_ear_offset, 18, 48, 0.68, ear_white, 250
    )
    _draw_rotated_ellipse(
        frame_pixels, 175, ear_y + 4 + left_ear_offset, 8, 32, -0.62, ear_shadow, 210
    )
    _draw_rotated_ellipse(
        frame_pixels, 304, ear_y + 4 + right_ear_offset, 8, 31, 0.68, ear_shadow, 210
    )

    head_y = 205 + body_y + shoulder_y
    head_x = 239
    _draw_rotated_ellipse(frame_pixels, head_x, head_y, 64, 84, -0.12, outline, 252)
    _draw_rotated_ellipse(frame_pixels, head_x, head_y - 3, 56, 75, -0.12, deep_fur, 250)
    _draw_rotated_ellipse(frame_pixels, head_x - 3, head_y + 9, 40, 61, -0.07, face_skin, 250)
    _draw_rotated_ellipse(frame_pixels, head_x - 1, head_y + 40, 36, 25, -0.03, muzzle_skin, 248)
    _draw_rotated_ellipse(frame_pixels, head_x - 2, head_y + 30, 16, 11, 0.0, (45, 47, 44), 245)
    _draw_rotated_ellipse(frame_pixels, head_x - 2, head_y + 33, 8, 4, 0.0, (15, 24, 25), 250)
    _draw_rotated_ellipse(frame_pixels, head_x, head_y + 54, 17, 4, -0.03, (48, 38, 34), 235)
    _draw_rotated_ellipse(frame_pixels, head_x - 15, head_y + 57, 5, 9, -0.22, ear_white, 225)
    _draw_rotated_ellipse(frame_pixels, head_x + 15, head_y + 57, 5, 9, 0.22, ear_white, 225)

    for side in (-1, 1):
        for tuft_index in range(4):
            _draw_rotated_ellipse(
                frame_pixels,
                head_x + side * (45 + tuft_index * 4),
                head_y - 24 + tuft_index * 16,
                3,
                13,
                side * 0.58,
                light_fur,
                115,
            )

    # A strong brow and small cyan eyes keep the face humanoid rather than canine.
    _draw_rotated_ellipse(frame_pixels, head_x - 22, head_y + 2, 19, 5, -0.18, outline, 245)
    _draw_rotated_ellipse(frame_pixels, head_x + 21, head_y, 19, 5, 0.18, outline, 245)
    for eye_x, eye_y in ((head_x - 21, head_y + 10), (head_x + 20, head_y + 8)):
        _draw_ellipse(frame_pixels, eye_x, round(eye_y), 8, 5, (22, 37, 38), 250)
        _draw_ellipse(frame_pixels, eye_x, round(eye_y), 4, 2, cyan, min(255, glow_alpha + 25))
        _draw_ellipse(frame_pixels, eye_x - 1, round(eye_y), 1, 1, (209, 255, 247), 250)

    # Cinnabar ritual marks and a restrained cyan breath pulse are the main accents.
    _draw_tapered_limb(
        frame_pixels,
        (head_x, head_y - 35),
        (head_x, head_y - 9),
        5,
        3,
        cinnabar,
        235,
    )
    _draw_tapered_limb(
        frame_pixels,
        (head_x - 13, head_y - 22),
        (head_x, head_y - 9),
        3,
        3,
        cinnabar,
        220,
    )
    _draw_tapered_limb(
        frame_pixels,
        (head_x + 13, head_y - 22),
        (head_x, head_y - 9),
        3,
        3,
        cinnabar,
        220,
    )
    chest_y = 324 + body_y
    _draw_rotated_ellipse(frame_pixels, 254, chest_y, 35, 49, -0.02, (37, 57, 56), 170)
    _draw_tapered_limb(
        frame_pixels, (232, chest_y - 25), (254, chest_y + 12), 5, 4, cinnabar, 225
    )
    _draw_tapered_limb(
        frame_pixels, (276, chest_y - 25), (254, chest_y + 12), 5, 4, cinnabar, 225
    )
    _draw_ellipse(frame_pixels, 254, chest_y + 9, 14, 14, cyan, round(glow_alpha * 0.38))
    _draw_ellipse(frame_pixels, 254, chest_y + 9, 6, 6, cyan, glow_alpha)
    _draw_ellipse(frame_pixels, 252, chest_y + 7, 2, 2, (213, 255, 249), 240)

    _clear_rectangle(
        frame_pixels,
        (0, SHENSHENG_ANCHOR[1] + 1, FRAME_WIDTH, FRAME_HEIGHT),
    )
    return _normalize_blended_transparency(frame_pixels)


def _validate_shensheng_idle_cycle(idle_cycle: list[bytearray]) -> None:
    if len(idle_cycle) != SHENSHENG_FRAME_COUNT:
        raise ValueError(
            f"Shensheng idle cycle must contain {SHENSHENG_FRAME_COUNT} frames"
        )
    if SHENSHENG_FRAME_COUNT < 4:
        raise ValueError("Shensheng idle cycle must contain at least four frames")
    if not 3.0 <= SHENSHENG_IDLE_FPS <= 5.0:
        raise ValueError("Shensheng idle FPS must stay between 3 and 5")

    continuity_limits = {
        "body_y": 1.0,
        "shoulder_y": 1.0,
        "left_ear_offset": 1.0,
        "right_ear_offset": 1.0,
        "arm_sway": 1.0,
        "glow_alpha": 50.0,
        "shadow_scale": 0.03,
    }
    for frame_index in range(SHENSHENG_FRAME_COUNT):
        current = SHENSHENG_FRAME_PARAMETERS[frame_index]
        following = SHENSHENG_FRAME_PARAMETERS[
            (frame_index + 1) % SHENSHENG_FRAME_COUNT
        ]
        for parameter_name, maximum_delta in continuity_limits.items():
            if (
                abs(float(current[parameter_name]) - float(following[parameter_name]))
                > maximum_delta
            ):
                raise ValueError(
                    f"Shensheng {parameter_name} changes too abruptly "
                    f"after frame {frame_index}"
                )

    if not any(int(frame["body_y"]) != 0 for frame in SHENSHENG_FRAME_PARAMETERS):
        raise ValueError("Shensheng idle must include breathing motion")
    if not any(
        int(frame["left_ear_offset"]) != 0
        or int(frame["right_ear_offset"]) != 0
        for frame in SHENSHENG_FRAME_PARAMETERS
    ):
        raise ValueError("Shensheng idle must include ear motion")
    if not any(int(frame["arm_sway"]) != 0 for frame in SHENSHENG_FRAME_PARAMETERS):
        raise ValueError("Shensheng idle must include arm follow-through")

    bounds = [_visible_bounds(frame) for frame in idle_cycle]
    for frame_index, frame_bounds in enumerate(bounds):
        if frame_bounds[3] != SHENSHENG_ANCHOR[1] + 1:
            raise ValueError(
                f"Shensheng frame {frame_index} feet baseline must be "
                f"{SHENSHENG_ANCHOR[1]}"
            )
        if frame_bounds[0] <= 0 or frame_bounds[2] >= FRAME_WIDTH:
            raise ValueError(
                f"Shensheng frame {frame_index} must stay inside the transparent canvas"
            )

    frame_deltas = [
        _normalized_alpha_difference(
            idle_cycle[frame_index],
            idle_cycle[(frame_index + 1) % SHENSHENG_FRAME_COUNT],
        )
        for frame_index in range(SHENSHENG_FRAME_COUNT)
    ]
    if max(frame_deltas) > SHENSHENG_MAX_NORMALIZED_ALPHA_FRAME_DELTA:
        raise ValueError("Shensheng idle contains an abrupt silhouette transition")
    if len({bytes(frame) for frame in idle_cycle}) != SHENSHENG_FRAME_COUNT:
        raise ValueError("Every Shensheng idle frame must contain distinct motion")

    for frame_index, parameters in enumerate(SHENSHENG_FRAME_PARAMETERS):
        print(
            f"shensheng_idle[{frame_index}] {parameters['phase']}: "
            f"bounds={bounds[frame_index]}, "
            f"next_alpha_delta={frame_deltas[frame_index]:.4f}"
        )


def _write_horizontal_atlas(
    output_path: Path,
    frames: list[bytearray],
) -> None:
    output_width = FRAME_WIDTH * len(frames)
    output_pixels = bytearray(output_width * FRAME_HEIGHT * 4)
    output_row_size = output_width * 4
    frame_row_size = FRAME_WIDTH * 4
    for frame_index, frame_pixels in enumerate(frames):
        for frame_y in range(FRAME_HEIGHT):
            frame_start = frame_y * frame_row_size
            output_start = frame_y * output_row_size + frame_index * frame_row_size
            output_pixels[output_start : output_start + frame_row_size] = frame_pixels[
                frame_start : frame_start + frame_row_size
            ]
    _write_rgba_png(output_path, output_width, FRAME_HEIGHT, output_pixels)


def _write_shensheng_metadata() -> None:
    metadata = {
        "design": "art_guided_shensheng_idle",
        "art_source": "deterministic_programmatic_demo_local",
        "frame_width": FRAME_WIDTH,
        "frame_height": FRAME_HEIGHT,
        "idle_frame_count": SHENSHENG_FRAME_COUNT,
        "idle_fps": SHENSHENG_IDLE_FPS,
        "anchor": list(SHENSHENG_ANCHOR),
        "visual_traits": [
            "white_ears",
            "humanlike_face",
            "beast_muzzle",
            "ape_body",
            "semi_crouched_posture",
            "forward_shoulders",
            "long_arms",
            "dark_teal_grey_fur",
            "cinnabar_markings",
            "cyan_eye_and_mark_glow",
        ],
        "moving_elements": [
            "breathing",
            "shoulders",
            "ears",
            "arms",
            "cyan_glow",
            "shadow",
        ],
        "frames": [
            {
                **parameters,
                "anchor": list(SHENSHENG_ANCHOR),
            }
            for parameters in SHENSHENG_FRAME_PARAMETERS
        ],
    }
    SHENSHENG_METADATA_PATH.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _generate_shensheng_idle_assets() -> None:
    idle_cycle = [
        _render_shensheng_idle_frame(parameters)
        for parameters in SHENSHENG_FRAME_PARAMETERS
    ]
    _validate_shensheng_idle_cycle(idle_cycle)
    _write_horizontal_atlas(SHENSHENG_OUTPUT_PATH, idle_cycle)
    _write_shensheng_metadata()
    print(
        f"generated {SHENSHENG_OUTPUT_PATH} "
        f"({FRAME_WIDTH * SHENSHENG_FRAME_COUNT}x{FRAME_HEIGHT}, "
        f"frames: idle=0-{SHENSHENG_FRAME_COUNT - 1}, "
        f"anchor={SHENSHENG_ANCHOR})"
    )
    print(f"generated {SHENSHENG_METADATA_PATH} (art-guided idle metadata)")


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
    _generate_shensheng_idle_assets()


if __name__ == "__main__":
    main()

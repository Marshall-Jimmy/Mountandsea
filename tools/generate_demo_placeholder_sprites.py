"""Clean, align, and assemble the demo-local player animation atlas.

Source layout: three columns by two rows of 512x512 RGBA frames.
Reading order: idle 0, idle 1, then four walk key poses.
Output layout: one horizontal row with two idle frames and an eight-frame walk
cycle ordered as contact, down, passing, up, opposite contact, opposite down,
opposite passing, opposite up.

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
SOURCE_FRAME_LAYOUT = (
    ("idle", 0, 0, (275, 491)),
    ("idle", 1, 0, (238, 491)),
    ("walk", 2, 0, (224, 486)),
    ("walk", 0, 1, (276, 470)),
    ("walk", 1, 1, (252, 471)),
    ("walk", 2, 1, (224, 471)),
)
IDLE_SOURCE_INDICES = (0, 1)
# The original four poses were not authored in cyclic order. This ordering
# minimizes silhouette jumps while progressing from a wide contact pose through
# a narrower passing pose into the opposite half of the stride.
WALK_KEYFRAME_SOURCE_INDICES = (2, 4, 3, 5)
WALK_CYCLE_PHASES = (
    "contact",
    "down",
    "passing",
    "up",
    "opposite_contact",
    "opposite_down",
    "opposite_passing",
    "opposite_up",
)
SOURCE_FRAME_COUNT = len(SOURCE_FRAME_LAYOUT)
WALK_FRAME_COUNT = len(WALK_CYCLE_PHASES)
OUTPUT_FRAME_COUNT = len(IDLE_SOURCE_INDICES) + WALK_FRAME_COUNT
TARGET_FEET_ANCHOR = (256, 488)
EDGE_ALPHA_CUTOFF = 32
SOLID_COLOR_ALPHA = 224
COLOR_REPAIR_RADIUS = 3
MIN_ALPHA_COMPONENT_PIXELS = 32
CANONICAL_WALK_BODY_SOURCE_INDEX = WALK_KEYFRAME_SOURCE_INDICES[0]
STABLE_BODY_END_Y = 260
VARIABLE_LOWER_BODY_START_Y = 380
INTERMEDIATE_SPLIT_X = TARGET_FEET_ANCHOR[0]
INTERMEDIATE_FEATHER_HALF_WIDTH = 12
BODY_CENTER_REGION = (180, 80, 340, 330)
MAX_BODY_CENTER_SPREAD = (8.0, 8.0)
MAX_BOUNDING_BOX_HEIGHT_SPREAD = 16
MAX_NORMALIZED_ALPHA_FRAME_DELTA = 0.08
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


def _blend_frames(
    first_frame: bytearray,
    second_frame: bytearray,
    second_weight: float,
) -> bytearray:
    first_weight = 1.0 - second_weight
    blended_pixels = bytearray(len(first_frame))
    for pixel_index in range(0, len(first_frame), 4):
        first_alpha = first_frame[pixel_index + 3]
        second_alpha = second_frame[pixel_index + 3]
        blended_alpha = round(first_alpha * first_weight + second_alpha * second_weight)
        if blended_alpha == 0:
            continue

        for channel in range(3):
            premultiplied_channel = (
                first_frame[pixel_index + channel] * first_alpha * first_weight
                + second_frame[pixel_index + channel] * second_alpha * second_weight
            )
            blended_pixels[pixel_index + channel] = min(
                255,
                round(premultiplied_channel / blended_alpha),
            )
        blended_pixels[pixel_index + 3] = blended_alpha
    return blended_pixels


def _stabilize_walk_body(
    canonical_frame: bytearray,
    pose_frame: bytearray,
) -> bytearray:
    stabilized_pixels = bytearray(len(canonical_frame))
    for y in range(FRAME_HEIGHT):
        if y <= STABLE_BODY_END_Y:
            pose_weight = 0.0
        elif y >= VARIABLE_LOWER_BODY_START_Y:
            pose_weight = 1.0
        else:
            progress = (y - STABLE_BODY_END_Y) / (
                VARIABLE_LOWER_BODY_START_Y - STABLE_BODY_END_Y
            )
            pose_weight = progress * progress * (3.0 - 2.0 * progress)

        row_start = y * FRAME_WIDTH * 4
        row_end = row_start + FRAME_WIDTH * 4
        stabilized_pixels[row_start:row_end] = _blend_frames(
            canonical_frame[row_start:row_end],
            pose_frame[row_start:row_end],
            pose_weight,
        )
    return _normalize_blended_transparency(stabilized_pixels)


def _splice_walk_poses(
    first_frame: bytearray,
    second_frame: bytearray,
    next_pose_on_left: bool,
) -> bytearray:
    spliced_pixels = bytearray(len(first_frame))
    feather_left = INTERMEDIATE_SPLIT_X - INTERMEDIATE_FEATHER_HALF_WIDTH
    feather_right = INTERMEDIATE_SPLIT_X + INTERMEDIATE_FEATHER_HALF_WIDTH

    for y in range(FRAME_HEIGHT):
        for x in range(FRAME_WIDTH):
            pixel_index = _frame_pixel_index(x, y)
            if x <= feather_left:
                second_weight = 1.0 if next_pose_on_left else 0.0
            elif x >= feather_right:
                second_weight = 0.0 if next_pose_on_left else 1.0
            else:
                progress = (x - feather_left) / (feather_right - feather_left)
                second_weight = 1.0 - progress if next_pose_on_left else progress

            if second_weight <= 0.0:
                spliced_pixels[pixel_index : pixel_index + 4] = first_frame[
                    pixel_index : pixel_index + 4
                ]
            elif second_weight >= 1.0:
                spliced_pixels[pixel_index : pixel_index + 4] = second_frame[
                    pixel_index : pixel_index + 4
                ]
            else:
                spliced_pixels[pixel_index : pixel_index + 4] = _blend_frames(
                    first_frame[pixel_index : pixel_index + 4],
                    second_frame[pixel_index : pixel_index + 4],
                    second_weight,
                )

    return _normalize_blended_transparency(spliced_pixels)


def _build_walk_cycle(aligned_source_frames: list[bytearray]) -> list[bytearray]:
    canonical_frame = aligned_source_frames[CANONICAL_WALK_BODY_SOURCE_INDEX]
    keyframes = [
        _stabilize_walk_body(canonical_frame, aligned_source_frames[source_index])
        for source_index in WALK_KEYFRAME_SOURCE_INDICES
    ]

    walk_cycle: list[bytearray] = []
    for keyframe_index, keyframe in enumerate(keyframes):
        next_keyframe = keyframes[(keyframe_index + 1) % len(keyframes)]
        walk_cycle.append(keyframe)
        walk_cycle.append(
            _splice_walk_poses(
                keyframe,
                next_keyframe,
                next_pose_on_left=keyframe_index % 2 == 1,
            )
        )
    return walk_cycle


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


def _validate_walk_cycle(walk_cycle: list[bytearray]) -> None:
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

    for frame_index, phase_name in enumerate(WALK_CYCLE_PHASES):
        center_x, center_y = body_centers[frame_index]
        print(
            f"walk[{frame_index}] {phase_name}: bounds={bounds[frame_index]}, "
            f"body_center=({center_x:.1f}, {center_y:.1f}), "
            f"next_alpha_delta={frame_deltas[frame_index]:.4f}"
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
    print(
        f"generated {OUTPUT_PATH} "
        f"({output_width}x{FRAME_HEIGHT}, frames: idle=0-1 walk=2-9, "
        f"feet anchor={TARGET_FEET_ANCHOR})"
    )


if __name__ == "__main__":
    main()

"""Generate the demo-local player placeholder sprite sheet.

Layout: one horizontal row of six 512x512 RGBA frames.
Frames 0-1 are idle; frames 2-5 are walk.
The generator uses only the Python standard library and repository art colors.
"""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


FRAME_SIZE = 512
FRAME_COUNT = 6
SHEET_WIDTH = FRAME_SIZE * FRAME_COUNT
SHEET_HEIGHT = FRAME_SIZE
OUTPUT_PATH = (
    Path(__file__).resolve().parents[1]
    / "game"
    / "assets"
    / "demo"
    / "placeholder_sprites"
    / "demo_player_idle_walk.png"
)

INK = (25, 61, 63, 255)
DEEP_GREEN = (50, 115, 69, 255)
MIST_BLUE = (79, 103, 129, 255)
PALE_MIST = (175, 191, 210, 255)
LIGHT_OCHRE = (228, 166, 114, 255)
TERRACOTTA = (184, 111, 80, 255)
CINNABAR = (158, 40, 53, 255)
BRIGHT_CINNABAR = (229, 59, 68, 255)
SPIRIT_CYAN = (44, 232, 244, 255)
WHITE = (255, 255, 255, 255)


def _clamp(value: float, lower: float = 0.0, upper: float = 1.0) -> float:
    return max(lower, min(upper, value))


def _noise(x: int, y: int, seed: int) -> float:
    value = (x * 374761393 + y * 668265263 + seed * 69069) & 0xFFFFFFFF
    value = ((value ^ (value >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((value ^ (value >> 16)) & 0xFF) / 255.0


class Canvas:
    def __init__(self, width: int, height: int) -> None:
        self.width = width
        self.height = height
        self.pixels = bytearray(width * height * 4)

    def blend(
        self,
        x: int,
        y: int,
        color: tuple[int, int, int, int],
        coverage: float,
        seed: int,
        texture_strength: float = 0.06,
    ) -> None:
        if coverage <= 0.0 or x < 0 or y < 0 or x >= self.width or y >= self.height:
            return

        frame_y = y % FRAME_SIZE
        lighting = (0.5 - frame_y / FRAME_SIZE) * 0.035
        texture = (_noise(x, y, seed) - 0.5) * texture_strength
        tint = 1.0 + lighting + texture
        src_r = int(_clamp(color[0] * tint, 0.0, 255.0))
        src_g = int(_clamp(color[1] * tint, 0.0, 255.0))
        src_b = int(_clamp(color[2] * tint, 0.0, 255.0))
        src_a = (color[3] / 255.0) * _clamp(coverage)

        index = (y * self.width + x) * 4
        dst_r = self.pixels[index]
        dst_g = self.pixels[index + 1]
        dst_b = self.pixels[index + 2]
        dst_a = self.pixels[index + 3] / 255.0
        out_a = src_a + dst_a * (1.0 - src_a)
        if out_a <= 0.0:
            return

        self.pixels[index] = int(
            (src_r * src_a + dst_r * dst_a * (1.0 - src_a)) / out_a
        )
        self.pixels[index + 1] = int(
            (src_g * src_a + dst_g * dst_a * (1.0 - src_a)) / out_a
        )
        self.pixels[index + 2] = int(
            (src_b * src_a + dst_b * dst_a * (1.0 - src_a)) / out_a
        )
        self.pixels[index + 3] = int(out_a * 255.0)

    def ellipse(
        self,
        center_x: float,
        center_y: float,
        radius_x: float,
        radius_y: float,
        color: tuple[int, int, int, int],
        seed: int,
        softness: float = 2.0,
        texture_strength: float = 0.06,
    ) -> None:
        padding = int(math.ceil(softness + 1.0))
        min_x = max(0, int(center_x - radius_x) - padding)
        max_x = min(self.width - 1, int(center_x + radius_x) + padding)
        min_y = max(0, int(center_y - radius_y) - padding)
        max_y = min(self.height - 1, int(center_y + radius_y) + padding)
        edge_scale = min(radius_x, radius_y)

        for y in range(min_y, max_y + 1):
            normalized_y = (y + 0.5 - center_y) / radius_y
            for x in range(min_x, max_x + 1):
                normalized_x = (x + 0.5 - center_x) / radius_x
                distance = (math.hypot(normalized_x, normalized_y) - 1.0) * edge_scale
                coverage = _clamp(0.5 - distance / max(softness, 0.01))
                self.blend(x, y, color, coverage, seed, texture_strength)

    def capsule(
        self,
        start_x: float,
        start_y: float,
        end_x: float,
        end_y: float,
        radius: float,
        color: tuple[int, int, int, int],
        seed: int,
        softness: float = 2.0,
        texture_strength: float = 0.06,
    ) -> None:
        padding = int(math.ceil(radius + softness + 1.0))
        min_x = max(0, int(min(start_x, end_x)) - padding)
        max_x = min(self.width - 1, int(max(start_x, end_x)) + padding)
        min_y = max(0, int(min(start_y, end_y)) - padding)
        max_y = min(self.height - 1, int(max(start_y, end_y)) + padding)
        line_x = end_x - start_x
        line_y = end_y - start_y
        line_length_squared = line_x * line_x + line_y * line_y

        for y in range(min_y, max_y + 1):
            for x in range(min_x, max_x + 1):
                if line_length_squared <= 0.0:
                    nearest_x = start_x
                    nearest_y = start_y
                else:
                    projection = (
                        (x + 0.5 - start_x) * line_x
                        + (y + 0.5 - start_y) * line_y
                    ) / line_length_squared
                    projection = _clamp(projection)
                    nearest_x = start_x + projection * line_x
                    nearest_y = start_y + projection * line_y
                distance = math.hypot(x + 0.5 - nearest_x, y + 0.5 - nearest_y)
                coverage = _clamp(0.5 - (distance - radius) / max(softness, 0.01))
                self.blend(x, y, color, coverage, seed, texture_strength)


def _draw_player_frame(
    canvas: Canvas,
    frame_index: int,
    body_lift: float,
    stride: float,
    lean: float,
    glow_alpha: int,
) -> None:
    origin_x = frame_index * FRAME_SIZE
    center_x = origin_x + FRAME_SIZE / 2.0 + lean
    body_y = body_lift
    left_foot_x = center_x - 38.0 + stride
    right_foot_x = center_x + 38.0 - stride
    left_foot_y = 438.0 + body_y + stride * 0.55
    right_foot_y = 438.0 + body_y - stride * 0.55
    left_hand_x = center_x - 118.0 - stride * 0.45
    right_hand_x = center_x + 118.0 + stride * 0.45

    canvas.ellipse(center_x, 452.0, 124.0, 25.0, (25, 61, 63, 70), 11, 7.0, 0.02)

    canvas.capsule(center_x - 42.0, 350.0 + body_y, left_foot_x, left_foot_y, 34.0, INK, 21)
    canvas.capsule(center_x + 42.0, 350.0 + body_y, right_foot_x, right_foot_y, 34.0, INK, 22)
    canvas.capsule(center_x - 42.0, 350.0 + body_y, left_foot_x, left_foot_y, 25.0, MIST_BLUE, 23)
    canvas.capsule(center_x + 42.0, 350.0 + body_y, right_foot_x, right_foot_y, 25.0, DEEP_GREEN, 24)
    canvas.ellipse(left_foot_x, left_foot_y + 16.0, 36.0, 18.0, INK, 25)
    canvas.ellipse(right_foot_x, right_foot_y + 16.0, 36.0, 18.0, INK, 26)

    canvas.capsule(center_x - 82.0, 214.0 + body_y, left_hand_x, 320.0 + body_y, 31.0, INK, 31)
    canvas.capsule(center_x + 82.0, 214.0 + body_y, right_hand_x, 320.0 + body_y, 31.0, INK, 32)
    canvas.capsule(center_x - 82.0, 214.0 + body_y, left_hand_x, 320.0 + body_y, 22.0, TERRACOTTA, 33)
    canvas.capsule(center_x + 82.0, 214.0 + body_y, right_hand_x, 320.0 + body_y, 22.0, DEEP_GREEN, 34)
    canvas.ellipse(left_hand_x, 324.0 + body_y, 20.0, 25.0, LIGHT_OCHRE, 35)
    canvas.ellipse(right_hand_x, 324.0 + body_y, 20.0, 25.0, LIGHT_OCHRE, 36)

    canvas.capsule(center_x, 208.0 + body_y, center_x, 365.0 + body_y, 116.0, INK, 41, 3.0)
    canvas.ellipse(center_x, 374.0 + body_y, 128.0, 104.0, INK, 42, 3.0)
    canvas.capsule(center_x, 211.0 + body_y, center_x, 363.0 + body_y, 106.0, DEEP_GREEN, 43, 3.0, 0.1)
    canvas.ellipse(center_x, 374.0 + body_y, 117.0, 94.0, DEEP_GREEN, 44, 3.0, 0.1)
    canvas.capsule(center_x, 225.0 + body_y, center_x, 384.0 + body_y, 39.0, MIST_BLUE, 45, 2.0, 0.08)
    canvas.capsule(center_x - 69.0, 270.0 + body_y, center_x + 69.0, 270.0 + body_y, 17.0, INK, 46)
    canvas.capsule(center_x - 66.0, 270.0 + body_y, center_x + 66.0, 270.0 + body_y, 10.0, CINNABAR, 47, 2.0, 0.08)
    canvas.capsule(center_x - 48.0, 307.0 + body_y, center_x + 44.0, 405.0 + body_y, 5.0, PALE_MIST, 48, 2.0, 0.03)
    canvas.capsule(center_x + 38.0, 302.0 + body_y, center_x + 63.0, 403.0 + body_y, 4.0, (175, 191, 210, 150), 49, 2.0, 0.02)

    canvas.ellipse(center_x, 126.0 + body_y, 87.0, 99.0, INK, 51, 3.0)
    canvas.ellipse(center_x, 131.0 + body_y, 77.0, 89.0, LIGHT_OCHRE, 52, 3.0, 0.08)
    canvas.ellipse(center_x, 91.0 + body_y, 80.0, 67.0, INK, 53, 3.0, 0.09)
    canvas.ellipse(center_x - 62.0, 145.0 + body_y, 24.0, 71.0, INK, 54, 3.0)
    canvas.ellipse(center_x + 62.0, 145.0 + body_y, 24.0, 71.0, INK, 55, 3.0)
    canvas.ellipse(center_x, 151.0 + body_y, 63.0, 57.0, LIGHT_OCHRE, 56, 3.0, 0.07)
    canvas.ellipse(center_x - 27.0, 142.0 + body_y, 8.0, 5.0, INK, 57, 1.5, 0.01)
    canvas.ellipse(center_x + 27.0, 142.0 + body_y, 8.0, 5.0, INK, 58, 1.5, 0.01)
    canvas.capsule(center_x - 12.0, 174.0 + body_y, center_x + 12.0, 174.0 + body_y, 3.0, CINNABAR, 59, 1.0, 0.01)
    canvas.ellipse(center_x + 2.0, 50.0 + body_y, 30.0, 34.0, INK, 60, 2.0, 0.08)
    canvas.capsule(center_x - 54.0, 204.0 + body_y, center_x, 233.0 + body_y, 13.0, INK, 61)
    canvas.capsule(center_x + 54.0, 204.0 + body_y, center_x, 233.0 + body_y, 13.0, INK, 62)
    canvas.capsule(center_x - 45.0, 202.0 + body_y, center_x, 225.0 + body_y, 7.0, PALE_MIST, 63)
    canvas.capsule(center_x + 45.0, 202.0 + body_y, center_x, 225.0 + body_y, 7.0, PALE_MIST, 64)

    charm_x = center_x + 77.0
    charm_y = 282.0 + body_y
    canvas.ellipse(charm_x, charm_y, 31.0, 31.0, (44, 232, 244, glow_alpha), 71, 10.0, 0.01)
    canvas.ellipse(charm_x, charm_y, 13.0, 18.0, SPIRIT_CYAN, 72, 3.0, 0.03)
    canvas.ellipse(charm_x - 3.0, charm_y - 6.0, 4.0, 6.0, WHITE, 73, 2.0, 0.01)
    canvas.ellipse(center_x - 48.0, 105.0 + body_y, 14.0, 10.0, (255, 255, 255, 55), 74, 4.0, 0.01)
    canvas.capsule(center_x - 92.0, 354.0 + body_y, center_x - 44.0, 410.0 + body_y, 4.0, (229, 59, 68, 115), 75, 3.0, 0.03)


def _png_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    checksum = zlib.crc32(chunk_type)
    checksum = zlib.crc32(payload, checksum) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + chunk_type + payload + struct.pack(">I", checksum)


def _write_png(path: Path, canvas: Canvas) -> None:
    raw_rows = bytearray()
    row_size = canvas.width * 4
    for y in range(canvas.height):
        raw_rows.append(0)
        row_start = y * row_size
        raw_rows.extend(canvas.pixels[row_start : row_start + row_size])

    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(
        _png_chunk(
            b"IHDR",
            struct.pack(">IIBBBBB", canvas.width, canvas.height, 8, 6, 0, 0, 0),
        )
    )
    png.extend(_png_chunk(b"IDAT", zlib.compress(bytes(raw_rows), level=9)))
    png.extend(_png_chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def main() -> None:
    canvas = Canvas(SHEET_WIDTH, SHEET_HEIGHT)
    frame_motion = [
        (0.0, 0.0, 0.0, 70),
        (-3.0, 0.0, 0.0, 105),
        (0.0, -18.0, 2.0, 80),
        (-4.0, -7.0, 0.0, 95),
        (0.0, 18.0, -2.0, 80),
        (-4.0, 7.0, 0.0, 95),
    ]
    for frame_index, motion in enumerate(frame_motion):
        _draw_player_frame(canvas, frame_index, *motion)

    _write_png(OUTPUT_PATH, canvas)
    print(
        f"generated {OUTPUT_PATH} "
        f"({SHEET_WIDTH}x{SHEET_HEIGHT}, frames: idle=0-1 walk=2-5)"
    )


if __name__ == "__main__":
    main()

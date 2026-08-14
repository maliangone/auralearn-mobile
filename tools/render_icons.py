"""Rasterize AuraLearn launcher SVGs for Android, iOS, and the Play Store."""

from __future__ import annotations

import json
import subprocess
import sys
from io import BytesIO
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError as error:  # pragma: no cover - only used on a fresh machine
    print(f"Pillow import failed: {error}")
    print("Attempting: python -m pip install Pillow")
    result = subprocess.run(
        [sys.executable, "-m", "pip", "install", "Pillow"],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if result.returncode != 0:
        print(result.stdout)
        raise
    from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BACKGROUND_SVG = ROOT / "assets" / "icons" / "app_icon.svg"
FOREGROUND_SVG = ROOT / "assets" / "icons" / "app_icon_fg.svg"
IOS_ASSET_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_CONTENTS = IOS_ASSET_DIR / "Contents.json"

INDIGO = "#4F6EF7"
DEEP_INDIGO = "#3A54D4"
VIOLET = "#7C3AED"
AMBER = "#F59E0B"
LIGHT_AMBER = "#FFD978"
WHITE = "#FFFFFF"
LIGHT_INDIGO = "#EEF1FE"

ANDROID_DENSITIES = (
    ("mdpi", 48, 108),
    ("hdpi", 72, 162),
    ("xhdpi", 96, 216),
    ("xxhdpi", 144, 324),
    ("xxxhdpi", 192, 432),
)

IOS_RENDERS = (
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
)

IOS_FILENAME_BY_KEY = {
    ("20x20", "1x"): "Icon-App-20x20@1x.png",
    ("20x20", "2x"): "Icon-App-20x20@2x.png",
    ("20x20", "3x"): "Icon-App-20x20@3x.png",
    ("29x29", "1x"): "Icon-App-29x29@1x.png",
    ("29x29", "2x"): "Icon-App-29x29@2x.png",
    ("29x29", "3x"): "Icon-App-29x29@3x.png",
    ("40x40", "1x"): "Icon-App-40x40@1x.png",
    ("40x40", "2x"): "Icon-App-40x40@2x.png",
    ("40x40", "3x"): "Icon-App-40x40@3x.png",
    ("60x60", "2x"): "Icon-App-60x60@2x.png",
    ("60x60", "3x"): "Icon-App-60x60@3x.png",
    ("76x76", "1x"): "Icon-App-76x76@1x.png",
    ("76x76", "2x"): "Icon-App-76x76@2x.png",
    ("83.5x83.5", "2x"): "Icon-App-83.5x83.5@2x.png",
    ("1024x1024", "1x"): "Icon-App-1024x1024@1x.png",
}


def relative(path: Path) -> str:
    """Return a stable repo-relative path for logs."""

    return path.relative_to(ROOT).as_posix()


def require_inputs() -> None:
    missing = [path for path in (BACKGROUND_SVG, FOREGROUND_SVG, IOS_CONTENTS) if not path.exists()]
    if missing:
        missing_text = "\n".join(f"  - {path}" for path in missing)
        raise FileNotFoundError(f"Required icon input(s) missing:\n{missing_text}")


def load_cairosvg() -> Any | None:
    """Load CairoSVG, installing it when the current Python lacks it."""

    try:
        import cairosvg

        print("CairoSVG import succeeded; using cairosvg.svg2png.")
        return cairosvg
    except Exception as import_error:
        print(f"CairoSVG import failed: {import_error}")
        print("Attempting: python -m pip install cairosvg")
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "cairosvg"],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if result.returncode == 0:
            try:
                import cairosvg

                print("CairoSVG installed successfully; using cairosvg.svg2png.")
                return cairosvg
            except Exception as retry_error:
                print(f"CairoSVG import still failed after installation: {retry_error}")
        else:
            output = (result.stdout or "").strip()
            if output:
                print(output[-1200:])
            print(f"CairoSVG installation failed with exit code {result.returncode}.")

        print("Rasterizer: PIL fallback approximation.")
        return None


def rgb(hex_color: str) -> tuple[int, int, int]:
    value = hex_color.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))  # type: ignore[return-value]


def lerp_color(start: tuple[int, int, int], end: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(round(a + (b - a) * amount) for a, b in zip(start, end))  # type: ignore[return-value]


def scaled_points(points: list[tuple[float, float]], size: int) -> list[tuple[int, int]]:
    return [(round(x * size), round(y * size)) for x, y in points]


def draw_fallback(size: int, foreground: bool) -> Image.Image:
    """Draw a simple icon approximation when CairoSVG cannot be used."""

    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    if not foreground:
        gradient = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gradient_draw = ImageDraw.Draw(gradient)
        start = rgb(INDIGO)
        end = rgb(VIOLET)
        for y in range(size):
            color = lerp_color(start, end, y / max(size - 1, 1))
            gradient_draw.line((0, y, size, y), fill=(*color, 255))

        mask = Image.new("L", (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle(
            (0, 0, size - 1, size - 1),
            radius=round(size * 0.215),
            fill=255,
        )
        image = Image.composite(gradient, image, mask)

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(
        (round(size * 0.17), round(size * 0.77), round(size * 0.83), round(size * 0.91)),
        fill=(*rgb(DEEP_INDIGO), 70),
    )
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(1, round(size * 0.025)))))
    draw = ImageDraw.Draw(image)

    star = scaled_points(
        [
            (0.50, 0.18),
            (0.55, 0.29),
            (0.72, 0.35),
            (0.55, 0.40),
            (0.50, 0.52),
            (0.45, 0.40),
            (0.28, 0.35),
            (0.45, 0.29),
        ],
        size,
    )
    draw.polygon(star, fill=rgb(AMBER))
    draw.line(star + [star[0]], fill=rgb("#FFC85A"), width=max(1, round(size * 0.012)), joint="curve")

    left_page = scaled_points(
        [(0.50, 0.61), (0.40, 0.56), (0.29, 0.57), (0.27, 0.76), (0.39, 0.74), (0.50, 0.81)],
        size,
    )
    right_page = scaled_points(
        [(0.50, 0.61), (0.60, 0.56), (0.71, 0.57), (0.73, 0.76), (0.61, 0.74), (0.50, 0.81)],
        size,
    )
    page_fill = rgb(WHITE)
    page_edge = rgb(LIGHT_INDIGO)
    page_width = max(1, round(size * 0.012))
    draw.polygon(left_page, fill=page_fill)
    draw.polygon(right_page, fill=page_fill)
    draw.line(left_page + [left_page[0]], fill=page_edge, width=page_width, joint="curve")
    draw.line(right_page + [right_page[0]], fill=page_edge, width=page_width, joint="curve")
    draw.line((round(size * 0.50), round(size * 0.61), round(size * 0.50), round(size * 0.81)), fill=page_edge, width=page_width)
    draw.arc(
        (round(size * 0.31), round(size * 0.62), round(size * 0.48), round(size * 0.74)),
        205,
        345,
        fill=page_edge,
        width=page_width,
    )
    draw.arc(
        (round(size * 0.52), round(size * 0.62), round(size * 0.69), round(size * 0.74)),
        195,
        335,
        fill=page_edge,
        width=page_width,
    )
    return image


def flatten_onto_indigo(image: Image.Image, size: int) -> Image.Image:
    rgba = image.convert("RGBA")
    background = Image.new("RGB", (size, size), rgb(INDIGO))
    background.paste(rgba, (0, 0), rgba.getchannel("A"))
    return background


def render_svg(
    svg_path: Path,
    output_path: Path,
    size: int,
    cairosvg: Any | None,
    *,
    foreground: bool = False,
    flatten: bool = False,
) -> str:
    """Render one SVG and return the method used."""

    output_path.parent.mkdir(parents=True, exist_ok=True)
    method = "CairoSVG"
    try:
        if cairosvg is None:
            raise RuntimeError("CairoSVG unavailable")
        png_bytes = cairosvg.svg2png(
            url=str(svg_path),
            output_width=size,
            output_height=size,
        )
        with Image.open(BytesIO(png_bytes)) as source:
            rendered = source.convert("RGBA")
        if flatten:
            rendered = flatten_onto_indigo(rendered, size)
    except Exception as error:
        method = "PIL fallback"
        print(f"CairoSVG render failed for {relative(svg_path)}: {error}")
        rendered = draw_fallback(size, foreground=foreground)
        if flatten:
            rendered = flatten_onto_indigo(rendered, size)

    rendered.save(output_path, format="PNG")
    print(f"WROTE {relative(output_path)} ({size}x{size}, method={method})")
    return method


def verify_ios_manifest() -> None:
    """Keep manifest filenames stable, repairing only an actual filename mismatch."""

    data = json.loads(IOS_CONTENTS.read_text(encoding="utf-8"))
    images = data.get("images")
    if not isinstance(images, list):
        raise ValueError(f"{relative(IOS_CONTENTS)} has no images array")

    changed = False
    for entry in images:
        if not isinstance(entry, dict):
            continue
        key = (entry.get("size"), entry.get("scale"))
        expected = IOS_FILENAME_BY_KEY.get(key)
        if expected and entry.get("filename") != expected:
            print(
                f"FIX Contents.json filename for {key}: "
                f"{entry.get('filename')!r} -> {expected!r}"
            )
            entry["filename"] = expected
            changed = True

    if changed:
        IOS_CONTENTS.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        print(f"Updated {relative(IOS_CONTENTS)} because filename metadata was mismatched.")
    else:
        print(f"Contents.json filenames unchanged: {relative(IOS_CONTENTS)}")

    manifest_names = {entry.get("filename") for entry in images if isinstance(entry, dict) and entry.get("filename")}
    expected_names = {filename for filename, _ in IOS_RENDERS}
    if manifest_names != expected_names:
        missing = sorted(expected_names - manifest_names)
        unexpected = sorted(manifest_names - expected_names)
        raise ValueError(f"Contents.json filename set mismatch; missing={missing}, unexpected={unexpected}")

    disk_names = {path.name for path in IOS_ASSET_DIR.glob("Icon-App-*.png")}
    if disk_names == manifest_names:
        print("Contents.json filenames match the existing Icon-App-*.png files on disk.")
    else:
        missing = sorted(manifest_names - disk_names)
        unexpected = sorted(disk_names - manifest_names)
        print(f"Existing iOS PNG filename mismatch before replacement: missing={missing}, unexpected={unexpected}")


def verify_outputs(outputs: list[tuple[Path, int, str]]) -> bool:
    print("\nVerification summary:")
    all_ok = True
    for path, expected_size, expected_mode in outputs:
        try:
            with Image.open(path) as image:
                actual_size = image.size
                actual_mode = image.mode
                image.verify()
            if actual_size != (expected_size, expected_size):
                raise ValueError(f"size {actual_size}, expected {(expected_size, expected_size)}")
            if expected_mode and actual_mode != expected_mode:
                raise ValueError(f"mode {actual_mode}, expected {expected_mode}")
            print(f"OK   {relative(path)} — {actual_size[0]}x{actual_size[1]}, mode={actual_mode}")
        except Exception as error:
            all_ok = False
            print(f"FAIL {relative(path)} — {error}")
    return all_ok


def main() -> int:
    require_inputs()
    cairosvg = load_cairosvg()
    methods_used: set[str] = set()
    outputs: list[tuple[Path, int, str]] = []

    for density, background_size, foreground_size in ANDROID_DENSITIES:
        mipmap_dir = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}"
        background_output = mipmap_dir / "ic_launcher.png"
        methods_used.add(render_svg(BACKGROUND_SVG, background_output, background_size, cairosvg))
        outputs.append((background_output, background_size, ""))

        foreground_output = mipmap_dir / "ic_launcher_foreground.png"
        methods_used.add(
            render_svg(
                FOREGROUND_SVG,
                foreground_output,
                foreground_size,
                cairosvg,
                foreground=True,
            )
        )
        outputs.append((foreground_output, foreground_size, ""))

    play_store_output = ROOT / "assets" / "icons" / "play_store_512.png"
    methods_used.add(render_svg(BACKGROUND_SVG, play_store_output, 512, cairosvg))
    outputs.append((play_store_output, 512, ""))

    verify_ios_manifest()
    for filename, size in IOS_RENDERS:
        output_path = IOS_ASSET_DIR / filename
        methods_used.add(
            render_svg(
                BACKGROUND_SVG,
                output_path,
                size,
                cairosvg,
                flatten=True,
            )
        )
        outputs.append((output_path, size, "RGB"))

    print(f"\nRasterization method used: {', '.join(sorted(methods_used))}")
    return 0 if verify_outputs(outputs) else 1


if __name__ == "__main__":
    raise SystemExit(main())

"""Render geometry previews from export_layout.lua; not native Designer screenshots."""
import csv
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "previews"


def color(value, default):
    return tuple(int(part) for part in value.split(",")[:3]) if value else default


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pages = {}
    with open(sys.argv[1], newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            pages.setdefault(row["page"], []).append(row)
    logo = Image.open(ROOT / "src" / "assets" / "shure-logo.jpeg").convert("RGB")
    for page, rows in pages.items():
        canvas = Image.new("RGB", (1008, 584), "white")
        draw = ImageDraw.Draw(canvas)
        for row in rows:
            x, y, w, h = (int(row[key]) for key in ("x", "y", "w", "h"))
            box = (x, y, x + w - 1, y + h - 1)
            kind = row["type"]
            ink = color(row["color"], (0, 0, 0))
            fill = color(row["fill"], (232, 232, 232))
            font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", int(row["font"]))
            if kind == "GroupBox":
                draw.rectangle(box, fill=fill, outline=(156, 171, 175))
            elif kind == "Image":
                canvas.paste(logo.resize((w, h)), (x, y))
            elif kind == "Label":
                draw.text((x, y + (h - int(row["font"])) // 2), row["text"], font=font, fill=ink)
            elif kind == "Led":
                draw.ellipse(box, fill=fill, outline=(156, 171, 175))
            elif kind == "Fader":
                draw.line((x + w // 2, y + 8, x + w // 2, y + h - 28), fill=(156, 171, 175), width=3)
                draw.rectangle((x + 3, y + h // 2, x + w - 4, y + h // 2 + 14), fill=fill)
                draw.rectangle((x, y + h - 24, x + w - 1, y + h - 1), fill=(232, 232, 232), outline=(156, 171, 175))
                draw.text((x + w // 2, y + h - 12), "0", anchor="mm", font=font, fill=(0, 0, 0))
            else:
                draw.rounded_rectangle(box, radius=2, fill=fill, outline=(156, 171, 175))
                if kind == "Button":
                    draw.text((x + w // 2, y + h // 2), row["text"], anchor="mm", font=font, fill=ink)
                elif kind == "ComboBox":
                    draw.polygon(((x + w - 15, y + 9), (x + w - 7, y + 9), (x + w - 11, y + 14)), fill=(50, 50, 50))
        canvas.save(OUT / (page.replace(" ", "-") + ".png"))
    print(OUT)


if __name__ == "__main__":
    main()

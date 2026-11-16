#!/usr/bin/env python3
"""把 output/ 里按页码命名的课件图片合成 PDF 和 PPTX。

用法：
    python3 build_deck.py --images 课件-xxx/output --name 课名 --out 课件-xxx/交付

图片文件名必须以两位页码开头（01-封面.png、02-xxx.png），从 01 连续，不能重复。
交付目录里已有同名 PDF/PPTX 时不会覆盖。
"""
import argparse
import re
import sys
from pathlib import Path

try:
    from PIL import Image
    from pptx import Presentation
    from pptx.util import Inches
except ImportError:
    sys.exit('缺少依赖：请先安装 Pillow 和 python-pptx（pip install pillow python-pptx）')

EXTS = {'.png', '.jpg', '.jpeg', '.webp'}
WIDTH = 1920
HEIGHT = 1080


def collect(folder: Path):
    pages = {}
    for f in folder.iterdir():
        if not f.is_file() or f.suffix.lower() not in EXTS:
            continue
        m = re.match(r'^(\d+)', f.name)
        if not m:
            continue
        n = int(m.group(1))
        if n in pages:
            sys.exit(f'页码重复：{pages[n].name} 和 {f.name}')
        pages[n] = f
    if not pages:
        sys.exit(f'没有找到以页码开头的图片：{folder}')
    missing = [n for n in range(1, max(pages) + 1) if n not in pages]
    if missing:
        sys.exit('页码不连续，缺少第 ' + '、'.join(str(n) for n in missing) + ' 页')
    return [pages[n] for n in sorted(pages)]


def to_slide_image(path: Path) -> Image.Image:
    img = Image.open(path).convert('RGB')
    ratio = img.width / img.height
    if abs(ratio - 16 / 9) > 0.02:
        print(f'提醒：{path.name} 不是 16:9（{img.width}×{img.height}），会按比例缩放后居中放置')
    scale = min(WIDTH / img.width, HEIGHT / img.height)
    size = (round(img.width * scale), round(img.height * scale))
    img = img.resize(size, Image.LANCZOS)
    if size == (WIDTH, HEIGHT):
        return img
    canvas = Image.new('RGB', (WIDTH, HEIGHT), 'white')
    canvas.paste(img, ((WIDTH - size[0]) // 2, (HEIGHT - size[1]) // 2))
    return canvas


def main():
    ap = argparse.ArgumentParser(description='课件图片合成 PDF 和 PPTX')
    ap.add_argument('--images', required=True, help='按页码命名的图片文件夹')
    ap.add_argument('--name', required=True, help='输出文件名，不含扩展名')
    ap.add_argument('--out', required=True, help='输出文件夹')
    ap.add_argument('--quality', type=int, default=88, help='JPEG 压缩质量，默认 88')
    a = ap.parse_args()

    images = collect(Path(a.images))
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    pdf_path = out / f'{a.name}.pdf'
    pptx_path = out / f'{a.name}.pptx'
    for p in (pdf_path, pptx_path):
        if p.exists():
            sys.exit(f'已存在同名文件，不覆盖：{p}。请换一个 --name 或 --out。')

    tmp = out / '.slides_tmp'
    tmp.mkdir(exist_ok=True)
    slides = []
    for i, src in enumerate(images, 1):
        jpg = tmp / f'{i:02d}.jpg'
        to_slide_image(src).save(jpg, 'JPEG', quality=a.quality)
        slides.append(jpg)

    first, *rest = [Image.open(p) for p in slides]
    first.save(pdf_path, 'PDF', save_all=True, append_images=rest, resolution=150)

    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank = prs.slide_layouts[6]
    for jpg in slides:
        slide = prs.slides.add_slide(blank)
        slide.shapes.add_picture(str(jpg), 0, 0, prs.slide_width, prs.slide_height)
    prs.save(pptx_path)

    for p in slides:
        p.unlink()
    tmp.rmdir()

    check = Presentation(pptx_path)
    print(f'完成：{len(images)} 页')
    print(f'PDF：{pdf_path}（{pdf_path.stat().st_size / 1e6:.1f} MB）')
    print(f'PPTX：{pptx_path}（{len(check.slides)} 页，{pptx_path.stat().st_size / 1e6:.1f} MB）')


if __name__ == '__main__':
    main()

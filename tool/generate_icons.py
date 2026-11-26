#!/usr/bin/env python3
"""Exporta o SVG da marca nos tamanhos das plataformas.

Requer Python, PyGObject/Rsvg e Pillow (veja docs/DISTRIBUICAO.md).
Não acessa a rede nem altera arquivos de configuração.
"""
import json
from pathlib import Path
import xml.etree.ElementTree as ET

import gi
from PIL import Image

gi.require_version('Rsvg', '2.0')
from gi.repository import Rsvg  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/branding/app_icon.svg'
SVG = SOURCE.read_bytes()


def render(size, *, foreground=False):
    data = SVG
    if foreground:
        tree = ET.fromstring(data)
        for node in list(tree):
            if node.get('id') == 'background':
                tree.remove(node)
        data = ET.tostring(tree)
    handle = Rsvg.Handle.new_from_data(data)
    pixbuf = handle.get_pixbuf()
    mode = 'RGBA' if pixbuf.get_has_alpha() else 'RGB'
    icon = Image.frombytes(mode, (pixbuf.get_width(), pixbuf.get_height()),
                           bytes(pixbuf.get_pixels()), 'raw', mode, pixbuf.get_rowstride())
    return icon.resize((size, size), Image.Resampling.LANCZOS)



def save(path, size, *, foreground=False, opaque=True):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    icon = render(size, foreground=foreground)
    if opaque:
        icon = icon.convert('RGB')
    icon.save(path)


for size in (192, 512):
    save(f'web/icons/Icon-{size}.png', size)
    save(f'web/icons/Icon-maskable-{size}.png', size)
save('web/favicon.png', 32)
save('assets/branding/app_icon_512.png', 512)
save('linux/runner/resources/app_icon.png', 512)

for density, size, foreground_size in [('mdpi', 48, 108), ('hdpi', 72, 162), ('xhdpi', 96, 216), ('xxhdpi', 144, 324), ('xxxhdpi', 192, 432)]:
    directory = f'android/app/src/main/res/mipmap-{density}'
    save(f'{directory}/ic_launcher.png', size)
    save(f'{directory}/ic_launcher_foreground.png', foreground_size, foreground=True, opaque=False)

for platform in ('ios', 'macos'):
    directory = Path(f'{platform}/Runner/Assets.xcassets/AppIcon.appiconset')
    for entry in json.loads((ROOT / directory / 'Contents.json').read_text())['images']:
        if 'filename' not in entry:
            continue
        size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].removesuffix('x')))
        save(directory / entry['filename'], size)

render(1024).save(ROOT / 'windows/runner/resources/app_icon.ico', format='ICO', sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)])
print('Ícones gerados a partir de assets/branding/app_icon.svg.')

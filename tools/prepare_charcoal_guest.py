#!/usr/bin/env python3
"""Deterministically pack the generated guest sheet; no generative edits."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def prepare():
    source = Image.open(ROOT/'art/sources/customer-charcoal-sheet.png').convert('RGBA')
    frames = []
    # Authored transparent row separators keep the first row's shoes out of
    # the next row. The generator's row spacing is slightly uneven.
    rows = [0,330,630,945,1261]
    for i in range(16):
        x, y = i % 4, i // 4
        frame = source.crop((round(x*source.width/4), rows[y],
                             round((x+1)*source.width/4), rows[y+1]))
        frame.putalpha(frame.getchannel('A').point(lambda a: 255 if a >= 160 else 0))
        bounds = frame.getbbox()
        if not bounds:
            raise ValueError(f'Empty charcoal guest frame {i}')
        frames.append(frame.crop(bounds))
    # One scale across all directions/poses prevents animation size pulsing.
    for name, indices, cell, cols, height in [
        ('patrons-charcoal', list(range(16)), (160,192), 4, 180),
        ('street-charcoal', list(range(4)), (96,128), 4, 120),
        ('street-charcoal-depth', list(range(4,12)), (96,128), 4, 120),
    ]:
        scale = min(height/max(f.height for f in frames),
                    (cell[0]-8)/max(f.width for f in frames))
        atlas = Image.new('RGBA', (cols*cell[0], ((len(indices)+cols-1)//cols)*cell[1]))
        for n, index in enumerate(indices):
            frame = frames[index]
            frame = frame.resize((round(frame.width*scale), round(frame.height*scale)),
                                 Image.Resampling.NEAREST)
            atlas.alpha_composite(frame, ((n%cols)*cell[0]+(cell[0]-frame.width)//2,
                                         (n//cols)*cell[1]+cell[1]-4-frame.height))
        atlas.save(ROOT/'assets/art'/f'{name}.png')


if __name__ == '__main__':
    prepare()
    path = ROOT/'assets/art/manifest.json'
    manifest = json.loads(path.read_text())
    for name in ['patrons-charcoal','street-charcoal','street-charcoal-depth']:
        asset = ROOT/'assets/art'/f'{name}.png'
        manifest[name] = {'file':f'res://assets/art/{name}.png',
                          'size':list(Image.open(asset).size),
                          'sha256':hashlib.sha256(asset.read_bytes()).hexdigest()}
    path.write_text(json.dumps(manifest, indent=2)+'\n')

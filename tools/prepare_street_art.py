#!/usr/bin/env python3
"""Pack only outdoor assets, preserving every existing room PNG byte-for-byte."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC, OUT = ROOT/'art/sources', ROOT/'assets/art'
NEAREST = Image.Resampling.NEAREST
STREET_BOX = (40, 40, 204, 475)
TIME_SOURCES = ['street-window-0', 'street-window-1', 'street-daylight-0',
                'street-daylight-1', 'street-daylight-2', 'street-daylight-3',
                'street-window-3', 'street-window-5']


def clean_sprite(image):
    """Remove tiny disconnected alpha specks while retaining wheels and shoes."""
    image = image.convert('RGBA')
    alpha = image.getchannel('A').point(lambda a: 255 if a >= 160 else 0)
    width, height = image.size
    pixels = bytearray(alpha.tobytes())
    seen = bytearray(width*height)
    components = []
    for start, opaque in enumerate(pixels):
        if not opaque or seen[start]:
            continue
        seen[start] = 1
        pending, component = [start], []
        while pending:
            index = pending.pop()
            component.append(index)
            x, y = index % width, index // width
            for neighbor in (index-1 if x else -1, index+1 if x+1<width else -1,
                             index-width if y else -1, index+width if y+1<height else -1):
                if neighbor >= 0 and pixels[neighbor] and not seen[neighbor]:
                    seen[neighbor] = 1
                    pending.append(neighbor)
        components.append(component)
    if not components:
        raise ValueError('Empty outdoor sprite cell')
    cutoff = max(16, max(map(len, components))*.002)
    for component in components:
        if len(component) < cutoff:
            for index in component:
                pixels[index] = 0
    image.putalpha(Image.frombytes('L', image.size, bytes(pixels)))
    return image.crop(image.getbbox())


def atlas(name, rows, cell, height, row_bounds=None):
    source = Image.open(SRC/(name+'.png')).convert('RGBA')
    sheet = Image.new('RGBA', (cell[0]*4, cell[1]*rows))
    for row in range(rows):
        top, bottom = row_bounds[row:row+2] if row_bounds else (
            round(row*source.height/rows), round((row+1)*source.height/rows))
        frames = [clean_sprite(source.crop((round(i*source.width/4),
                  top, round((i+1)*source.width/4), bottom))) for i in range(4)]
        # One scale per identity avoids pulsing bodies between walk phases.
        scale = min(height/max(im.height for im in frames),
                    (cell[0]-8)/max(im.width for im in frames))
        for i, frame in enumerate(frames):
            frame = frame.resize((max(1,round(frame.width*scale)),
                                  max(1,round(frame.height*scale))), NEAREST)
            sheet.alpha_composite(frame, (i*cell[0]+(cell[0]-frame.width)//2,
                                         row*cell[1]+cell[1]-4-frame.height))
    sheet.save(OUT/(name+'.png'))


def prepare():
    OUT.mkdir(parents=True, exist_ok=True)
    for level in range(8):
        Image.open(SRC/f'street-activity-{level}.png').convert('RGB').resize(
            (960,540), NEAREST).save(OUT/f'street-activity-{level}.png')
    for period, name in enumerate(TIME_SOURCES):
        Image.open(SRC/(name+'.png')).convert('RGB').resize((960,540), NEAREST).crop(
            STREET_BOX).save(OUT/f'street-day-{period}.png')
    atlas('street-walkers', 4, (96,128), 120)
    atlas('street-scooters', 2, (192,144), 136)
    atlas('street-cars', 1, (224,112), 100)
    # The native front/rear walker sheet has uneven row spacing. Authored
    # separators preserve every shoe/head before ordinary cell normalization.
    atlas('street-walkers-depth', 8, (96,128), 120,
          [0,254,500,730,964,1173,1374,1574,1774])
    atlas('street-scooters-depth', 4, (192,144), 136)
    atlas('street-cars-depth', 2, (224,112), 100)


if __name__ == '__main__':
    prepare()
    manifest = {}
    for path in sorted(OUT.glob('*.png')):
        image = Image.open(path)
        manifest[path.stem] = {'file':'res://assets/art/'+path.name,
            'size':list(image.size), 'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    (OUT/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('Packed 8 district plates, 8 time-of-day underlays and 6 outdoor atlases')

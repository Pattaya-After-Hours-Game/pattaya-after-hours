#!/usr/bin/env python3
"""Pack and install the eight discoverable staff identities.

Uses the existing art pipeline's alpha cutoff, nearest-neighbour resampling,
foot pivot and four-pixel baseline. No generative image editing.
"""
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / 'art/staff-pack-v1'
PORTRAITS = {
    'staff-copper': (245, 0, 410, 165),
    'staff-platinum': (245, 0, 410, 165),
    'staff-ruby': (250, 0, 415, 165),
    'staff-rose': (245, 0, 410, 165),
    'host-violet': (220, 0, 380, 160),
    'host-goldie': (175, 0, 345, 170),
    'host-scarlet': (175, 0, 345, 170),
    'host-onyx': (195, 0, 375, 180),
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    jobs = json.loads((PACK / 'recipes.json').read_text())['jobs']
    entries = []
    lineup = Image.new('RGBA', (1280, 560), '#171626')
    draw = ImageDraw.Draw(lineup)
    font = ImageFont.truetype(str(ROOT / 'assets/DejaVuSans.ttf'), 18)
    small = ImageFont.truetype(str(ROOT / 'assets/DejaVuSans.ttf'), 12)
    review = Image.new('RGBA', (1040, 8 * 290), '#171626')
    rd = ImageDraw.Draw(review)
    for n, job in enumerate(jobs):
        slug = job['slug']
        bartender = job['role'] == 'bartender'
        cols, rows = (2, 2) if bartender else (3, 2)
        cell = (160, 192 if bartender else 256)
        poses = ['idle', 'walk-a', 'walk-b', 'serve'] if bartender else [
            'idle', 'greeting', 'dance-a', 'dance-b', 'walk-a', 'walk-b']
        source = PACK / 'sources' / f'{slug}.png'
        im = Image.open(source).convert('RGBA')
        im.putalpha(im.getchannel('A').point(lambda a: 0 if a < 160 else 255))
        crops = []
        cuts = []
        for i in range(cols * rows):
            x, y = i % cols, i // cols
            cut = (round(x * im.width / cols), round(y * im.height / rows),
                   round((x + 1) * im.width / cols), round((y + 1) * im.height / rows))
            crop = im.crop(cut)
            bounds = crop.getbbox()
            if not bounds or bounds[0] < 2 or bounds[1] < 2 or bounds[2] > crop.width - 2 or bounds[3] > crop.height - 2:
                raise ValueError(f'{slug} frame {i}: empty or clipped source')
            crops.append(crop.crop(bounds))
            cuts.append(list(cut))
        # One scale for the whole identity prevents pose-dependent size pulses.
        scale = min(180 / max(c.height for c in crops),
                    (cell[0] - 8) / max(c.width for c in crops))
        atlas = Image.new('RGBA', (cell[0] * len(crops), cell[1]))
        frames = []
        for i, crop in enumerate(crops):
            sprite = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.NEAREST)
            feet = sprite.getchannel('A').crop((0, max(0, sprite.height - 12), sprite.width, sprite.height)).getbbox()
            pivot = (feet[0] + feet[2]) / 2 if feet else sprite.width / 2
            px = max(2, min(cell[0] - sprite.width - 2, round(cell[0] / 2 - pivot)))
            tile = Image.new('RGBA', cell)
            tile.alpha_composite(sprite, (px, cell[1] - 4 - sprite.height))
            atlas.alpha_composite(tile, (i * cell[0], 0))
            frames.append(tile)
            bg = '#ece4db' if i % 2 else '#232239'
            review.paste(bg, (10 + i * 170, n * 290 + 24, 170 + i * 170, n * 290 + 280))
            review.alpha_composite(tile, (10 + i * 170, n * 290 + 280 - cell[1]))
            rd.text((16 + i * 170, n * 290 + 30), poses[i], font=small, fill='#9185a2')
        target = PACK / 'atlases' / f'{slug}.png'
        atlas.save(target)
        portrait_path = PACK / 'portraits' / f'{slug}.png'
        im.crop(PORTRAITS[slug]).resize((96, 96), Image.Resampling.NEAREST).save(portrait_path)
        rd.text((12, n * 290 + 2), job['name'] + ' / ' + job['role'], font=font, fill='#ffffff')
        x, y = (n % 4) * 320, (n // 4) * 280
        lineup.alpha_composite(frames[0], (x + 80, y + 238 - cell[1]))
        draw.text((x + 20, y + 240), job['name'], font=font, fill='#f1cadf')
        draw.text((x + 20, y + 264), f"{job['role']} / {len(poses)} poses", font=small, fill='#b5afc9')
        entries.append({
            'id': slug, 'name': job['name'], 'role': job['role'],
            'source': str(source.relative_to(PACK)), 'source_sha256': digest(source),
            'source_grid': [cols, rows], 'source_cuts': cuts,
            'atlas': str(target.relative_to(PACK)), 'sha256': digest(target),
            'cell': list(cell), 'columns': len(poses), 'rows': 1,
            'frames': poses, 'foot_pivot': [80, cell[1] - 4],
            'portrait': str(portrait_path.relative_to(PACK)),
            'portrait_crop': list(PORTRAITS[slug]), 'portrait_sha256': digest(portrait_path),
            'animations': {'idle': [0], 'walk': [1, 2], 'carry': [3], 'serve': [3, 0]} if bartender else {
                'idle': [0], 'carry': [1], 'serve': [1, 0], 'dance': [2, 3], 'walk': [4, 5]},
        })
    (PACK / 'manifest.json').write_text(json.dumps({'status': 'integrated', 'characters': entries}, indent=2) + '\n')
    lineup.convert('RGB').save(PACK / 'lineup.png')
    review.convert('RGB').save(PACK / 'pose-review.png')
    print(f'Packed {len(entries)} characters, {sum(len(e["frames"]) for e in entries)} frames and eight portraits.')
    install()


def install():
    """Install only this collection, preserving every other runtime asset."""
    output = ROOT / 'assets/art'
    manifest_path = output / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    for entry in json.loads((PACK / 'manifest.json').read_text())['characters']:
        for source, name in [(entry['atlas'], entry['id']), (entry['portrait'], 'portrait-' + entry['id'])]:
            target = output / (name + '.png')
            shutil.copy2(PACK / source, target)
            manifest[name] = {'file': 'res://assets/art/' + target.name,
                              'size': list(Image.open(target).size), 'sha256': digest(target)}
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()

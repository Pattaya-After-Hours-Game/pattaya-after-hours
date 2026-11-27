#!/usr/bin/env python3
"""Pack generated customer sheets with authored cuts, fixed scale and foot pivots.

No generation or illustration occurs here. Existing production atlases are never
rewritten. Exact prompts and row/column cuts live in each source receipt.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
NAMES = ['sunfaded-regular', 'silver-polo', 'maroon-casual', 'plum-club',
         'sage-holiday', 'ivory-club', 'cobalt-evening', 'amber-local',
         'beard-glasses', 'navy-tourist', 'teal-dress', 'gold-blouse',
         'capybara', 'rainbow-duo']


def prepare(names=NAMES):
    outputs = []
    for name in names:
        receipt = json.loads((ROOT / f'art/recipes/customer-{name}-motion.json').read_text())
        source = Image.open(ROOT / receipt['source']).convert('RGBA')
        columns = receipt['columns']
        rows = receipt['rows']
        assert len(columns) == len(rows) == 5
        assert columns[0] == rows[0] == 0
        assert columns[-1] == source.width and rows[-1] == source.height
        frames = []
        for index in range(16):
            x, y = index % 4, index // 4
            frame = source.crop((columns[x], rows[y], columns[x+1], rows[y+1]))
            frame.putalpha(frame.getchannel('A').point(lambda a: 255 if a >= 160 else 0))
            box = frame.getbbox()
            if not box:
                raise ValueError(f'Empty customer pose: {name}/{index}')
            # Fail instead of silently shipping a limb cut by a source boundary.
            if box[0] == 0 or box[1] == 0 or box[2] == frame.width or box[3] == frame.height:
                raise ValueError(f'Pose touches authored source cut: {name}/{index}: {box}')
            frames.append(frame.crop(box))
        width = 288 if name == 'rainbow-duo' else 256 if name == 'capybara' else 160
        street_width = 192 if width > 160 else 96
        for asset_id, indices, cell, height in [
            ('customer-motion-'+name, list(range(16)), (width, 192), 180),
            ('street-customer-'+name, list(range(4)), (street_width, 128), 120),
            ('street-customer-'+name+'-depth', list(range(4, 12)), (street_width, 128), 120),
        ]:
            # A shared scale within each authored four-frame cycle preserves
            # gait variation. Normalize row sizes because generated front/side
            # rows can differ by 10%; otherwise turning changes adult height.
            scales = [min(height / max(f.height for f in frames[row*4:row*4+4]),
                          (cell[0]-8) / max(f.width for f in frames[row*4:row*4+4]))
                      for row in range(4)]
            atlas = Image.new('RGBA', (cell[0]*4, cell[1]*((len(indices)+3)//4)))
            for n, index in enumerate(indices):
                frame = frames[index]
                scale = scales[index//4]
                frame = frame.resize((max(1, round(frame.width*scale)),
                                      max(1, round(frame.height*scale))), Image.Resampling.NEAREST)
                # Human foot pivot for the capybara's wide composed silhouette.
                # Other sheets use the centre of their supporting feet.
                foot = frame.getchannel('A').crop((0, max(0, frame.height-10), frame.width, frame.height)).getbbox()
                pivot = frame.width*.26 if name == 'capybara' else (foot[0]+foot[2])/2 if foot else frame.width/2
                left = max(4, min(cell[0]-frame.width-4, round(cell[0]/2-pivot)))
                atlas.alpha_composite(frame, ((n%4)*cell[0]+left,
                                             (n//4)*cell[1]+cell[1]-4-frame.height))
            destination = ROOT / f'assets/art/{asset_id}.png'
            atlas.save(destination)
            outputs.append(destination)
    return outputs


def update_manifest(outputs):
    path = ROOT / 'assets/art/manifest.json'
    manifest = json.loads(path.read_text())
    for asset in outputs:
        manifest[asset.stem] = {'file': f'res://assets/art/{asset.name}',
                                'size': list(Image.open(asset).size),
                                'sha256': hashlib.sha256(asset.read_bytes()).hexdigest()}
    path.write_text(json.dumps(manifest, indent=2)+'\n')


if __name__ == '__main__':
    packed = prepare()
    update_manifest(packed)
    print(f'Prepared {len(packed)} customer motion atlases')

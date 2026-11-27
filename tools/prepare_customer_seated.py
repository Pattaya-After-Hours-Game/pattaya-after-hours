#!/usr/bin/env python3
"""Deterministic packing of reference-generated seated / TV-watching poses."""
import json
from PIL import Image
from prepare_customer_motion import ROOT, NAMES, update_manifest


def prepare(names=None):
    outputs = []
    for name in names if names is not None else NAMES+['charcoal']:
        recipe = json.loads((ROOT/f'art/recipes/customer-{name}-seated.json').read_text())
        source = Image.open(ROOT/recipe['source']).convert('RGBA')
        columns, rows = recipe['columns'], recipe['rows']
        assert len(columns) == len(rows) == 3
        assert columns[0] == rows[0] == 0
        assert columns[-1] == source.width and rows[-1] == source.height
        frames = []
        for index in range(4):
            x, y = index % 2, index // 2
            frame = source.crop((columns[x],rows[y],columns[x+1],rows[y+1]))
            frame.putalpha(frame.getchannel('A').point(lambda a: 255 if a >= 160 else 0))
            box = frame.getbbox()
            if not box or box[0] == 0 or box[1] == 0 or box[2] == frame.width or box[3] == frame.height:
                raise ValueError(f'Empty/clipped seated pose: {name}/{index}: {box}')
            frames.append(frame.crop(box))
        cell = (288 if name == 'rainbow-duo' else 256 if name == 'capybara' else 160,192)
        atlas = Image.new('RGBA',(cell[0]*4,cell[1]))
        # Seated adults stay shorter than standing; never enlarge a bent body
        # into a full-height adult. The first three poses share one scale.
        seated_scale = min(140/max(f.height for f in frames[:3]),
                           (cell[0]-8)/max(f.width for f in frames[:3]))
        for index, frame in enumerate(frames):
            scale = seated_scale if index < 3 else min(180/frame.height,(cell[0]-8)/frame.width)
            frame = frame.resize((max(1,round(frame.width*scale)),max(1,round(frame.height*scale))),Image.Resampling.NEAREST)
            # Align the torso over its chair cushion. The capybara stays beside
            # its owner rather than displacing his seat to the group centre.
            pivot = frame.width*(.23 if name=='capybara' else .36 if name=='rainbow-duo' else .3) if index<3 else frame.width*(.26 if name=='capybara' else .5)
            left = max(4,min(cell[0]-frame.width-4,round(cell[0]/2-pivot)))
            atlas.alpha_composite(frame,(index*cell[0]+left,cell[1]-4-frame.height))
        path = ROOT/f'assets/art/customer-seated-{name}.png'
        atlas.save(path)
        outputs.append(path)
    return outputs


if __name__=='__main__':
    paths = prepare()
    update_manifest(paths)
    print(f'Prepared {len(paths)} seated/watching atlases')

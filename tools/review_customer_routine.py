#!/usr/bin/env python3
"""Review seated alpha edges and assemble actual Godot routine captures."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw
from prepare_customer_motion import ROOT, NAMES

out = Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/pattaya-routine-review')
captures = Path(sys.argv[2]) if len(sys.argv)>2 else None
out.mkdir(parents=True,exist_ok=True)
for name in NAMES+['charcoal']:
    atlas = Image.open(ROOT/f'assets/art/customer-seated-{name}.png').convert('RGBA')
    edges = Image.new('RGB',(atlas.width,atlas.height*2),'#241820')
    for light in range(2):
        tile = Image.new('RGBA',atlas.size,'#eee9df' if light else '#241820')
        tile.alpha_composite(atlas)
        edges.paste(tile.convert('RGB'),(0,light*atlas.height))
    edges.save(out/f'{name}-seated-edges.png')

if captures:
    board = Image.new('RGB',(960,580),'#241820')
    draw = ImageDraw.Draw(board)
    for i,state in enumerate(['counter','seated','mingle','watch']):
        shot = Image.open(captures/f'routine-0-1-{state}.png').convert('RGB')
        shot.resize((480,270)).save(out/f'{state}.png')
        x,y = i%2*480,i//2*290
        board.paste(shot.resize((480,270)),(x,y+20))
        draw.text((x+10,y+5),{'counter':'Get a drink','seated':'Take a seat','mingle':'Mingle','watch':'Watch the game'}[state],fill='#ffd083')
    board.save(out/'customer-routines.png')
    frames = []
    # Preserve native preview frames; a short display sampling is for sharing.
    for prefix in ['routine-arrival','routine-pool']:
        frames.extend(Image.open(p).convert('RGB') for p in sorted(captures.glob(prefix+'-*.png'))[::2])
    durations = [250]*len(frames)
    for state in ['seated','mingle','watch']:
        frames.append(Image.open(captures/f'routine-0-1-{state}.png').convert('RGB'))
        durations.append(1600)
    if frames:
        # Share one palette so the unchanged production room stays bit-identical
        # between frames. Crop only the documentation clip, never runtime art.
        frames = [frame.crop((190,185,900,420)) for frame in frames]
        palette = frames[0].quantize(colors=256,dither=Image.Dither.NONE)
        frames = [frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
        frames[0].save(out/'customer-routines.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=True)
print(out)

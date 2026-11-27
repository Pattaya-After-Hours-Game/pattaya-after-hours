#!/usr/bin/env python3
"""Review named customer poses and assemble frame-by-frame Godot captures."""
import argparse
import json
from pathlib import Path
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('output',type=Path)
parser.add_argument('--captures',type=Path)
args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=True)
catalog=json.loads((ROOT/'assets/art/customer-characters.json').read_text())
board=Image.new('RGB',(1440,5*324),'#241820')
for n,(name,definition) in enumerate(catalog.items()):
    atlas=Image.open(ROOT/f"assets/art/{definition['atlas']}.png").convert('RGBA')
    w,h=definition['cell']
    for i,state in enumerate(['beer_walk','beer_seated_idle','beer_seated_drinking','beer_stand']):
        index=definition['animations'][state][0]
        tile=atlas.crop((index%4*w,index//4*h,(index%4+1)*w,(index//4+1)*h))
        tile.thumbnail((232,144),Image.Resampling.NEAREST)
        x=n%3*480+i%2*240;y=n//3*324+24+i//2*148
        board.paste(tile,(x+(240-tile.width)//2,y),tile)
    ImageDraw.Draw(board).text((n%3*480+8,n//3*324+7),name,fill='#ffd083')
    for light,color in [('dark','#241820'),('light','#eee9df')]:
        edge=Image.new('RGBA',atlas.size,color);edge.alpha_composite(atlas)
        edge.convert('RGB').save(args.output/f'{name}-{light}.png')
board.save(args.output/'beer-cast.png')
if args.captures:
    paths=sorted(args.captures.glob('serve-return-*.png'))
    if paths:
        crop=(190,186,900,420)
        with Image.open(paths[0]) as source:
            palette=source.crop(crop).convert('RGB').quantize(colors=256,dither=Image.Dither.NONE)
        frames=[]
        for path in paths[::2]:
            with Image.open(path) as source:
                frames.append(source.crop(crop).convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE))
        frames[0].save(args.output/'customer-return.gif',save_all=True,append_images=frames[1:],duration=67,loop=0,optimize=True)
print(args.output)

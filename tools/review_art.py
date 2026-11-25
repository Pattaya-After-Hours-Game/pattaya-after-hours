#!/usr/bin/env python3
"""Build local review sheets and animation strips from the shipped atlases."""
import json,sys
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/pattaya-art-review')
out.mkdir(parents=True,exist_ok=True)
for name,spec in json.loads((ROOT/'art/packing.json').read_text()).items():
    atlas=Image.open(ROOT/'assets/art'/f'{name}.png').convert('RGBA')
    w,h=spec['cell'];count=len(spec['frames']);columns=min(6,count)
    sheet=Image.new('RGB',(w*columns,(h+20)*((count+columns-1)//columns)*2),'#211621')
    for n in range(count):
        frame=atlas.crop((n*w,0,(n+1)*w,h))
        for light in range(2):
            x=n%columns*w;y=(n//columns+light*((count+columns-1)//columns))*(h+20)
            tile=Image.new('RGBA',(w,h),'#eee9df' if light else '#211621')
            tile.alpha_composite(frame);sheet.paste(tile.convert('RGB'),(x,y))
            ImageDraw.Draw(sheet).text((x+4,y+h+3),f'{name} / {n}',fill='white')
    sheet.save(out/f'{name}-edges.png')
    # A filmstrip is also produced; timing in the engine remains authoritative.
    if name.startswith('fight-'): states={'walk':[1,2],'attack':[0,5,6,5,0,5,7,5,0,5,8,5,0]}
    elif name in ['bee','may','june','lek','fah','nan']: states={'dance':[2,3],'walk':[4,5]}
    elif name=='monster': states={'encounter':[0,1,2,1,2,3]}
    else: states={'walk':[1,2],'service':[0,3,0]}
    for state,indices in states.items():
        frames=[]
        for i in indices:
            tile=Image.new('RGBA',(w,h),'#382437');tile.alpha_composite(atlas.crop((i*w,0,(i+1)*w,h)));frames.append(tile.convert('RGB'))
        frames[0].save(out/f'{name}-{state}.gif',save_all=True,append_images=frames[1:],duration=180,loop=0)
print(out)

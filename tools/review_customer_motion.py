#!/usr/bin/env python3
"""Review committed customer atlases without modifying generated artwork."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from prepare_customer_motion import ROOT, NAMES

out = Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/pattaya-customer-review')
out.mkdir(parents=True, exist_ok=True)
font = ImageFont.truetype(str(ROOT/'assets/DejaVuSans.ttf'), 13)
identities = NAMES+['charcoal']
frames = []
for name in identities:
    path = ROOT / ('assets/art/patrons-charcoal.png' if name=='charcoal' else f'assets/art/customer-motion-{name}.png')
    if not path.exists(): continue
    atlas = Image.open(path).convert('RGBA')
    width, height = atlas.width//4, atlas.height//4
    # Full sheet over light and dark backgrounds exposes alpha halos and cuts.
    edges = Image.new('RGB', (atlas.width*2, atlas.height), '#241820')
    for light in range(2):
        tile = Image.new('RGBA', atlas.size, '#eee9df' if light else '#241820')
        tile.alpha_composite(atlas)
        edges.paste(tile.convert('RGB'), (atlas.width*light,0))
    edges.save(out/f'{name}-edges.png')

for index in range(24):
    direction = index//8
    frame = index%4 + direction*4
    sheet = Image.new('RGBA', (960,720), '#241820')
    draw = ImageDraw.Draw(sheet)
    for i,name in enumerate(identities):
        path = ROOT / ('assets/art/patrons-charcoal.png' if name=='charcoal' else f'assets/art/customer-motion-{name}.png')
        if not path.exists(): continue
        atlas = Image.open(path).convert('RGBA')
        w,h = atlas.width//4,atlas.height//4
        sprite = atlas.crop((frame%4*w, frame//4*h, (frame%4+1)*w, (frame//4+1)*h))
        sprite.thumbnail((184,192), Image.Resampling.NEAREST)
        x,y = (i%5)*192,(i//5)*230
        sheet.alpha_composite(sprite, (x+(192-sprite.width)//2,y+32+192-sprite.height))
        draw.text((x+96,y+229),name.replace('-',' ').title(),font=font,anchor='ms',fill='#f7dec4')
    draw.text((12,8), ['SIDE WALK','APPROACH','WALK AWAY'][direction]+' / CUSTOMER CAST',font=font,fill='#ffd083')
    frames.append(sheet.convert('RGB'))
frames[0].save(out/'customer-walks.gif',save_all=True,append_images=frames[1:],duration=140,loop=0)
frames[0].save(out/'customer-walks.png')
print(out)

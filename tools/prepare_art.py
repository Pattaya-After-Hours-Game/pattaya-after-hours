#!/usr/bin/env python3
"""Deterministic packing of generated artwork; no generative image editing.
Run from any directory. Sources, crop recipes and receipts live in art/.
"""
import hashlib, json, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
ROOT = Path(__file__).resolve().parents[1]
SRC, OUT = ROOT/'art/sources', ROOT/'assets/art'
OUT.mkdir(parents=True, exist_ok=True)
NEAREST = Image.Resampling.NEAREST
required=[f'{kind}-{stage}' for kind in ['beer','soi','gogo'] for stage in range(1,4)]
required+=['district','toybox','counter','event-inspection','icon','anong-walk-reference','core-cast-reference','support-cast-reference']
missing_plates=[name for name in required if not (SRC/(name+'.png')).exists()]
if missing_plates and '--partial' not in sys.argv:
    raise SystemExit('Missing source artwork: '+', '.join(missing_plates))

def normalize(im, cell=(128,192), height=180, foot_pivot=True, foot_x_fraction=None):
    im=im.convert('RGBA')
    # Remove near-transparent fringes before measuring the silhouette.
    im.putalpha(im.getchannel('A').point(lambda a: 0 if a < 160 else 255))
    bounds=im.getbbox()
    if not bounds: raise ValueError('Empty sprite')
    im=im.crop(bounds)
    scale=min((cell[0]-8)/im.width, height/im.height)
    im=im.resize((max(1,round(im.width*scale)),max(1,round(im.height*scale))),NEAREST)
    tile=Image.new('RGBA',cell)
    # Anchor the feet rather than the full silhouette (a tray/punch extends it).
    foot_region=im.getchannel('A').crop((0,max(0,im.height-12),im.width,im.height)).getbbox()
    foot_x=(foot_region[0]+foot_region[2])/2 if foot_region and foot_pivot else im.width/2
    if foot_x_fraction is not None: foot_x=im.width*foot_x_fraction
    paste_x=round(cell[0]/2-foot_x)
    # Never crop extended limbs: packer selects sufficiently wide cells.
    paste_x=max(2,min(cell[0]-im.width-2,paste_x))
    tile.alpha_composite(im,(paste_x,cell[1]-4-im.height))
    return tile

def grid(source, name, cols, rows, cell=(128,192), height=180):
    im=Image.open(SRC/source).convert('RGBA')
    atlas=Image.new('RGBA',(cell[0]*cols,cell[1]*rows))
    for y in range(rows):
        for x in range(cols):
            crop=im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows)))
            atlas.alpha_composite(normalize(crop,cell,height),(x*cell[0],y*cell[1]))
    atlas.save(OUT/(name+'.png'))

for kind in ['beer','soi','gogo']:
    for stage in range(1,4):
        p=SRC/f'{kind}-{stage}.png'
        if p.exists(): Image.open(p).convert('RGB').resize((960,540),NEAREST).save(OUT/p.name)
for name in ['district','toybox','street']:
    p=SRC/(name+'.png')
    if p.exists(): Image.open(p).convert('RGB').resize((960,540),NEAREST).save(OUT/p.name)
grid('anong-walk-reference.png','anong-walk',4,4)
# Portrait bounds are deliberately authored, not inferred from a nominal grid.
im=Image.open(SRC/'core-cast-reference.png')
for name,box in zip(['anong','dao','mali','fern'],[(116,90,332,264),(476,90,695,264),(837,90,1061,264),(1201,90,1420,264)]):
    im.crop(box).resize((96,96),NEAREST).save(OUT/f'portrait-{name}.png')
im=Image.open(SRC/'support-cast-reference.png')
for name,box in zip(['nok','jin','pim'],[(163,90,404,270),(646,90,888,270),(1132,90,1373,270)]):
    im.crop(box).resize((96,96),NEAREST).save(OUT/f'portrait-{name}.png')
recipe=ROOT/'art/packing.json'
# Generation job manifests are also the packing inventory. Incomplete groups are
# allowed only during the art pass; final preparation fails closed.
groups={}
missing=[]
for filename in ['service-jobs.json','remaining-jobs.json','extra-jobs.json','locomotion-jobs.json','frontage-jobs.json','customer-jobs.json','nida-jobs.json','customer-capybara.json']:
    for job in json.loads((ROOT/'art/recipes'/filename).read_text()):
        if not (SRC/(job['id']+'.png')).exists(): missing.append(job['id'])
        if 'group' in job: groups.setdefault(job['group'],[]).append(job['id']+'.png')
if missing and '--partial' not in sys.argv:
    raise SystemExit('Missing source poses: '+', '.join(missing))
# Split the generated equal 2x2 Gabby sheet before the ordinary pose packer.
gabby=Image.open(SRC/'gabby-sheet.png').convert('RGBA')
for i in range(4):
    x,y=i%2,i//2
    gabby.crop((round(x*gabby.width/2),round(y*gabby.height/2),round((x+1)*gabby.width/2),round((y+1)*gabby.height/2))).save(SRC/f'gabby-{i}.png')
groups['gabby']=[f'gabby-{i}.png' for i in range(4)]
packing={}
for kind in ['beer','soi','gogo']:
    for stage in range(1,4):
        name=f'frontage-{kind}-{stage}'
        if (SRC/(name+'.png')).exists():
            normalize(Image.open(SRC/(name+'.png')),(320,256),248).save(OUT/(name+'.png'))
for name,frames in groups.items():
    if not all((SRC/f).exists() for f in frames): continue
    spec={'frames':frames,'cell':[160,192],'height':180}
    if name in ['bee','may','june','lek','fah','nan']:
        spec.update(cell=[160,256],frame_heights=[180,180,196,196,180,180])
    if name.startswith('fight-'):
        spec.update(cell=[320,256],height=200,frame_heights=[200,200,200,160,185,185,200,190,185,195,52,235])
    if name=='monster': spec.update(cell=[320,320],height=290,frame_heights=[290,290,290,210])
    if name=='patrons-capybara': spec.update(cell=[224,192],foot_x_fraction=0.26)
    packing[name]=spec
normalize(Image.open(SRC/'compact-bench.png'),(240,128),120,False).save(OUT/'compact-bench.png')
Image.open(SRC/'portrait-nida.png').convert('RGBA').resize((96,96),NEAREST).save(OUT/'portrait-nida.png')
recipe.write_text(json.dumps(packing,indent=2)+'\n')
# Transparent foreground props retain their own aspect ratios.
for name,target in [('counter',(800,236)),('event-inspection',(160,192))]:
    if (SRC/(name+'.png')).exists():
        im=Image.open(SRC/(name+'.png')).convert('RGBA')
        im.putalpha(im.getchannel('A').point(lambda a: 0 if a<160 else 255))
        if name=='counter': im=im.crop(im.getbbox()).resize(target,NEAREST)
        else: im=normalize(im,target,180)
        im.save(OUT/(name+'.png'))
if (SRC/'icon.png').exists():
    emblem=Image.open(SRC/'icon.png').convert('RGBA')
    emblem.putalpha(emblem.getchannel('A').point(lambda a: 0 if a<100 else 255))
    emblem=emblem.resize((432,432),NEAREST)
    emblem.save(OUT/'adaptive-foreground.png')
    bg=Image.new('RGBA',(432,432),'#231529')
    bg.save(OUT/'adaptive-background.png')
    bg.alpha_composite(emblem)
    bg.resize((192,192),NEAREST).save(OUT/'icon.png')
if recipe.exists():
    for name,spec in json.loads(recipe.read_text()).items():
        cell=tuple(spec.get('cell',[128,192]))
        if 'grid' in spec:
            grid(spec['source'],name,*spec['grid'],cell=cell,height=spec.get('height',180))
        else:
            frames=[]
            for index,path in enumerate(spec['frames']):
                height=spec.get('frame_heights',[spec.get('height',180)]*len(spec['frames']))[index]
                frames.append(normalize(Image.open(SRC/path),cell,height,not (name.startswith('fight-') and index==10),spec.get('foot_x_fraction')))
            atlas=Image.new('RGBA',(cell[0]*len(frames),cell[1]))
            for i,frame in enumerate(frames): atlas.alpha_composite(frame,(i*cell[0],0))
            atlas.save(OUT/(name+'.png'))
        if name in ['bee','may','june','lek','fah','nan','fight-juno','fight-vega','fight-orchid']:
            original=Image.open(SRC/spec['frames'][0]).convert('RGBA')
            alpha=original.getchannel('A').point(lambda a:255 if a>=160 else 0)
            bbox=alpha.getbbox()
            original=original.crop(bbox)
            head=original.crop((original.width*.15,0,original.width*.85,original.height*.32))
            portrait=Image.new('RGBA',(96,96),'#2c192b')
            head.thumbnail((88,92),NEAREST)
            portrait.alpha_composite(head,((96-head.width)//2,96-head.height))
            portrait.convert('RGB').save(OUT/('portrait-'+name.removeprefix('fight-')+'.png'))
# A fixed head-and-shoulders crop from Gabby's idle cell, on the portrait palette.
gabby=Image.open(SRC/'gabby-sheet.png').convert('RGBA')
head=gabby.crop((225,0,378,153))
head.thumbnail((88,88),NEAREST)
portrait=Image.new('RGBA',(96,96),'#2c192b')
portrait.alpha_composite(head,((96-head.width)//2,96-head.height))
portrait.convert('RGB').save(OUT/'portrait-gabby.png')
# Ownership patches use generated fan-free walls, cropped only at the fan.
# Original venue plates remain byte-for-byte unchanged.
fan_recipe=json.loads((ROOT/'art/recipes/fan-ownership.json').read_text())
for item in fan_recipe['assets']:
    source=SRC/(item['id']+'.png')
    if not source.exists():
        if '--partial' in sys.argv: continue
        raise SystemExit('Missing fan artwork: '+str(source))
    im=Image.open(source).convert('RGBA')
    if 'crop' in item:
        x,y,w,h=item['crop']
        im=im.resize((960,540),NEAREST).crop((x,y,x+w,y+h))
        # Package only the removed fixture's footprint, keeping surrounding
        # boards from the untouched plate and softening the join by one pixel.
        mask=Image.new('L',(w,h))
        pen=ImageDraw.Draw(mask)
        pen.ellipse(tuple(item['mask_ellipse']),fill=255)
        pen.rounded_rectangle(tuple(item['mask_mount']),radius=3,fill=255)
        mask=mask.filter(ImageFilter.GaussianBlur(item['mask_feather']))
        im.putalpha(mask)
    else:
        im.putalpha(im.getchannel('A').point(lambda a: 0 if a<160 else 255))
        im=im.crop(im.getbbox())
        im.thumbnail(tuple(item['output_size']),NEAREST)
        canvas=Image.new('RGBA',tuple(item['output_size']))
        canvas.alpha_composite(im,((canvas.width-im.width)//2,0))
        im=canvas
    im.save(OUT/(item['id']+'.png'))
manifest={}
for p in sorted(OUT.glob('*.png')):
    im=Image.open(p)
    manifest[p.stem]={'file':'res://assets/art/'+p.name,'size':list(im.size),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Prepared {len(manifest)} assets')

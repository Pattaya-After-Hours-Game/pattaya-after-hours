#!/usr/bin/env python3
"""Build individual customer atlases from named-pose definitions.

Only the selected character's PNG is rebuilt. Adding a source/pose never requires
regenerating approved artwork, and the catalog refresh does not repack others.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
DEFINITIONS=ROOT/'art/characters'
RUNTIME=ROOT/'assets/art/customer-characters.json'


def clean_frames(recipe_path):
    recipe=json.loads((ROOT/recipe_path).read_text())
    source=Image.open(ROOT/recipe['source']).convert('RGBA')
    columns,rows=recipe['columns'],recipe['rows']
    assert columns[0]==rows[0]==0 and columns[-1]==source.width and rows[-1]==source.height
    frames=[]
    for y in range(len(rows)-1):
        for x in range(len(columns)-1):
            frame=source.crop((columns[x],rows[y],columns[x+1],rows[y+1]))
            frame.putalpha(frame.getchannel('A').point(lambda a: 255 if a>=160 else 0))
            box=frame.getbbox()
            if not box or 0 in box[:2] or box[2]==frame.width or box[3]==frame.height:
                raise ValueError(f'Empty/clipped source: {recipe_path}/{len(frames)}: {box}')
            frames.append(frame.crop(box))
    return frames


def source_frames(group,cell,name):
    if group['kind']=='atlas':
        image=Image.open(ROOT/group['path']).convert('RGBA')
        width,height=group['cell'];cols=image.width//width
        indices=group.get('indices',list(range(group.get('count',image.width//width*(image.height//height)))))
        frames=[]
        for i in indices:
            frame=image.crop((i%cols*width,i//cols*height,(i%cols+1)*width,(i//cols+1)*height))
            tile=Image.new('RGBA',cell)
            if frame.width>cell[0] or frame.height>cell[1]: raise ValueError('Atlas cell cannot shrink approved art')
            tile.alpha_composite(frame,((cell[0]-width)//2,cell[1]-height))
            frames.append(tile)
        return frames
    if group['kind']!='generated': raise ValueError('Unsupported source kind')
    frames=clean_frames(group['recipe'])
    heights=group.get('heights',[180]*len(frames))
    if len(heights)!=len(frames): raise ValueError('One body height is required per generated pose')
    # Direction cycles share scale. Other poses share their prescribed body
    # height; seated adults remain shorter than standing adults.
    cycles=group.get('scale_groups',[[i] for i in range(len(frames))])
    scale_for={}
    for indices in cycles:
        if not indices or any(i<0 or i>=len(frames) for i in indices): raise ValueError('Invalid scale group')
        if len({heights[i] for i in indices})!=1: raise ValueError('Scale groups must share body height')
        scale=min(heights[indices[0]]/max(frames[i].height for i in indices),(cell[0]-8)/max(frames[i].width for i in indices))
        for index in indices:
            if index in scale_for: raise ValueError('Duplicate frame in scale groups')
            scale_for[index]=scale
    if len(scale_for)!=len(frames): raise ValueError('Scale groups must cover each frame')
    tiles=[]
    for i,frame in enumerate(frames):
        scale=scale_for[i]
        frame=frame.resize((max(1,round(frame.width*scale)),max(1,round(frame.height*scale))),Image.Resampling.NEAREST)
        seated=heights[i]<180
        if seated:
            pivot=frame.width*(.23 if name=='capybara' else .36 if name=='rainbow-duo' else .3)
        elif name=='capybara': pivot=frame.width*.26
        else:
            feet=frame.getchannel('A').crop((0,max(0,frame.height-10),frame.width,frame.height)).getbbox()
            pivot=(feet[0]+feet[2])/2 if feet else frame.width*.5
        left=max(4,min(cell[0]-frame.width-4,round(cell[0]/2-pivot)))
        tile=Image.new('RGBA',cell)
        tile.alpha_composite(frame,(left,cell[1]-4-frame.height))
        tiles.append(tile)
    return tiles


def metadata(definition):
    animations={};offset=0
    for group in definition['sources']:
        if group['kind']=='atlas': count=len(group['indices']) if 'indices' in group else int(group['count'])
        else:
            count=len(group['heights']) if 'heights' in group else int(group['count'])
        for state,indices in group['animations'].items():
            if state in animations or not indices or any(i<0 or i>=count for i in indices): raise ValueError('Invalid/duplicate named pose: '+state)
            animations[state]=[offset+i for i in indices]
        offset+=count
    for state,target in definition.get('fallbacks',{}).items():
        if state not in animations: animations[state]=animations.get(target,animations['idle'])
    return {'atlas':definition['atlas'],'cell':definition['cell'],'frames':math.ceil(offset/4)*4,'seat_span':int(definition.get('seat_span',1)),'animations':animations}


def prepare_character(name):
    definition=json.loads((DEFINITIONS/(name+'.json')).read_text())
    cell=tuple(definition['cell']);frames=[]
    for group in definition['sources']: frames.extend(source_frames(group,cell,name))
    spec=metadata(definition)
    atlas=Image.new('RGBA',(4*cell[0],spec['frames']//4*cell[1]))
    if max(atlas.size)>4096: raise ValueError('Customer atlas exceeds mobile texture limits')
    while len(frames)<spec['frames']: frames.append(frames[spec['animations']['idle'][0]].copy())
    for index,frame in enumerate(frames): atlas.alpha_composite(frame,(index%4*cell[0],index//4*cell[1]))
    path=ROOT/f"assets/art/{definition['atlas']}.png"
    atlas.save(path)
    manifest_path=ROOT/'assets/art/manifest.json'
    manifest=json.loads(manifest_path.read_text())
    manifest[definition['atlas']]={'file':'res://assets/art/'+path.name,'size':list(atlas.size),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
    return path


def write_catalog():
    catalog={}
    for path in sorted(DEFINITIONS.glob('*.json')):
        definition=json.loads(path.read_text())
        catalog[definition['id']]=metadata(definition)
    RUNTIME.write_text(json.dumps(catalog,indent=2)+'\n')


def prepare(names=None):
    if names is None: names=[p.stem for p in sorted(DEFINITIONS.glob('*.json'))]
    paths=[prepare_character(name) for name in names]
    write_catalog()
    return paths


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--character',action='append',help='Build only this definition; repeat for selected characters')
    parser.add_argument('--all',action='store_true',help='Rebuild every defined customer, e.g. after adding a shared pose')
    args=parser.parse_args()
    if not args.character and not args.all: parser.error('Choose --character NAME or --all')
    paths=prepare(None if args.all else args.character)
    print(f'Prepared {len(paths)} independent customer atlas(es)')

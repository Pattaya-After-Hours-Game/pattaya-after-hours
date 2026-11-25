# Blue Hour production art

This directory contains authoring material only. `.gdignore` and the export
presets keep it out of the game. Runtime PNGs are in `assets/art/`; there are no
concept-board textures in the runtime catalog.

## Provenance

Artwork was generated with the built-in image-generation tool in this Codex
session on 25 November 2026, using the project's generated Blue Hour and cast
references. Exact prompts and returned source paths are saved in `recipes/`.
The tool does not expose its model version or random seed; those values are not
invented. `references/` contains the selected environment concept; cast and
walking reference images are retained in `sources/`. Reference paths in receipts
record their original locations. No ComfyUI server or external generation
service was used.

`service-jobs.json`, `remaining-jobs.json`, `extra-jobs.json`, and
`locomotion-jobs.json` define the source inventory. Each production pose is an
individual generated image, except Anong's previously generated four-direction
walking reference, whose 16 frames are extracted with fixed cell boundaries.
`*-refinement.json` records replacements of a first iteration. Superseded local
renders belong in ignored `rejected/`, never `assets/art/`.

The asset-preparation guidance from `references/art_agents.md` informed the
pipeline: consistent references, individual poses, real alpha, deliberate
normalization, fixed pivots, engine-authored lettering, and in-engine review.
All characters are adults. Host costumes use covered bikinis; private activity
remains off-screen.

## Rebuild

Install Pillow in the development Python environment, then run:

```sh
python3 tools/prepare_art.py
```

The packer refuses missing source poses. `--partial` is only for intermediate
art work. It preserves aspect ratio for character silhouettes, removes alpha
below 160, uses nearest-neighbor resizing, and anchors each sprite at the centre
of its supporting feet, four pixels above the bottom of its atlas cell. Extended
limbs retain padding. Raised arms, jumps, and floor poses use explicit heights in
the recipe rather than resizing every silhouette to the same height.

Environment plates are 960 × 540. The foreground bar and inspection character
are independent transparent layers. Exact signs, text, values, and controls are
rendered by Godot. Ambient light, fan blades, weather, water, confetti, attack
trails, and impact particles remain engine effects.

`packing.json` records the final source-frame order and cell dimensions.
`assets/art/manifest.json` records resource paths, dimensions and SHA-256 hashes.
The largest atlas fits within 4096 pixels on either axis. Regeneration from a
prompt is not deterministic; packing the committed sources is deterministic.

## Engine mapping

`scripts/art.gd` owns texture lookup, venue stages, identities, semantic animation
states, atlas bounds and event identifiers. City staff availability comes from
the existing campaign state. Gogo stages use one, two or three pole positions;
remaining hosts work the floor. The foreground counter occludes Anong's legs.

Fight simulation coordinates and attack durations remain unchanged. Presentation
maps the simulation into the 960 × 540 scene, selecting anticipation, contact and
recovery poses from the existing timers. UI hit regions use the same displayed
rectangles and transforms. Idle breathing and light animation are independent of
simulation ticks.

## Review

```sh
tools/test.sh
tools/preview-art.sh /tmp/pattaya-art-preview
python3 tools/review_art.py /tmp/pattaya-art-review
```

The preview runner isolates saves. Review edge sheets on both backgrounds,
compare each character's silhouette across poses, and inspect in-engine playback
for foot sliding, clipping, stage alignment and contact timing. Review all venue
stages and event states at 960 × 540 before checking a larger landscape window.
Target-device playtesting is separate from successful desktop/Android exports.

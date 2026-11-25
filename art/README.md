# Blue Hour production art

This directory contains authoring material only. `.gdignore` and the export
presets keep it out of the game. Runtime PNGs are in `assets/art/`; there are no
concept-board textures in the runtime catalog.

Nida has four production poses (idle, wave, indicate entrance, acknowledge) and
a portrait, with [source receipts](recipes/nida-jobs.json). Her earlier
[frontage concept](concepts/promoter-frontage-v1.png) stays authoring-only. The
[compact bench receipt](recipes/compact-bench.json) records the new seating prop.
Existing room plates and cast artwork remain unchanged. Nida appears at the
entrance only while contracted, scheduled on and trading; benches appear only
for purchased level-three beer-bar seating.

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
`locomotion-jobs.json`, `frontage-jobs.json`, and `nida-jobs.json` define the source inventory. Each production pose is an
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
of its supporting feet, four pixels above the bottom of its atlas cell. Floor-level
KO poses use the full silhouette centre instead. Extended limbs retain padding. Raised arms, jumps, and floor poses use explicit heights in
the recipe rather than resizing every silhouette to the same height.

Environment plates are 960 × 540. The foreground bar and inspection character
are independent transparent layers. Exact signs, text, values, and controls are
rendered by Godot. Ambient light, fan blades, weather, water, confetti, attack
trails, and impact particles remain engine effects.

Nine transparent 320 × 256 frontage illustrations appear in Empire property
cards. The compact selector uses matching interior thumbnails for quick recognition.

`packing.json` records the final source-frame order and cell dimensions.
`assets/art/manifest.json` records resource paths, dimensions and SHA-256 hashes.
The largest atlas fits within 4096 pixels on either axis. Regeneration from a
prompt is not deterministic; packing the committed sources is deterministic.

## Engine mapping

`scripts/art.gd` owns texture lookup, venue stages, identities, semantic animation
states, atlas bounds and event identifiers. City staff availability comes from
the existing campaign state. Gogo stages use one, two or three pole positions;
remaining hosts work the floor. Interior adults share a floor-depth scale, including Anong and the inspector.
The foreground counter occludes Anong's legs; crops of the original venue plate
occlude bartenders behind the illustrated counters. Customers and pool tables
are drawn in floor-depth order, with waiting-order dots above customer heads.
Both pool tables stay indoors. Street traffic follows the visible outside lane,
cycling through the three distinct existing patron appearances on successive
crossings, alternating direction and leaving a short gap. Each appearance stays
fixed throughout its crossing; the patron cells are not a walking-animation cycle.
The visual clock does not consume gameplay RNG or count as customer arrivals;
the furnished beer-bar terrace does not receive a passerby sprite. Event effects
do not add an indoor decorative crowd. The message strip sits above the room,
leaving customers' feet clear of the property selector.

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

## Additional male customers — 25 November 2026

Eight new adult men use the original patron sprite as a rendering-style reference.
The built-in image-generation tool produced each character separately. Exact
prompts and generation receipts are in `recipes/customer-jobs.json` and the
matching `recipes/customer-*.json` files; originals are in `sources/customer-*.png`.
No ComfyUI or external generation service was used for this addition.

| Atlas cell | Appearance |
| --- | --- |
| 0 | Stocky older regular, sun-faded teal vest, cargo shorts and flip-flops |
| 1 | Silver-haired old boy, salmon polo, shorts, socks and sandals |
| 2 | Indian visitor, rumpled maroon T-shirt, olive shorts and crossbody bag |
| 3 | Indian clubgoer, plum shirt, tailored trousers and oxblood loafers |
| 4 | Korean visitor, sage T-shirt, shorts, waist bag and worn trainers |
| 5 | Korean clubgoer, ivory blazer, black shirt and polished loafers |
| 6 | Black clubgoer, cobalt shirt, cream trousers and leather loafers |
| 7 | Thai regular, amber patterned shirt, navy trousers and slip-on shoes |
| 8 | User-reference guest, curly dark hair, black glasses, full beard, white graphic tee and navy shorts |

The ninth guest was added from a supplied likeness reference, retained at
`references/customer-beard-glasses-reference.png`. The built-in generator used
that image for identity/clothing and the sun-faded regular for rendering style.
The blue shirt graphic is simplified for sprite readability. Its exact prompt,
reference roles and output provenance are in `recipes/customer-beard-glasses.json`.

`assets/art/patrons-men.png` has nine 160 × 192 cells. The existing packer
normalizes alpha, height, padding and foot pivots. These are standing appearances
with the scene's existing idle breathing, not a walking-animation sequence.
`tools/review_art.py` produces a labelled lineup and light/dark edge sheets.

The catalog mixes these men with the existing patrons. Appearance and facing
come from the saved customer ID, so departures, queue reordering and reloads
do not change a remaining guest's look. Ethnicity, age and wardrobe do not alter
customer budgets, audience groups, orders or the simulation RNG. No save fields
were added. Only actual admitted customers are drawn; closures still empty rooms.
Use the `customers-men-*` preview filter to see the cast in each venue type,
or `customer-beard-glasses-*` for a small group led by the reference guest.

The consolidated catalog has 72 runtime textures, 22 sprite atlases and 149 frames,
including the fan ownership overlays and nine additional male customers.
See [the cast lineup](../docs/customer-cast.png) and
[testing notes](../docs/TESTING.md) for review coverage.

## Integration verification — 25 November 2026

The shipped catalog contains 61 textures, including 20 atlases with 136 frames,
nine interiors, nine frontage illustrations and 16 portraits. Two complete
packing runs produced identical manifests. Integrity checks validate hashes,
resource paths, atlas bounds, frame coverage, transparent padding and icon sizes.

The complete automated suite passes: gameplay, migration, economy, events, UI,
arcade, tutorial, Godzilla, art integrity and transformed input. The isolated-save
preview run rendered 196 captures covering 193 distinct views; combat playback
was recaptured after the final contact-effect adjustment. Alpha edges were
reviewed on light and dark backgrounds. Gameplay was inspected at 960 × 540 and
in a 1560 × 720 landscape window, including the management drawer.

Linux, Windows and macOS archives and the Android debug APK export successfully.
The Linux executable passes the isolated-save headless smoke test and an X11
graphical startup/shutdown check with hardware OpenGL. Active audio playback is
released on shutdown to avoid leaked stream resources. Android APK signature
verification passes. Windows/macOS execution and Android device
playtesting remain unverified; no Android device was connected. These are local
build artifacts; no release was published.

Current gameplay screenshots: [Blue Hour](../docs/blue-hour.png),
[showroom](../docs/showroom.png), [district](../docs/district.png), and
[Toybox](../docs/toybox.png).

## Customer-economy branch integration

The complete catalog is now integrated with the customer-demand model. Staff
identity comes from their assigned role/host ID; customers and order markers
come from live occupancy, and gogo pole performances follow the shift schedule.
Pool games keep stable table IDs through completion and save migration. All
replacement fighter atlases are present, so the temporary fallback is removed.

Sports-screen ownership now uses the existing stage-two beer-bar TV artwork.
The engine composites that crop onto the wall (or the Soi karaoke display),
and fitted stage-two/three beer-bar displays stay dark until purchased. Room
views and property thumbnails share cached fan/screen variants. No source PNGs,
manifest entries or generated art are replaced. Waiting-order dots use model
patience/visit time: yellow/gold normally, red at ten seconds or less remaining.

The combined gameplay, art integrity, transformed-input and nine-campaign pacing
suite passes. The integration review captured 51 general graphics views and 23
economy views, plus wider-window pool/layout checks. Linux export and its isolated
headless smoke test pass; the integrated Android debug APK exports and verifies.
Android device, Windows and macOS execution were not tested in this integration.

## Equipment ownership: wall fans

The wall fan and its animation now follow each venue's `equipment.comfort`.
Room views and interior thumbnails share the same cached ownership variant.
Unowned beer/gogo fans are covered by small matching wall patches; purchased
Soi fans use a transparent prop. Original room PNGs are unchanged, and pixels
outside each fan region are identical between the two ownership states.

Seven added textures bring the current catalog to 68. The built-in image tool
created the edits and transparent prop. Prompts and crop rectangles are in
[fan-ownership.json](recipes/fan-ownership.json), with source receipts in
[fan-ownership-receipts.json](recipes/fan-ownership-receipts.json). Selected
sources live in `art/sources/fan-hidden-*.png` and `art/sources/wall-fan.png`;
`tools/prepare_art.py` downsizes/crops these into `assets/art/fan-hidden-*.png`
and `assets/art/wall-fan.png`. The original room sources and packed pixels remain unchanged.

Use the `fan-*` general-preview filter to inspect owned/unowned pairs across
all nine stages; the economy preview includes a real comfort purchase.

## Music and automation presentation

Nida's existing four-frame production atlas is mirrored in-engine so she faces
the street. No artwork pixels or manifest hashes change. A purchased music
system receives an engine-drawn playing/off indicator beneath the venue sign.
The till gains a compact five-second net-trading readout; all amounts and
automation states come from the shared model. Use the `automation-*` economy
preview filter for controls, supplier/manager tiers, refills and closure.

The `bulk-*` economy preview group checks bartender pricing, Nida's Welcome
explanation, fridge reputation text and six-to-twelve delivery boundaries against
the same production scene. It adds no textures or decorative customers.

## Weekly celebration presentation

The `party-*` economy preview group covers anticipation, the live party and its
closeout. City draws temporary coloured bunting near the ceiling only while the
selected host is trading in its celebration window. Existing room plates,
portraits and atlases are unchanged; all visible visitors remain actual customers.
The countdown and actual contribution report are model-driven UI.

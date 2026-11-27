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

## Continuous motion, beer and individual sheets — 27 November 2026

Fifteen additional built-in ImageGen sources provide carrying-beer walks in
side/front/rear views, seated holding and sipping, and front/rear standing with
a glass. Sources and exact prompts/provenance/cuts are in
`sources/customer-<name>-beer.png` and `recipes/customer-<name>-beer.json`.
Approved earlier images remain unchanged. The capybara keeps its harness/leash;
the duo's shorter member keeps the dog while the taller member carries the beer.

Each customer now has one complete runtime atlas, `customer-<name>.png`, owned
by a [named-pose definition](characters/README.md). Ordinary/seated/beer poses
and existing companion/sunglasses/kiss frames are packed into that person's
sheet. Old runtime sheets remain available for street/compatibility references.
Adding a person or pose can rebuild only selected sheets; `--all` handles a common
pose addition without regenerating approved artwork. A new pose can be appended
as a one-cell source rather than remaking the full generated reference sheet.

The real Serve button previously rebuilt City and lost its visual cache. City
now survives HUD rebuilds. Existing records are never reseeded to destinations;
route changes begin at current feet. Gait phase follows travelled distance,
small aisle adjustments keep their facing, and stalled frames have bounded
visual catch-up. Actors walk to their destination before changing posture.

Seating reservations measure all relevant pose silhouettes with a twelve-pixel
clearance, including companions and lowered/raised glasses. Standing overflow
and conversations use clear floor space around seated guests. The finite game
seat capacity and all actual business rules remain model-owned.

Paid drinking phases select carrying or seated-beer poses; orders alone do not
create a glass. The seated glass lowers between sips. Rear watchers and standing
conversations keep their already-paid drink. Real pool uses its existing cue pose.

[Continuous return clip](../docs/customer-return.webm) · [GIF](../docs/customer-return.gif) ·
[Beer pose cast](../docs/customer-beer-cast.png).

```sh
python3 tools/prepare_customers.py --character silver-polo
python3 tests/test_customer_art_build.py
PATTAYA_PREVIEW_SCRIPT=tests/preview_customer_continuity.gd tools/preview-art.sh /tmp/pattaya-continuity
python3 tools/review_customer_continuity.py /tmp/pattaya-review --captures /tmp/pattaya-continuity
```

## Customer social routines — 27 November 2026

All fifteen customer identities have four additional authored poses: seated idle,
seated drinking, seated conversation and a planted rear-view standing watcher.
Fifteen `sources/customer-<name>-seated.png` sheets and matching
`recipes/customer-<name>-seated.json` receipts contain exact built-in ImageGen
prompts, identity references, provenance and authored cuts. Companions stay in
all four cells, including the capybara's harness and the duo's carried dog.
Original images and earlier sheets remain unchanged.

`tools/prepare_customer_seated.py` creates fifteen `customer-seated-*` runtime
atlases. Each contains four cells using the same widths as that customer's
walking sheet. The seated trio shares a 140px normalization; the still watcher
uses 180px. Bent adults keep their body proportions instead of being stretched
to standing height. Cushions use authored torso pivots and the existing room
stools; no placeholder furniture or room repainting is introduced. On tall
stools, lower legs can sit behind the property dock like the illustrated legs.

The presentation-only `customer_routine.gd` reserves physical chair positions
per visitor (two adjacent places for the duo), walks longer journeys along the
public aisle, sends ordinary pending orders to the counter, and returns served
guests to seats. Between rounds, staggered dwell phases select paired mingling
or a maximum of two TV viewers. Conversations require available actual guests;
watching requires a purchased sports screen. Pool and hosted rounds retain their
real model assignments; a pool queue never invents another game. Drinking seats
alternate occasional sip poses with rest, without changing drinking deadlines.

No route, seat, leisure phase or partner is saved. Closures/departures clear
records, campaign changes reset them, and navigation/image reads do not mutate
model state. Orders remain immediately serviceable during walks. The same
ordinary sales, real pool games, budgets, finite visits and RNG own every result.

[Routine preview](../docs/customer-routines.gif) · [Four activities](../docs/customer-routines.png).

```sh
python3 tools/prepare_customer_seated.py
PATTAYA_PREVIEW_SCRIPT=tests/preview_customer_routine.gd tools/preview-art.sh /tmp/pattaya-routines
python3 tools/review_customer_routine.py /tmp/pattaya-routine-review /tmp/pattaya-routines
```

## Full customer animation cast — 27 November 2026

Fourteen new reference-preserving sheets extend the existing charcoal sheet to
all fifteen live customer identities. Each has sixteen frames: four side walks,
four front walks, four rear walks, idle, drinking, Chat and pool. Leftward walking
mirrors the side cycle; front/rear views are authored. The capybara and rainbow
duo remain composed groups with their existing companions. The duo's dog stays
carried, matching its original sprite. Original production PNGs are unchanged.

Sources are `sources/customer-<name>-motion.png`; matching
`recipes/customer-<name>-motion.json` files contain the exact built-in ImageGen
prompts, original identity reference, generation receipt and authored crop cuts.
No model version or seed was exposed. These sheets were generated with the
built-in image tool; deterministic packing creates the runtime variants.

`tools/prepare_customer_motion.py` packs forty-two new atlases: fourteen bar
sheets (`customer-motion-*`) plus side and front/rear street variants
(`street-customer-*`). Standard bar cells are 160×192; capybara/duo cells are
256×192 and 288×192. Street cells are 96×128, or 192×128 for companion groups.
A shared scale within each four-frame cycle, consistent adult row height and
fixed supporting-foot baselines prevent gait pulsing and changes of size on
turns. Alpha below 160 is removed, source cuts fail closed on clipped silhouettes,
and nearest-neighbour packing preserves crisp small sprites. The full packer
calls this scoped packer. Repacking never rewrites older customer atlases.

`Art.customer_motion_id` maps the existing saved identities to the new sheets;
no admissions or save appearance fields change. City keeps a disposable visual
cache for stable floor slots, entrance arrivals and actual pool transitions.
The cache advances only with the visible scene and resets between campaigns.
Opening a room places existing guests directly at their places. Walking never
delays service or changes budgets, visit timers, stock, payments or gameplay RNG.
Drinking, Chat and pool poses read model state. Capybara idle, cobalt sunglasses
and the duo's existing stationary kiss reaction keep their original art.

Street traffic now rotates through nineteen walking identities: four existing
ambient walkers and all fifteen customers. Density, vehicle limits and shared
demand stay unchanged. These are ambient walkers, not extra admitted guests.
Both street directions and bar depth views remain native four-frame cycles.

[Walking cast preview](../docs/customer-walks.gif) · [In-bar arrival](../docs/customer-arrival.gif).

```sh
python3 tools/prepare_customer_motion.py
python3 tools/review_customer_motion.py /tmp/pattaya-customer-review
PATTAYA_PREVIEW_SCRIPT=tests/preview_customer_motion.gd tools/preview-art.sh /tmp/pattaya-customer-motion
```

## Provenance

The charcoal-suited supplied-reference guest has a 16-frame sheet: four side
walks, four front walks, four rear walks, idle, drink, Chat and pool. The
[receipt](recipes/customer-charcoal.json) contains the exact built-in ImageGen
prompt and reference roles. `sources/customer-charcoal-sheet.png` is the
generated source; `tools/prepare_charcoal_guest.py` packs the 160×192 bar atlas
and 96×128 street atlases using authored transparent row separators and a
shared scale. The full packer includes it. Existing runtime PNGs stay intact.
Only new admissions receive the optional saved `appearance: charcoal` identity
(one in 48 IDs); old guests retain their previous art. Street traffic adds this
fifth walking identity. Indoor drink/Chat/cue poses follow model state.

Preview with `PATTAYA_PREVIEW_SCRIPT=tests/preview_charcoal_guest.gd tools/preview-art.sh`.

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

### Street activity — 27 November 2026

Eight new lighting edits of the existing district map are saved as
`sources/street-activity-0.png` through `sources/street-activity-7.png`.
The built-in image generator produced individual reference edits; exact prompts
and returned source paths are in `recipes/street-activity-low.json`,
`recipes/street-activity-mid.json` and `recipes/street-activity-high.json`.
The original district source and runtime plate remain intact. Fine illustrated
details vary between generated edits, while destinations and road layout match.
`tools/prepare_street_art.py` packs each into a 960×540 RGB runtime plate and
updates the manifest; the full packer calls it too. No people are baked into
the plates. The scoped packer preserves all existing room files byte-for-byte.

`district.gd` reads customers in currently trading venues, choosing Quiet / Sleepy /
Warming up / Steady / Lively / Busy / Buzzing / Packed at 0/1/3/6/10/16/24/36
guests. A 0.4-second crossfade softens transitions. Four adult walking identities,
two helmeted scooters and a compact car have four animation frames each.
The district keeps these side-profile sheets. The bar has separate `*-depth`
atlases: four front-facing and four rear-facing frames for each identity.
Approaching traffic shows faces, headlights and front wheels; departing traffic
shows backs and taillights. Crossings alternate direction, including when only
one vehicle is present. They never mirror side art to suggest depth.
The `street-*-depth.json` receipts contain the built-in ImageGen prompts and
provenance. The walker source has authored row separators in `street-packing.json`
to preserve heads and shoes before scale/baseline normalization.
`street_view.gd` supplies deterministic motion and activity bands to both views.
The district caps its ambient traffic at 36 walkers, six scooters and three cars.
They disappear at zero activity and are not extra admitted customers. Animation
and image selection are read-only, with no RNG or saved visual state. Signs,
controls, Anong, paths and destinations remain engine-authored. Rain stays an
engine effect. Atlas prompts and provenance are in `recipes/street-walkers.json`,
`street-scooters.json` and `street-cars.json`.

The bar uses eight reusable **time-of-day underlays**, cropped to 164×435 from
lighting edits of `beer-1.png`. The clock selects late night / before dawn /
dawn / morning / daylight / sunset / dusk / night at
00:00/03:00/05:00/07:00/11:00/17:00/19:00/21:00. The first second of each
period crossfades. `street-window-*.json` and `street-daylight-*.json` record
the built-in image prompts and source receipts; `street-packing.json` maps
the selected sources to runtime periods. Unused night-lighting studies remain
authoring-only. Generated interior pixels are discarded during packing.

`Art.room_shell` makes a cached transparent aperture in the existing room texture.
The underlay and moving traffic draw first, then this exact original foreground
occludes them. Pixels outside the aperture remain unchanged, including all
purchased equipment. The stage-three beer bar uses a smaller, distant cutout
behind its original furnished terrace. Bar traffic caps at seven subdued walkers,
three scooters and two cars, scaled by distance. Room sources, runtime PNGs and
property thumbnails remain unchanged.

Foreground traffic approaches the room's adult scale: the 120px walkers grow
from 0.27× to 1.25×, and vehicles from 0.20× to 1.05×. The smaller stage-three
terrace retains its 0.42× distance multiplier. District scales stay unchanged.
The preview includes `bar-traffic-scale-*` near/far, front/rear, charcoal-guest,
scooter and car captures at all three beer-bar stages.
Verified on 27 November 2026 with the complete isolated `tools/test.sh` suite
and in-engine previews at 960×540 and 1280×720, including front/rear traffic,
all nine venue apertures and the furnished terrace. Device play remains unverified.

```sh
PATTAYA_PREVIEW_SCRIPT=tests/preview_street_activity.gd tools/preview-art.sh /tmp/pattaya-street-activity
```

This preview covers all eight bands, closure and rain, eight bar lighting periods,
all nine room apertures and animated traffic using actual campaign customers.
See [the district comparison](../docs/street-activity.png) and
[the bar comparison](../docs/street-underlays.png).
Motion previews: [inside the bar](../docs/street-motion.gif) and
[district crowd](../docs/district-motion.gif).

### Shared scene catalog

`scripts/art.gd` owns texture lookup, venue stages, identities, semantic animation
states, atlas bounds and event identifiers. City staff availability comes from
the existing campaign state. Gogo stages use one, two or three pole positions;
remaining hosts work the floor. Interior adults share a floor-depth scale, including Anong and the inspector.
The foreground counter occludes Anong's legs; crops of the original venue plate
occlude bartenders behind the illustrated counters. Customers and pool tables
are drawn in floor-depth order, with waiting-order dots above customer heads.
Both pool tables stay indoors. Street traffic follows the visible outside lane
using the separate walking and vehicle atlases described above. The visual clock
does not consume gameplay RNG or count as customer arrivals; the furnished
beer-bar terrace only reveals distant traffic behind its furnishings. Event effects
do not add an indoor decorative crowd. The message strip sits above the room,
leaving customers' feet clear of the property selector.

Fight presentation maps the simulation into the 960 × 540 scene. Attack timers
select anticipation, contact and recovery poses. The existing fighter atlas
supplies the crouch, uppercut and roundhouse poses with sprite transforms, and
contact effects distinguish each special move. UI hit regions use the same
displayed rectangles and transforms. Idle breathing and light animation are
independent of simulation ticks.

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

`assets/art/patrons-men.png` begins with nine 160 × 192 standing appearances,
followed by three poses for the cobalt-shirt guest. The packer normalizes the
standing cells and appends the aligned sunglasses sheet. The guest raises his
black sunglasses, fits them, wears them briefly, then reverses the gesture on a
16-second loop. The [pose recipe](recipes/customer-cobalt-evening.json) records
the reference and prompt.
`tools/review_art.py` produces a labelled lineup and light/dark edge sheets.

The catalog mixes these men with the existing patrons. Appearance and facing
come from the saved customer ID, so departures, queue reordering and reloads
do not change a remaining guest's look. Ethnicity, age and wardrobe do not alter
customer budgets, audience groups, orders or the simulation RNG. No save fields
were added. Only actual admitted customers are drawn; closures still empty rooms.
Use the `customers-men-*` preview filter to see the cast in each venue type,
or `customer-beard-glasses-*` for a small group led by the reference guest.

The runtime catalog includes the fan ownership overlays and nine additional
male customers.

The capybara regular uses a wide atlas anchored under the customer's shoes.
The pet blinks, lowers onto its haunches, and stands again on an eight-second
loop. The existing customer pose and leash anchor are aligned across all five
cells. See the [original generation recipe](recipes/customer-capybara.json).

The rainbow duo and their orange dog share one sprite and one order on opening
day and recurring visits. Double-click or tap them to swap to their kiss frame
for 1.2 seconds, with a heart rising from their lips. The [customer jobs](recipes/customer-jobs.json)
include the original cutout recipe. Both new pose sheets use built-in ImageGen
references and are packed as aligned cells for the [companion animations](recipes/companion-poses.md).
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

## Equipment ownership: adaptive fridges

Every room and property thumbnail uses the saved fridge tier. The live room
draws bottles from the venue's actual stock, including the starter cabinet.
The fitted upgrades add a shelf, a side bay, twin doors and a cold drawer,
with a brief burst of frost on the final purchase. The cabinet atlas and
wall patches for the nine room plates are packed by `tools/prepare_art.py`
using the [fridge recipe](recipes/blue-hour-fridges.json).

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
system receives an engine-drawn playing/off indicator in the venue.
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

## Actual bartender service feedback

The top-right BARTENDERS list reuses existing portraits and reads the model's
cooldown/readiness, training levels and shared tip jar. Actual staff sales remain
in row tooltips and Service. Bartender atlases enter their existing serve animation only
for two seconds after a real staff sale; the old decorative six-second loop is
removed. No textures or atlas frames are replaced. Use `staff-ready-*` economy
previews for ready, served, cooldown, quiet, stockout, rota and expiry states.

## Gabby — 26 November 2026

Gabby's pale skin, tied-back brown hair and very short red collared dress follow
the supplied reference and requested revision. The built-in image generator made
a transparent four-pose sheet, using Dao only as a rendering-style reference.
[Exact prompts and receipts](recipes/gabby.json) record both passes. Personal
reference photos remain local attachments and are not runtime assets.

`art/sources/gabby-sheet.png` is split at fixed equal 2×2 cell boundaries by the
existing packer, then normalized into `assets/art/gabby.png` (four 160×192 cells).
A fixed idle-pose crop provides `assets/art/portrait-gabby.png`. The optional
saved identity selects her own art without changing any existing worker's look.
Only real staff sales trigger her serving pose; rota, expiry and closure still
control presence. Use the economy preview filter `gabby-*` for hiring, roster,
all three venue types, serving, tips, off-duty and renewal states.


## Daisy — 26 November 2026

Daisy is a separate fictional adult entertainer based on the generated Gabby
design. The user confirmed that the original reference photos were AI-generated.
She has pale skin, tied-back brown hair, a fuller bust, a small opaque red bikini
top and matching thong bottoms. The built-in image tool created a six-pose 3×2
sheet; [prompts and receipt](recipes/daisy.json) record generation and cutout.
The existing packer splits `sources/daisy-sheet.png`, normalizes six 160×256
host cells into `assets/art/daisy.png`, and creates `assets/art/portrait-daisy.png`.
All existing character PNGs remain unchanged. Inspect her hiring, roster,
three venue stages, off-duty/away/closed states and renewal using
`PATTAYA_PREVIEW_SCRIPT=tests/preview_daisy.gd tools/preview-art.sh`.

## Street-event mini-games

Cart Jam uses a directly overhead atlas of a delivery van and three decorated
food carts. The bed race uses an illustrated Beach Road panorama and two
separate side-on racing teams. The packer trims and aligns the sprites. Godot
rotates the cart tiles and animates the racing beds, wheels and finish effects.

## Bar-fine presentation

The `barfine-*` economy previews show existing host portraits in a compact
room card with model-owned acceptance and return countdowns, plus Service and
training offers. The existing `away` state removes only the booked host from
the production scene. Returning, expiry and closure use the same availability
rules as attraction. No portraits, room plates or character atlases are replaced.

## Good Company feedback

The `hosted-*` economy previews show matches, queued/paid drinks, Room Buzz,
training and closure. Existing portraits appear in the shared Good Company card.
Engine-drawn POUR/CHEERS markers represent real orders; hosts keep their appeal
and use a stationary existing pose while entertaining. The meter reads saved
completion progress. This feature adds no image assets; concurrent cast artwork
is preserved.

## Shotgun — 27 November 2026

Shotgun uses the supplied photograph as his identity reference and the finished
charcoal customer atlas as a style reference. The built-in ImageGen tool produced
[one 25-pose source](sources/customer-shotgun-sheet.png); its
[receipt](recipes/customer-shotgun.json) records the exact prompt, returned path
and authored grid cuts. Eight transparent border pixels were added during
packing; generated pixels stay unchanged. His [individual definition](characters/shotgun.json)
owns empty/beer walks, seated activities, Chat, pool and the ribs reaction.
Two authored steps repeat over each four-entry walking cycle. Existing art
files are unchanged. Rebuild only him with:

```sh
python3 tools/prepare_customers.py --character shotgun
```

`assets/shotgun.wav` is an original synthetic espeak-ng utterance, not a recording
or imitation of the reference person. Its reproducible command is recorded in
the art receipt. Godot renders the exact “Shotgun BBQ!” text; the click/tap
reaction holds only his visual walking position for 3.2 seconds. Real model
service, budgets, drinking timers and stock continue. Clicking now requests the
model-owned +5-second street patience bonus with its saved 30-second cooldown;
the bubble reports the bonus and then displays remaining cooldown. Sound / Muted
controls the voice.

[In-game reaction](../docs/shotgun.png). Preview with
`PATTAYA_PREVIEW_SCRIPT=tests/preview_shotgun.gd tools/preview-art.sh`.

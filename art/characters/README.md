# Individual customer templates

Each `*.json` owns one customer's complete runtime sheet and named poses.
`template.json.example` is the starting point for another person. Existing staff
already have individual atlases; these definitions extend that ownership pattern
to every customer, including the capybara guest and rainbow duo.

```sh
# Rebuild one person, without touching anyone else's PNG:
python3 tools/prepare_customers.py --character silver-polo

# Rebuild selected people:
python3 tools/prepare_customers.py --character silver-polo --character charcoal

# Repack the cast after adding a shared pose to their definitions:
python3 tools/prepare_customers.py --all
```

Output: `assets/art/customer-<id>.png`. The cheap shared index is
`assets/art/customer-characters.json`, explicitly included in every export.
The scene requests names such as `beer_walk`, `beer_seated_idle` or `pool`;
it does not contain offsets into these individual sheets.

Definitions list independent `sources`:

- `atlas`: copy approved frames from an existing atlas, preserving their pixels.
  Supply its `cell`, and either `count` or explicit `indices`.
- `generated`: extract a committed source sheet using the `recipe`'s authored
  `columns` and `rows`. A single new pose can use a one-cell source sheet.
  `heights` sets standing/seated normalization. `scale_groups` shares one scale
  across a gait cycle; omitted groups normalize each pose individually.
- Each source's `animations` maps a semantic name to indices local to that
  source. The packer computes runtime offsets. Appending a pose does not require
  regenerating any previously approved art or editing scene frame numbers.

`seat_span` reserves one chair or an adjacent pair for a composed group.
Explicit data-defined identities resolve through the same runtime catalog.

Every current customer includes ordinary movement/actions, seated poses, beer
movement/rest/sips and a rear watcher. Companion idle, sunglasses and kiss poses
are copied into their owner's individual sheet too. Leftward movement mirrors
the side cycle; front and rear walks are authored.

`fallbacks` can point an optional named pose to an existing animation. An unknown
optional name also resolves to idle while its art is being authored. The current
release validates the complete common pose set for all fifteen identities.
Atlas padding repeats idle and stays within the 4096px mobile limit.

To add another person, copy the example to `<id>.json`, provide their own source
art, then build that ID. Integrate their identity through the relevant roster or
admission rules, retaining existing saved IDs and appearance mapping. The art
builder does not change customer rotation, budgets, purchases or saves.

To add a common pose, generate just that pose for each identity, append its
source/named mapping to each definition, then run `--all`. This repacks local
files; it does not call image generation or remake existing poses.

Verification:

```sh
python3 tests/test_customer_art_build.py
tools/test.sh
```

The authoring test adds a pose and another person in an isolated temporary tree
and proves unrelated sheets are not rewritten. Runtime tests validate semantic
coverage, asset bounds, actual drink ownership and exported resource inclusion.

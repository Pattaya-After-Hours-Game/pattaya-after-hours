# Testing and release checks

This document separates automated checks, visual review and platform testing.
It is a handover checklist, not a claim that every platform has been played.

## Automated suite

Run from the repository root with Godot 4.7.2:

```sh
GODOT_BIN=godot tools/test.sh
git diff --check
```

The wrapper imports assets, runs `tests/check.gd`, then runs the fresh-campaign
balance simulations in `tests/economy_balance.gd`. It isolates both user data and
editor configuration. The save tests deliberately create, corrupt and remove
campaigns; use the wrapper rather than running them against your personal saves.

| Area | What the suite covers |
| --- | --- |
| Customer economy | Real orders, stockouts, service delays, full rooms and bounded shared traffic |
| Finance | Quiet-period payroll, closure/recovery, raid fine ledgers and local renovation gates |
| Clock and prep | Noon/midnight/1am/3am boundaries, nightly permissions, manager/manual cleaning, skipped work and closure precedence |
| Peak hours | Separate beer/Soi/gogo windows, midnight wrap, bounded shared demand, double dirt and legal-hours offline segments |
| Late raids | Per-venue heat counters, cooling, deterministic RNG, immediate saves, capped fines and next-noon recovery |
| Pool and promotions | One fee per game, free-game expiry, table identity, cooldowns, quote preservation and reload safety |
| Offline operation | Legal-window cursor, peak segmentation, demand/stock/cost limits, eight-hour cap, unchanged live state and repeat-safe claims |
| Active actions | Exact fractional refill boundaries, shared social cooldown, once-per-visit reassurance, upgrades/reserves, per-venue independence and UI state |
| Saves and guided shifts | Older-schema migration, backup recovery, shared timing and no click-through income |
| Startup menu | No simulation or writes before selection, disabled Resume without a valid save, backup recovery, cancellation, immediate new-game save and removal of erased progress from backups |
| Story and legacy modes | Incident responses, ongoing campaign, tutorial isolation and Godzilla outcomes |
| Presentation | Catalog resources/hashes, atlas frames/padding, host identity, property hit regions, scrolling, district paths and combat input |
| Pacing | Nine target campaigns plus six no-chat/manual-versus-staff comparisons, with no injected money or offline income |

The six active-strategy runs must meet the configured milestone windows. The
three mostly-idle runs must complete without getting stuck. Six additional
manual-first/staff-first comparisons must finish without Chat. Thirty paired
promotion scenarios compare quiet and full-house free-pool contribution. These
are useful repeatable checks; they do not replace human balance testing.

## Visual review

Use a graphical display. Both runners isolate their saves:

```sh
tools/preview-art.sh /tmp/pattaya-art-review
PATTAYA_PREVIEW_FILTER='fight-*,drawer-*' tools/preview-art.sh /tmp/pattaya-focused-review
PATTAYA_PREVIEW_SCRIPT=tests/preview_economy.gd tools/preview-art.sh /tmp/pattaya-economy-review
PATTAYA_PREVIEW_RESOLUTION=1560x720 tools/preview-art.sh /tmp/pattaya-wide-review
```

Comma-separated filters apply to the general art runner. The economy runner
supports a single name pattern for its standard captures; its separate fight
captures are also produced. Runtime imagery is in `assets/art/`; provenance and
packing instructions are in [art/README.md](../art/README.md).

Review these behaviours, not just whether a PNG exists:

- Use `boot-*` to review first launch, a resumable campaign and the destructive
  New Game confirmation. Check legibility, focus, Cancel and touch target sizes.
- Clock, peak hours, 12:30am warning and raid notices remain legible; financial
  rates clearly use real minutes. Prep exposes cleaning, stock and optional skip.

- Use `empty-*`, `full-*` and `closed-*` general-preview filters for all three
  venue types, including the 24-customer maximum. Check character proportions,
  visible feet, counter/table occlusion and a clear outside lane.
- Use `passerby-*` to inspect six consecutive crossings and the empty gap.
  Appearances change between crossings, remain stable during each crossing, and
  face their travel direction without entering the bar.
- Use `fan-*` for owned/unowned pairs at all nine venue stages. The economy
  runner includes `fan-before-purchase` and `fan-after-purchase` using the actual
  upgrade action. Check room artwork and property thumbnails together.
- Empty venues look empty, waiting-order markers match customers, and closed or
  off-duty staff do not appear to be working.
- Beer-bar pool states distinguish paid, free, idle and not-open facilities.
  A surviving game stays at its assigned table when another finishes.
- Mixed teams use the correct host identity; gogo bartenders remain bartenders,
  and scheduled dancers line up with the poles.
- Every venue stage and exterior is recognisable. Drawers, property selection,
  labels, touch targets and scrollable controls fit at ordinary and wide sizes.
- Fighters face the opponent, contact effects fit attacks, and corner KO/victory
  poses stay visible. Monster arrival, drinking, sleep and closure remain readable.
- Tutorial and guided-shift screens display their correct model and controls.

## Build checks

See [DEVELOPMENT.md](../DEVELOPMENT.md) for templates, SDK/JDK paths and signing.
Local desktop exports can be built without enabling Android release signing:

```sh
env -u ANDROID_HOME -u JAVA_HOME tools/release.sh
```

That script writes ignored `dist/` packages and checksums, then runs the Linux
executable with isolated user data. An Android debug export can be checked with
`apksigner verify` using the installed Android SDK. Debug signing does not replace
production signing or confirm that a device can update an installed release.
Build commands do not publish a release.

## Verification record and remaining work

At completed-art integration (`1f97b70`, 25 November 2026):

| Check | Recorded result |
| --- | --- |
| Combined gameplay, art, input and pacing suite | Passed; all nine pacing runs completed |
| Runtime catalog | 61 textures; 20 atlases / 136 frames; no missing catalog assets |
| Graphical review | 51 general captures, 23 economy captures, plus wide pool and drawer views |
| Linux integrated export | Export and isolated headless startup passed |
| Android integrated debug APK | Export and signature verification passed |
| Android device playtest | Not performed |
| Windows/macOS integrated execution | Not performed |
| Human progression study across multiple sessions | Still needed; simulation targets are not human-play certification |

Before proposing a merge, run checks on the actual combined branch. Record the
commit, command, result and any unresolved issue. In particular, rerun the full
suite when merging model, save, UI or asset changes from another branch. For a
docs-only change, verify facts against code, local links and diff formatting;
there is no need to rerun the game solely for prose edits.

Before a release, play a fresh opening, resume an older save, test pause/resume,
check offline reporting, try touch/back controls and exercise platform-specific
features on the target OS. Keep release numbers, signing identity and changelog
in sync. Do not describe an exported package as a published or device-tested one.

## Consolidated branch verification

The follow-up merge with upstream `87a0107` was tested on
`codex/ready-for-main`. Both feature branches and upstream main passed their own
suites; the combined suite also passed, including new update-worker isolation
and header-layout checks. Linux, Windows and macOS packages exported successfully,
and the Linux startup smoke test passed. The exact inputs and maintainer notes
are recorded in [MERGE_HANDOFF.md](MERGE_HANDOFF.md). Windows update execution and
rollback still require Windows testing.

## Clock, prep and peak-hours verification — 25 November 2026

Working branch: `codex/game-clock`, based on `c056dfc`. These are source checks,
not a published release or a new target-device certification.

- `tools/test.sh`: passed, including the new clock/cleaning/raid/peak regressions,
  v1–v4 migration and backup checks, UI controls, thirty paired promotion scenarios
  and all nine fresh-campaign pacing runs with preparation counted.
- `git diff --check` and local Markdown link checks: passed.
- `tools/preview-art.sh`: full general runner completed (197 captures), followed
  by focused review of affected drawers, closures, guidance and tutorial screens.
- `PATTAYA_PREVIEW_SCRIPT=tests/preview_economy.gd tools/preview-art.sh`: completed;
  inspected clock, all three peak windows, prep, late trading, raid and noon states.
- Repeated the clock/peak captures with `PATTAYA_PREVIEW_RESOLUTION=1560x720` and
  inspected the wide layout. Existing production artwork is retained.

The active policy reaches pool in 15.8–17.6 real minutes, stage 2 in 39.1–43.5,
a second property in 129.4–142.9 and stage 3 in 217.1–236.0. The original target
windows remain unchanged. These simulations include normal 1am closing and prep;
late-trading risk is covered separately by deterministic gameplay tests.

Android touch/device play, Windows/macOS execution and a human multi-session
balance study remain unverified for this change. The initial feature verification
did not publish a release or create exports; integration is recorded below.

## Bar-scene perspective correction — 25 November 2026

The scene uses one depth-based scale for interior adults, counter occlusion for
bartenders, indoor customer/table positions, and overhead order markers. The
message strip no longer covers the floor. Production textures are unchanged.

Verified with Godot 4.7.2: `tools/test.sh` (including all nine pacing campaigns),
65 general captures, the complete economy preview, and six wider-window views.
The added scene checks cover real occupancy/orders, available staff, closure,
read-only rendering, floor bounds and surviving pool-table identity. Visual review
included all nine stages, empty/full rooms, inspection and other event treatments,
management drawers and pool states. Device playtesting remains outstanding.

## Clock and perspective integration — 25 November 2026

Combined clock/peak/prep feature commit `85777c1` with upstream main `ac8a4d6`
(bar-scene perspective commit `9d232ea`). Retained both documentation updates,
scene depth/scale changes and the clock's shared trading-availability checks.
New scene regressions cover scheduled closure, late opening and raid closure.

The combined `tools/test.sh` passed, including all nine pacing campaigns.
The complete economy preview and seven focused general previews were rendered;
opening, peak trade, prep and raid closure were inspected. Raid artwork uses the
new perspective scale and sits clear of the closure notice. Diff formatting and
local documentation links passed. This integration is merged to local `main`;
no push, release publication or export is part of this merge.

## Diverse male customer sprites — 25 November 2026

Branch `codex/diverse-male-customers`, based on `1273636`. Added eight adult male
appearances in a new atlas, mixed with the existing patrons. Saved customer IDs
select appearance and facing; queue position, budget and audience do not.

- `GODOT_BIN=/home/zak/.local/bin/godot-4.7.2 tools/test.sh`: passed, including
  atlas/hash checks, all eight variants being reachable, stable appearances after
  departures/reordering/JSON round-trip, read-only rendering and nine pacing runs.
- `tools/preview-art.sh` with `opening,customers-men-*,type-*,full-*,empty-*,closed-*`:
  22 captures. Inspected opening, the new cast in all venue types, full occupancy,
  empty rooms and closure visibility at 960 × 540.
- Economy preview runner with `*pool*`: four pool views plus its three standard
  fight captures. Inspected the paid-pool drawer and surviving second-table game.
- Wide preview at 1560 × 720 with `customers-men-*,full-2`: four captures;
  inspected the gogo cast and control layout.
- `tools/review_art.py`: inspected each new silhouette on light and dark
  backgrounds and the labelled [cast sheet](customer-cast.png).
- `git diff --check` and changed-document local links: passed.

No economy rules or save fields changed. This asset update has not been exported,
published or played on Android/Windows/macOS devices.

## Startup menu — 25 November 2026

Branch `codex/boot-menu`: launches now offer New Game and Resume. Existing
campaigns require confirmation before replacement, including removal of the old
backup. Menu time does not simulate the street or write campaign saves.

- Godot 4.7.2 `tools/test.sh`: passed, including all nine pacing runs, menu
  inactivity, resume/backup recovery, replacement, cancellation, pointer controls,
  tutorial isolation and deferred, repeat-safe offline credit.
- `tools/preview-art.sh`: inspected first-launch, Resume and confirmation screens
  at 960 × 540 and 1560 × 720, plus the fresh opening and economy Service drawer.
- `git diff --check`: passed. Existing artwork and unrelated working changes
  were preserved; save schema and economic balance are unchanged.

No exports or release publication. Android device and Windows/macOS playtesting
remain outstanding; the automated back-button check is not a device playtest.


## Supplied-reference customer — 25 November 2026

Added the curly-haired, bearded guest with black glasses and a white graphic
T-shirt as cell 8 of `patrons-men`. The existing customer catalog assigns him
through real customer IDs; this addition does not add save fields or economy rules.

- Godot 4.7.2 `tools/test.sh`: passed, including all nine male appearances,
  identity stability, atlas bounds/checksums and the current pacing suite.
- Nine focused general previews: the new guest, the complete male cast and full
  occupancy in each venue type. Inspected the guest in all three interiors at
  960 × 540 and alpha edges against light and dark backgrounds.
- Economy pool previews completed; existing order markers and table occlusion
  remain intact. See [the in-game guest](customer-beard-glasses.png).
- Updated the packing recipe, generation provenance and cast sheet. Existing
  uncommitted gameplay and boot-menu work was retained.

No exports, publication or target-device playtesting for this addition.


## Active service and customer chat — 25 November 2026

Branch `codex/active-service-cooldowns`, based on `1273636` with the existing
startup-menu and artwork working changes preserved. This is source verification,
not a published release or device certification.

- Godot 4.7.2 `tools/test.sh`: passed. Includes exact fractional cooldown boundaries,
  rapid/failed actions, live refill controls, chat targeting and shared recovery,
  all upgrade tiers/reserves, per-venue independence, guided choices, recovery,
  v1–v5 migration, fractional save round-trips, backups and unchanged offline rules.
- Nine target campaigns passed, plus six manual-first/staff-first comparisons
  without Chat. Active targets measured: first purchase 2.7–4.4 minutes, pool
  15.9–18.6, stage 2 38.7–41.9, second property 137.9–147.0, stage 3 221.8–236.9.
  Mostly-idle campaigns finished in 235.2–243.8 minutes. Both no-chat routes
  finished without manual upgrades being a mandatory gate.
- `tools/preview-art.sh`: 17 focused general captures and the full economy runner.
  Inspected ready/refilling buttons, urgent chat and its customer marker, purchase
  shortfalls/max levels, stockouts, closures, navigation and the practice tutorial.
- Repeated the action previews in a 1560 × 720 window (the aspect-preserving game
  content is 1280 × 720), checking the action bar and upgrade drawer.
- `git diff --check` and local documentation-link checks passed.

The first action-upgrade price was calibrated from ฿650 to ฿900 to preserve the
opening purchase window. Other economic prices, traffic and wages are unchanged;
manual-first tests defer deliveries/fridge until stage 2 and restock by hand.
These are deterministic strategy checks, not proof of every human play style.
Android device play, Windows/macOS execution and human balance testing remain
unverified. No exports, merge or publication were performed.

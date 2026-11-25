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
| Staff | Exact 25/20/15-second service, individual training, expiry/rehires, skipped/closed/offline time, migration, partial work and UI buttons |
| Waiting bell | Empty queues, immediate notification, ten-second repeat limit, empty/refilled queues and mute/inactive suppression |
| Clock and prep | Noon/midnight/1am/3am boundaries, nightly permissions, manager/manual cleaning, skipped work and closure precedence |
| Peak hours | Separate beer/Soi/gogo windows, midnight wrap, bounded shared demand, double dirt and legal-hours offline segments |
| Late raids | Per-venue heat counters, cooling, deterministic RNG, immediate saves, capped fines and next-noon recovery |
| Pool and promotions | One fee per game, free-game expiry, table identity, cooldowns, quote preservation and reload safety |
| Offline operation | Legal-window cursor, peak segmentation, demand/stock/cost limits, eight-hour cap, unchanged live state and repeat-safe claims |
| Saves and guided shifts | Older-schema migration, backup recovery, shared timing and no click-through income |
| Story and legacy modes | Incident responses, ongoing campaign, tutorial isolation and Godzilla outcomes |
| Presentation | Catalog resources/hashes, atlas frames/padding, host identity, property hit regions, scrolling, district paths and combat input |
| Pacing | Three seeds × click-heavy, balanced and mostly-idle strategies, with no injected money or offline income |

The six active-strategy runs must meet the configured milestone windows. The
three mostly-idle runs must stay solvent and complete within ten simulated hours.
All styles must obey actual order counts and bounded shared traffic. Thirty paired
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

- Clock, peak hours, 12:30am warning and raid notices remain legible; financial
  rates clearly use real minutes. Prep exposes cleaning, stock and optional skip.

- Use `empty-*`, `full-*` and `closed-*` general-preview filters for all three
  venue types, including the 24-customer maximum. Check character proportions,
  visible feet, counter/table occlusion and a clear outside lane.
- Use the economy runner with `PATTAYA_PREVIEW_FILTER='staff-*'` for base,
  trained, expired and rehired cards. Check terms, individual training and rehire
  buttons; departed staff should disappear from the room. Listen to the bell in
  normal play and check mute; headless tests verify timing, not listening quality.
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

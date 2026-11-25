# Testing and release checks

This document separates automated checks, visual review and platform testing.
It is a handover checklist, not a claim that every platform has been played.

## Current automatic night-prep verification — 26 November 2026

`tools/test.sh` passes gameplay/save/UI regressions, 42 fresh campaigns and sixty
paired party scenarios on Godot 4.7.2. Existing pacing bounds are unchanged.
`night_prep_check.gd` verifies fifteen full seconds, cancellation on the final
second, continued cleaning, no overnight revenue/stock purchase/extra date,
manual skip, active/cancelled reloads, offline exclusion, hidden-control pause,
late venue/flood guards, daytime closure, schema-nine migration and malformed
schema-ten rejection. Existing cleaning fixtures now explicitly cancel automatic
advancement when testing prolonged manual prep. The UI test clicks the visible
street cancellation button and checks the saved model outcome.

Four `night-prep-*` economy previews at 960 × 540 cover the countdown, last second
with Service open, cancelled clean prep and noon. The last-second state is also
checked at 1280 × 720. No production assets changed. Android device play remains
unverified; export success is separate from device testing.

## Previous opening-arc balance verification — 26 November 2026

Godot 4.7.2 `tools/test.sh` passes all regressions, 42 fresh campaigns and sixty
paired celebration scenarios. Before/after baseline runs compare against v1.0.19
(`e644c55`) with the same seeds/policies. First renovation stays at 33.6–36.8
minutes; the second property moves from 117.7–122.2 to 102.2–104.7, and stage three
from 166.9–172.4 to 142.5–144.1. Mostly-idle stage three is 178.9–184.5 minutes.

The revised active criteria are explicit: stage two 30–45 minutes, second property
90–125, stage three 135–240, first-manager saving gap at most 30 minutes and the
longest gap between improvements at most 38. The measured gaps are 24.8–26.8 and
34.2–36.2 minutes. These intentionally replace the former final-stage lower bound
in response to the request for less grind; no artificial waiting timer is added.
Alternative investment routes remain solvent and respect demand/stock/customer
limits. Current route measurements are in [ECONOMY](ECONOMY.md).

`balance_guidance_check.gd` covers revised price/reserve boundaries, unchanged
service deadlines, retained paid ownership after reload, all three final
renovation prices and each local gate. It verifies pure guidance reads, shared
chapter requirements and UI navigation without spending or simulating. An isolated
regression rerun passes after refining the opening button to reveal Serve rather
than suggest buying stock that is already available.

Four `guidance-*` economy previews at 960 × 540 and 1280 × 720 cover opening,
renovation progress, management saving and festival objectives. Existing art and
bottom service controls remain visible. Source docs and relative links are checked.
No human retention study, full-festival pacing simulation or Android device play
is claimed; those remain follow-up evidence rather than inferred from export success.

## Previous bartender-priority / renewal verification — 26 November 2026

`tools/test.sh` passes on Godot 4.7.2: regressions, 42 fresh campaigns and 60
paired celebration scenarios, with no changed pacing thresholds. Auto-serve
routes reach the second property in 142.3–149.8 minutes and stage three in
189.6–196.2 minutes. Baseline manual routes are unchanged.

New checks cover quiet queues waiting for staff without spending the owner timer,
overflow service on the same ten-second owner deadline, urgency versus staff
recovery, first staff priority, reload, absent/expired staff and no fake demand.
Renewal checks cover exact reserve boundaries, full floor rosters, retained
training, pure quotes and repeated clicks. UI checks expire Nida live, verify
insufficient cash disables renewal, then enable it after adding cash without
reopening the drawer and rehire successfully. The expanded UI checks were rerun
in isolated save/config directories after the full suite and passed.

Four economy previews show Nida's shortfall, funded renewal, renewed contract
and the owner relief status at 960 × 540; renewal also checked at 1280 × 720.
No production art changed. Local links and whitespace are checked before commit.
No Android device playtest or new human balance study has been performed.

## Previous ready-bartender / auto-serve verification — 25 November 2026

The full Godot 4.7.2 suite passes regressions, 42 fresh campaigns and 60 paired
party scenarios. Active baseline second-property times are 117.7–122.2 minutes;
stage three takes 166.9–172.4, inside the existing celebration-adjusted bounds.
Owner auto-serve routes now reach their second venue in 142.5–144.6 minutes with
the lower purchase price. Sustained bartender capacity remains 2.4/3/4 drinks
per minute, with immediate ready service replacing repeatedly cancelled warmup.

`tests/staff_ready_check.gd` and updated staff tests cover first readiness,
25/20/15-second recovery, training with an existing deadline, quiet queues,
stockouts, toggles/closure, shared orders, owner priority separation, actual staff
counters, pure HUD reads, fractional save/reload and v8 migration. UI tests check
the indicator's counter and Service navigation. Auto-serve settlement verifies
exactly ฿3,000 and the unchanged manual deadline. Startup/offline isolation remains.

Nine `staff-ready-*` economy previews were rendered at 960 × 540 and 1280 × 720.
Visual review covers the bottom-right counter, sale confirmation, countdown,
quiet/stockout/rota/expired states and the new price across those sizes. Serving
poses use existing production frames after actual staff sales. No art is replaced.

Docs/local links and `git diff --check` are checked before commit. Release CI
repeats tests and verifies signed exports. Android device play and Windows/macOS
execution remain unverified; a successful build is not a device playtest.

## Previous v1.0.17 day-seven / weekly celebration verification — 25 November 2026

Godot 4.7.2 `tools/test.sh` passed all regressions, 42 fresh campaigns and 60 paired celebration scenarios
(120 trading days). The paired prepared bar sold 54% more drinks and earned 59%
more contribution in aggregate, while basic service produced more queue losses.
Full active campaigns reach the second property in 119.0–125.2 minutes and stage
three in 170.0–176.3 minutes. The new event intentionally rewards the middle of
the campaign; the stage-three lower acceptance bound is now 165 minutes versus
the original approximate 180. Other early milestone and expansion bounds remain.
This explicit tuning change is not a waiting timer or a claim of proven retention.

`tests/celebration_check.gd` checks the day-five warning, noon start, midnight
continuity, 1am cutoff, pure countdown reads, real orders/budgets, music timing,
extra visit patience, bounded shared traffic, no duplicated host bonus across
properties, actual report accounting, repeat-safe reload/close, different weekly
stories, closed-host behaviour, reputation's role, offline exclusion, v7-to-v8
migration and rejection of incomplete reports. Startup tests now load a day-seven
save to verify that the menu cannot start its pending celebration or age staff.

Seven `party-*` economy previews cover the day-six banner, countdown, live room
and bunting, live details, trading report, closeout and the next week's story.
They are rendered at 960 × 540 and 1280 × 720. Visual review covers the affected
controls and scene states across both sizes; no production image asset changes.
The actual economy supplies customers and orders. Local links and whitespace
are checked before commit. Saves are isolated by `tools/test.sh` and preview tools.

Signed release CI repeats the suite, builds all four platforms, checks APK
identity/checksums and smoke-tests Linux. Android device play, Windows/macOS
execution and whether human players stay interested after day seven remain
unverified. Final source/release status is tracked in [the handover](MERGE_HANDOFF.md).

## Previous v1.0.16 affordable-staff and bulk-delivery verification — 25 November 2026

Godot 4.7.2 `tools/test.sh` passed all regressions and **42 fresh campaigns**: the existing 39 routes plus three
early-bartender routes that save for a contract before other equipment. Hiring
policies use the actual ฿1,200 bartender price. The earliest active stage-three
results move below three hours by less than a minute, so that lower-bound check
now allows 179 minutes; other baseline bounds remain unchanged. This is an
explicit consequence of the requested cheaper contracts, not a new waiting timer.
The new first-hire route reaches a bartender in 4.2–4.7 minutes across three
seeds, with no injected cash or offline earnings. Measured ranges are recorded in [ECONOMY.md](ECONOMY.md#balance-verification).

`tests/bulk_stock_check.gd` covers six-to-twelve supplier terms, exact cash/space
boundaries, automatic operating reserves, save/reload, fridge reputation only
from happy departures and its cap, specialist reassignment fees, offline delivery
size and repeat safety. A short offline claim protects its opening cash and can
buy less stock than one long claim; the comparison checks no extra value is
minted, rather than promising identical working capital across claim boundaries.
Staff checks retain expiry, rehire, training and independent 25/20/15-second clocks.

Eight `bulk-*` economy previews were rendered at 960 × 540 and 1280 × 720.
Visual review covered all eight states across those resolutions:
hiring, Nida’s Welcome explanation, fridge description, supplier terms, blocked
cash/space and successful delivery. The graphics refresh is unchanged. Godot
4.7.2 is the pinned engine; the wrapper isolates all test saves. Local Markdown
links and `git diff --check` are checked before commit.

Publication repeats the full suite and exports signed packages through the main
release workflow. Android device play and Windows/macOS execution remain
unverified; previews and successful exports do not substitute for device play.

## Previous v1.0.15 music/automation verification — 25 November 2026

Godot 4.7.2 `tools/test.sh` passed the shared-economy regressions and **39 fresh campaigns**:
15 baseline/no-Chat runs, 12 promoter/alternative runs and 12 music/automation/
supplier runs. Six active baseline runs retain all original milestone windows.
Feature routes pay their own prices and must remain solvent, complete stage three
within ten simulated hours, and respect real orders and bounded street traffic.
Auto-serve policies stop manual Serve clicks once it is purchased.

`tests/automation_check.gd` covers music timing/budgets, purchase prices,
auto/manual timer sharing, fractional deadlines and rapid toggles, no-order
stock safety, two-second pouring, supplier levels/reserves and FIFO paid costs,
manager income without fabricated sales, closure, healthy-service exclusion,
five-second sampling, facing, schema-seven migration and repeat/split offline
settlement. Existing startup/clock/contracts/commission/tutorial/art checks remain.

Focused economy previews cover music and reversed Nida, ready/refilling/maxed
auto-serve, supplier and manager tiers, an empty managed bar's net rate and
closure. Eight scenarios were rendered at 960 × 540 and 1280 × 720. Production
textures are unchanged; indicators and mirrored facing are engine presentation.
Local Markdown targets and `git diff --check` are verified before commit.

The signed main-branch release workflow repeats tests, exports Android/Linux/
Windows/macOS, verifies the APK signer and checksums, and smoke-tests Linux.
Android device play, Windows/macOS execution, Windows updater execution and
human balance/audio feedback remain unverified. A build is not a device playtest.
Higher manager/supplier tiers have model regression coverage, not a fully measured
post-stage-three campaign balance claim.

## Previous v1.0.14 verification — 25 November 2026

The frontage/stock/capacity implementation includes the earlier TV/patience fix
and v1.0.13 consolidation. The [handover](MERGE_HANDOFF.md) identifies scope;
older individual-feature records below are historical.

- Godot 4.7.2 `tools/test.sh` passes: gameplay, staff timing, startup isolation,
  migration through schema six, pool, clock/raids, guided/tutorial flows, art,
  input and Windows updater regressions.
- Twenty-seven fresh campaigns pass: nine baseline target runs, six no-chat
  comparisons and twelve feature/alternative runs. Original active windows apply
  to the six active baseline runs. Optional promoter investment has a documented
  payback delay, not a new mandatory gate. See [measured pacing](ECONOMY.md#balance-verification).
- `tests/promoter_check.gd` covers all stage-one furniture combinations at twelve
  places; pack cash/room boundaries and supplier reserve; dedicated roster slots;
  commission rounding across reloads/rota/expiry; premium/discount drinks and pool
  exclusion; seven-person saves and corrupt-field rejection; retained stage-gated
  dancer/promoter training; no-order/no-sale; offline repeat/split claims, pack
  ledger reconciliation, protected opening cash and consignment repayment.
- Production previews cover Nida before hire, working/off duty, forecast/card,
  training/expiry, empty compact layout and twelve customers, all nine venue
  stages and closure. Nineteen promoter captures were generated at both 960 × 540
  and 1280 × 720. Inspected all nine room stages, entrance placement, readable
  hire/training/expiry controls and twelve-person order markers. Existing
  production room/cast assets are preserved.
- Source/art manifests and local documentation links are checked with the final
  diff. CI repeats the suite before signed Android and desktop export, checksum
  verification, Linux smoke testing and release publication.

Remaining verification: Android device input/lifecycle and human balance/audio
feedback, Windows/macOS execution and Windows update/restart/rollback. Desktop
captures and successful exports do not substitute for those playtests.

### Earlier sports-screen and order-warning checks

The preceding source passed all fifteen baseline pacing campaigns and rendered
23 TV/patience scenarios at 960 × 540, plus urgent-order checks at 1280 × 720.
Wall placement was inspected across nine stages, alongside dark fitted screens
and purchase/urgent/Chat/served states. These fixes are included in this branch.

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
| Active actions | Exact fractional refill boundaries, shared social cooldown, once-per-visit reassurance, upgrades/reserves, per-venue independence and UI state |
| Saves and guided shifts | Older-schema migration, backup recovery, shared timing and no click-through income |
| Startup menu | No simulation or writes before selection, disabled Resume without a valid save, backup recovery, cancellation, immediate new-game save and removal of erased progress from backups |
| Story and legacy modes | Incident responses, ongoing campaign, tutorial isolation and Godzilla outcomes |
| Presentation | Catalog resources/hashes, atlas frames/padding, host identity, property hit regions, scrolling, district paths and combat input |
| Pacing | Nine targets, six no-chat comparisons, twelve promoter/alternative runs, twelve automation runs; no injected money or offline income |

The six active-strategy runs must meet the configured milestone windows. The
three mostly-idle runs must complete without getting stuck. Six additional
manual-first/staff-first comparisons must finish without Chat. The mostly-idle and feature runs must stay solvent and complete within ten simulated hours.
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
- Use the economy runner with `PATTAYA_PREVIEW_FILTER='tv-*'` for a real screen
  purchase, all nine owned/unowned room pairs, and urgent/reassured/served order
  dots. Check the TV remains on the wall and the red marker clears after service.
  Regression checks cover saved ownership, property cache isolation, unchanged
  surrounding art, and patience/comfort/Chat/visit-time warning boundaries.

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

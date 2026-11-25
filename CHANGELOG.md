# Changelog

These entries describe source development, not published release versions.
Save-schema versions are not application release numbers. The current source's
player-facing overview is in [README.md](README.md).

## Source update — A clearer opening arc and shorter saving gaps

- Bartender training costs ฿400 then ฿800; first management costs ฿12,000.
- Final beer / Soi / gogo renovations cost ฿40,000 / ฿65,000 / ฿120,000 and
  require 450 happy visits, retaining 70 regulars and forty healthy shifts.
- Added Anong's Next Step in Service: live story progress and navigation to the
  relevant controls, without new rewards, timers or compulsory purchases.
- Measured pre/post-change fresh campaigns and added saving-gap acceptance checks.
  Existing progress, training, cooldowns and prices paid for old stock are retained.

## Source update — Bartender priority and Nida renewal

- Owner auto-serve now backs up staffed venues during queue overflow or imminent
  missed orders; quiet orders go to bartenders. Price remains ฿3,000.
- Nida renewal is visible in Frontage promoter, with the exact fee, retained
  payroll/stock reserve and missing cash. Contract expiry refreshes roster controls.
- Added live dispatch, renewal boundary and UI regression coverage; existing
  training, contracts, deadlines, stock commitments and saves are retained.

## Source update — Ready bartenders and affordable auto-serve

- Reduced owner auto-serve from ฿6,000 to ฿3,000; existing ownership is preserved.
- Bartenders start ready, automatically settle a real order, then recover for
  25/20/15 seconds. Empty queues and owner clicks no longer reset a warmup.
- Added the bottom-right staff sales/readiness/countdown indicator and linked
  serving poses to actual sales. Staff get first chance before owner automation.
- Schema nine preserves deadlines, fractional timing and actual-sale counters;
  old partial work migrates without resetting skills or contract time.
- Added regression and HUD checks, readiness previews and updated player,
  economy, story, development and agent documentation.

## Source update — A reason to reach day seven

- Added Anong's free day-seven birthday opening, with a two-day reminder,
  countdown, temporary room bunting and actual trading report.
- Added bounded extra shared traffic, stronger host appeal, third drinks within
  customer budgets, faster repeat timing and a little extra visitor patience.
- Weekly regulars' reunions, Pim's mixtape parties and Bo's thank-you nights
  follow. No real-world login requirement, cash claim or offline party bonus.
- Clarified reputation: it helps attract visitors; it does not increase budgets
  or repeat frequency. Music remains useful during parties.
- Schema eight retains party accounting and guest patience without removing
  existing progress. Added lifecycle/migration/boot-menu tests, 60 paired party
  scenarios, visual previews and updated story/design/player/agent documentation.

## v1.0.16 source — Affordable help and bulk terms

- Bartender hire/rehire now costs ฿1,200 for ten days, retaining wages, training
  and service timing. Hosts/dancers stay ฿4,500, with prorated role adjustments.
- Each fridge tier adds +1 reputation per ten satisfied visits, capped at 100.
- Supplier level two switches to twelve drinks for ฿144; later levels buy twelve
  for ฿120/96/72, requiring full cash and space. Old stock retains its paid cost.
- Explained Welcome upgrades while Nida is working. Added three first-hire
  campaign comparisons and atomic stock, offline, reputation and renewal tests.

## Source update — Music and automation

- Music costs ฿1,200 and reduces repeat-order time from 35 to 25 seconds.
- Nida faces toward the street using the existing production atlas.
- Auto-serve costs ฿6,000 and shares the manual Serve timer; pouring gains a
  stage-two two-second tier for ฿5,600. Welcome and Chat limits are unchanged.
- Manager tiers cost ฿18,000/36,000/72,000, earning separate ฿10/20/40 per open
  real second. They stop on closure and do not create drink sales or regulars.
- Supplier levels discount whole packs to ฿72/60/48/36. Saved inventory lots
  retain actual purchase costs; old stock is never repriced or refunded.
- Till shows net street trading per second, sampled every five foreground
  seconds. Updated forecasts, reports, legal-hours offline estimates and schema
  seven migration preserve existing paid appointments and prevent repeat credit.
- Added twelve feature campaigns alongside the existing 27, regression cases,
  focused visual previews and updated game/developer/agent documentation.

## v1.0.14 source — Compact seating, whole packs and Nida

- Added beer-bar seating level three: twelve guests at stage one with pool/fans,
  with compact bench production artwork and capacity previews.
- Manual and supplier purchases now buy exactly six drinks for ฿84 with shared
  cash/space checks. Offline deliveries consume actual inventory and buy whole
  packs from newly generated surplus; consignment costs are repaid once.
- Added Nida's separate frontage slot, ฿1,200 ten-day contract and 10% drink-only
  commission, retained visit/order commitments and saved fractional carry.
- Added stage-gated, retained audience training for promoters/dancers; forecasts,
  shift/promotion reports and offline accounting include commissions.
- Added four production poses, a portrait, schema-six migration, boundary/ledger
  regressions and twelve feature campaigns alongside the fifteen baseline runs.
- Updated product, story, player, economy, developer, art, testing and agent docs.
  Publication uses the main-branch signed multi-platform release workflow.

## Source update — Visible sports screens and impatient customers

- Sports-screen purchases now appear on the wall and in property thumbnails
  across all venue stages, using the existing TV artwork. Fitted beer-bar screens
  stay dark until purchased; existing saved purchases show immediately.
- Waiting-order dots turn red with ten seconds or less before patience or visit
  time expires, using the same model rule as Chat. Comfort and reassurance extend
  the warning window; fulfilled orders lose their dot.
- Added purchase/reload and presentation regression coverage plus owned/unowned
  TV and order-warning captures. No balance, prices or save-format changes.

## v1.0.13 source — Completed-chat consolidation and builds

- Combined the completed customer cast, New Game / Resume, day/clock, cooldown
  upgrades/Chat, staff contracts and current main's fan/passerby fixes.
- Added ฿4,500 ten-day contracts, personal 25/20/15-second service training and
  waiting-order audio; retained trained staff records after expiry for rehiring.
- Reconciled schema-five timers, boot-menu isolation, contracts and all test suites.
- Balanced the combined investment path with a ฿16,000 Soi starter lease. Preserved
  original active targets across six runs, plus nine idle/no-chat comparisons.
- Updated README, story, economy/player/developer/art guides and agent instructions;
  restored the completed research roadmap and replaced the stale merge handover.
- Prepared local multi-platform test builds; publication and device playtesting
  remain separate. See the handover and build manifest for revision and scope.

## Unreleased — Active service and customer chat

- Serve and Welcome now show ten-second base refills. Each venue can buy separate
  8/6/4-second action upgrades for ฿900, ฿1,400 and ฿2,800 per track.
- Added once-per-visit customer reassurance with ten extra seconds of patience
  and visit time; Chat shares Welcome’s timer and always recovers for twenty seconds.
- Added authoritative fractional cooldowns, eligibility feedback and schema-five
  migration preserving existing campaigns, deadlines and paid/free pool games.
- Retained progression targets with tested investment strategies; manual upgrades
  and Chat remain optional. Added action, UI, save and no-chat balance regressions.

## Unreleased — Visible campaign day counter

- Show an explicit DAY number above the clock, starting at Day 1 and using the
  existing saved calendar. Midnight advances it; offline estimates do not.

## Unreleased — Game clock and overnight preparation

- Added a one-game-minute-per-second clock, noon opening, 1am closing and nightly
  per-venue extensions to 3am; calendar days now change at midnight.
- Added distinct beer/Soi/gogo peak hours with extra attraction and twice the
  dirt per drink, including peak-aware legal-hours offline estimates.
- Added timed cleaning, manager cleaning, dirt affecting attraction and optional
  skipping to noon with unfinished preparation.
- Added late-operation heat, saved raid checks, per-stage fines and closure until
  noon, preserving owner closures and recovery routes.
- Restricted offline estimates to projected legal opening windows with a saved
  cursor. Added schema-four migration preserving existing campaigns.
- Kept original pacing windows with a small traffic adjustment and prep-aware
  fresh-campaign policies. Updated gameplay, story, save and testing documentation.
## 25 November 2026 — Fans follow equipment ownership

- Hide the wall fan until Fans & comfortable seats is purchased, in both the
  room and property thumbnail. Installed fans stop spinning when closed.
- Preserve the original room artwork, using small generated wall patches for
  unowned fans and a transparent purchased fan for Soi venues.
- Add purchase/save/renovation ownership checks, pixel-preservation checks and
  before/after previews for every venue stage.

## 25 November 2026 — Street passerby variety

- Replaced the repeating single-man street loop with three distinct existing
  patron appearances, alternating directions and a short gap between crossings.
- Kept each appearance stable throughout a crossing, independent of customer
  counts, saves and gameplay randomness. Added crossing previews and regression
  coverage for variety, continuity and outside-lane bounds.

## 25 November 2026 — Bar-scene perspective and layout

- Unified interior character scale, reduced Anong's foreground size, and placed
  bartenders behind the illustrated counters instead of on stools.
- Kept customers and both pool tables inside, placed passersby in the outside
  lane, and removed event crowds that did not represent actual customers.
- Sorted people and tables by depth, raised order dots above heads, and moved
  messages away from customers' feet. Kept existing production artwork.
- Added full/empty/closed visual fixtures and scene regression checks.

## Historical — Earlier branch consolidation

- Combined the progression and customer-economy histories with current upstream
  `main` (`87a0107`) on `codex/ready-for-main`; `main` itself was unchanged at that historical handoff.
- Preserved the Windows update feature while fitting its control into the new
  header. Kept current release metadata with the finished artwork icon paths.
- Prevented the headless update worker from running or autosaving a fresh street
  campaign while it replaces the executable; added integration regression checks.

## Unreleased — Documentation and handover

- Reworked the README into a current overview with play instructions and a
  documentation index; removed conflicting historical descriptions from it.
- Added [story.md](story.md) for the cast, chapters, venue identities and tone,
  separating current progression from future narrative hooks.
- Added [player guidance](docs/PLAYER_GUIDE.md) and a
  [testing/release reference](docs/TESTING.md).

## 25 November 2026 — Completed artwork integration (`1f97b70`)

- Integrated all 61 runtime textures, twenty animation atlases with 136 frames,
  nine interiors and nine matching exterior illustrations.
- Replaced temporary fighter fallbacks; added exterior cards to Empire.
- Kept customer occupancy, orders, pool states, rotas and scheduled performances
  connected to the live economy. Corrected mixed-team host identity and made
  pool table assignments persist through completion and reload.
- Imported sprite mirroring, pole alignment, district path, combat effect/KO,
  offline-notice Back and audio-shutdown fixes.
- Enabled the complete art-integrity suite and updated preview fixtures.
- Combined tests and pacing checks passed. Linux startup and Android debug APK
  export/signature checks passed; target-device playtesting remains separate.

## 25 November 2026 — Customer economy (`31ec7bc`)

- Replaced guaranteed click/staff sales with shared visitors, occupancy, budgets,
  waiting orders, service limits and stock settlement.
- Added stage-one pool purchases, ฿50 timed games, Free Pool Night, Happy Hour,
  Pool Tournament and Sports Night, including cooldowns and contribution reports.
- Added equipment, staff roles/rotas, timed operating costs, temporary closure,
  recovery shifts and per-venue renovation milestones with cash reserves.
- Unified guided shifts with the live model. Added demand-limited, repeat-safe
  offline projections and version-three save migration.
- Added regression checks, thirty paired promotion scenarios and nine fresh
  campaigns for pacing. This commit initially used a partial artwork snapshot;
  the completed-art integration above supersedes that limitation.

## 25 November 2026 — From One Bar to the Whole Soi (`93735b4`)

- Introduced three venue types with three stages each, eight owned properties,
  staff automation and managers.
- Added five milestone chapters, recurring street events and the repeatable
  After Hours Street Festival. Removed the mandatory one-year ending.
- Retained the cast, district exploration, optional tours and Toybox fights.
- Added version-two saves and migration of older campaigns.
- The initial guaranteed-sales economy in this iteration was replaced by the
  customer economy above; it is historical behaviour, not the current rules.

Earlier releases and changes remain available in the Git history and repository
release notes. This file intentionally does not invent release dates or assign
new version numbers to unpublished work.

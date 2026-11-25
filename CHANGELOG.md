# Changelog

These entries describe source development, not published release versions.
Save-schema versions are not application release numbers. The current source's
player-facing overview is in [README.md](README.md).

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

## Unreleased — Branch consolidation

- Combined the progression and customer-economy histories with current upstream
  `main` (`87a0107`) on `codex/ready-for-main`; `main` itself is unchanged.
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

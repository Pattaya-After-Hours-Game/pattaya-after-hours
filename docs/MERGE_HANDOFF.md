# Current implementation and release handoff

Updated **25 November 2026**. The day-seven/weekly celebration feature is on
**`codex/week-seven-celebrations`**, based on main `fe0068d` (published v1.0.16).
Affordable bartenders, bulk stocking, fridge reputation and prior music/Nida/
graphics work are already integrated. Other worktrees and attachments are preserved.

Anong's Birthday runs at the Blue Hour on the day-seven opening, noon to 1am.
Day-five warning, countdown, temporary bunting, bounded traffic, faster repeat
orders, an optional third drink and real trading reports give the mid-game a
predictable reward. Weekly reunions/mixtape/thank-you nights follow. There is no
fee, instant cash gift or offline event multiplier. New random announcements
wait during the party; already announced events continue. Reputation still
changes attraction, not per-visitor spending or order timing.

Schema 8 preserves active/last party ledgers and per-visitor patience. Migration
keeps existing ownership, contracts, cash and inventory costs; no retroactive
party payout. Existing v7 campaigns at/past day seven get their current/upcoming
calendar opportunity. Production textures/atlases remain unchanged.

`tools/test.sh` covers regressions, 42 fresh campaigns and 60 paired celebration
scenarios. The [testing record](TESTING.md), [economy evidence](ECONOMY.md#balance-verification)
and [design rationale](design/WEEKLY_CELEBRATIONS.md) record results and limits.
The user explicitly requested commit, build and deployment. Main's signed release
workflow supplies publication; verify its run and
[latest release](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest)
for the actual tag and source commit. Android device play and human retention
feedback remain separate from successful builds and simulations.

The earlier PR #4/#5 review scope is unchanged. This is a feature handoff, not a
new audit of every conversation. The consolidation audit below is historical.

## Historical consolidation audit

Checked on **25 November 2026**. The integration branch is
**`codex/consolidated-build`**, based on the completed local clock/perspective
work and merged with upstream `main` at `06cc3cb`. The original shared checkout
was preserved; this build uses `/home/zak/projects/pattaya-release-integration`.
This is a source/build handoff, not a claim that the latest downloads contain it.

## Chat audit

Every related chat found had a completed latest turn and was idle/not loaded at
the audit. None was still implementing work. Completion in a chat did not always
mean the files had been committed or included in main.

| Chat title | Result included or disposition |
| --- | --- |
| Build out Pattaya bar game | ฿4,500 ten-day contracts, individual training, waiting-order bell; `39c9862` |
| Redo game graphics and sprites | Nine added male customers including the supplied-reference guest; completed uncommitted files captured in `a503602` |
| Add service and welcome cooldowns | 10-second actions, 8/6/4 upgrades, Chat and schema-five saves; captured in `a503602` |
| Check whether progress persists | Paused New Game / Resume, confirmation and backup handling; captured in `a503602` |
| Add bar hours and raid risk | Clock, prep, peaks and raids (`85777c1`/`1273636`); day counter merged from `69afb4b` |
| Fix main bar scene scale | Perspective work plus varied passersby and owned-fan visuals; latest fixes already in main (`305fe89`, `60bec29`) |
| Build Windows test release | Earlier test package completed; superseded by this combined build |
| Assess organization impact on pushing | Organization remote and cleanup completed; original checkout and backups preserved |
| Research incremental game success | Completed research roadmap restored from backup and updated for current mechanics; proposals remain future work |
| Collect Pattaya reference images | Concept collection/mockups completed; intentionally gitignored authoring references, not runtime assets |
| Inspect Pattaya bar simulator | Setup and initial verification already integrated; no remaining implementation task |

No new gameplay feature was delegated or silently started from the research
backlog. Windows/macOS execution, Android device playtesting, human balance
feedback and maintainer review remain outstanding verification, not running chats.

## Integration decisions

- Keep all completed customer artwork, fans, street variety, boot-menu controls,
  clock/day, staff contracts and owner actions together. The catalog contains
  69 runtime textures and 145 frames across 21 sprite atlases.
- Keep schema 5 and fractional owner-action timers. Staff work uses independent
  saved timers. Contracts consume skipped/offline time; owner-action cooldowns
  do not. The paused menu consumes neither and claims offline time only on Resume.
- Keep ฿1,200 bartender / ฿4,500 host/dancer contracts and 25/20/15-second bartender service. For the combined
  investment curve, lower the Soi starter lease to ฿16,000. Existing owned assets
  and cash are preserved; no refund or migration reward is created.
- Preserve both test suites, including a bartender completing work during the
  owner's cooldown. Fifteen fresh campaigns test active, idle and no-chat paths.
- Upstream PRs [#4](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/pull/4)
  (mobile sparring) and [#5](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/pull/5)
  (individual drink inventory), authored by rknell, remain separate review work.
  They were not part of these completed chats and are not claimed as integrated.

## Verify and build

```sh
git fetch origin
git switch --track origin/codex/consolidated-build
tools/test.sh
env -u ANDROID_HOME -u JAVA_HOME tools/release.sh
```

Use an existing local branch if already created. `tools/test.sh` isolates saves;
the release script exports Linux/Windows/macOS, checksums the archives and smoke
tests Linux. Signed Android release builds require the existing key; local debug
APKs are test artifacts, not updates to the signed production application.

Local test exports may use an isolated staging copy with a `test-<commit>`
application version and a separate Android test package ID. These metadata
changes are recorded in `dist/BUILD_INFO.txt`; they do not change committed
release numbering. The Windows release checker ignores non-release version
labels, preventing a test build from offering an older public build as an update.

Source commits do not publish a release. A subsequent approved merge/push to
main runs the existing signed multi-platform release workflow. Do not discard
other working trees or replace current user saves as part of that handoff.

# Current implementation and release handoff

Updated **26 November 2026**. Main `e644c55` shipped as **v1.0.19** with staff-first
auto-serve and visible Nida renewal. The follow-up **`codex/opening-arc-balance`**
addresses the player's request to review story, rules, prices and grind together.
Other worktrees and user attachments are preserved.

Bartender training is ฿400/800, first management ฿12,000, and final beer/Soi/gogo
renovations ฿40,000/65,000/120,000. Stage three needs 450 happy visits while retaining
seventy local regulars and forty healthy shifts. Initial progression, contracts,
customer demand, owner/staff cooldowns, auto-serve price, birthday rules and later
manager tiers remain unchanged. Existing ownership is retained without refunds.

Anong's Next Step reads shared chapter requirements and current business progress.
Its button navigates to existing controls; it cannot purchase, award money or
advance time. No save schema change or extra compulsory quest is introduced.

Full regressions, 42 fresh campaigns and sixty paired party scenarios pass.
Compared with v1.0.19, the first-manager saving gap falls from 44–48 to 25–27
minutes; active stage three moves from 167–173 to 143–144. Four guidance previews
are inspected at 960 × 540 and 1280 × 720. See [testing](TESTING.md) and
[economy](ECONOMY.md) for measurements, revised bounds and limitations.

Ready for the authorized main merge and signed release workflow. Verify its run
and the [latest release](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest)
for the published tag/source. Human retention, full-festival pacing and device
play remain unverified. This handoff is not a new audit of every conversation.

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

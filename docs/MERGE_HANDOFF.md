# Current implementation and release handoff

## Profit-cycle implementation — 26 November 2026

Branch `codex/profit-cycle` preserves completed Gabby work in its own checkpoint
`1a23e49` above main `cc30403`, then adds variable visit plans, final-drink
turnover, expanded beer-bar tracks, shared frontage traffic, separate customer
profit and schema-13 saves. No other worktrees or attachments were changed.
See the [design](design/PROFIT_CYCLE.md), [economy](ECONOMY.md) and measured
[verification](TESTING.md#profit-cycle-verification--26-november-2026).

Gameplay/save/UI checks and matched bottleneck scenarios pass. Baseline stage
two is slightly faster than the existing lower target in two runs; five new
purchase-cadence medians are slightly below the requested three minutes. These
failures remain visible in tests. The user decision on keeping prices and
accepting faster lower bounds versus retuning is pending. Do not merge/publish
this branch as verified until that decision and the complete wrapper pass.
The local desktop export is not a signed Android release or device playtest.

## Gabby addition — local source, 26 November 2026

Adds a named adult bartender with pale skin, a very short red dress and her own
four-pose atlas/portrait. Service offers her normal ฿1,200 ten-day contract when
a floor slot is free; one Gabby may belong to the street. Her actual staff sales
add ฿5 each to the existing nightly bonus jar, stacking with matched-drink tips.
Renewal preserves identity/training/deadlines. Old workers retain their looks;
no migration rewards or offline tips are added. Schema remains 12.

The pre-existing Nida/pool work was preserved and reached `cc30403` while this
addition was underway. Combined tests and Gabby UI/art checks pass; see
[testing](TESTING.md). Gabby was preserved in local commit `1a23e49`, not yet a published build.

## Nida and pool update — 26 November 2026

Based on main `f1cc217`, published as v1.0.31. Nida's ฿1,200 ten-day fee remains,
with drink commission removed from live/offline settlement and forecasts. Old
uncharged commitments/carry are cancelled, while historical payments stay recorded
without refunds. Pool now starts thirty-second games for the same ฿50 per table;
Free Pool remains free, and already-running games retain their saved time/fee.
Schema remains 12 and existing progress is retained.

The user approved a 21-minute first-manager saving-gap target after the new pool
timing produced a 20m29s run. Prices and other pacing thresholds are unchanged.
The combined isolated suite and relevant Nida/pool previews are recorded in
[testing](TESTING.md). Main's workflow retests and publishes signed downloads;
verify its completion and the release tag before claiming a build is available.
Device play remains unverified; other worktrees and attachments are untouched.

## Previous stage-two income handoff

Updated **26 November 2026**. This work starts from main `0b00fc8` (published as
v1.0.30), retaining Ryan's drink inventory, tutorial, capybara, rainbow duo/dog,
rat event, tuning sandbox, upgraded UI and mobile sparring. Branch
**`codex/stage-two-regulars`** implements the requested day-eight income bridge
and the follow-up music/training upgrades.

- Regulars Club: ฿600/1,200/2,400, stage two, 10/20/35 local regulars. Invites
  35/65/100% of new visitors to stay longer with budget for a third round.
- Better sound: ฿2,400 after original music; stage-two repeat timing 25→18s.
- Advanced bartender training: ฿1,200/1,600 for 15→12→10s service at stage two.
- First manager: ฿8,000 instead of ฿12,000, same +฿10/open second and gates.
- Schema 12 retains existing progress, deadlines, prices paid and queues,
  without retroactive membership, free upgrades or manager refunds.

The isolated Godot 4.7.2 suite passes regressions, 48 fresh campaigns, 60 paired
party comparisons and 80 stage-two income scenarios. Four affected UI states
were rendered at 960×540 and 1280×720. See [testing](TESTING.md) and the
[design](design/STAGE_TWO_INCOME.md) for exact comparisons and limitations.
Main's push workflow tests again, exports/signs and publishes the release.
Verify the workflow and [latest downloads](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest)
for the actual published tag; this source record is not a publication receipt.
Android device play remains unverified. Other worktrees and attachments are untouched.

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

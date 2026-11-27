# Current implementation and release handoff

## Front/rear traffic in the bar opening — 27 November 2026

The bar now uses separate native front/rear walking and driving atlases for
approaching/departing traffic. Each of the four adults, two scooters and car has
four frames per view. Quiet traffic alternates direction between crossings.
District traffic retains its side-profile sheets. Original rooms, outdoor
underlays, density bands, ledgers and saves are unchanged. The updated bar motion
preview is [here](street-motion.gif); prompt receipts and authored walker crop
boundaries are in [the art guide](../art/README.md).

## Outdoor underlays and traffic — 27 November 2026

Built on main, retaining the concurrent Linux AppImage work in `4ba103c`.
Eight district atmosphere plates remain available. The bar opening instead uses
eight reusable clock-based street underlays behind an exact-pixel room shell.
The original nine interiors, furniture, equipment and stage-three beer terrace
remain intact. No production source/runtime room PNG is replaced.

Four walking adult identities, two helmeted scooters and a car each have four
frames. Shared read-only `street_view.gd` scales ambient traffic from actual
guests in trading venues; it creates no customers, receipts, RNG draws or save
fields. The bar tints pedestrians as subdued silhouettes and clips traffic
behind the doorway/terrace. District roads use the same separate animated atlases.

Full isolated tests and pacing pass; all activity/time bands, nine apertures and
motion were inspected at 960×540 and 1280×720. See [testing](TESTING.md),
[bar motion](street-motion.gif), [district motion](district-motion.gif) and
[packing/provenance](../art/README.md#street-activity--27-november-2026).
Target-device play remains unverified. Pushing main triggers the release workflow;
this source handoff does not claim that release downloads are already published.

## Separate tills, company funding and growth — 27 November 2026

This revision builds on main `4cfc7e4`, retaining the Rat Plague catch controls,
full swarm and Bo's overnight cleanup as well as the completed graphics refresh.
It supersedes the earlier upgrade-visibility-only fix and shared-wallet rules.

- Each venue owns its till, local costs, tips and five-second net sample. Company
  money lives in the bank. Tap Till for explicit transfers and Deposit surplus.
- Fund & buy covers only a local upgrade's cash shortfall. Leases spend bank
  money and transfer a startup float into the new property. No automatic bailout.
- Renovations need cash/reserve, with unchanged prices. Old customer milestones
  now earn +5%/+10% local loyalty appeal. Regulars Club keeps its regular gates.
- All venue types have frontage tiers 1/3/5 by stage. Ten bank-funded street
  marketing tiers add bounded shared traffic; additional open premises also
  attract a small shared audience.
- Managers cost ฿2,000/6,000/18,000 and earn 25/50/75% of real drink and paid-pool
  margin. They no longer earn independently of customer trade. Owned levels stay.
- Schema 16 conserves old cash plus reserve exactly, assigns working floats and
  banks surplus. It preserves paid inventory, venues, staff, training and visits.

Rules and measurements are in [finance and growth](design/FINANCE_AND_GROWTH.md),
[ECONOMY](ECONOMY.md) and [TESTING](TESTING.md). README, story, player guide,
DEVELOPMENT and AGENTS reflect the changed rules. Prior sections below describe
historical integration states, not the current list of worktrees or releases.

Verification: the full isolated combined suite passed, including all pacing
routes; the final stock-return regression and both visual sizes also passed. Device play remains unverified. The main release workflow repeats
all tests, exports signed Android and desktop packages, and verifies hashes before
publishing. Use the [release list](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases)
for the published version; source changes are not release downloads until CI completes.

## Combined graphics and controls update — 27 November 2026

The main checkout held the remaining changes. All other local and fetched
branch tips were already reachable from main, and Git listed no additional
worktrees. This update includes the four Blue Hour fridge cabinet tiers,
cobalt-shirt sunglasses animation, refreshed rainbow duo lighting,
demand-aware action refills, the full upgrade list by default, and the
expanded Toybox moves and controls.

The full isolated Godot 4.7.2 suite passed, and the affected states were
reviewed at 960 × 540 and 1280 × 720. See [testing](TESTING.md) for the
individual regression checks. The
[release workflow](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/actions/workflows/release.yml)
publishes signed downloads from main. Device play remains unverified.

The Upgrades follow-up groups cards by venue stage and budget, with a shortcut
from the stage summary to the live renovation requirements. Ready only still
shows local progress. The combined isolated suite passed again, and the
renovation and budget views were reviewed at both resolutions.

## Upgrade blocker visibility — 27 November 2026

User's wealthy Neon Mango screenshot exposed stage-locked training with no
obvious local renovation progress. Synced main through `860b56c`. Upgrades now
shows the selected venue's milestone counts and cash/reserve status above its
price-sorted list, including Ready only. View renovation navigates to its card
and reason; What counts explains healthy shifts. Locked cards display live
model reasons without a help tap. Prices, gates, saves and production art stay
unchanged; the screenshot alone cannot identify the player's unmet counter.

Full isolated suite and final regression checks pass; five preview states were
reviewed at two resolutions. README, story, economy and player guidance are
aligned. See [verification](TESTING.md#upgrade-blocker-visibility--27-november-2026).
Main's workflow retests and builds the release; verify publication in GitHub
before reporting a downloadable version. Device play remains pending.

## Combined release wrap-up — 26 November 2026

User requested all finished local and deployment work be committed, pushed and
built. Hosted drinks and Daisy are checkpointed in `20e032b`; integration
`7435f05` retains upstream simplified Service (`b5c1cf5`) and discounted specialty
packs (`366d56b`). Integration `d2d40e8` also retains the pinned Back controls
from `b0c9d13`. Daisy hiring uses the new Team help controls, and the Good Company
arrow opens Team directly. The other existing worktrees were clean and their
feature commits already belonged to upstream main. Personal attachments remain
outside source control.

The combined `tools/test.sh` suite passes with zero failures, including 66 fresh
campaigns. Final isolated gameplay/save/UI checks pass after the Back integration;
hosted-drink and Daisy previews were regenerated and inspected. See
[the integration verification record](TESTING.md#combined-release-verification--26-november-2026).
The push runs both GitHub workflows; the release job retests, exports Android,
Linux, Windows and macOS, verifies the Android signing certificate and archive
checksums, then publishes. Publication status and downloads are recorded by
[the release workflow](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/actions/workflows/release.yml)
and [tagged releases](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases).
Device play remains unverified.

## Hosted drinks / Good Company — integrated source, 26 November 2026

Built from synced `7c28019`; concurrent Daisy work was preserved. The Good Company
card adds genuine sponsored drinks alongside barfines. New interested guests
have one invitation per visit, topic matches add ฿40, and host training raises
base prices ฿180→220→260. Real stock, guest entertainment budgets and shared
service clocks settle every sale. Hosts keep appeal through twenty seconds of
company; three completions create thirty seconds of +2 appeal Room Buzz.

Paid auto-host rounds (฿1,500) finds matches and prioritises hosted-drinks-only
colleagues in a tie. Barfine automation goes first if both are enabled. No paid
rounds or Buzz are replayed offline. Schema 15 saves orders, quotes, activity,
flags and fractional timers; existing visitors keep their budgets/plans and
receive no invitations or grants. Production host art is reused.

Combined tests, final regressions, thirty comparison scenarios and two-resolution
previews pass; see [verification](TESTING.md#hosted-drinks--good-company--26-november-2026).
Committed together with Daisy in `20e032b` and integrated with upstream Service
and supplier changes. The combined release handoff above supersedes the earlier
local-only status.
Device play and player feedback remain pending.

## Daisy entertainer — integrated source, 26 November 2026

Adds the requested fictional adult counterpart to Gabby with pale skin, a fuller
bust, a red bikini/thong outfit, six-pose atlas and portrait. User clarified that
Gabby's references were AI-generated. Gabby and all existing runtime art remain
unchanged. Hostess bars offer **Hire Daisy · ฿4,500** under normal ten-day host
contracts, wages, reserves, training and availability. Appended host ID 6 is
stable across renewal/save/load and has the Chat topic; only one Daisy can hold
a roster place across the street. Existing host IDs are unchanged.

This addition was made in shared `main` at `7c28019` while the hosted-drinks task
edited economy/UI/save files. Those edits and attachments were preserved. No
commit or release was made by the Daisy task itself; the release wrap-up
subsequently committed it in `20e032b`. The combined wrapper and final
regression run passed; ten Daisy previews were reviewed. See
[verification](TESTING.md#daisy-verification--26-november-2026). Further concurrent
edits must be verified before release; Android device play remains untested.

## Hostess naming and expansion prices — 26 November 2026

User-approved follow-up in `codex/venue-pricing`, isolated at
`/home/zak/projects/pattaya-venue-pricing` from main `654a60b`. Completed host controls and bartender HUD work were preserved in separate
commit `ef17ddc` and merged into this branch.
This follow-up changes the lease ladder, repeat premiums, visible retirement
offers, model-owned opening quotes and type-1 display name. Renovation prices,
paid ownership and save identities stay unchanged. The complete combined
`tools/test.sh` run passed with zero failures, including 66 fresh campaigns.
Lease/UI previews and final live-control regressions pass. Both feature commits
are included in the main integration; its workflow retests and publishes signed
downloads. Check workflow completion before claiming a published release.

## Bar-fine controls — local working tree, 26 November 2026

Pulled main from `dadd995` to `654a60b` before editing, retaining the prior local
bartender HUD. This includes upstream Soi Dispatch events and the Cart Jam /
bed-race graphics and controls. The combined isolated suite passes; see
[verification](TESTING.md#bar-fine-controls-verification--26-november-2026).

Hostess bars now expose an in-room Accept button and matching Service controls.
Willing hosts earn ฿500 per actual affordable request, leave for thirty foreground
seconds and lose their appeal until returning. Auto-accept costs ฿3,000 and has
an on/off toggle. Personal host training costs ฿1,500/3,000 at stages 2/3, raising
appeal 0.6→1.2→1.8 and future fees ฿500→750→1,000. Consent, contracts, budgets,
booking capacity and operating reserves still apply; no offline booking fees.

Schema 14 retains automation, host training, fractional return deadlines and
booking reports. Old paid absences retain their original shift return with no
repayment. Timed bookings and the bed-race runner return independently. Existing
art and personal attachments are untouched. These changes and the bartender HUD
were subsequently committed as `ef17ddc` for the combined pricing release.

## Bartender HUD — local working tree, 26 November 2026

Based on synced main `dadd995`. Replaces the bottom-right aggregate with a compact
selected-venue portrait roster at the top right: training-based levels, red
cooldown fills, availability labels and the existing shared unpaid tip jar.
Four rows fit before scrolling; row/arrow taps open Service. Uses existing
production portraits and saved staff deadlines, with no economy or save changes.
This update is included in checkpoint `ef17ddc`. See the current
[verification record](TESTING.md#bartender-hud-verification--26-november-2026).

## Profit-cycle implementation — 26 November 2026

Branch `codex/profit-cycle` preserves completed Gabby work in its own checkpoint
`1a23e49` above main `cc30403`, then adds variable visit plans, final-drink
turnover, expanded beer-bar tracks, shared frontage traffic, separate customer
profit and schema-13 saves. No other worktrees or attachments were changed.
See the [design](design/PROFIT_CYCLE.md), [economy](ECONOMY.md) and measured
[verification](TESTING.md#profit-cycle-verification--26-november-2026).

The user confirmed keeping prices and accepting stage two from 28 minutes and
2.5–5-minute median flagship purchase cadence. Other bounds remain unchanged.
Gabby is already committed as `1a23e49` and included in the feature branch; no
second copy or re-hire migration is necessary. The complete Godot 4.7.2 `tools/test.sh` wrapper passed with zero failures,
including Gabby and all 57 fresh campaigns. Both features are included in the
main integration. Main's workflow retests, exports and publishes signed downloads;
verify its completion before claiming the release is available.
The local desktop export is not a signed Android release or device playtest.

## Gabby addition — included in main integration, 26 November 2026

Adds a named adult bartender with pale skin, a very short red dress and her own
four-pose atlas/portrait. Service offers her normal ฿1,200 ten-day contract when
a floor slot is free; one Gabby may belong to the street. Her actual staff sales
add ฿5 each to the existing nightly bonus jar, stacking with matched-drink tips.
Renewal preserves identity/training/deadlines. Old workers retain their looks;
no migration rewards or offline tips are added. Schema remains 12.

The pre-existing Nida/pool work was preserved and reached `cc30403` while this
addition was underway. Combined tests and Gabby UI/art checks pass; see
[testing](TESTING.md). Gabby was preserved in commit `1a23e49` and included with the profit-cycle integration.

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

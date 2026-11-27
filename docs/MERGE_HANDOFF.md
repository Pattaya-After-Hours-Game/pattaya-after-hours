# Current implementation and release handoff

## Hidden Shotgun Easter egg — 27 November 2026

User correction: keep the interaction hidden. Removed the cooldown/countdown
and patience-bonus feedback, restoring only the original ribs/shout bubble.
The saved 30-second shared cooldown and +5-second patience effect remain.
Player documentation no longer gives away the interaction or mechanics.
See [verification](TESTING.md#hidden-shotgun-easter-egg--27-november-2026).
Concurrent tour and closure changes are preserved outside this commit.
Device play and release publication remain unverified.


## Tour manager and individual guide training — 27 November 2026

Adds independent tour manager purchases (฿2,000/4,000/8,000) and personal guide
training (฿800/1,600). Automation renews eligible guides on their last route only
on normal live plan ticks, with cash strictly above ฿1,000 and an open venue
with space and more than two game hours before its scheduled close. Manager
levels 2/3 save 10%/25% on future fees; guide levels 2/3 add 10%/25% appeal to
the same bounded arrival draw. Saved agreements are never charged again.
Optional schema-17 fields preserve the toggle, levels and last routes; missing
fields grant nothing. Navigation, startup menus and offline claims never book.

The full isolated `tools/test.sh` passed on tour commit `50d7a55`, including
all pacing and balance suites; focused checks and two-resolution previews also
passed. Verification and remaining platform limits are recorded in
[testing](TESTING.md#tour-manager-and-guide-training--27-november-2026).
Concurrent Shotgun and incident-recovery work in the shared checkout is preserved.
The main release workflow determines when source changes reach downloads.

## Shotgun patience boost — 27 November 2026

Click/tap Shotgun to give all current customers across the street +5 seconds
of patience, with one saved 30-second live cooldown shared across venues.
The eating bubble reports the bonus, then the remaining cooldown appears above
Shotgun. Optional schema-17 fields retain exact deadlines and granted visit
bonuses without changing old visits or replaying rewards on load. All money,
orders, stock, modern drinking deadlines, visit plans and RNG stay unchanged.
This supersedes the original cosmetic-only click behavior below.

Verification includes model/UI/save regressions, two-resolution preview review,
all pacing suites and isolated Shotgun-only focused tests; see
[the test record](TESTING.md#shotgun-patience-boost--27-november-2026).
Concurrent tour-manager edits are preserved outside this commit. Device play
and release publication remain unverified.


## Shotgun — 27 November 2026

Added the supplied-reference adult Shotgun as a normal customer, with an
independent named-pose sheet. Click or tap for ribs-eating animation, exact
“Shotgun BBQ!” bubble and a mute-aware synthetic shout. Identity survives saves;
existing guests, business rules and gameplay RNG stay intact. No new food
purchase or economic reward is introduced. Source/recipe/audio provenance is
committed alongside the runtime assets.

The full isolated suite, final regression rerun, authoring test and two-resolution
visual previews passed; see [verification](TESTING.md#shotgun-customer-and-ribs-reaction--27-november-2026).
Target-device play and release publication remain unverified.


## Continuous motion, beer and customer templates — 27 November 2026

Fixes the real Serve/HUD redraw path that recreated City and discarded walking
state. The live room, route records and gait phase now survive redraws; existing
records never reseed to destination feet. Frame budgets prevent catch-up jumps,
small aisle adjustments retain facing and sitting starts after arrival. Physical
silhouettes reserve chair clearance, and standing/conversation targets avoid
seated bodies. Game capacity, visits, service and accounting remain unchanged.

Fifteen new beer sheets add carrying walks, lowered/seated sipping and standing
front/rear glass poses. Each customer now has one independent complete runtime
atlas with a named-pose definition under `art/characters/`. Selected-character
builds leave all other PNGs untouched; a shared pose can be appended and locally
repacked across the cast without regenerating approved art. The runtime catalog
is explicitly included in each export preset. Existing saved appearance mapping,
companion poses and original source/packed assets stay intact.

The complete combined isolated suite, real-Serve continuity regressions, Python
authoring contracts and exported-resource checks pass. Visual review includes
both resolutions and a 30fps real-button return clip; see
[verification](TESTING.md#continuous-customer-motion-and-individual-templates--27-november-2026).
The concurrent AFK implementation is preserved. Device play and publication
remain unverified.


## AFK mode — 27 November 2026

User-requested scope: unattended street-incident purchases and existing staff
renewals only. AFK uses normal shared-cash offers, completes paid rat cleanup and
prepared Godzilla visits, and suppresses interrupting notices. No automatic
upgrades, leases, new hires, venue promotions or supplier specials. Prepared
monster visits finish without manual minigame prizes. Unaffordable rats use the
existing close-for-day recovery; other setbacks remain recoverable.

Additive schema-17 flags retain opt-in preference and expired staff rota; menus
and offline estimates never execute AFK purchases. Tutorial, Events help,
README, story, economy, player and agent rules describe the resulting behavior.
The full isolated suite, expanded regressions and two-resolution AFK visual
checks pass. This change is prepared for the main release workflow; verify its
publication before treating it as a downloadable build. Concurrent title-screen
and customer-graphics work in the shared checkout is preserved. See
[the test record](TESTING.md#afk-mode--27-november-2026).

## Customer social routines — 27 November 2026

The customer animation follow-up adds real seated art for every identity and a
presentation-only room routine. Ordinary pending orders approach the counter;
service sends guests back to reserved chairs. Between rounds visitors can pair
up to mingle or use two viewing places at a purchased sports screen. Active
pool games and host rounds retain their model assignments. Long journeys use
the clear floor aisle. A departing neighbour does not shuffle occupied chairs.

Fifteen four-pose built-in ImageGen sheets add seated idle/drinking/conversation
and a planted rear watcher. Prompts, sources, authored cuts, scoped packer and
review tooling are committed alongside the runtime atlases. Existing art and
save identities remain intact. Visual routes never gate service, create buyers,
change budgets/timers/stock, extend visits or grant income/tips/loyalty.

Rebased onto the concurrent shared-account change `65fe5c1`, preserving its
schema-17 model and documentation. The full combined isolated `tools/test.sh`
passed, including pacing; placement regressions also passed. Sixty new poses and 199
in-engine captures at each of two resolutions were reviewed. See
[verification](TESTING.md#customer-social-routines--27-november-2026).
Device play and release publication remain unverified.


## One shared account and closing tips — 27 November 2026

The user's requested simplification replaces separate tills, bank transfers and
purchase reserves. Work is in the shared main checkout, based on freshly synced
upstream `eb96a48`. These source changes and the local Linux debug export are
not a published release.

- `s.cash` is the sole spendable account. All venues earn and pay from it;
  venue reports retain attribution. The MONEY HUD opens Money & costs with
  named rent, electricity, wages and recent transactions.
- All purchases require their listed price alone. Leases no longer transfer
  startup floats. Prices, physical gates, customer demand and production art
  are preserved.
- Close & count tips pays only the existing earned jar once, pauses running
  costs and lets the player restock while closed. Existing consignment remains
  for small jars. Recovery suspends collection of an unpaid bill without
  deleting the bill or granting cash.
- Schema 17 combines schema-16 bank, all venue tills and legacy reserve exactly;
  earlier shared-account saves conserve cash plus reserve directly. No assets,
  paid stock costs, visits or deadlines are reset, refunded or revalued.
- The user approved accepting quicker purchasing while keeping prices unchanged:
  active stage-two investment cadence now accepts a 2m20s median, previously
  2m30s. The retained baseline measures 2m26s minimum. Other pacing bounds remain.

See the [current plan](design/FINANCE_AND_GROWTH.md) and
[verification record](TESTING.md#one-shared-account-and-closing-tips--27-november-2026).
The complete isolated `tools/test.sh` passed with zero failures, including all
66 fresh-campaign runs and the paired scenario suites. Two-resolution visual
checks and an isolated Linux export startup also passed.
Target-device play remains unverified. Older finance and tour-routing entries
below are historical and are superseded by this record.

## Full customer animation cast — 27 November 2026

Fourteen new reference-preserving sixteen-frame sheets complete all fifteen
existing customer identities alongside the charcoal guest. Side/front/rear
walks and idle/drinking/Chat/pool poses are packed into forty-two new runtime
atlases. Original images, companion idle/kiss/sunglasses reactions and saved
identities remain intact. Exact built-in ImageGen prompts and source cuts are
committed with a deterministic scoped packer and review tool.

The visible room now interpolates real arrivals and pool transitions, keeps
surviving guests in stable floor slots and hit-tests their displayed frames.
Orders stay immediately serviceable while walking. Street traffic rotates
through the full cast within its existing density caps. All position caches are
presentation-only; no economy, save, RNG or progression rules change.

The full isolated `tools/test.sh` passed with zero failures, including pacing.
All new sheets/alpha edges and 83 in-engine views at each of two resolutions
were reviewed; deterministic repacking preserves every original production PNG.
See [verification](TESTING.md#full-customer-animation-cast--27-november-2026).
Device play and release publication remain unverified.


## Shared notification badges — 27 November 2026

All tab notifications now use `scripts/status_badge.gd`: green numeric counts,
yellow warnings and red exclamation alerts. The component owns compact sizing,
font, border, hover/pressed colours and keyboard focus. Tab layout, click sound,
tooltips and model-driven visibility remain in `main.gd`. Upgrade counts now
match active-tour counts. No economy or save change.

Badge regressions and two-resolution in-engine previews are documented in
[TESTING](TESTING.md#shared-notification-badges--27-november-2026).
Source changes do not confirm release publication; device play is unverified.

## Action readiness and event timers — 27 November 2026

Serve, Welcome and Chat now share the bright mint ready-button style and dark
caption, retaining the existing refill and eligibility rules. Timed street-event
banners and Events details show a draining time bar; active venue promotions
show the same bar in Events. Seconds remain visible, and active Rat Plague
remains untimed. Presentation reads existing timers; no economy/save change.

Focused action/event/promotion previews are available with
`PATTAYA_PREVIEW_SCRIPT=tests/preview_economy.gd PATTAYA_PREVIEW_FILTER='timers-*' tools/preview-art.sh`.
See [testing](TESTING.md#action-readiness-and-event-timers--27-november-2026)
for verification. Source updates do not confirm published release downloads.

## Charcoal reference guest — 27 November 2026

Adds the user's supplied adult likeness as an ordinary customer and fifth street
walker. Sixteen authored frames cover side/front/rear walking, idle, drinking,
Chat and pool. Built-in ImageGen source, exact prompt, deterministic packer and
three runtime atlases are committed together. Existing production assets remain
intact. New admissions alone receive the optional cosmetic appearance; old saved
guests retain their look, budgets, plans and quotes. No prices, demand or RNG change.

Sprite/save/scene regressions and two-resolution art review are documented in
[TESTING](TESTING.md#charcoal-reference-guest--27-november-2026). Device play is
unverified; source on main is not a receipt for published release downloads.

## Tour funding clarity — 27 November 2026

Follow-up to `2ad8d36`: Tours now pays guides directly from the selected venue's
till and starts the agreement in one tap. Removed the deposit popup and bank
transfer step. Quotes and validation use the same local balance; company-bank
wealth cannot cover a local shortfall. Other guide eligibility rules still apply.

Guide pay is recorded once in weekly costs and stays outside the five-second
trading sample. Existing agreements retain their terms, with no refund or extra
charge. Navigation is pure. Other finance routing and save formats are unchanged.
The full isolated combined suite and two-resolution visual review passed,
including the charcoal-guest work committed separately as `ed4136a`.
See [testing](TESTING.md#tour-funding-clarity--27-november-2026). Target-device
play remains unverified; source changes do not confirm release publication.

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

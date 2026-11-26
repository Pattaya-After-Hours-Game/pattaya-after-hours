# Testing and release checks

## Separate finance and growth — 27 November 2026

The release gate remains the isolated `tools/test.sh` on pinned Godot 4.7.2,
including all existing balance suites. Current acceptance windows remain stage 2
28–45 minutes, second property 75–115, stage 3 110–210, manager-saving gap ≤21,
longest investment gap ≤38 and active profit-cycle median 2.5–5 minutes. Older
measurements and acceptance windows below are historical.

`finance_check.gd` verifies separate fresh balances, exact transfer conservation,
no invalid/foreign transfers, lease floats, atomic Fund & buy, stale-price
rejection, local insolvency, FIFO-margin bonuses and fractional carry, paid/free
pool, consignment repayment counted once, loyalty, all ten marketing tiers,
save conservation/reload, malformed finances, local offline credit and repeat
safety. Its four-venue ฿700k scenario funds three new renovations with no local
loyalty and verifies that marketing creates no sales. UI coverage checks the
funding control, custom-transfer controls and pure navigation.

All legacy regression fixtures now distinguish venue money from company funding.
Pre-schema-16 fixtures reconstruct their old shared wallet explicitly. Balance
policies deposit actual earned money for leases/preparations/marketing, hire into
new-property floats, and choose useful investments from forecast improvements.
They receive no extra starting cash. Rat-catching and Bo's overnight cleanup
from main `4cfc7e4` are included in the combined scenarios.

Fresh baseline active policies, seeds 11/72/291, measured:

| Milestone | Observed elapsed active play |
| --- | --- |
| First small investment | 2m37s–3m40s |
| First pool table | 13m00s–17m56s |
| Stage two | 29m03s–33m32s |
| First manager | 46m56s–51m52s |
| Second property | 96m41s–109m24s |
| Stage three | 131m53s–143m39s |
| Manager saving gap | 2m16s–3m20s |
| Longest investment gap | 19m35s–23m08s |

`finance-*` economy previews cover Cash & Bank, the rich-company upgrade list,
Ready-only renovation and per-venue marketing forecasts at 960×540 and 1280×720.
Production graphics are retained. The full isolated suite passed; the final
stock-return cashflow regression also passed. Active profit-cycle median
investment gaps were 164–196.5 seconds (2m44s–3m16.5s), within 2.5–5 minutes.
These checks are not an Android device playtest.

## Rat Plague

The street checks cover guests fleeing with and without the patrol, Bo
sweeping the full swarm down to six, clearing on the last catch, ongoing swarms
surviving reload, and overnight cleanup before and after midnight. The UI
check sends a mouse click and a touch through the viewport with Events open,
checks the counter, and uses the overnight action. The `event-10-*` previews
cover the warning, Dispatch, full swarm, patrol, stragglers and cleanup.

## Celebration notices — 27 November 2026

Celebration checks cover no day-five notice, **Tomorrow** on day six, **Today**
before noon, live details at opening, and the report after the 1am close. They
also cover opening via the overnight skip and keeping a separate street alert
visible during the celebration. The `party-*` economy previews cover these
states at 960 × 540 and 1280 × 720.

## Cobalt-shirt sunglasses — 27 November 2026

The art check covers raising the sunglasses, fitting them, wearing them, removing
them and repeating the loop. The `sunglasses-*` previews show each pose in the
Blue Hour at 960 × 540 and 1280 × 720. The nine original atlas cells and the
animated guest's lower body were checked for pixel-for-pixel alignment.

## Blue Hour fridge art

The art checks compare consecutive fridge variants at each renovation stage.
The UI check uses the four paid upgrade buttons, verifies the room reveal and
thumbnail, then reloads the saved cabinet without replaying the cold puff.
The `blue-hour-fridge-*` economy previews cover all tiers, a renovated room
with the starter cabinet, and stocked and empty versions of the final tier.
The previews were inspected at 960×540 and 1280×720.

## Demand-aware action refills — 27 November 2026

The isolated Godot 4.7.2 `tools/test.sh` suite passes. Action checks cover
grey refill progress without orders, an eligible Chat guest or a free seat,
and a live switch to green at the same refill progress when demand changes.
The `actions-*` economy previews were inspected at 960×540 and 1280×720.
The Linux export passed isolated startup and opened on the local desktop.

## Companion animations — 27 November 2026

The isolated `tools/test.sh` suite passes on Godot 4.7.2, including the
capybara frame sequence, mouse double-click, simulated touch tap, return to
idle, and unchanged order and campaign state. The `companion-*` art previews
were checked at 960×540 and 1280×720. The Linux export starts headless and
opens a desktop window. Physical touch-device play remains unverified.

## Upgrade blocker visibility — 27 November 2026

Synced through `860b56c`, retaining price ordering and live cash shortfalls.
`tools/test.sh` passes with zero failures across the gameplay/save/UI suite,
66 fresh campaigns, 60 celebration scenarios, 80 club scenarios and 120 paired
profit-cycle scenarios. Final isolated `tests/check.gd` passes after navigation
polish. No economy values or save fields changed.

Guidance checks cover a rich street with an unqualified new hostess venue,
selected-venue counts, Ready-only visibility, live progress while still locked,
exact renovation reserve, purchase-to-stage-three progress and final-stage
suppression. Navigation and display preserve the model and RNG. Existing price
sorting, locked training, pointer navigation and supplier-shortcut checks pass.

Five `renovation-*` economy previews were inspected at 960×540 and 1280×720:
local progress, Ready-only, help, renovation blockers and a one-baht reserve
shortfall. The renovation shortcut brings its explanation into view. Production
art is unchanged. Local doc links and `git diff --check` pass. Android/device
play remains unverified; the main release workflow builds and publishes packages.

## Combined release verification — 26 November 2026

The combined hosted-drinks / Daisy source was reconciled with simplified Service,
supplier specials and pinned Back navigation through `d2d40e8`. The full isolated
`tools/test.sh` run passed: gameplay/save/UI checks, 66 fresh campaigns, 60 paired
celebration scenarios, 80 club scenarios and 120 paired profit-cycle scenarios.
A final isolated `tests/check.gd` pass verifies the last Back integration and the
Good Company arrow opening Team. Daisy hire/rota/renewal and sponsored-drink
automation checks use the new Team navigation.

Regenerated seven hosted-drink and ten Daisy previews at 960×540. Inspected the
combined room, hire control and Team view; the final Team view includes the pinned
Back control. Earlier 1280×720 hosted previews remain documented below. Local
documentation links and `git diff --check` pass. The release workflow independently
repeats the full suite, exports all four platforms, smoke-tests Linux and verifies
the Android signing certificate and release checksums before publication. These
checks do not substitute for Android, Windows or macOS device play.

## Hosted drinks / Good Company — 26 November 2026

Started from synced main `7c28019`, preserving concurrent Daisy roster/art work.
Godot 4.7.2 `tools/test.sh` passes the combined gameplay/save/UI/art checks, 66
fresh campaigns, 60 celebration scenarios, 80 club scenarios and 120 paired
profit-cycle scenarios. A final isolated regression run passed after UI polish,
fractional-hosting and duplicate-order save checks; focused hosted-model checks
also pass after the zero-sized service guard.

`hosted_drinks_check.gd` covers pure topic/price offers, one real sponsor per round,
stock and entertainment-budget settlement, no extra visit tips/personal rounds,
unchanged accepted quotes, normal bartender clocks, fractional paid-round reload,
bounded stockouts/timeouts, once-only Buzz, finite shared traffic, automation
priority/toggles, booking conflicts, offline exclusion, closure and schema-14
migration. Actual HUD invitation, Serve and automation purchase are exercised.

Seven `hosted-*` economy states were reviewed at 960×540 and 1280×720: matching,
waiting, paid company, Buzz, Service, upgrades and closure. Final small-meter
polish was recaptured at 960×540. Existing production art is retained, alongside
the separate Daisy addition. Local links and `git diff --check` pass.

Thirty controlled ten-minute scenarios compare ten identical seeds for each
policy, with a stage-three hostess bar, three hosts, one twice-trained bartender,
stock delivery, owner auto-serve and auto-barfines. The other venue is closed and
random events are suppressed equally. Starting setup purchases are excluded;
these are operating comparisons, not fresh-campaign pacing or guaranteed returns.

| Policy | Total net cashflow | Hosted sales | Hosted receipts | Service misses |
| --- | ---: | ---: | ---: | ---: |
| Barfines only | ฿72,708 | 0 | ฿0 | 37 |
| Also auto-host | ฿79,492 | 175 | ฿35,620 | 64 |
| Also train each host once | ฿96,302 | 188 | ฿45,320 | 86 |

Extra company improves aggregate net by about 9%; adding training reaches about
32% over barfines alone, but increases service pressure. Every scenario keeps
sales bounded by orders and arrivals bounded by offered traffic. Device play,
long-run human balance/retention and publication remain unverified.

## Daisy verification — 26 November 2026

Godot 4.7.2 `tools/test.sh` completed with zero failures in the shared checkout.
An additional isolated `tests/check.gd` run passed after the concurrent hosted-drink
checks joined the runner. Daisy regressions cover venue/affordability gates,
paid hiring, one street-wide roster place, coexistence with Gabby, no bartender
sales or bonus, rota attraction, host training, actual booking fees, save/load,
retained return deadlines and the visible hire/renewal controls.

`PATTAYA_PREVIEW_SCRIPT=tests/preview_daisy.gd tools/preview-art.sh` produced ten
960×540 captures, visually reviewed for hiring, roster, all three hostess stages,
off-duty/away/closed states, expiry and renewal. The hire view was recaptured to
include its button. Atlas and portrait were inspected directly. All 79 pre-existing
runtime manifest entries remain identical; only Daisy's atlas and portrait were
added. Local documentation links and `git diff --check` pass. Device play and
release publication were not performed for this addition. These checks cover the
checkout at verification time; further concurrent changes need their own checks.

## Lease ladder and Hostess Bar verification — 26 November 2026

Godot 4.7.2 `tools/test.sh` passes with zero failures on the isolated pricing
branch and again after merging host/HUD checkpoint `ef17ddc`: gameplay/save/UI
checks, 66 fresh campaigns and the existing 60 party,
80 club and 120 profit-cycle scenarios. New lease tests verify the inherited-bar
exemption, non-compounding repeat prices, exact reserve boundaries, actual
payment, rotating offers, reload preservation and stage-one manager gating.

Across three matched balanced seeds, second-property opening takes 84.2–92.2
minutes for beer bars, 92.5–103.5 for hostess bars and 129.8–139.3 for gogos.
Their first stage-three flagship takes 123.6–134.3, 129.9–142.8 and 165.4–175.6
minutes respectively. All remain solvent and demand-limited. The cheaper beer
route is intentionally useful; stage-two managers still need earned venue
progress, and later story chapters still require a mixed street. No manager
income, renovation price or existing pacing criterion changed.

The baseline active hostess route reaches property two in 92.5–103.5 minutes
and stage three in 129.9–142.8, with longest investment gaps 33.9–36.2 minutes.
Empire previews at 960×540 and 1280×720 cover the three leases, repeat surcharge,
shortfall and an explicit retiring-owner offer. No production assets were replaced.
The final UI regression rerun also verifies live affordability and offer expiry
without reopening Empire. Combined previews include the Hostess room/badge and
the preserved portrait HUD. Device play and full-festival balancing remain
unverified; source verification is separate from publication.

This document separates automated checks, visual review and platform testing.
It is a handover checklist, not a claim that every platform has been played.

## Bar-fine controls verification — 26 November 2026

Synced main to `654a60b` before implementation and restored the local bartender
HUD without conflicts. Godot 4.7.2 `tools/test.sh` passes with zero failures:
gameplay/save/UI/art regressions, 57 fresh campaigns, 60 celebration scenarios,
80 club scenarios and 120 paired profit-cycle scenarios. This includes the
pulled Soi Dispatch events and both full-screen event minigames.

`bar_fine_check.gd` verifies real affordable requests, consent, a once-only ฿500
base receipt, appeal loss, no fabricated drink/tip receipts, exact fractional
thirty-second returns, report boundaries, save/reload and schema-13 migration.
It also checks stage/reserve limits, ฿750/1,000 trained fees, increased expected
customer share without increased street traffic, retained skills, rota/expiry/
rehire, offline exclusion, auto-accept/toggle behavior, malformed save rejection,
visible UI acceptance and independent returns for the bed-race runner.

Nine `barfine-*` economy previews at 960×540 and 1280×720 cover acceptance,
absence, return, Service, upgrades, automation, a full host roster and closure.
Existing production portraits and room art are retained. Documentation links and
`git diff --check` pass. Changes are local and unpublished; Android/touch-device
playtesting and long-run player balance feedback remain unverified.

## Bartender HUD verification — 26 November 2026

The top-right portrait list replaces the old aggregate indicator. UI regressions
cover six bartenders with Nida excluded, Gabby's portrait, fractional recovery,
training during an existing cooldown, off-duty/expired states, the shared bonus
jar, pure rendering and navigation to Service without campaign changes.

The isolated Godot 4.7.2 `tools/test.sh` suite passes, including gameplay, saves,
UI/art and all pacing scenarios. Economy previews were inspected at 960×540 for
recovery, readiness, six-person scrolling and closure, and at 1280×720 for the
full roster. Existing production portraits are retained. Documentation links and
`git diff --check` pass. Android/touch-device playtesting and publication of this
working-tree update remain unverified.

## Profit-cycle verification — 26 November 2026

Main integration includes `codex/profit-cycle` (`b48b427`) and the separate Gabby
checkpoint `1a23e49`, based on `cc30403`. Source and release status are distinct.

Gameplay/save/UI regressions pass, including variable visit plans, final-drink
occupancy, happy one-drink departures, budget/stock limits, pool completion and
bounded waiting, locked tiers, paid upgrades, preserved cooldowns, schema-13 and
legacy visits, malformed tiers and read-only profit/visit views. Existing Gabby,
nightly tips, commission-free Nida and thirty-second pool checks remain included.

All promoter, automation, celebration and Regulars Club suites pass separately.
The new 120 paired bottleneck scenarios pass: ten seeds × four bottlenecks ×
three choices, each trading for 600 seconds. Total operating contribution:

| Bottleneck | Baseline | Matching purchase | Unrelated purchase |
| --- | ---: | ---: | ---: |
| Seats | ฿27,632 | ฿36,608 | ฿29,084 |
| Drinking turnover | ฿27,632 | ฿34,980 | ฿29,084 |
| Service | ฿14,300 | ฿19,756 | ฿14,300 |
| Appeal | ฿27,764 | ฿38,984 | ฿27,764 |

These are paired test businesses, not fresh-game earnings or guaranteed returns;
purchase prices are excluded from operating contribution. No scenario bypasses
orders, stock, cash or shared visitor supply.

Fresh active routes across three seeds each:

| Measure | Original baseline policy | New profit-cycle policy |
| --- | ---: | ---: |
| First purchase | 2.6–3.7 min | 2.6–3.7 min |
| First pool | 13.0–17.9 | 13.0–17.9 |
| Stage two | 27.9–33.3 | 27.9–33.3 |
| First manager | 71.7–81.9 | 80.0–87.3 |
| Second property | 86.7–95.8 | 92.1–101.9 |
| Stage three | 121.8–132.3 | 118.9–129.7 |
| Saving gap before manager | 15.3–20.9 | 3.2–9.8 |
| Longest gap between investments | 32.5–35.4 | 24.3–25.4 |

The new policy reinvests more before management, so it reaches management later
but has useful purchases during the wait. Its stage-two flagship purchase median
is **160–189 seconds** (2m40s–3m09s). All gaps are printed, including occasional
5–11-minute gaps and much longer late idle-route gaps. Mostly-idle routes remain
slower and solvent; their cadence is not held to the active-player target.

**Confirmed acceptance:** the user confirmed keeping prices and accepting stage
two from 28 minutes and an active flagship purchase median of 150–300 seconds.
This explicitly resolves the two earlier stage-two lower-bound failures (1676s
and 1769s, compared at nearest-minute precision) and five cadence medians below
180s. Other targets remain unchanged. The complete Godot 4.7.2 `tools/test.sh` wrapper passes with zero failures:
gameplay/save/UI regressions, 57 fresh campaigns, 60 celebration scenarios, 80
club scenarios and 120 profit-cycle scenarios. Prior failures are retained here
as the reason for this agreed change.

Production-art previews at 960×540 and 1280×720 cover locked/unlocked tiers,
waiting/drinking/finishing-pool details, customer profit and 32/34-person capacity.
Linux, Windows and macOS exports and isolated Linux startup were checked locally.
Android device play, Windows/macOS execution, human retention and a published
release of this feature remain unverified. Previous dated records below are
historical and do not replace this feature's combined verification.

## Gabby verification — 26 November 2026

Godot 4.7.2 `tools/test.sh` passes the combined gameplay/save/UI/art suite,
48 fresh campaigns, 60 celebration scenarios and 80 stage-two scenarios.
Additional isolated regression/UI checks pass for Gabby's paid hiring, named
rota and renewal controls, actual-service tips, stacking with matched drinks,
repeat rounds, stockouts, empty queues, offline exclusion, saved identity and
training, retained deadlines, and once-nightly payment across reloads.

Nine `gabby-*` economy previews at 960×540 cover hiring, roster, the three venue
types, actual serving, the tip jar, off duty and expiry/renewal. Packed sprites
were inspected against light/dark backgrounds and the portrait in the production
UI. Existing worker artwork is preserved. Device playtesting and Gabby-specific
full-campaign pacing remain unverified; existing baseline routes do not hire her.
This is local source verification, not a release publication receipt.

## Current commission/pool verification — 26 November 2026

The isolated Godot 4.7.2 wrapper passes gameplay/save/UI regressions, 48 fresh
campaigns, 60 paired celebration scenarios and 80 stage-two income scenarios.
Promoter checks cover commission-free ordinary/premium/Happy Hour/offline sales,
old quoted orders and fractional carry, retained historical payments, no refunds,
repeat claims, unchanged contracts and renewal. Pool checks require thirty-second
paid and free games, once-only ฿50 settlement, saved timers, and free-game identity
after a promotion ends. A legacy 45-second game reloads and completes without a
second fee. New games and forecast throughput use thirty seconds.

Active baseline runs reach stage two in 29.9–32.9 minutes, management in
70.5–73.2, property two in 86.2–89.0 and stage three in 121.2–126.1. Nearest-minute
milestone comparisons remain unchanged. The manager-saving gap is 17.4–20.48
minutes; the user explicitly approved a **21-minute** ceiling instead of 20,
keeping all prices unchanged. The longest investment gap remains 31.9–34.9
minutes, below the unchanged exact 38-minute ceiling. No unrelated price or
progression-gate adjustment was made to accommodate the shorter pool timer.

The Nida hire forecast/contract and active pool presentation were inspected at
960×540 against production artwork: no 10% fee on the hire controls, and a new
paid pool game showing 29 seconds after one tick. Android device play remains
unverified. Prior measurements below describe their respective source versions.

## Previous stage-two income verification — 26 November 2026

Godot 4.7.2 `tools/test.sh` passes gameplay/save/UI regressions, **48 fresh
campaigns**, **60 paired celebration scenarios** and **80 stage-two scenarios**.
The latter compare club tiers across ten matched seeds, music/training options
and service-limited controls. The fresh routes add club-first and the combined
stage-two purchases to the existing baseline, promoter and automation policies.

`regulars_club_check.gd` covers local gates, exact purchase reserves, no retroactive
visit rewards, real third-drink settlement, birthday cap, finite budgets,
stockouts, repeat-safe offline projection, schema-eleven migration, saved
membership/music/training, retained cooldowns through rehire, and actual advanced
staff service. UI checks buy club level one from a ฿2,611 till, then purchase
better sound and advanced training through the actual Upgrades drawer.

| Baseline active milestone | Three seeds, click-heavy and balanced |
| --- | ---: |
| First purchase | 2.5–3.6 min |
| First pool table | 13.8–16.4 min |
| Stage two | 31.7–33.7 min |
| First manager | 69.9–73.7 min |
| Second property | 86.0–89.8 min |
| Stage three | 121.4–126.1 min |
| Saving specifically for first manager | 16.5–19.5 min |
| Longest gap between investments | 33.0–34.2 min |

The full stage-two bundle reaches management in 85.6–87.8 minutes, the second
property in 100.8–103.0 and stage three in 133.7–136.6. Buying every optional
upgrade costs time; the baseline does not buy them all. Both routes finish
solvent with bounded traffic and sales no greater than orders. Current targets
are 30–45 / 75–115 / 110–210 minutes for stage two/property two/stage three,
with exact 20/38-minute saving-gap ceilings. This intentionally supersedes the
previous longer curve in response to the day-eight player report.

Matched day-eight contribution rises from ฿38,486 to ฿51,912 across ten
600-second runs at club level zero versus three: about 35%, or ฿2.24/sec.
Music and training benefits depend on the bottleneck; the
[design note](design/STAGE_TWO_INCOME.md) records separate results and costs.
These estimates exclude purchase fees and do not guarantee human play outcomes.

Four `club-*` states rendered at **960×540 and 1280×720** show the affordable
club offer, next tier, better sound and advanced training against the production
art. New purchase controls are exercised in the UI suite. No production assets
were replaced. Android device play, Windows/macOS execution and full-festival
pacing remain unverified; CI exports are not device playtests.

## Previous venue-price verification — 26 November 2026

`tools/test.sh` passes on Godot 4.7.2: gameplay/save/UI regressions, 42 fresh
campaigns and sixty paired celebration scenarios. Existing minute-based targets remain; comparisons now round to the
nearest minute. The integrated run’s 129m51s stage-three result meets the
130-minute target; exact raw times remain reported. Saving gaps remain exact. The added `drink_prices_check.gd` settles real ฿80/100/120 orders,
checks renovation/premium/Happy Hour rules, then loads an old ฿55 waiting quote
and mixed ฿6/14 inventory: both settle at their recorded values without revaluing
cash, budgets or stock. Updated boundary tests cover ฿228 six-packs and
฿432 bulk packs, supplier reserves, commission carry and three-sale recovery.

Baseline active timings across three seeds and two play styles:

| Milestone | Time |
| --- | ---: |
| First small purchase | 2.5–3.6 min |
| Pool table | 13.8–16.4 min |
| Beer-bar stage two | 31.7–33.7 min |
| First manager | 78.9–83.1 min |
| Second property | 93.4–98.0 min |
| First stage three | 129.85–136.1 min |

The manager-saving gap is 25.4–28.9 minutes and the longest between-investment
gap 32.9–34.7, within the existing 30/38-minute ceilings. All alternate purchase
routes and mostly-idle policies finish solvent. Celebration comparison inventory
valuation now uses the current stock cost rather than the former fixed ฿14;
the focused suite and then the full integrated suite are rerun after correcting
its reporting formula. Integration includes main through `6003191`, preserving
the drink inventory, tutorial, bonus tips, upgrade UI and mobile controls.

Three `prices-*` previews at 960 × 540 verify the prices and delivery control
against each production interior; the gogo state is also inspected at 1280 × 720.
Pricing changes preserve Ryan’s merged production artwork and UI. Android device play and full-festival pacing
remain unverified; these tests establish the opening-arc balance and settlement.

## Previous nightly tips and recovery verification — 26 November 2026

Godot 4.7.2 `tools/test.sh` passes all gameplay/save/UI regressions, 42 fresh
campaigns and sixty paired celebration scenarios. `tips_check.gd` covers real
first-sale visit counting, repeated drinks, no-order/stockout calls, staff and
owner automation, separate commission/accounting, late multi-venue closure,
Stay/reload/skip repeat safety, schema-ten migration, malformed saves and offline
exclusion. Its UI test clicks the recovery button in the reported ฿39/zero-stock
state. Two regular beer sales repay Bo and leave ฿121; a normal six-pack then
costs ฿84. Bulk supplier recovery uses the current pack's affordability.

Baseline active results: stage two 31.6–34.0 minutes, second property 93.8–98.0,
first stage three 130.7–135.9. The active stage-three lower acceptance bound is
explicitly relaxed from 135 to 130 minutes for earned tips; all other bounds are
unchanged. Earlier tables below are historical, before tips.

Five `tips-*` economy previews at 960 × 540 and 1280 × 720 show the stockout,
consignment delivery, pending jar, closing payout and prep report. The actual
customer art, stock count, till and cancellation control remain visible. No
production artwork changed. Device play and human retention feedback remain
unverified; automated exports do not establish either.

## Previous automatic night-prep verification — 26 November 2026

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
| Staff | Exact 25/20/15-second service plus stage-two 12/10-second tiers, individual training, expiry/rehires, skipped/closed/offline time, migration, partial work and UI buttons |
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
  venue types, including the 34-customer unfurnished beer-bar maximum. Check character proportions,
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
- Use `fight-crouch`, `fight-uppercut`, `fight-roundhouse`, `fight-ultimate`
  and `fight-mobile-controls` to review contact effects and persistent controls.
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

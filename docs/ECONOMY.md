# Customer economy

The charcoal-suited supplied-reference guest uses ordinary admission, budgets,
orders, paid stock, service and pool rules. His optional saved appearance is
assigned only to new visits without RNG; existing visits keep their old looks.
All fifteen customer identities have model-driven drinking, Chat and pool poses.
Counter visits, reserved seats, paired mingling and purchased-screen watching
are disposable visual routines. Pending orders send visitors toward the counter;
real service sends them back to a seat. Active pool players retain their actual
table. Orders remain serviceable while walking. Animation never changes admission,
patience, drinking intervals, budgets, stock, finances, saves or gameplay RNG.
It grants no extra visit time, sales, tips, loyalty or pool income. Beer-carrying
poses require an actual paid drinking phase; a pending order keeps empty hands.
Physical room spacing affects presentation rather than the model seating cap.
HUD rebuilds retain routes and never move actors to their destinations.

The current account and growth rules are defined in
[Finance and growth](design/FINANCE_AND_GROWTH.md). Schema 17 restores one shared
account and removes purchase reserves. Loyalty and earned manager bonuses remain. Older dated
balance records below describe previous releases, not current purchase rules.

The live street is authoritative. `scripts/economy.gd` owns visitors, orders,
stock settlement, payroll, pool games, promotions and forecasts. `street.gd`
advances this model once per foreground second and settles reports every 120
seconds of street trading, plus one partial report at overnight closure. UI and artwork consume this state; they never award sales themselves.
Balance and purchase definitions live in `scripts/street_content.gd`.

District artwork reads the total customers currently in trading venues, using
`Economy.trading` for opening, late permission, owner, raid and temporary closures.
Eight visual bands begin at 0/1/3/6/10/16/24/36 guests. The atmosphere plates
and bounded ambient street walkers create no arrivals, orders, revenue or RNG
draws. The map labels the actual count as guests in open venues. No save fields
or economic thresholds change.

The bar's reusable exterior underlay instead follows eight clock periods, starting
at 00:00/03:00/05:00/07:00/11:00/17:00/19:00/21:00. Cars, scooters and animated
pedestrians use the same activity bands in both views. District caps are 36
pedestrians, six scooters and three cars; the narrow bar opening caps them at
seven/three/two. These are ambient visual traffic, not customers, queues or
capacity. All nine original interiors retain exact pixels outside their outdoor
apertures; the final beer bar uses a smaller opening behind its furnished terrace.

The [seating/six-pack/promoter design](design/PROMOTER_CAPACITY_PLAN.md) is
implemented. Its initial forecast examples are analytical estimates; measured
campaign outcomes appear below.

## AFK incident handling — 27 November 2026

The optional saved `street.afk` flag defaults false, including old schema-17
saves. Only normal live `plan` ticks execute AFK purchases. Each tick tries
existing event preparation first, then expired existing staff in venue/roster
order, using the normal offer, listed price and shared-money action. There are
no reserves, automatic new hires, upgrades, leases, promotions or speculative
supplier purchases. Navigation/status reads never spend or roll RNG.

Renewal retains identity, training and service deadlines. Expiry saves the prior
duty setting in optional `person.renew_on`; AFK restores that setting after the
ordinary rehire action. Pre-field expired workers default to returning on duty.
Unaffordable contracts retry on later live ticks. Closed, skipped and offline
time still ages contracts; offline claims never renew them.

Paid Rat Plague retains its normal swarm and sweep, then AFK catches one of the
last six rats per live second. Without patrol money, AFK invokes the existing
close-for-day cleanup, with its real tip settlement and skipped contract time.
Paid Godzilla preparation costs ฿450 (festival ฿1,200), including when AFK is
enabled after the active monster arrives. At the normal event expiry it avoids
repair closure without awarding tapping-game cash or victory reputation.
Festival completion still counts once. Unpaid monsters keep ordinary setbacks;
other events retain their existing gates, durations and consequences.

UI suppresses blocking news and supplier-special offers while AFK is enabled.
The supplier offer is marked seen, never bought. AFK gives no extra owner service,
attraction, stock, income or offline earnings. Menus, practice and explicit
interactive decisions remain paused. The normal nightly cleanup/countdown remains.

## Current finance and pacing — 27 November 2026

One shared balance pays every venue and street action. There are no purchase
reserves or opening floats. Close & count tips settles the selected real jar
immediately and pauses costs. Named rent, electricity and payroll retain their
existing combined rates; the Money view records recent cash movements.
[Finance and growth](design/FINANCE_AND_GROWTH.md) defines exact routing,
schema-17 conservation and closing recovery. Prior separate-account timings
are historical; current verification is in [TESTING](TESTING.md).

## Current profit-cycle rules — 26 November 2026

The [profit-cycle specification](design/PROFIT_CYCLE.md) defines the current
visitor lifecycle, beer-bar tier caps/prices, bounded frontage traffic, financial
feedback and schema-13 compatibility. New visitors have variable one/two-round
plans; club or birthday adds one non-stacking round. They drink the final round
before leaving, with bounded pool waiting. Happy one-drink visits count.

Beer caps by stage: seating **3/5/7**, frontage **1/3/5**, fridges **2/3/4**,
music **1/2/4**, service training **2/4/6**. Prices per tier N are respectively
฿400N/900N/800N/1,200N/400N. Hostess and gogo frontage shares the 1/3/5 caps; their other tracks are unchanged.
Music takes 35/25/18/14/11 seconds (party 26/19/14/11/8); bartender service takes
25/20/15/12/10/8/6. Existing timers are never shortened retroactively.

Base street traffic is 7.3 + 2 × max(0, highest owned beer frontage − 1) per minute,
plus cumulative marketing. Each additional open property adds two; existing type
diversity also applies. This remains shared among all venues. Completed-shift advice reads actual losses/occupancy;
customer profit subtracts consumed paid stock and operating expenses, excluding
manager income and tips. The till sample remains actual cashflow. Offline visitor
estimates divide settled drinks by expected variable rounds, not a fixed two.
Older visitors keep legacy rules until departure; paid progress is preserved.
Dated previous sections below describe earlier releases where explicitly labelled.

## Previous promoter and pool update — 26 November 2026

Nida's ฿1,200 ten-day contract is her entire fee; commission is removed. New
pool games last **30 seconds**, still costing **฿50 once per table at start**.
Free games still cost zero and keep that identity after the promotion ends.
Already-running games retain their saved remaining time, even if longer than
thirty seconds. Forecast throughput uses the new duration; real games still
require two customers, available table capacity and sufficient budgets.
Prices and progression gates are unchanged. The user approved a **21-minute**
first-manager saving-gap ceiling after a baseline run measured 20m29s with faster
pool; the 38-minute longest-gap ceiling stays exact. Older balance measurements
below describe their stated versions; current verification is in [TESTING](TESTING.md).

## Previous stage-two income rules — 26 November 2026

See the [stage-two design and measured trade-offs](design/STAGE_TWO_INCOME.md).
Regulars Club tiers cost **฿600/1,200/2,400**, require stage two and **10/20/35
local regulars**, and invite **35/65/100%** of new arrivals to stay twenty seconds
longer with an extra house-price budget allowance and a third-drink limit.
Membership is saved per visit; existing guests are unchanged by purchase.
The club does not generate arrivals or sales. Birthday and membership never
combine into a fourth round. Purchase retains a full stock pack plus the next
shift's operating costs. Forecasts include extra occupancy and expected rounds.

Better sound costs **฿2,400** after the original ฿1,200 music purchase, at stage
two. Repeat intervals are **35/25/18 seconds**, or **26/19/14** at the birthday.
Bartender training adds **15→12→10-second** recovery for **฿1,200 then ฿1,600**
from stage two, after the existing ฿400/800 tiers. Existing customer and staff
deadlines finish normally. Skills survive contract expiry and rehire.

First management costs **฿8,000**, with unchanged ฿10/sec income and prerequisites.
Later tiers remain ฿36,000/72,000. The first appointment's additional ฿588/min
net management income repays its fee in roughly 13.6 open minutes, excluding
other trading changes. Renovation prices and local milestone gates are unchanged.

Schema **12** saves these purchases and visit entitlements. Older saves preserve
all owned progress, cash, paid stock, quotes, budgets and timers, with no club
entitlement, free training or retroactive manager refund. Ordinary receipts and
offline estimates remain limited by demand, service, supply and operating costs.

Current active pacing acceptance: stage two **28–45 min**, second property
**75–115**, stage three **110–210**; manager saving gap **≤21 min**, longest
investment gap **≤38 min**. Milestones use nearest-minute comparisons; gaps use
exact seconds. Active profit-cycle routes target a **2m20s–5-minute median** between
flagship investments at stage two. The user confirmed the faster lower bounds
without changing prices, including the quicker no-reserve cadence approved on
27 November. The following dated pricing/bonus/balance sections document prior
passes; their historical timings do not override these targets.

## Earlier venue pricing pass — 26 November 2026

| Venue | Standard receipt | Starting stock cost | Gross contribution | After Nida's 10%, before other costs |
| --- | ---: | ---: | ---: | ---: |
| Beer bar | ฿80 | ฿38 | ฿42 | ฿34 |
| hostess bar | ฿100 | ฿38 | ฿62 | ฿52 |
| Gogo | ฿120 | ฿38 | ฿82 | ฿70 |

These are game balance values, not promised real-world supplier terms. The
requested ladder replaces ฿55/85/140. Supplier levels 0–5 cost ฿38/38/36/34/32/30
per unit; upgrade fees stay unchanged. The premium menu unlocks mango cocktails at a ฿30
surcharge and Happy Hour its 20% discount. Renovation never adds a price bump.

Ryan's concurrent drink-inventory work is retained. The ladder is the house-lager
base. Lime soda stays ฿10 below it, rum and cola ฿18 above it, mango cocktails
฿30 above it. Those products retain base supply costs ฿6/19/25; supplier discounts
still apply to each. Single-drink packs, paid-cost
returns, audience preferences, lager substitutions and matched-drink tip bonuses
use the merged model. These are distinct products, not cheaper beer stock.

Fresh games start with ฿228 and twelve drinks, plus the same three opening
customers. The float covers one complete pack; the smaller starter fridge avoids
a windfall from repricing eighteen free drinks. New-property opening reserves
now use a full current base pack instead of the old fixed ฿140 stock allowance.
Normal purchases and old saves do not grant a free cash adjustment.

That pricing pass retained schema 11; the current stage-two pass uses schema 12. Existing waiting quotes and budgets, inventory quantities
and paid FIFO lot costs survive; only future orders and deliveries use new prices.
Pre-lot saves backfill inventory/report costs at the historical ฿14, not today's
price. Validation accepts paid drink costs from ฿1 to ฿38, including old lots. Consignment
uses a separate fixed ฿14 repayment in live/offline settlement. It is explicitly
a recovery concession, never the normal supplier price. Tips remain ฿10 per visit.

The first ฿35 supply candidate accelerated some milestones outside current
bounds; ฿39 introduced a long manager-saving gap in one baseline seed. ฿38 keeps
beer gross contribution near the old ฿41 while passing the existing baseline
bounds. No renovation/staff/manager prices or minute-based pacing targets were changed.
After integration with the new drink inventory, milestone assertions round to
the nearest minute: a 129m51s result meets the 130-minute target. Exact times
remain in output; the 30/38-minute saving-gap ceilings still use exact seconds.
Current verification and timing results are in [TESTING](TESTING.md); older
measurements below describe earlier price versions.

## Nightly tip settlement and recovery — 26 November 2026

Each real visit's first successful drink sale increments `bar.tip_visits`; the
saved `customer.drinks` counter prevents repeat tips for further rounds. Manual,
staff and owner automation share settlement. Tips are an additional house bonus
of ฿10 per served visit, outside the existing drink budget and Nida's commission.
Serving the requested specialty drink on the first round can also add ฿5 to the same nightly jar.
The odds depend on drink and audience. The roll is stable per guest and drink,
independent of traffic RNG. Substitutes earn the base tip only.
Tips are never earned by arrivals alone, pool, managers or offline estimates.

The street counts all jars at final nightly closure, or an explicit legal night
skip. Explicit early closing also counts the selected venue’s unpaid jar; short
business reports do not. Reopening alone never counts tips.
`street.tip_night` prevents a second settlement on the same night, and pending
counts clear atomically into each bar's `last_tips` and `tips_total`. If a player
reopens a late venue after its jar was counted, newly earned tips remain pending
until explicit closing or the next nightly count. Waiting for a late venue to finish does not multiply
the bonus. Cancellation of the clean-up jump does not undo or repay tips.

Cash, weekly revenue and total street earnings receive the payout. Drink/pool
counters, shift profitability/healthy-service gates, party/promotion reports and
the five-second trading-rate sample exclude it. The separate tip report explains
the amount. Offline projections neither earn nor count pending tips. Schema 11
validates these fields; older saves begin with zero counts, with no reward for
historical visits or an already-served customer's next drink.

A visible emergency delivery handles zero stock and insufficient cash for the
current pack. It uses the existing recovery terms: six consignment units, ฿14
charged on each sale, staff off duty and 120 seconds of covered overhead. No cash
is granted and existing orders/cooldowns remain. An active recovery period cannot
be restarted; normal deliveries still use six/twelve units. The eligibility check
uses the actual pack price, so a ฿430 till unable to buy a ฿432 bulk pack can recover.

The earned bonus intentionally brings active baseline stage three forward to
130.7–135.9 minutes; its acceptance lower bound is now 130 rather than 135 minutes.
First renovation remains within 30–45 minutes; second property within 90–125.
At the v1.0.22 tip release, baseline measurements were: pool 14.4–17.1, stage two 31.6–34.0, manager
79.2–82.9, second property 93.8–98.0 minutes. First purchase remains 2.5–4.4.
Earlier measurements below describe the opening-arc pass before nightly tips.
No prices or customer/regular/healthy-shift thresholds were reduced for this bonus.

## Weekly calendar celebrations

Day seven is Anong's Birthday at the flagship Blue Hour. Day fourteen/twenty-one/
twenty-eight are the Regulars' Reunion, Pim's Mixtape Party and Bo's Thank-You
Night; these last three rotate afterward. The calendar reminder, Events and
street banner announce each celebration one day ahead. The party runs from
noon on the opening's date until normal 1am close, crossing
midnight correctly. Late-opening permission does not extend the party.

The event has no fee and requires no specific purchase or staff member. Only
while the host trades, shared traffic increases 40%, capped at 2.4× the current
base venue-mix supply after other event multipliers. Weather applies afterward.
Host attraction gets +2 before audience/peak/dirt factors. Other venues compete
for the same finite supply; they do not copy host timing or the third-drink limit.
New random event announcements wait during the party; existing events continue.

New host visitors plan one extra round, capped at three, subject to actual
budgets. Drinking timing becomes 26/19/14/11/8 seconds by music tier, including
the final drink. Existing timers and quoted orders are preserved. New party
visitors gain ten seconds of patience, saved through reload.
After closing, no new third rounds are requested. Real stock, serving deadlines,
space, pool capacity and normal prices remain authoritative. Nida has no commission.

The active/last report records actual host arrivals, sales, happy visits, regulars,
lost business and paid costs during the window. Trading contribution is drink
plus pool receipts minus consumed-stock cost, commission, operating charges,
promotion costs and fines. It excludes street-wide charges, manager income, capital purchases and
unused stock deliveries. It is not a causal uplift estimate or a second payout.
Pausing, reloads and opening the report cannot create rewards. Offline forecasts
exclude the temporary bonuses and neither update the report nor advance its date.
Schema eight adds the report/date and per-visitor patience; old saves receive
empty reports and future calendar opportunities while retaining owned progress.

Reputation independently adds `min(1.5, reputation / 80)` to each venue's
attraction before audience/peak/dirt modifiers. With the current 100 cap, its
maximum is +1.25. Shared traffic stays finite; reputation improves the chance
of choosing a venue over outside options. It does not change drink budgets,
repeat timing, staff speed or prices. Music and parties own repeat timing.

The rationale and paired comparisons are in the
[celebration design](design/WEEKLY_CELEBRATIONS.md).

## Clock, closing and preparation

The authoritative street clock starts at minute 720 (12pm); each foreground
second advances one game minute. Midnight advances the existing calendar and
weekly accounts. All venue types trade from noon to 1am, with a per-venue nightly
extension until 3am that must be selected before 1am. Noon resets late permission
and raid closure, never owner intent or cash-shortage closure.

`Economy.trading` is the shared eligibility rule for simulation and presentation.
Scheduled closure, raid closure, temporary event closure and the owner's `open`
flag remain separate. Scheduled/raid/owner closure removes customers, requests
and pool games without new fees, refunds or invented service failures. It finishes
promotion reporting once. Existing temporary disaster closures preserve their
queues. Closed venues do not sell, attract customers or accrue operating costs.
A final partial ledger is settled when all venues stop overnight, including any
guided session. Short business reports are not calendar days.

Peak windows are beer 17:00–21:00, Soi 19:00–23:00 and gogo 22:00–02:00,
including midnight wraparound. A peak multiplies that venue's attraction by 1.5;
the shared traffic pool remains bounded. Forecasts and real customer allocation
use the same peak multiplier, after accounting for the venue's opening state.

Each actual drink sale adds one dirt point, or two during its venue's peak,
capped at 100. Attraction is multiplied
by `1 - 0.25 * dirt / 100`, including offline forecasts. A fifteen-foreground-second
clean, available while closed, clears dirt and costs no cash. Nightly clean-up starts the
job for all venues; managers also start cleaning during other closures. Restocking uses the existing paid purchase action.

Between 1am and noon, an entirely closed street may skip to noon. It cancels
unfinished cleaning without clearing dirt or buying stock. Natural noon opening
also cancels unfinished jobs. Skipping never runs simulation ticks, cools heat,
resolves events or grants healthy reports. Normal closed-hour ticks advance prep
and temporary closure timers, while street-event countdowns pause.

## Late-trading enforcement

Each venue accumulates actual trading minutes after 1am. Every ten adds one
shared heat point (maximum 100); every fifteen checks for a raid using the saved
economy RNG. Chance is `2 + 0.2 * heat` percent. Safe foreground time removes one
heat point per 120 seconds; late operation resets that cooling counter.

A raid charges `min(available cash, 300 * venue stage)`, records a separate fine
in the venue and weekly ledgers, and closes only that venue until noon. It never
creates debt or removes owned progress. Fine costs also count in actual net and
healthy-shift assessment. The completed raid tick requests an immediate campaign
save. Existing scheduled inspections retain their separate preparation mechanics.

## Playing the first bar

Start with ฿228, 12 drinks and three forgiving opening customers. Serve their
actual orders; welcome passersby when there are no orders. A yellow/gold dot marks a
waiting order and turns red when the lesser of remaining order patience and
visit time is ten seconds or less. The display uses the same remaining-time rule
as Chat, including comfort and reassurance bonuses; it adds no new timers.
Customers normally buy up to two drinks during a visit (three for club members
or flagship party visitors), have a spending
budget, and leave unhappy when an order waits too long. A quiet click neither
uses stock nor earns money. Manual service immediately sells one ordered drink,
then refills for ten foreground seconds. Failed attempts consume no cooldown.
Bartenders continue serving independently during manual recovery.

Each venue buys separate Faster pouring and Better welcoming levels in Service:
10 → 8 → 6 → 4 seconds, at incremental prices of ฿900, ฿1,400 and ฿2,800.
Pouring alone adds a stage-two 4 → 2 second tier for ฿5,600. Welcome still caps
at four seconds. Auto-serve is a separate ฿3,000 purchase, using the same saved
Serve deadline, actual-order/stock checks and current cooldown as manual serving.
It runs per venue during live ticks, including guided play; it does not stack a
second owner timer, reset an active deadline or advance through paused screens.
Its toggle changes scheduling, never speed. Managed offline forecasts include
its capacity without replaying saved live orders or advancing the live deadline.
Purchases charge only their price and affect subsequent uses,
never shorten an active refill. They do not change staff training or demand caps.

Have a chat targets the eligible guest nearest departure, with at most ten seconds
of patience or visit time remaining. Once per visit, it adds ten seconds to order
patience and remaining visit time. It cannot undo a missed order or directly grant
income, satisfaction or regulars. Welcome and Chat share a social timer: Welcome
starts its upgraded cooldown; Chat always starts twenty seconds on both buttons.
Serve has an independent timer. A brief +10s marker identifies the reassured guest.

Action deadlines use elapsed foreground time plus a saved fractional second.
The economic model still steps once per second. Closed-hour preparation advances
timers; paused decisions, startup menus, offline claims and skipping to noon do
not. Buttons display readiness and remaining time from the same model gates used
by actions and guided choices.

Welcoming has a ten-second cooldown, a short expiry and a capped attraction
bonus. The street supplies 7.3 potential visitors per real minute before events;
opening a different venue type adds an audience, while similar venues compete.
Local, tourist and nightlife groups choose among the venues and outside options.
Each booked tour guide adds 0.5 to live venue appeal before modifiers. When the
guide's share of the same arrival draw brings customers who get seats, the
street update names the guide and venue.
Live tour agreements pay the guide upfront from the selected venue’s till in
the same action that starts the tour. The company bank and other tills are not
used. Guide pay remains excluded from the five-second trading sample; weekly
costs record it once. Existing agreements are not charged again or refunded.
Guide eligibility and pay rules still apply; navigation changes no model state.
An empty bar needs appeal; a queue needs service; a full bar needs more space.

Useful early investments include signage, seating, deliveries, pool and a fridge.
A bartender contract costs ฿1,200, matching Nida’s contract fee. Base service is one drink
per 25 real seconds (2.4/min); individual training costs ฿400 then ฿800 and
reduces this to 20s (3/min) then 15s (4/min). Stage two adds 12s (5/min) for
฿1,200 and 10s (6/min) for ฿1,600. Each bartender has a saved cooldown deadline. She starts ready, serves one
actual order on the next live tick, and only then begins recovery. Empty queues
and stockouts do not restart that deadline or bank multiple future sales. Manual
serving remains useful alongside staff. Hosts and dancers attract
visitors instead. Gogos perform between seconds 40 and 80 of each shift; drinks
and premium-menu orders are priced independently of renovation stage.

House lager stock starts at ฿38 per drink when delivered; supplier levels reduce future
unit costs to ฿36/34/32/30. Inventory lots retain paid unit costs and are consumed
first-in, first-out for promotion contribution and healthy-shift margins. Wages and premises overhead are charged
throughout open time, including quiet periods. Schedule staff off or close a venue
to reduce charges. An unaffordable operating charge closes the venue before debt
is created. Staff records and equipment remain; contracts continue to expire. Anong's owner-run recovery shift
covers two minutes of overhead; if the fridge is empty, six consignment drinks
are paid for only when a real customer buys them. No buyer means no income.

## Rat Plague

After the reopening chapter, each eligible random street-event slot has a 1 in
50 chance to announce Rat Plague. The roll leaves the regular rotation intact.
After a 20-second warning, 144 rats arrive from the restaurant down the street.
All venues lose their current customers, pending orders and pool games. Passing
traffic drops to 15%. The active swarm persists through ordinary night skips
and saves the uncaught rats.

Bo’s ฿120 patrol is available during the warning and while more than six rats
remain. It takes out up to 24 per live second until six are left and preserves
55% of passing traffic. The player can click or tap each rat to restore normal
foot traffic on the last catch. **Close for the day and leave it to Bo** settles
the street’s actual shift and earned tips, ages contracts through the skipped
hours and reopens at the next noon with the rats gone. Saved active swarms
keep existing catch progress and discard the previous event timer.

## Drink demand and inventory

Patron audience affects drink preferences. The fridge shares capacity across
house lager, lime soda, rum and cola, and premium mango cocktails. Guests may
accept house lager at its order-time quote if their preferred drink is unavailable.
Drinks with more waiting requests than stock appear under Needed now when
automatic deliveries cannot cover the shortage. Locals, visitors
and big spenders have different willingness to pay. Guests can trade down to
lager or soda if an order exceeds their price ceiling or remaining budget.
Expected popularity uses the audience and current menu prices, including
Happy Hour. Pending orders keep their original quotes.

Manual orders buy a full pack of one drink. Supplier terms apply to each product.
The first Supplier upgrade unlocks automatic deliveries for
drinks already stocked at that bar. Stock lots retain their paid prices for FIFO
service and half-cost returns. Old stock becomes house lager and pending orders
keep their saved quote. Offline trading estimates a drink mix within stock and
working-capital limits.

## Compact layout, deliveries and the frontage promoter

Beer-bar seating levels cost ฿400, ฿800 and ฿1,200. Stage-one capacity before
furniture is 6/8/10/12. Pool normally uses two places per table and comfort one;
the third seating level recovers up to three furniture places. Thus every legal
stage-one combination holds twelve. At seating tier three, stage two holds eighteen with one table and
comfort, sixteen with two. Tiers four/five add two more each. The layout recovery
applies to all seating tiers from three onward. Other venue types retain two seating upgrades.
Purchases charge only their price and show actual capacity.

`pack_quantity`, `stock_offer` and `restock` settle six drinks for ฿228 at supplier
levels 0/1, then twelve drinks at level 2 and above (initially ฿432). Neither
manual nor automatic delivery permits partial purchases. Manual buying needs
room for the entire delivery and its full price;
it shows cash afterward and the next operating charge. Supplier deliveries buy
one pack below the current pack quantity when orders are pending, retaining the next one-second
operating charge. Bo's six recovery drinks remain a consignment exception, paid
once on sale in live or offline accounting. Fridge sizes and saved stock remain
unchanged; eleven spare spaces cannot accept a twelve-drink delivery. Each fridge
tier also adds +1 to the base +1 reputation earned per ten satisfied departures
at that venue, capped at 100 street reputation. Purchases grant no immediate
reputation; already-owned fridges benefit on future milestones.
The cabinet display uses the venue's current stock divided by its capacity,
including at the starter tier.

Nida costs ฿1,200 for ten game days, with no drink commission or hourly wage. One frontage slot is separate from seats and floor staffing. While
contracted/on duty, her attraction weight is +4.8; the model uses the greater of
her bonus and owner Welcome, never their sum. Welcome is disabled while she
works; Chat retains its existing social timer. Welcome upgrades only benefit
owner welcoming when Nida is off duty or expired. They do not boost her attraction
or shorten Chat’s twenty seconds; the upgrade panel explains this. She does not serve, stock, manage
or accept host requests. Closure and expiry remove her from the entrance.

Stage two unlocks audience training for ฿800; stage three unlocks another tier
for ฿1,600. Promoter weights become +6.0/+7.2. Dancer training scales only the
individual's existing attraction/show contribution by ×1.25/×1.5, with no extra
service or drink commission. This track is distinct from bartender training and
persists across expiry/rehire. Stage alone grants no training.

Nida's commission is zero for ordinary, premium and discounted drinks, both live
and offline. Existing queued commissions and fractional carry are cancelled on
load. The settlement guard also prevents charges from old commitment flags.
Past `commission_paid` and report costs remain unchanged: no refund, cash gift
or rewriting of historical profitability. Schema 12 remains compatible; legacy
commission fields stay in the save and validators for historical reporting.

Hire previews show post-hire cash and the required
the exact contract-price shortfall, arrivals, unattended and owner-active net,
and whole-street impact. These are capacity estimates, not promises of revenue;
they account for other properties losing some shared visitors. Hiring more
attraction into a service bottleneck can reduce net profit.

## Ready staff and visible service

Staff cooldowns are independent of owner Serve/auto-serve. `staff_service` checks
eligibility, deadline, real orders and stock; a successful settlement records
`service_ready`, `last_served` and `drinks_served` on that person. Ready staff are
processed before owner auto-serve so the purchase cannot continually pre-empt
them. Multiple workers share the same queue and cannot sell one order twice.

After staff service, owner auto-serve intervenes only when pending orders exceed
the count of contracted, on-duty, present bartenders, or an order has at most ten
seconds before patience/visit expiry and even the next bartender cannot recover
before that deadline. With no eligible bartender it serves normally. Quiet orders
leave the owner timer untouched; manual service remains unrestricted by this
relief policy and shares its existing deadline with automation. Promoters, hosts
and dancers never count as bartenders. The ฿3,000 price is unchanged.
Forecasts and offline income retain demand-limited sustained capacity estimates;
they do not simulate the live queue dispatch or promise its exact throughput.

The base cooldown is 25 seconds; training makes subsequent cooldowns 20/15, then 12/10 at stage two; beer-bar stage three adds 8/6 for ฿2,000/2,400.
Training preserves a deadline already running. Owner clicks, empty queues,
stockouts, rotas, closure, reassignments and reloads never reset it. Foreground
closed/off-duty time can finish recovery; paused/menu/offline time does not
advance the live deadline. Overnight skips retain it, like owner action timers.
Offline projections retain demand-limited sustained service estimates and do not
add to live staff counters or fake a recent serving animation.

The top-right bartender list and Service roster read the authoritative state.
The HUD level is personal training plus one; red bars fill against saved service
deadlines. Its tip jar reads the venue’s unpaid visit and bonus tips, without
attributing shared tips to individuals or settling them.
Counts are actual staff sales since hiring or this update, not reconstructed
historical totals. Serving poses follow actual settlement for two seconds.
The HUD cannot award money or run service. Save schema nine preserves fractional
deadlines and counters; old nonzero `service_clock` progress becomes its remaining
cooldown once. An idle old bartender becomes ready. Old training, contracts,
stock, cash and purchased auto-serve remain; the lower price grants no refund.

## Hosted drinks and Room Buzz

New hostess-bar visits have a stable 40/60/80% local/tourist/nightlife chance of
interest in one sponsored drink, with saved chat/music/pool preferences. Offers
need a real first drink, an available on-duty contracted host, a trading venue,
an affordable quote and neither participant already hosting/booked. UI reads
consume no RNG. Old visits migrate without an invitation or extra money.

Interested new locals/tourists have ฿340/380 of entertainment money; nightlife
guests retain `600 × stage`. This is the existing `fine_budget`, shared with
bookings; personal drink money and planned rounds stay unchanged. Host levels
quote **฿180/220/260**, plus **฿40** for a topic match. Acceptance saves the quote
and marks this visit's sole invitation used. Training never reprices it.

Acceptance reserves a host and creates one order, without income. Normal service
consumes one paid house lager, spends the sponsor's entertainment budget and
records actual revenue, FIFO stock cost and a twenty-second hosted round. It
shares pending/stock checks, bartender and owner cooldowns, supplier pack rules,
consignment cost and owner relief. A queued sponsored order gets priority in its
last ten seconds and expires at thirty seconds if unserved, recording the actual
stock/service loss. The sponsor can stay to finish this bounded activity after
finishing personal drinks; no personal round or drinking deadline is replaced.

Hosted orders/sales count in ordinary totals, with `hosted_drinks`, `hosted_income`
and `hosted_matches` as report breakdowns. They grant no extra first-visit tip or
matched-menu tip and do not increment the sponsor's `drinks`. Gabby's existing
bonus still applies to an actual hosted drink she serves. Customer contribution
and the five-second sample include normal receipts and costs. The host stays in
the room and keeps appeal, but neither participant can take a barfine meanwhile.
Rota/contract loss, closure or departure cancels activity. A served drink stays
paid; interrupted company earns no completion. Role reassignment waits.

Three paid, uninterrupted completions reset `host_cheers` and set
`host_buzz_until = action_time + 30`. Buzz adds **+2 base appeal** while open,
competing for bounded shared traffic. It grants no cash/reputation. Further trios
refresh rather than stack duration. Fractional foreground deadlines, quotes,
progress and guest flags survive reload; menu/offline time cannot advance them.
Ordinary forecasts/offline estimates exclude hosted transactions and Buzz.

**฿1,500 auto-host rounds** needs an on-duty host and its listed price.
It prefers matches and gives hosted-drinks-only colleagues first choice in ties.
Auto-barfines, if enabled, run first; auto-hosting then invites remaining guests.
Purchasing/toggling pays no receipt. The saved toggle affects future invitations.

Schema **15** validates unique host/guest pairings, order states, saved quotes,
flags, interests, fractional deadlines and report counters. Existing visits keep
their budgets/plans and receive no invitation. Migration grants no purchases or
retroactive income and preserves schema-14 bookings and paid receipts.

## Bar-fine requests, host appeal and automation

Soi hosts use the existing request source: a real nightlife guest with a separate
booking budget may request a booking after their second actual served drink
(40% chance while a host is on duty). New requests need at least the ฿500 base
budget. Existing guest budgets are unchanged; new nightlife guests retain
`600 × venue stage` in their separate `fine_budget`. Drink money is never used
for bookings. Requests disappear when that customer leaves or the venue closes.

Acceptance checks a live affordable request, a willing adult host, an active
contract, on-duty rota, trading venue and available booking space. May and Fah
continue to decline. There are at most `venue stage` simultaneous host bookings.
The model consumes one request, deducts the **entire fee** from its customer's
booking budget and credits that fee once to normal actual revenue. Ledger fields
`bar_fines` and `bar_fine_income` report it separately; it is not a drink sale,
tip, commission, manager receipt or offline estimate. Duplicate clicks cannot
pay again. The normal five-second cashflow sample includes the actual receipt.

The host joins `away` until `host_return = action_time + 30`. Her entire base
appeal contribution is absent during that period. Foreground time can complete
the absence while closed or off duty; expiry/rehire, role controls and report
boundaries cannot reset it. Menu, paused and offline time do not advance it.
A return restores eligibility, not an expired contract or an off-duty rota.
The newly integrated bed-race runner keeps its separate event return rule.

Host training is personal, independent of bartender/audience training, and
survives expiry, renewal and reassignment. Levels 0/1/2 supply base appeal
**0.6/1.2/1.8** and future fees **฿500/750/1,000**. Training costs **฿1,500/3,000**
and needs venue stage **2/3** respectively, an active contract and the listed price. Non-booking hosts may train appeal without changing
consent. Appeal competes for the same shared traffic; it creates no extra buyers.
Training never changes an already-paid fee or its return deadline.

**฿3,000 auto-accept** is a permanent per-Soi-venue purchase requiring a contracted
willing host and the listed price. Its saved toggle defaults on when bought.
Live ticks use the same acceptance action after service; purchasing or toggling
it does not itself accept anything. It adds no offline booking income.

Schema **14** preserves automation, personal host training, fractional return
deadlines and booking report fields. Previous saves receive no purchases,
training or repayments. Old `away` entries without a deadline still return at
their original shift boundary; historical fees remain in their original revenue
rather than being reconstructed. All UI offers and countdowns are pure reads.

## Staff contracts and alerts

Bartender, host and dancer contracts last 14,400 game minutes (ten days).
Bartenders cost ฿1,200 per hire or rehire; hosts/dancers remain ฿4,500. Nida uses the separate ฿1,200 promoter contract. Remaining minutes are stored per person, alongside their training and
service timer. Foreground clock ticks, skipped overnight minutes and the full
offline gap consume time, including closed/off-duty periods. Only live simulation
phases advance contracts in the foreground. Backward wall clocks never extend
them. Managers remain a separate permanent appointment with operating costs.

Expiry switches the person off and removes any host
absence. Their stable roster slot, role and training remain. Expired staff cannot
serve, attract, accept bar fines, draw wages or be reactivated through the rota.
Rehire starts a fresh term without resetting training or an outstanding cooldown.
Role changes retain training and remaining term; service training only benefits
bartenders. A switch to a more expensive role charges the positive contract-price
difference × remaining minutes / 14,400, rounded up. There is no additional reserve requirement. Switching back grants no refund. This prevents
cheap bartender contracts from bypassing host/dancer pricing. Training
and rehire charge only their listed price. Rosters retain at most two
floor workers per stage, plus one frontage promoter; rehire an expired slot
rather than replacing its person. Promoters cannot be reassigned into cheaper
bartender/dancer hires.

Older saves initialise missing contract fields and copy the venue's old training
level to its existing staff. Future hires start at level zero. Optional fields
are validated on loading; the compatibility equipment key remains in schema 9,
but venue-wide training purchases are disabled. Normal offline catch-up applies
after migration. Existing money, venues and staff records are retained.

The selected venue's real pending orders drive a presentation-only bell. It can
sound immediately, then at most every ten seconds; empty/refilled queues do not
reset that cooldown. Mute, practice, fights and exploration suppress it. The
original sound is generated by `python3 tools/order-chime.py`; no external sample
or new audio dependency is needed.

## Music, supplier tiers and manager income

Music costs ฿1,200 for 25-second repeat orders instead of 35. Stage-two better
sound costs another ฿2,400 for 18-second repeats. Beer-bar stage three adds
฿3,600/4,800 tiers for 14/11 seconds. Music also controls finishing the final
drink, allowing earlier departure. None of these tiers adds visitors, enlarges
budgets, raises visit limits or bypasses service/stock. Existing timers stay
intact. Forecast demand uses expected rounds per visit, including club membership;
actual timing and losses determine whether music improves sales.

| Supplier level | Incremental purchase | Drinks per delivery | Unit / delivery cost | Minimum venue stage |
| --- | ---: | ---: | ---: | ---: |
| 1 | ฿900 | 6 | ฿38 / ฿228 | 1 |
| 2 | ฿1,200 | 12 | ฿36 / ฿432 | 1 |
| 3 | ฿2,400 | 12 | ฿34 / ฿408 | 2 |
| 4 | ฿4,800 | 12 | ฿32 / ฿384 | 2 |
| 5 | ฿9,600 | 12 | ฿30 / ฿360 | 3 |

Level zero has no automated deliveries and the same ฿38 unit cost as level one.
Discounts apply to both manual and automatic future packs; no retroactive refund.
Automatic deliveries still require waiting orders, stock below the current delivery quantity, space and
cash for a complete pack. Supplier purchases require only their listed price. Pre-lot inventory migrates at ฿14 per unit; recorded lots retain their paid costs.
Consignment drinks retain Bo's original ฿14 repayment regardless of supplier tier.

| Manager level | Incremental purchase | Bonus on earned margin | Minimum venue stage |
| --- | ---: | ---: | ---: |
| 1 | ฿2,000 | 25% | 2 |
| 2 | ฿6,000 | 50% | 3 |
| 3 | ฿18,000 | 75% | 3 |

Purchases require an on-duty bartender, deliveries and their listed price, without
healthy-shift gates. Management adds ฿12/minute overhead and enables offline
operation and cleaning. Bonuses use the current percentage, not stacked levels.
Each real drink (including hosted rounds) earns a bonus on its actual receipt
less FIFO paid stock cost and any consignment repayment. Paid pool fees also
qualify. Negative margins earn no bonus; saved hundredths carry into later sales.
Free pool, bookings, tips, refunds, transfers and event rewards earn no bonus.
Empty or closed venues generate no manager income. Owned manager levels survive
migration without refunds or recharge.

Manager receipts remain separate from drink/pool counters and healthy-shift
margin, while entering actual trading cashflow. Offline estimates use the same
margin formula after demand, stock and service limits and credit the venue till.
They protect starting cash, stop when unviable and never advance live milestones.

The HUD samples each venue’s trading cash flow every five foreground seconds, keeping
sample time and pending net in the save. `income` and operating/stock/commission/
fine charges feed it. One-off equipment, staff contracts, training, leases and
offline claims do not. The selected venue’s sample is displayed; closed seconds move its sample
toward zero. Decisions, boot menu and offline time do not run the sampler.

## Pool and promotions

A first pool table costs ฿2,000 and is available at beer-bar stage 1. Each table
uses two seats. Two real customers start a 30-second game for **฿50 total**, paid
once at the start. Guests retain their drink orders and stay thirty seconds
longer. The waiting list shows up to four players; unresolved interest expires
after thirty seconds. Installing furniture never evicts existing guests; new
arrivals wait for occupancy to fall below the revised capacity.

Free Pool Night, Happy Hour, Pool Tournament and Sports Night last 120 seconds,
then impose a 120-second cooldown. The same promotion repeated immediately after
that cooldown has diminishing attraction. Another promotion or a further ordinary
shift restores its appeal. Sports Night requires a screen. Tournament games still
cost ฿50, with the prize budget charged as the promotion expense. Happy Hour
reduces newly quoted drink prices by 20%; existing orders keep their quote.

Free games cost nothing even if the promotion expires before the game ends.
Previously paid games are never refunded or billed twice. Timers and promotion IDs
are saved. The report distinguishes actual pool receipts, free games, foregone
fees, attributed visitors and their drink sales/stock costs, new regulars and
queue losses. It deducts the entire promotion window's operating costs for a
conservative contribution figure. The unpromoted visitor baseline is an estimate,
not additional revenue. Late purchases from attributed guests update the report.

## Renovation and expansion

Renovations require only the unchanged price. Local milestones
now earn loyalty: 70 satisfied visits / 10 regulars / eight healthy shifts gives
+5% appeal; 450 / 70 / forty gives +10% total, not an additional 10%.
These milestones do not gate construction.
A healthy shift serves at least four orders, fulfils at least 80% of orders and
has positive operating margin after stock consumed, payroll, promotion costs, fines and drink commission.
The cash report separately records inventory purchases when paid. Manager
income and nightly tips do not qualify a healthy shift.

Upgrades groups each stage’s offers by whether shared money covers the price. The next renovation separates current-stage purchases from later-stage
previews and shows the shared money and selected renovation price. Loyalty counts appear separately.
The top shortcut jumps to that section. Ready only keeps renovation progress
visible while filtering purchase cards.

Loyalty belongs to the venue. Renovation requires only its fee. Beer-bar renovations cost ฿4,800 and ฿40,000. New leases require no additional float.
First purchased leases cost ฿12,000/24,000/60,000 for beer/hostess/gogo. Each
prior same-type purchase adds 25% of its base lease, never compounded. The original
beer bar in slot zero is excluded even if renamed. Existing owned venues count
for future quotes, but retain their cash, progress and paid inventory without refunds.

Every fourteenth game day offers an advertised 10% lease discount on one type,
rotating hostess/beer/gogo from day fourteen. It applies after the repeat premium,
to purchases during that day only. No reward is claimed or replayed; quotes derive
from the saved date and current ownership. The menu does not advance the offer.
The reopening, reputation, eight-property cap and listed-price affordability gates remain.
The retirement story no longer silently discounts every first hostess property.

`street.lease_quote()` owns price, base/repeat/offer breakdown,
total affordability, overhead and one-bartender house-drink break-even. Empire
presents the same quote that purchase settlement uses. There is no startup float. Forecast
break-even excludes pool and manager receipts and does not promise demand.
Money earned elsewhere can fund the building but cannot buy its loyal clientele.
There are no mandatory waiting timers. Renovation adds space, staffing positions
and operating options; it does not increase ordinary beer prices.

## Guided shifts, saves and offline time

The startup menu pauses simulation and saving until the player chooses New Game
or Resume. Resume claims eligible offline time once, including time spent on the
menu. Confirmed New Game replaces the single campaign slot and removes the old
backup; it starts with the ordinary opening cash, stock and customers.

Managed-shift guidance has three decisions at the ordinary shift boundaries
(start, 40s and 80s). Decision screens pause the model. Continuing resumes the
same visitors, games, inventory and ledger. Repeated choices cannot skip time,
create customers or settle another report. The tutorial practises the live service
loop and closing in a separate campaign. Old saves interrupted inside a legacy shift finish that shift
once, then enter the live economy.

Version-seven saves add music, owner automation, manager/supplier levels, stock
cost lots and the five-second trading sample. Existing appointments migrate to
level one; cash, ownership, stock counts and active deadlines are preserved.
Unpurchased upgrades remain unpurchased.

Version-six saves retain the frontage roster, audience training, commission carry
and customer commitments, plus fractional offline sales/cost/pool credits. Older
saves gain zeroed fields without free purchases or fees. Save validation supports
six floor staff plus one promoter and rejects invalid new fields.

Version-five saves additionally retain fractional foreground time, action upgrade
levels, cooldown durations/deadlines and per-visit chat allowance. Versions 1–4
migrate with unpurchased upgrades and their existing deadlines preserved.
Version-four saves already retain queues, game fees, promotion timers, clock, cleaning,
nightly permissions, raid counters and RNG state. Version-three migration starts
at noon on the existing day with clean venues, preserving its live queues and
paid/free pool identity. Version-one/two migration retains money, properties,
stages and hires;
older beer bars at stage 2+ receive their depicted pool table. New queues start
empty. Existing progress is not rolled back to enforce the new pacing curve.

Offline trading is an explicitly **estimated** projection, capped at eight hours.
Only enabled managed venues outside temporary event closure/recovery qualify.
Project from a saved private minute cursor, counting only noon–1am windows at
one game minute per real second. Advance that cursor across the full wall-clock
gap (even beyond the earning cap), but leave the live clock unchanged. Foreground
clock movement reanchors it; consecutive offline claims cannot reuse a legal
window. Split the projection at opening, closing and all venue peak boundaries;
calculate competition and service/stock limits separately for each segment.
Also split at every staff contract expiry across all venues, so expired staff
stop contributing service, attraction and payroll at the correct projected minute.
Consume contract time across the full absence, even beyond the eight-hour earning
cap, and include expiry notices in the offline report. Never auto-renew contracts inside an offline claim; AFK renewals resume only on live street ticks.
Expected sales are bounded by shared demand, space, service and stock. Estimated
sales consume owned stock; supplier purchases add complete six- or twelve-drink deliveries at the
venue’s current supplier price.
Only surplus generated within that claim funds packs: existing cash is protected.
An empty fridge cannot bootstrap offline trading; restock before leaving. Manager
bonuses depend on estimated customer margins and cannot generate seed money. Operating costs and
commission settle with projected receipts; fractional sales and their associated
costs/pool income persist together so short claims cannot avoid charges.
Repeated claims at the same timestamp credit nothing. Splitting a long absence
can be more conservative when a fresh claim lacks pack working capital; it does
not create free inventory. Unviable trading pauses without idle-mode cash debt. Temporary promotions, customer queues, local milestones, events and
calendar time, dirt, cleaning, heat and raids do not advance. Reports in Journal
separate time away from eligible trading seconds and list estimated customers served,
income, costs, net profit and limiting factors. Monotonic saved claim timestamps
prevent repeat rewards, including clock rollback.

## Historical opening-arc balance pass — 26 November 2026

The first manager now costs ฿12,000; later levels remain ฿36,000/72,000.
Bartender training is ฿400 then ฿800, with unchanged 25/20/15-second service.
Audience training is still ฿800/1,600. Final renovations cost ฿40,000/65,000/120,000
for beer/Soi/gogo venues; first renovations stay ฿4,800/18,000/45,000. The final
local gate is 450 happy visits, 70 regulars and forty healthy shifts. No new stage
price multiplier, free hires, reward currency or retroactive refund is introduced.

Before this pass, six active baseline runs had 44.4–47.9-minute gaps while saving
for management. The revised first-manager saving gap is 24.8–26.8 minutes.
Reducing only the manager cost moved the long wait to final renovation, so that
price and its happy-visit requirement were tuned together. Regulars, healthy
shifts, operating reserves and bounded customer demand remain required.

| Baseline milestone | Before | Revised measured range | Current active acceptance |
| --- | --- | --- | --- |
| First useful purchase | 2.5–4.4 min | unchanged | 2–5 min |
| Pool | 15.9–18.4 min | unchanged | 10–20 min |
| Stage two | 33.6–36.8 min | unchanged | 30–45 min |
| First manager | 98.7–102.2 min | 85.8–87.8 min | saving gap ≤30 min |
| Second property | 117.7–122.2 min | 102.2–104.7 min | 90–125 min |
| Stage three | 166.9–172.4 min | 142.5–144.1 min | 135–240 min |
| Longest gap between improvements | 44.4–47.9 min | 34.2–36.2 min | ≤38 min |

Mostly-idle baseline stage three improves from 227.1–233.2 to 178.9–184.5 minutes.
These policies do not optimize later properties or simulate a full festival run.
The bounds intentionally supersede the old three-to-five-hour target in response
to the player's request for less grind. They are not imposed waiting periods.
Buying discretionary equipment can delay a milestone; all alternative routes
still need to remain solvent and respect demand, orders and supply.

At full incremental demand, the first training tier's ฿400 buys 0.6 extra drinks
per minute: roughly 16 minutes to repay at a ฿41 margin, before commission.
The second tier buys one extra drink per minute, roughly 20 minutes to repay.
An empty bar has no training payback. First management's separate ฿600/min income
less its extra ฿12/min overhead repays ฿12,000 in about 20.4 open minutes, before
changes in other trade. Stage two and viable-operation prerequisites prevent an
opening cash generator. Forecasts remain estimates, not promised profit.

Anong's next-step panel reads the shared chapter predicates and real progress.
It points to supplies, local renovation, reopening events, staff, deliveries,
management and expansion. It cannot change money, RNG, time or progression.
Story reminders grant no reward and add no new mandatory steps or save fields.

## Historical opening-arc balance verification

Run `tools/test.sh` with Godot 4.7.2. Temporary save/config directories isolate
regressions and 42 fresh campaigns: fifteen baseline/no-Chat runs, twelve promoter
comparisons and fifteen automation/early-bartender routes. Seeds are 11, 72 and
291. Attentive players check actions each second, balanced players every two
seconds, mostly-idle players every fifteen seconds. All actions use real stock,
orders, paid purchases, contracts and the normal clock; no offline income or
injected cash is used in these campaign runs.

The baseline buys pouring level one, signage, seating and pool, then renovates.
It buys further pouring, hires/trains, arranges deliveries/management and expands.
Alternative routes change this investment order. Routine stock and renewals do
not count as new improvements when measuring saving gaps. Cleaning and skipping
use actual actions. The player may choose other investments during these gaps;
this policy is a reproducible comparison, not a claim that every human waits.

| Optional purchase route | Stage 2 | Second property | Stage 3 |
| --- | ---: | ---: | ---: |
| Promoter before renovation | 47.3–47.5 min | 110.5–112.0 min | 148.2–150.5 min |
| Service first, promoter later | 43.4–44.0 min | 109.7–111.2 min | 148.4–149.6 min |
| Compact layout | 38.7–42.2 min | 102.5–105.0 min | 141.5–143.8 min |
| Music first | 41.2–42.5 min | 106.7–110.4 min | 146.0–148.7 min |
| Auto-serve and two-second pouring | 35.5–36.3 min | 126.5–127.3 min | 165.4–165.9 min |
| Supplier first | 35.5–36.3 min | 105.4–109.2 min | 143.4–146.8 min |
| Automation bundle | 41.2–42.5 min | 130.4–131.4 min | 168.0–168.6 min |
| Bartender before other upgrades | 47.6–50.3 min | 106.4–107.5 min | 147.2–148.0 min |

The early hire still occurs at 4.2–4.7 minutes. Convenience spending buys fewer
taps rather than the fastest possible milestone. Auto-serve routes stop tapping
Serve once purchased. Nida retains her price/commission; no training or upgrade
can bypass shared traffic. All runs finish solvent, with sales bounded by orders
and arrivals bounded by street supply. Staff/idle and no-Chat paths remain viable.

Sixty paired celebration scenarios additionally compare 120 trading days. The
unchanged birthday rules produce 51% more drinks and 57% more contribution for
prepared bars in aggregate; basic bars gain 28% and 27%, with more queue losses.
Pool checks across thirty paired seeds still show a quiet-night benefit and a
full-house trade-off. These are scenario results, not a universal profit promise.

Larger management tiers, gogo rules and final venue prices have settlement/gate
coverage. This pass does not establish full-festival pacing or human retention.
Relevant scene previews preserve the existing artwork. Device playtesting remains
separate from the automated regressions and desktop renders.

## Renewal availability

`rehire_offer` supplies the action and UI with the same exact contract-fee quote.
No additional payroll or stock reserve is required.
The frontage section always exposes her renewal control after the first hire,
with a live shortfall/active-contract explanation. Roster expiry explicitly
invalidates the UI, independently of history notices. Full floor staffing never
blocks her separate frontage renewal. No schema change or new rehire reward.

## Closing clean-up and tomorrow's opening

After the last venue closes for the night, a free **15-second clean-up** starts
for all dirty venues, including those without a manager. A visible street button
counts down to noon. **Stay here** cancels the automatic jump for that night;
cleaning continues, and **Skip to open** stays on the bottom bar until noon.
Even an already-clean street gives you the full fifteen-second choice.

The countdown waits for late-trading venues to finish. Daytime closure and a
temporary event closure cannot end an otherwise scheduled late night. It advances
only during foreground street play, never on the start menu or through offline
estimates; its countdown pauses while the street is hidden by district/arcade
views. Normal clock rules still apply. Schema 10 preserves the remaining time
and cancellation across reloads; older saves start with no pending countdown.

At zero, completed cleaning is retained and the existing skip moves the clock
to noon. Stock is not bought, no income is awarded, and contracts age through the
skipped hours as before. Owner-closed or cash-shortage-closed venues stay closed.
The date already advanced at midnight, so the jump does not add another day.

## Gabby's service tips

Gabby is an optional named adult bartender: ฿1,200 for ten game days, standard
bartender wages, training and floor-slot limits. Only one roster place
across the street can belong to her, including expired contracts. She remains
a bartender; renewal preserves her identity, training and service deadline.

After each successful live staff sale by Gabby, add ฿5 to the existing saved
`bonus_tips` jar. This stacks with first-visit tips and matched-drink bonuses,
including on repeat rounds. No order, stock, availability or ready deadline means
no bonus. Owner/other staff sales, offline estimates and manager/pool income earn
none of her tips. Normal once-nightly settlement pays the jar; no separate sales,
commission, healthy-margin or five-second trading entry is created. Existing
campaigns receive no hire, identity replacement or retroactive tips.

## Daisy's host contract

Daisy is an optional named adult entertainer available only in Hostess bars.
Her ฿4,500 ten-day contract delegates to normal host hiring: one floor slot,
host wages and exact contract price. She uses existing host attraction,
training, consent and booking rules, with Chat as her hosted-drink topic.
She never serves orders or earns Gabby's bartender bonus. Only one roster place
across the street belongs to Daisy, including expired contracts. Renewal retains
her training and any booking deadline. Her appended host ID preserves the six
existing host identities; no saved employee is replaced or granted for free.

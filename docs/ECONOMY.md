# Customer economy

The live street is authoritative. `scripts/economy.gd` owns visitors, orders,
stock settlement, payroll, pool games, promotions and forecasts. `street.gd`
advances this model once per foreground second and settles reports every 120
seconds of street trading, plus one partial report at overnight closure. UI and artwork consume this state; they never award sales themselves.
Balance and purchase definitions live in `scripts/street_content.gd`.

The [seating/six-pack/promoter design](design/PROMOTER_CAPACITY_PLAN.md) is
implemented. Its initial forecast examples are analytical estimates; measured
campaign outcomes appear below.

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
clean, available while closed, clears dirt and costs no cash. Managers start the
job automatically on closure. Restocking uses the existing paid purchase action.

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

Start with ฿200, 18 drinks and three forgiving opening customers. Serve their
actual orders; welcome passersby when there are no orders. A yellow/gold dot marks a
waiting order and turns red when the lesser of remaining order patience and
visit time is ten seconds or less. The display uses the same remaining-time rule
as Chat, including comfort and reassurance bonuses; it adds no new timers.
Customers can buy two drinks during a visit, have a spending
budget, and leave unhappy when an order waits too long. A quiet click neither
uses stock nor earns money. Manual service immediately sells one ordered drink,
then refills for ten foreground seconds. Failed attempts consume no cooldown.
Bartenders continue serving independently during manual recovery.

Each venue buys separate Faster pouring and Better welcoming levels in Service:
10 → 8 → 6 → 4 seconds, at incremental prices of ฿900, ฿1,400 and ฿2,800.
Pouring alone adds a stage-two 4 → 2 second tier for ฿5,600. Welcome still caps
at four seconds. Auto-serve is a separate ฿6,000 purchase, using the same saved
Serve deadline, actual-order/stock checks and current cooldown as manual serving.
It runs per venue during live ticks, including guided play; it does not stack a
second owner timer, reset an active deadline or advance through paused screens.
Its toggle changes scheduling, never speed. Managed offline forecasts include
its capacity without replaying saved live orders or advancing the live deadline.
Purchases preserve the next shift’s operating reserve and affect subsequent uses,
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
An empty bar needs appeal; a queue needs service; a full bar needs more space.

Useful early investments include signage, seating, deliveries, pool and a fridge.
A bartender contract costs ฿1,200, matching Nida’s upfront fee without her commission. Base service is one drink
per 25 real seconds (2.4/min); individual training costs ฿800 then ฿1,600 and
reduces this to 20s (3/min) then 15s (4/min). Each bartender has a saved work timer;
empty queues and stockouts cannot bank future service or generate sales. Manual
serving remains useful alongside staff. Hosts and dancers attract
visitors instead. Gogos perform between seconds 40 and 80 of each shift; drinks
and premium-menu orders are priced independently of renovation stage.

Stock starts at ฿14 per drink when delivered; supplier levels reduce future
unit costs to ฿12/10/8/6. Inventory lots retain paid unit costs and are consumed
first-in, first-out for promotion contribution and healthy-shift margins. Wages and premises overhead are charged
throughout open time, including quiet periods. Schedule staff off or close a venue
to reduce charges. An unaffordable operating charge closes the venue before debt
is created. Staff records and equipment remain; contracts continue to expire. Anong's owner-run recovery shift
covers two minutes of overhead; if the fridge is empty, six consignment drinks
are paid for only when a real customer buys them. No buyer means no income.

## Compact layout, deliveries and the frontage promoter

Beer-bar seating levels cost ฿400, ฿800 and ฿1,200. Stage-one capacity before
furniture is 6/8/10/12. Pool normally uses two places per table and comfort one;
the third seating level recovers up to three furniture places. Thus every legal
stage-one combination holds twelve. Stage two holds eighteen with one table and
comfort, sixteen with two. Other venue types retain two seating upgrades.
Purchases preserve the next shift's operating reserve and show actual capacity.

`pack_quantity`, `stock_offer` and `restock` settle six drinks for ฿84 at supplier
levels 0/1, then twelve drinks at level 2 and above (initially ฿144). Neither
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

Nida costs ฿1,200 for ten game days plus 10% of drink receipts, with no additional
hourly wage. One frontage slot is separate from seats and floor staffing. While
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

Commission settles once per actual drink, including premium and discounted
orders, excluding pool and host fees. Add `receipt × 10` to a saved percentage
remainder, pay integer baht divided by 100, retain modulo 100. Two ฿55 beers pay
฿11 total across reloads. Every sale while the promoter works qualifies. Visits
admitted on duty retain eligibility for the visit; existing orders committed
while she works remain eligible after rota changes or expiry. Abandoned orders
cost nothing. Flags never stack two commissions on one sale.

Gross drink income and commission are separate ledger entries. Weekly costs,
shift net/healthy margin, promotion contribution, forecasts and offline estimates
include commission once. Hire previews show post-hire cash and the required
one-shift payroll plus one current-price pack reserve, arrivals, unattended and owner-active net,
and whole-street impact. These are capacity estimates, not promises of revenue;
they account for other properties losing some shared visitors. Hiring more
attraction into a service bottleneck can reduce net profit.

## Staff contracts and alerts

Bartender, host and dancer contracts last 14,400 game minutes (ten days).
Bartenders cost ฿1,200 per hire or rehire; hosts/dancers remain ฿4,500. Nida uses the separate ฿1,200 promoter contract. Remaining minutes are stored per person, alongside their training and
service timer. Foreground clock ticks, skipped overnight minutes and the full
offline gap consume time, including closed/off-duty periods. Only live simulation
phases advance contracts in the foreground. Backward wall clocks never extend
them. Managers remain a separate permanent appointment with operating costs.

Expiry switches the person off, clears their partial work and removes any host
absence. Their stable roster slot, role and training remain. Expired staff cannot
serve, attract, accept bar fines, draw wages or be reactivated through the rota.
Rehire starts a fresh term and resets work progress without resetting training.
Role changes retain training and remaining term; service training only benefits
bartenders. A switch to a more expensive role charges the positive contract-price
difference × remaining minutes / 14,400, rounded up, and requires a full shift’s
operating reserve afterward. Switching back grants no refund. This prevents
cheap bartender contracts from bypassing host/dancer pricing. Training
and rehire require the next shift's operating reserve. Rosters retain at most two
floor workers per stage, plus one frontage promoter; rehire an expired slot
rather than replacing its person. Promoters cannot be reassigned into cheaper
bartender/dancer hires.

Older saves initialise missing contract fields and copy the venue's old training
level to its existing staff. Future hires start at level zero. Optional fields
are validated on loading; the compatibility equipment key remains in schema 7,
but venue-wide training purchases are disabled. Normal offline catch-up applies
after migration. Existing money, venues and staff records are retained.

The selected venue's real pending orders drive a presentation-only bell. It can
sound immediately, then at most every ten seconds; empty/refilled queues do not
reset that cooldown. Mute, practice, fights and exploration suppress it. The
original sound is generated by `python3 tools/order-chime.py`; no external sample
or new audio dependency is needed.

## Music, supplier tiers and manager income

Music is a one-time ฿1,200 equipment purchase. Newly served drinks start a
25-second repeat-order interval instead of 35 seconds: 40% faster repeat timing.
It does not add visitors, enlarge budgets, remove the two-drink limit, guarantee
satisfaction or bypass stock/service. Already-running repeat timers stay intact.
Forecast demand remains the conservative two-orders-per-visit capacity estimate;
actual timing and losses determine whether music improves sales.

| Supplier level | Incremental purchase | Drinks per delivery | Unit / delivery cost | Minimum venue stage |
| --- | ---: | ---: | ---: | ---: |
| 1 | ฿900 | 6 | ฿14 / ฿84 | 1 |
| 2 | ฿1,200 | 12 | ฿12 / ฿144 | 1 |
| 3 | ฿2,400 | 12 | ฿10 / ฿120 | 2 |
| 4 | ฿4,800 | 12 | ฿8 / ฿96 | 2 |
| 5 | ฿9,600 | 12 | ฿6 / ฿72 | 3 |

Level zero has no automated deliveries and the same ฿14 unit cost as level one.
Discounts apply to both manual and automatic future packs; no retroactive refund.
Automatic deliveries still require waiting orders, stock below the current delivery quantity, space and
cash for a complete pack plus the next operating charge. Supplier purchases
preserve one shift's operating reserve. Old inventory migrates at ฿14 per unit.
Consignment drinks retain Bo's original ฿14 repayment regardless of supplier tier.

| Manager level | Incremental purchase | Separate income per real second | Minimum venue stage |
| --- | ---: | ---: | ---: |
| 1 | ฿18,000 | ฿10 | 2 |
| 2 | ฿36,000 | ฿20 | 3 |
| 3 | ฿72,000 | ฿40 | 3 |

Level one retains the bartender, deliveries and eight-healthy-shift requirements.
Every purchase preserves operating reserve. A manager adds ฿12/real-minute
overhead, enables managed offline estimates and cleaning, and now provides
explicit separate management income while trading. This is a user-requested
passive-income exception, not an ordinary drink sale. It grants no orders,
customers, satisfaction, regulars, pool games or commission, consumes no stock,
and is excluded from healthy-service margin. Owner closure, scheduled closure,
raids, temporary event closure and recovery suppress it. Skipping time grants
none; existing managers receive level one without an additional fee.

Manager income enters gross revenue plus a dedicated shift-report field, and
is included in net forecasts. Offline legal windows project it independently
from demand-limited drink sales. It can fund packs from that claim's new surplus;
starting cash is still protected. No service means no projected drinks or packs,
but manager income continues while the projected venue is legally open.

The HUD samples shared trading cash flow every five foreground seconds, keeping
sample time and pending net in the save. `income` and operating/stock/commission/
fine charges feed it. One-off equipment, staff contracts, training, leases and
offline claims do not. All venues contribute; closed seconds move the sample
toward zero. Decisions, boot menu and offline time do not run the sampler.

## Pool and promotions

A first pool table costs ฿2,000 and is available at beer-bar stage 1. Each table
uses two seats. Two real customers start a 45-second game for **฿50 total**, paid
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

Stage 2 requires 70 satisfied visits, 10 local regulars and eight healthy shifts.
Stage 3 requires 600 satisfied visits, 70 local regulars and forty healthy shifts.
A healthy shift serves at least four orders, fulfils at least 80% of orders and
has positive operating margin after stock consumed, payroll, promotion costs, fines and drink commission.
The cash report separately records inventory purchases when paid.

Milestones belong to the venue. Renovation also requires its fee and the next
shift's operating reserve. Beer-bar renovations cost ฿4,800 and ฿50,000. New
leases additionally require a float for a ฿1,200 bartender contract, stock and existing street payroll.
The first Soi lease is ฿16,000: a cheaper entry from the retiring owner, balanced
against its higher overhead. This leaves room for contracts, individual training
and action upgrades without delaying the second property past the active target.
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
create customers or settle another report. The original tutorial is a separate
practice campaign. Old saves interrupted inside a legacy shift finish that shift
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
cap, and include expiry notices in the offline report. Never auto-renew contracts.
Expected sales are bounded by shared demand, space, service and stock. Estimated
sales consume owned stock; supplier purchases add complete six- or twelve-drink deliveries at the
venue’s current supplier price.
Only surplus generated within that claim funds packs: existing cash is protected,
so an empty fridge needs newly generated manager income before an offline pack
can be bought. A legacy projection without manager income cannot bootstrap it. Operating costs and
commission settle with projected receipts; fractional sales and their associated
costs/pool income persist together so short claims cannot avoid charges.
Repeated claims at the same timestamp credit nothing. Splitting a long absence
can be more conservative when a fresh claim lacks pack working capital; it does
not create free inventory. Unviable trading pauses without idle-mode cash debt. Temporary promotions, customer queues, local milestones, events and
calendar time, dirt, cleaning, heat and raids do not advance. Reports in Journal
separate time away from eligible trading seconds and list estimated customers served,
income, costs, net profit and limiting factors. Monotonic saved claim timestamps
prevent repeat rewards, including clock rollback.

## Balance verification

Run `tools/test.sh` with Godot 4.7.2. It uses temporary save directories and runs
the regression suite, `tests/economy_balance.gd`, `tests/promoter_balance.gd` and
`tests/automation_balance.gd`: 42 fresh campaigns in total.

The combined balance runner uses fresh campaigns with seeds 11, 72 and 291,
without injected cash or offline income. Attentive players check ready actions
each second, balanced players every two seconds, and mostly-idle players every
fifteen seconds. Every serve still obeys its cooldown, actual orders and stock.

Active players buy pouring level 1, signage, seating and pool, then renovate.
They buy remaining pouring levels after stage 2, hire and train a bartender,
arrange deliveries/management, and buy welcoming level 1 before expanding.
Expired staff are rehired through the same paid action when affordable. Idle and
staff-first comparisons use no action upgrades; six additional campaigns disable
Chat. Closed-hour cleaning and skipping use actual player actions. An existing
staff order is allowed to finish while the owner's Serve button refills.

The current tuning uses ฿1,200 bartender contracts, 25/20/15-second staff service, ten-second
base owner actions and ฿900/1,400/2,800 action upgrade prices. Combining those
investments required lowering the first Soi lease from ฿26,000 to ฿16,000.
Existing money, properties and upgrades are never reset; no refunds are minted.

| Milestone | Original active target | Measured combined active range |
| --- | --- | --- |
| First useful purchase | 2–5 min | 2.5–4.4 min |
| Pool table | 10–20 min | 15.9–18.5 min |
| First stage 2 | 30–45 min | 33.6–36.8 min |
| Second property | 90–150 min | 127.2–137.1 min |
| First stage 3 | 180–300 min | 179.1–189.3 min |

Mostly-idle campaigns reach stage 3 in 230–239 minutes. No-chat manual-upgrade
campaigns take 178–187 minutes; no-chat staff-first campaigns take 192–195 minutes.
The six active target runs use the original windows with a one-minute allowance
below the three-hour stage-3 lower bound for the explicitly cheaper contracts; the other nine
must remain viable and complete within the ten-hour simulation limit. All target
runs also check sales against orders and arrivals against shared street supply.
This is a reproducible purchase policy, not a promise for every human
strategy. Across thirty paired scenario seeds, free pool improved aggregate quiet
night contribution and reduced full-house contribution. Regression coverage also
includes empty-order clicks, stockouts, service queues, shared demand, timed wages,
closure/recovery, pool/save idempotency, role separation, local renovation gates,
consensual customer-originated bar fines, offline claims and guided shift timing.

Twelve additional campaigns compare promoter-before-renovation, service-first,
compact-first and no-promoter/no-Chat paths using the same seeds and paid actions.
All finish solvent within ten hours and respect order/shared-traffic limits.
These optional investments are not forced into the baseline milestone windows:

| Purchase route | Stage 2 | Second property | Stage 3 |
| --- | ---: | ---: | ---: |
| Promoter before renovation | 47.3–47.5 min | 138.0–142.9 min | 190.9–197.0 min |
| Service first, promoter after renovation | 43.4–44.0 min | 137.3–143.8 min | 189.5–197.2 min |
| Compact layout, no promoter | 38.7–42.2 min | 131.2–133.1 min | 181.9–183.4 min |

The early promoter route buys pouring level two and compact seating before Nida,
yet still delays renovation: automatic welcoming is a convenience with a real
cost, not a compulsory profit upgrade. The six active target runs retain the early milestone windows, with the
one-minute stage-3 allowance described above. Promoter contract/commission terms and shared traffic remain unchanged.
The new manager income is priced separately as described above. Dancer stage gates/retained skills and service separation
have regression coverage, not a new full-gogo campaign balancing claim.

The additional twelve automation campaigns compare music-first, auto-serve plus
two-second pouring, supplier-first and the combined bundle. Automatic strategies
stop pressing Serve once it is purchased; they still pay for every upgrade.

| Route | Stage 2 | Second property | Stage 3 |
| --- | ---: | ---: | ---: |
| Music first | 41.2–42.5 min | 133.8–137.5 min | 185.8–188.9 min |
| Auto-serve and two-second pouring | 35.5–36.3 min | 154.2–163.2 min | 207.6–216.9 min |
| Supplier first | 35.5–36.3 min | 135.0–137.5 min | 185.7–188.5 min |
| Automation bundle | 41.2–42.5 min | 163.4–168.1 min | 213.7–219.2 min |

Optional convenience spending delays expansion; it is not required for the
baseline targets. All strategies remain solvent and respect orders/shared demand.
The initial ฿24,000 manager price delayed baseline expansion beyond 150 minutes;
฿18,000 keeps active expansion inside the target range without raising drink prices or
inventing customer sales. Larger manager tiers have settlement/gate coverage,
not a claim of fully balanced post-stage-three play.

Three further campaigns save for a bartender before other investments. The first
hire is affordable at **4.2–4.7 minutes**; pool follows at 23.1–24.1 minutes,
stage 2 at 55.5–57.8, the second property at 138.9–142.0 and stage 3 at
190.1–193.4. Early wages and delayed owner upgrades make this a convenience
choice, not a guaranteed acceleration of every milestone. All three remain
solvent and respect demand; the first-hire acceptance ceiling is ten minutes.

The graphical preview harness renders the opening, pool, free-pool report,
recovery, all nine venue stages and festival states. It consumes the current
artwork refresh; it does not replace that artwork. Device playtesting remains
separate from automated desktop checks.

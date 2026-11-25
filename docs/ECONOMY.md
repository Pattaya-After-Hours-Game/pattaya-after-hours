# Customer economy

The live street is authoritative. `scripts/economy.gd` owns visitors, orders,
stock settlement, payroll, pool games, promotions and forecasts. `street.gd`
advances this model once per foreground second and settles reports every 120
seconds of street trading, plus one partial report at overnight closure. UI and artwork consume this state; they never award sales themselves.
Balance and purchase definitions live in `scripts/street_content.gd`.

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
actual orders; welcome passersby when there are no orders. A gold dot marks a
waiting order. Customers can buy two drinks during a visit, have a spending
budget, and leave unhappy when an order waits too long. A quiet click neither
uses stock nor earns money. Manual service is capped at one order per second.

Welcoming has a ten-second cooldown, a short expiry and a capped attraction
bonus. The street supplies 7.3 potential visitors per real minute before events;
opening a different venue type adds an audience, while similar venues compete.
Local, tourist and nightlife groups choose among the venues and outside options.
An empty bar needs appeal; a queue needs service; a full bar needs more space.

Useful early investments include signage, seating, one bartender, automatic
deliveries, a pool table and a fridge. A bartender serves ten drinks per minute
before training, only when real orders and stock exist. Hosts and dancers attract
visitors instead. Gogos perform between seconds 40 and 80 of each shift; drinks
and premium-menu orders are priced independently of renovation stage.

Stock costs ฿14 per drink when delivered. Wages and premises overhead are charged
throughout open time, including quiet periods. Schedule staff off or close a venue
to reduce charges. An unaffordable operating charge closes the venue before debt
is created. Staff and equipment remain owned. Anong's owner-run recovery shift
covers two minutes of overhead; if the fridge is empty, six consignment drinks
are paid for only when a real customer buys them. No buyer means no income.

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
has positive operating margin after stock consumed, payroll, promotion costs and fines.
The cash report separately records inventory purchases when paid.

Milestones belong to the venue. Renovation also requires its fee and the next
shift's operating reserve. Beer-bar renovations cost ฿4,800 and ฿50,000. New
leases additionally require a float for hiring, stock and existing street payroll.
Money earned elsewhere can fund the building but cannot buy its loyal clientele.
There are no mandatory waiting timers. Renovation adds space, staffing positions
and operating options; it does not increase ordinary beer prices.

## Guided shifts, saves and offline time

Managed-shift guidance has three decisions at the ordinary shift boundaries
(start, 40s and 80s). Decision screens pause the model. Continuing resumes the
same visitors, games, inventory and ledger. Repeated choices cannot skip time,
create customers or settle another report. The original tutorial is a separate
practice campaign. Old saves interrupted inside a legacy shift finish that shift
once, then enter the live economy.

Version-four saves retain queues, game fees, promotion timers, clock, cleaning,
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
Expected sales are bounded by shared demand, space, service and stock; stock and operating costs are deducted. Unviable trading
or insufficient working cash pauses the projection, without spending the opening
cash reserve. Temporary promotions, customer queues, local milestones, events and
calendar time, dirt, cleaning, heat and raids do not advance. Reports in Journal
separate time away from eligible trading seconds and list estimated customers served,
income, costs, net profit and limiting factors. Monotonic saved claim timestamps
prevent repeat rewards, including clock rollback.

## Balance verification

Run `tools/test.sh` with Godot 4.7.2. It uses temporary save directories and runs
both the regression suite and `tests/economy_balance.gd`.

The balance runner uses fresh campaigns with seeds 11, 72 and 291 and no offline
income or injected money. Click-heavy players serve every second, balanced players
every four seconds, and mostly-idle players every fifteen seconds. The purchase
policy invests in signage, staff, deliveries and seating before pool, then a
fridge, stage 2, management, a second property and stage 3. All purchases pass the
real action gates. Policies clean each venue and skip to noon using real actions;
prep seconds count toward milestone times. Base traffic was adjusted from 7 to
7.3 per real minute to retain the acceptance windows with dirt and nightly prep. Active styles must meet every target; mostly-idle must still
finish without becoming stuck.

| Milestone | Active target | Measured active range |
| --- | --- | --- |
| First useful purchase | 2–5 min | 2.1–2.5 min |
| Pool table | 10–20 min | 15.8–17.6 min |
| First stage 2 | 30–45 min | 39.1–43.5 min |
| Second property | 90–150 min | 129.4–142.9 min |
| First stage 3 | 180–300 min | 217.1–236.0 min |

Mostly-idle runs reach stage 3 in approximately 235–244 minutes, with a slower
opening. These are deterministic policy tests, not a claim about every human
strategy. Across thirty paired scenario seeds, free pool improved aggregate quiet
night contribution and reduced full-house contribution. Regression coverage also
includes empty-order clicks, stockouts, service queues, shared demand, timed wages,
closure/recovery, pool/save idempotency, role separation, local renovation gates,
consensual customer-originated bar fines, offline claims and guided shift timing.

The graphical preview harness renders the opening, pool, free-pool report,
recovery, all nine venue stages and festival states. It consumes the current
artwork refresh; it does not replace that artwork. Device playtesting remains
separate from automated desktop checks.

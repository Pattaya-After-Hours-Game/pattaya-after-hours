# Customer economy

The live street is authoritative. `scripts/economy.gd` owns visitors, orders,
stock settlement, payroll, pool games, promotions and forecasts. `street.gd`
advances this model once per foreground second and settles reports every 120
seconds. UI and artwork consume this state; they never award sales themselves.
Balance and purchase definitions live in `scripts/street_content.gd`.

## Playing the first bar

Start with ฿200, 18 drinks and three forgiving opening customers. Serve their
actual orders; welcome passersby when there are no orders. A gold dot marks a
waiting order. Customers can buy two drinks during a visit, have a spending
budget, and leave unhappy when an order waits too long. A quiet click neither
uses stock nor earns money. Manual service is capped at one order per second.

Welcoming has a ten-second cooldown, a short expiry and a capped attraction
bonus. The street supplies seven potential visitors per minute before events;
opening a different venue type adds an audience, while similar venues compete.
Local, tourist and nightlife groups choose among the venues and outside options.
An empty bar needs appeal; a queue needs service; a full bar needs more space.

Useful early investments include signage, seating, one bartender, automatic
deliveries, a pool table and a fridge. A bartender serves ten drinks per minute
before training, only when real orders and stock exist. Hosts and dancers attract
visitors instead. Gogos perform between seconds 40 and 80 of each shift; drinks
and premium-menu orders are priced independently of renovation stage.

Patron preferences are drawn from the audience at each venue. The current crowd
mix affects the expected demand used by the fridge display and mixed deliveries.
The display counts requests and shortages across the current and previous shift.
Products share fridge capacity. Orders reserve their quoted price, and some guests
will take house lager at its order-time quote if their first choice runs out.
Unfillable orders can expire even when the fridge has other drinks. A bartender
can still serve the next guest. Out-of-stock substitutions count as shortages of
the requested drink. Wholesale costs are charged on delivery. The shift tracks
the cost of drinks sold separately when calculating operating margin.

Wages and premises overhead are charged throughout open time, including quiet
periods. Schedule staff off or close a venue
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
has positive operating margin after stock consumed, payroll and promotion costs.
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

Version-three saves retain queues, game fees, promotion timers and RNG state.
Saves from before the drink list carry their existing stock forward as house lager
and keep open orders' prices. Version-one/two migration retains money, properties, stages and hires;
older beer bars at stage 2+ receive their depicted pool table. New queues start
empty. Existing progress is not rolled back to enforce the new pacing curve.

Offline trading is an explicitly **estimated** projection, capped at eight hours.
Only open managed venues qualify. Expected sales are bounded by shared demand,
space, service and the available stock of each drink. Automatic deliveries cover
the house lager and drinks previously stocked. Wholesale and operating costs are deducted. Unviable trading
or insufficient working cash pauses the projection, without spending the opening
cash reserve. Temporary promotions, customer queues, local milestones, events and
calendar time do not advance. Reports in Journal list estimated customers served,
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
real action gates. Active styles must meet every target; mostly-idle must still
finish without becoming stuck.

| Milestone | Active target | Measured active range |
| --- | --- | --- |
| First useful purchase | 2–5 min | 2.2–4.1 min |
| Pool table | 10–20 min | 14.1–17.2 min |
| First stage 2 | 30–45 min | 36.2–39.3 min |
| Second property | 90–150 min | 119.0–124.1 min |
| First stage 3 | 180–300 min | 196.4–202.9 min |

Mostly-idle runs reach stage 3 in approximately 207–216 minutes, with a slower
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

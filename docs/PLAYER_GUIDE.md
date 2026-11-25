# Running your first bar

Start the game from the repository with `godot --path .`, or run a packaged
build. The main street is the live business. **Tutorial** is an optional practice
campaign using the original decision lessons; it does not spend your real till.

## Your first shift

1. Serve the three opening customers. A gold dot above a customer marks an order. Each successful
   click sells one drink and consumes one unit of stock.
2. When no orders are waiting, welcome passersby. Welcoming has a cooldown and a
   capped effect; it cannot create an unlimited crowd.
3. Open **Service**. Read demand, staff service, occupied seats and stock together.
   Manual serving helps when staff capacity is zero. “Forecast automatic net” is
   not a prediction that you will earn nothing while actively serving.
4. Restock before the fridge empties. Stock costs money when delivered, while
   wages and overhead accrue during open trading.
5. Buy the improvement that addresses your current limit. Keep money for the
   next shift rather than spending the till down to zero.

The first useful purchase depends on the bar: frontage helps quiet trade,
seating helps a full room, and a bartender helps unattended orders. More service
capacity cannot sell drinks to customers who are not there.

Customers appear inside the doorway, in front of the furniture and service
counters; bartenders work behind the counters. Smaller passersby stay in the
street opening and do not count toward occupancy. Pool players stay beside
their assigned table, with its paid/free timer on the table front.

## Read the bottleneck

| What you see | What to try |
| --- | --- |
| Few visitors and staff waiting | Welcome, improve frontage or try an appropriate promotion |
| Orders waiting with stock available | Serve manually, add a bartender or train existing bartenders |
| Full venue and rejected arrivals | Add seating, renovate when eligible, or stop advertising harder |
| Empty stock and lost orders | Buy stock; consider a bigger fridge and automatic deliveries |
| Sales but negative recent net | Check inventory purchases, wages and promotion costs in the shift report |
| Dancers but no automatic sales | Hire or reassign a bartender; dancers attract customers, not serve drinks |
| Plenty of money but a locked renovation | Build that venue's satisfied visits, regulars and healthy shifts |

Recent net records actual cash movements. A large stock delivery can make the
current report look worse even though some inventory will sell next shift.
Forecasts are estimates of automatic operation, not money already in the till.

## Pool and promotions

The first beer-bar pool table costs ฿2,000. Two customers pay **฿50 total** when a
45-second game starts. You do not click the table to collect another fee. Pool
players remain customers and can order drinks. A table uses space that could
otherwise seat visitors, and players stay longer.

Open **Events** for venue promotions:

| Promotion | What changes |
| --- | --- |
| Free Pool Night | New games are free; drinks keep ordinary prices; attracts pool visitors |
| Happy Hour | Newly placed drink orders are discounted by 20%; existing quotes are unchanged |
| Pool Tournament | Pool stays paid; the promotion includes a prize-budget cost |
| Sports Night | Requires a screen and attracts visitors for the fixture |

Only one promotion can run at a venue at once. It lasts two minutes, followed by
a two-minute cooldown. Repeating the same offer immediately after cooldown has
less pull; vary it or allow another ordinary shift. Paid games stay paid, and
free games stay free even when a promotion ends mid-game.

Free pool works best when you have spare room and can sell the visitors drinks.
It can underperform in a packed bar. Check actual receipts, foregone fees,
attributed drinks and costs in the promotion report. Its baseline visitor figure
is an estimate, not extra customers or income credited to you.

## Staff, management and growth

Bartenders serve waiting orders. Adult hosts and dancers attract the appropriate
audience. Use each team member's rota button to schedule them off; staff remain
hired. At Soi venues and gogos, role reassignment changes service and payroll.
Hosts' preferences still apply, and only an actual customer request can produce
a bar fine. An accepting host is unavailable for the remainder of the shift.

Automatic deliveries are a paid supplier agreement; delivered stock still costs
money. A manager needs stage 2, an on-duty bartender, deliveries and eight healthy
shifts, plus the hiring fee and operating reserve. Managers enable the offline
estimate. Check the current prices and requirements in **Service**.

Renovations require a local customer base and healthy shifts as well as cash.
The wealth of another property cannot satisfy those milestones. **Empire** shows
leases and their opening reserves. Finish the Blue Hour opening chapter before
buying a second venue. Soi venues require 20 reputation; gogos require 45.

The tested active-play curve reaches a first pool table around 17–20 minutes,
stage 2 around 40–44 minutes and a second property around two hours. These are
simulation results for a particular investment strategy, not timers or promises
for every play style. [Economy details](ECONOMY.md) include the full measurements.

## If money runs out

Use **Close venue** to pause its payroll and overhead. Off-duty staff do not
charge wages. If an operating charge becomes unaffordable, the venue closes
before adding new idle debt, while keeping its hires and upgrades.

At an empty till, a closed venue can take an **Owner-run recovery shift**. Anong
covers two minutes of overhead and the team is scheduled off. If the fridge is
empty, Bo provides six recovery drinks whose stock cost is taken only when a
customer buys one. Welcome and serve manually, then reopen with a sustainable
rota. Event closures must finish before recovery can begin.

## Away from the street

Open, viable managed venues can earn an estimated net amount for up to eight
hours away. The calculation includes limited demand and costs; an unviable
projection pauses instead of consuming your starting cash. It does not advance
promotions, disasters, local renovation milestones or calendar time. **Journal**
shows the estimate and limiting factors.

**Open managed shift** offers decisions across the same live two-minute shift.
The decision screens pause the model; continuing does not skip the clock or
create another stream of money. Exploring the district and Toybox sparring are
optional. The street continues after the festival.

## Saves and versions

Saves happen after decisions and every fifteen seconds, with a backup retained.
Old campaigns preserve owned progress when migrated, so an existing stage-3 bar
will not revert to stage 1 for the new balance. Use a fresh campaign if you want
to play the revised opening. **Restart campaign** erases that run; back up saves
first if you want to keep it. [Developer setup](../DEVELOPMENT.md) lists save paths.

The source branch and a published release may be different builds. Use the
checkout containing the changes you want to play, and avoid running two versions
against the same campaign at once.

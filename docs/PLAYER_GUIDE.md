# Running your first bar

Start the game from the repository with `godot --path .`, or run a packaged
build. On the startup menu, choose **New Game** to open your first bar or
**Resume** to continue your saved campaign. Starting another new game asks you
to confirm erasing the previous campaign, including its backup; **Cancel** keeps
it. Resume is disabled when no readable save is available.

The main street is the live business. **Tutorial** is an optional practice
campaign using the original decision lessons; it does not spend your real till.

## Your first shift

1. Serve the three opening customers. A gold dot above a customer marks an order. Each successful
   click sells one drink and consumes one unit of stock, then refills for ten seconds.
   No order or unavailable stock means no spent cooldown.
2. When no orders are waiting, welcome passersby. Welcoming has a cooldown and a
   capped effect; it cannot create an unlimited crowd.
3. Open **Service**. Read demand, staff service, occupied seats and stock together.
   Manual serving helps when staff capacity is zero. “Forecast automatic net” is
   not a prediction that you will earn nothing while actively serving.
4. Restock before the fridge empties. Stock costs money when delivered, while
   wages and overhead accrue during open trading.
5. Buy the improvement that addresses your current limit. Keep money for the
   next shift rather than spending the till down to zero.

Wall fans appear after buying **Fans & comfortable seats**. They remain installed
when the venue closes, but stop spinning. Renovating does not buy this equipment.

The first useful purchase depends on the bar: frontage helps quiet trade,
seating helps a full room, and a bartender helps unattended orders. More service
capacity cannot sell drinks to customers who are not there.

## Give yourself a faster shift

The Serve and Welcome buttons fill back up as foreground time passes. The label
shows seconds remaining, Ready, or why the action is unavailable. Each venue has
its own timers. Bartenders keep serving while your own Serve button refills.

Near the top of **Service**, **Faster pouring** and **Better welcoming** each have
three purchases: **10 → 8 → 6 → 4 seconds**, costing **฿900 / ฿1,400 / ฿2,800**.
The menu shows cash still needed, including the next shift’s operating reserve.
Buying a level changes the next use; it does not clear an active refill. Existing
Service training improves bartenders separately.

**Have a chat** helps the eligible guest nearest walking out, when they have ten
seconds or less left to wait. It adds ten seconds of patience and visit time,
once per visit. You still need to fulfil their orders to earn satisfaction.
Chat and Welcome share a timer: welcoming uses its current cooldown; chatting
locks both for twenty seconds, even with upgraded welcoming. Serve stays separate.
This creates a choice between attracting newcomers and looking after a queue.

An active opening can buy pouring speed, frontage, seating and pool before hiring,
while restocking by hand. Delaying automatic deliveries and a larger fridge until
stage 2 leaves money for the renovation. A signage-and-staff opening also works;
neither manual upgrades nor Chat is required to finish. Avoid buying every speed
level when stock, seats or customers are your actual limit.

Closing a venue does not reset timers. Normal prep time refills them; skipping to
noon, paused decisions, startup menus and offline time do not. Reloading preserves
the remaining refill and which visitors have already had a chat.

## The clock and tomorrow's opening

**TIME** advances one game minute per real second. Every venue type opens at
12pm and normally shuts at 1am. Dates change at midnight; two-minute business
reports and the 45-second pool timer still use real seconds. Financial rates
are shown per real minute.

Check the peak indicator in Service when planning staffing and stock:

| Venue | Peak hours |
| --- | --- |
| Beer bar | 5–9pm |
| Soi venue | 7–11pm |
| Gogo | 10pm–2am |

Peaks add 50% attraction, increasing your share of the existing street traffic.
They do not guarantee sales or extra service capacity. Each drink sold during a
peak adds two dirt points instead of one, so a busy night needs more cleanup.
Gogos still need permission to operate during their peak hour after 1am.

Before 1am, use **Stay open until 3am tonight** in Service for any venue you want
to keep trading. A warning appears at 12:30am. You can cancel the extension or
close early. No venue trades after 3am, and the choice resets at noon.

Each late venue adds one heat point per ten minutes of actual late operation.
Every fifteen late minutes it risks a raid: 2% plus 0.2 percentage points per
heat point, up to 22%. The fine is ฿300 per venue stage, capped at the cash you
have, and that venue shuts until noon. Fines appear in its report and the weekly
books. Heat cools by one point per two safe real minutes; skipping does not cool
it. Reopening buttons cannot override a raid.

When closed, Service shows **Prep for opening**. Start a fifteen-second clean,
buy stock, and check the rota. Managers start cleaning automatically. Each drink
sold adds dirt; a completely dirty bar loses 25% of its attraction. Cleaning
costs no cash. Stock still costs ฿14 per drink, subject to fridge capacity.

After 1am, when all venues have stopped trading, **Skip to 12pm** is available.
The list shows unfinished prep across the street. You can skip anyway: incomplete
cleaning is cancelled, dirt stays, and no stock is purchased. Waiting naturally
until noon also cancels incomplete cleaning. Skipping does not run events,
complete jobs, award sales or grant healthy-shift progress.

Scheduled closure pauses sales and operating costs. Noon makes venues available
again, but preserves owner closures and cash-shortage shutdowns. Use **Enable
opening** when ready, or the existing owner-run recovery option after a raid
has ended. Street-event countdowns pause while all venues are shut; temporary
closure and cleaning timers still run during foreground prep time.

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

Only one promotion can run at a venue at once. It lasts two real minutes, followed by
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

The tested active-play curve reaches a first pool table around 16–19 minutes,
stage 2 around 39–42 minutes and a second property around 138–147 minutes. These are
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

Enabled, viable managed venues can earn an estimated net amount for up to eight
real hours away. Only projected noon–1am windows count, at the game's clock
speed; late permissions do not extend offline hours. The calculation includes
limited demand, stock, saved dirt, each venue's peak windows and costs. An unviable projection pauses instead
of consuming your starting cash. It does not advance the visible clock, cleaning,
heat, raids, promotions, disasters or local milestones. **Journal** distinguishes
time away from eligible trading time and reports the estimate and limiting factors.

**Open managed shift** offers decisions across the same live two-minute shift.
The decision screens pause the model; continuing does not skip the clock or
create another stream of money. Exploring the district and Toybox sparring are
optional. The street continues after the festival.

## Saves and versions

There is one local campaign slot. New Game saves immediately; later saves happen
after decisions, every fifteen seconds, and on normal close or application pause,
with a backup retained. Waiting on the startup menu does not run the business,
write saves or claim offline estimates. Resume claims eligible time away once.
Save schema 5 preserves action upgrades, fractional cooldowns and customer chat
allowances. Existing venues begin with unpurchased action upgrades. Migration from
pre-clock saves introduces noon on the campaign’s existing day,
with initially clean venues. Old campaigns preserve owned progress when migrated, so an existing stage-3 bar
will not revert to stage 1 for the new balance. Use a fresh campaign if you want
to play the revised opening. **New Game** and **Restart campaign** replace that
run and remove its old backup after confirmation; back up saves
first if you want to keep it. [Developer setup](../DEVELOPMENT.md) lists save paths.

The source branch and a published release may be different builds. Use the
checkout containing the changes you want to play, and avoid running two versions
against the same campaign at once.

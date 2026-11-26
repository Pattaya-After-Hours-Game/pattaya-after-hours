# Stage-two income bridge

The day-eight report showed a stage-two Blue Hour with ฿2,611, ample stock,
maximum reputation and no waiting orders. Faster pouring alone would not solve
that quiet queue. The next visible targets, ฿12,000 management and ฿40,000
renovation, left too few affordable ways to improve trading.

## Implemented choices

| Investment | Incremental price | Requirement | Effect |
| --- | ---: | --- | --- |
| Regulars Club 1 | ฿600 | Stage 2, 10 local regulars | 35% of new visitors join |
| Regulars Club 2 | ฿1,200 | Stage 2, 20 local regulars | 65% join |
| Regulars Club 3 | ฿2,400 | Stage 2, 35 local regulars | 100% join |
| Better sound | ฿2,400 | Stage 2, original ฿1,200 music installed | Repeat orders 25→18 seconds |
| Advanced bartender training | ฿1,200 then ฿1,600 per person | Stage 2, previous 20/15-second training | Service 15→12→10 seconds |
| First manager | ฿8,000, reduced from ฿12,000 | Existing stage, staff, delivery and healthy-shift gates | Existing separate ฿10 per open second |

Club membership lasts for the current visit: twenty extra seconds, one additional
house-price allowance in the guest's finite budget, and permission for a third
round. Invitations use a stable customer-ID roll without changing traffic RNG.
It does not increase arrivals, serve a drink, charge a fee, discount orders or
promise that every member will finish three drinks. Joining is decided on arrival;
upgrading the club leaves existing visits and quoted orders intact. Local regular
thresholds apply separately at each property. Purchase keeps a full delivery and
two minutes of operating costs in the till.

Longer visits occupy seats, so a full room can lose turnover. Music changes the
next repeat after a sale, leaving already-running timers intact. Training changes
future recovery after a sale; it does not reset the current staff deadline.
All extra drinks still require budget, stock, patience and service. Birthday and
club cap at three combined; party repeat intervals are 26/19/14 seconds at music
levels 0/1/2. Pool, tips and commission keep their existing identities and rules.
Manager income stays separate, with no refund for an appointment already bought.

## Balance and limits

Ten matched 600-second day-eight scenarios per club level use two 15-second
bartenders, four-second owner relief, music level one, supplier four and two pool
tables. Aggregate contribution, including stock consumed and operating costs,
is ฿38,486 / ฿45,694 / ฿49,192 / ฿51,912 at levels 0/1/2/3. Investment prices
are excluded from that ongoing-trade comparison. Top-tier contribution rises
about 35%, or ฿2.24 per real second, with 1,169 real sales versus 882.

Under those particular conditions, the first ฿600 tier pays back in about eight
open minutes; all three club investments together take about 31 minutes. The
incremental benefit diminishes at higher tiers. These are scenario estimates,
not a guaranteed reward rate. Birthday, crowds, stock, staffing and the mix of
drinks change the result.

On the already well-served level-three club, better sound alone only changes
aggregate contribution to ฿52,248; advanced training alone reaches ฿54,236, and
both reach ฿53,918. Event/arrival timing and finite seats mean benefits are not
simply additive. Buy the club first for more rounds; buy sound/training when
repeat timing or queues leave rounds unfinished. Neither creates unlimited
orders. Ten slow-service controls remain capped by a single base bartender.

Fresh-campaign acceptance deliberately brings the second property to 75–115
minutes and stage three to 110–210 for baseline active policies; stage two stays
30–45. First-manager saving gaps cap at twenty minutes, and longest investment
gaps at 38. These are simulation checks, not timers imposed on the player.
Baseline, club-first and full stage-two-bundle routes are recorded in
[testing](../TESTING.md). Full-festival pacing and human retention remain unverified.

## Compatibility and presentation

Schema 12 adds venue club level and per-visit membership. Existing saves start
with no purchased club and no membership on current guests. Cash, paid stock,
owned venues, music, training, contracts, quotes and cooldowns remain intact.
Offline estimates include club demand and longer occupancy, still capped by
shared traffic, service, stock, costs and the eight-hour limit. They never replay
parties or earn live visit tips. Claims remain repeat-safe.

The Upgrades drawer shows prices, local gates, changed service/repeat intervals
and a labelled estimate of automatic net change for club purchases. Service
retains club status after the last tier. Existing artwork remains in place.

# Profit cycle: build the next bottleneck

Implemented source direction, 26 November 2026. This is one feature, integrated
with the preserved Gabby addition. Release readiness is recorded in
[testing](../TESTING.md) and the [handoff](../MERGE_HANDOFF.md).

## Intended play

Seats → service → appeal → seats. Each purchase should improve one constraint
and reveal the next. Empty seats need visitors; waiting orders need service;
a room of guests drinking their final round may benefit from music and turnover.
Stock remains a separate constraint throughout. A new stage opens several smaller
investments rather than granting a blanket income or drink-price multiplier.

## Visits have a purpose and an end

A new visitor plans one or two ordinary rounds. The one-round probability is
20% for locals, 40% for tourists and 10% for nightlife guests. The three opening
visitors retain a forgiving two-round plan. Starting spending budget is the
venue's house price × planned rounds + ฿100; actual product quotes and remaining
budget still decide what can be bought. Club invitation shares remain 35/65/100%.
Membership or a birthday invitation adds one planned round and its house-price
budget allowance, never both: maximum three rounds.

Every served drink takes the current music interval to finish, including the
last drink. Only then does the visitor order an affordable next planned round,
or finish the visit. Finished visitors leave, except that an active pool game
can finish or an existing bounded pool wait can expire. Pool still charges ฿50
once per table and lasts 30 seconds. No new universal 90-second stay applies.
Order patience, stockouts, budgets and closures remain real limits.

Completing a satisfied one-round visit counts as a happy visit and can create a
regular. A missed order does not. Nightly base tips still count once on the first
real drink; Gabby's and matched-drink bonuses retain their existing rules.
Comfort improves patience; it does not add an invisible fixed-length stay.

## Beer-bar investment tracks

The stage columns are cumulative purchase caps, not free upgrades. Existing paid
ownership remains. Costs below are incremental cost for tier N.

| Track | Stage 1 | Stage 2 | Stage 3 | Price and benefit |
| --- | ---: | ---: | ---: | --- |
| Seating | 3 | 5 | 7 | ฿400 × N; +2 seats per tier |
| Frontage | 1 | 3 | 5 | ฿900 × N; +2 appeal per tier |
| Fridge | 2 | 3 | 4 | ฿800 × N; +40 stock and colder-beer reputation |
| Music | 1 | 2 | 4 | ฿1,200 × N; drinking 35→25→18→14→11s |
| Bartender training | 2 | 4 | 6 | ฿400 × N per person; service 25→20→15→12→10→8→6s |

Compact layout applies from seating tier three onward, recovering up to three
furniture places. Stage one holds twelve with one pool table and fans. Stage
three holds 34 without furniture, or 32 with the two-table maximum and fans. Other venue types keep their existing equipment/training limits.
The next locked tier remains visible with its required stage. Current drink and
staff timers finish normally after upgrades. Training survives rehire.

The shared street's base traffic is **7.3 + 2 × max(0, highest owned beer-bar
frontage − 1)** visitors/minute. Mixed audiences, weather and events still modify
it. Multiple venues compete for this one bounded pool; copying a sign does not
copy a customer stream. Existing prices, stock costs, contracts, manager income,
renovation prices and local milestone gates are otherwise retained.

## Readable feedback and saves

Service's **Your profit cycle** report reads the last completed shift (current
shift until one exists). It separates customer trading contribution from manager
income, shows its sample duration, arrivals, orders, sales and happy completed
visits, and identifies stock, service, seating, demand or drinking turnover.
Customer contribution uses consumed inventory at its paid cost, not today's
whole stock deliveries; it excludes tips, manager income and capital purchases.
The till's five-second cashflow sample remains unchanged and can differ.

Optional visit details show each real guest's planned round and current wait,
drinking timer or finishing-pool state. Yellow/red waiting dots remain; a small
cyan glass identifies drinking. Advice and views do not purchase or simulate.

Schema 13 saves plans, phases and completion counters. Older current visitors
finish under their saved legacy lifetime, quote, budget and repeat timer; they
are not randomly replanned or given membership. Existing purchases, staff and
paid inventory survive. No retroactive happy visits or cash are awarded.
Offline estimates use audience-weighted rounds and drinking/serving duration,
remain demand/space/service/stock/cost limited and report estimated visitors.
They retain the eight-hour cap, protected opening reserve and repeat safety;
they do not advance live visits, birthday rewards or progression milestones.

## Verification method

Matched 600-second scenarios compare baseline, the relevant upgrade and an
unrelated upgrade over ten seeds per bottleneck. Operating contribution excludes
purchase prices and values remaining paid stock consistently. Fresh campaigns
exercise click-heavy, balanced and mostly-idle play without grants or forced
purchase timers. The profit-cycle policy buys affordable positive forecast
contribution, choosing estimated return per baht among frontage, seating, music,
training and club. The original baseline policies remain separate checks.

Cadence counts actual flagship investments while at stage two, excluding ordinary
stock deliveries, renewals and purchases for another property. Report the median
and every gap, including long manager-saving gaps; do not hide those in an
average. Milestone and cadence bounds require explicit user approval to change.
The user confirmed keeping prices and accepting stage two from 28 minutes and
a 2.5–5-minute median cadence. Other milestone and saving-gap bounds remain
unchanged. See the current verification record for measured results.

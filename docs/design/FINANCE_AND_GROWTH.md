# One shared account and customer-driven growth

Approved revision, 27 November 2026. The user rejected separate tills, transfers
and protected purchase reserves as confusing. This supersedes the earlier
separate-finance plan. Retain loyalty, bounded shared traffic and management
bonuses earned through customer trade.

## Money in, money out

`s.cash` is the only spendable balance for the whole street. Every venue's
receipts, tips, stock, staff, upgrades and fines use it, as do leases, tours,
street marketing and events. Venue reports still explain which bar earned or
spent money. They are not separate accounts. There are no deposits, withdrawals,
Fund & buy controls, working floats or protected stock/payroll budgets.

Every purchase requires exactly its advertised price. Physical stage, staff,
space, consent and local-regular requirements remain. Atomic purchases recheck
eligibility and the quoted price; stale input cannot buy an extra tier. Leases
keep their prices and rotating discounts, with no extra opening-cash requirement.
A purchase may leave zero cash. Opening still needs enough to pay the next actual
running-cost charge; this is a bill, not cash reserved against a later purchase.

Tap **MONEY** for **Money & costs**. It shows the shared balance, each venue's
named running costs, and up to sixty recent money movements (the latest twelve
are displayed). Adjacent movements with the same reason/venue/day combine.
Saved entries start when this update is used; migration does not invent history.

## Named costs, never unexplained drain

Existing prices and total ongoing rates are retained, with the premises charge
explained as rent and electricity. Rates are baht per real minute of trading:

| Cost | Beer bar | Hostess bar | Gogo |
| --- | ---: | ---: | ---: |
| Rent | 12 | 30 | 60 |
| Base electricity | 6 | 15 | 30 |
| Each comfort tier's electricity | 4 | 4 | 4 |
| Manager wages, if appointed | 12 | 12 | 12 |

On-duty contracted bartenders/hosts/dancers cost ฿24/20/36 per real minute.
Nida has no ongoing wage or commission. Bills accrue gradually with the existing
fractional carry and rounding, including quiet trading. The transaction entry
names the billed rates; stock packs, contract fees, training, promotions,
renovations, leases, tour pay and event fines have their own reasons.

Closed venues pause these running costs. Off-duty staff earn no wage. Contract
terms still age with the clock. A venue unable to pay an actual bill closes
without creating negative cash or automatic debt. Offline estimates remain
separate, demand/cost limited and repeat-safe; they never drain opening money.

## Close, count tips, restock

**Close & count tips** is available in Hours and Money & costs, and next to an
empty, unaffordable fridge. It closes the selected venue and credits only its
existing earned jar: ฿10 per actually served visit plus saved matched-drink and
Gabby bonuses. It works after an automatic cash-shortage closure too. Closing
clears the jar, retains the paid report and saves through the usual action path.
Reopening, repeated input, nightly settlement and reload cannot pay it twice.
Other venues keep trading and keep their own uncounted jars.

Stock can be bought while closed. If tips cover a full pack, buy it and enable
opening. Tips are not a guaranteed bailout: a small jar can be insufficient.
Bo's existing six-drink consignment recovery remains available, with its usual
฿14-per-sale repayment and no fake customers or cash grants. An unpaid operating
charge is retained but collection pauses during recovery cover, preventing an
immediate zero-cash reclosure. It becomes payable when cover ends. Nightly automatic
counting still settles uncounted jars. Tips remain outside sales, management
bonuses, healthy-shift margins and the five-second trading sample.

## Renovation and loyalty

Renovations retain their prices, including final beer/hostess/gogo stages at
฿40,000/65,000/120,000. Only the listed cash price gates construction.
A new bar may renovate immediately, but still needs customers.

| Local loyalty rank | Happy visits | Regulars | Healthy shifts | Total appeal bonus |
| --- | ---: | ---: | ---: | ---: |
| Known locally | 70 | 10 | 8 | 5% |
| Neighbourhood favourite | 450 | 70 | 40 | 10% |

These bonuses replace rather than stack. The existing healthy-shift calculation
still excludes manager receipts and tips. Regulars Club keeps its own local
regular requirements. Hostess and gogo frontage now follows cumulative stage
caps 1/3/5, costs ฿900 × new tier and adds +2 appeal per tier.

## Grow the street

Street marketing requires one stage-two venue and uses the shared account.
Each additional open property beyond inherited slot zero also adds two potential
visitors/minute (up to seven properties). Existing best beer-sign and venue-type
diversity effects remain. Events still adjust the bounded shared traffic pool.

| Tier | Incremental cost | Additional potential visitors/minute |
| --- | ---: | ---: |
| 1 | ฿2,000 | 2 |
| 2 | ฿4,000 | 3 |
| 3 | ฿8,000 | 4 |
| 4 | ฿16,000 | 6 |
| 5 | ฿30,000 | 8 |
| 6 | ฿50,000 | 10 |
| 7 | ฿80,000 | 12 |
| 8 | ฿120,000 | 15 |
| 9 | ฿180,000 | 20 |
| 10 | ฿260,000 | 25 |
| Total | ฿750,000 | 105 |

Potential visitors are shared between venues and passersby who do not enter.
Marketing previews label demand and net estimates; customers still need space,
orders, budget, stock and service. This preserves seats → service → appeal → seats.

## Management earns its money

Levels cost ฿2,000 / ฿6,000 / ฿18,000 and pay 25% / 50% / 75% of eligible
margin, using the current level rather than stacking percentages. Stage gates
are 2/3/3. An on-duty bartender and deliveries remain required;
the eight-healthy-shift gate is removed. Manager wages remain ฿12/minute while trading.

Eligible margin is actual drink receipt minus FIFO consumed stock cost and any
consignment repayment, floored at zero per sale. Hosted drinks qualify. Paid
pool fees qualify with zero stock cost. Free games, bar fines, nightly tips,
stock returns and event rewards do not qualify. A sale settles the
bonus once, with integer hundredths retained as `manager_bonus_carry`.
For example, an ฿80 beer using ฿38 paid stock earns a ฿31.50 bonus at level 3;
the first sale pays ฿31 and carries 50 hundredths into the next qualifying sale.

The bonus enters local trading cashflow but has its own ledger field, separate
from drink and pool receipts and healthy-service margins. Empty rooms generate
no timer income. Offline projections use eligible estimated margins after demand,
service and stock limits, cap at eight hours, protect the opening shared balance and
credit the shared account. An empty fridge cannot bootstrap offline income.

## Saves and verification

Schema 17 adds every schema-16 venue till to the existing bank and legacy reserve,
then removes venue cash fields and clears reserve. Earlier saves retain their
shared cash plus reserve directly. Migration preserves the exact total, including
one-baht campaigns, and never reallocates or refunds owned assets. Repeated loads
cannot add money again. Fresh campaigns have ฿228 shared money and twelve drinks.
Paid stock costs, quotes, visit plans, deadlines, contracts and artwork remain.

The HUD's five-second figure now covers actual street trading from all venues.
Individual business reports retain local attribution. Investments, tips and
offline claims remain excluded from the trading sample. Navigation is read-only.

Regression tests cover exact-price purchases, early tip recovery and reload,
account conservation, journal reconciliation, ordinary/offline settlement and
UI. Fresh pacing policies use the same real closing-tip action if a venue runs
out of stock or shuts for cash, then use existing consignment if tips are too
small and restore the rota after recovery; no cash is injected. Milestone windows, saving-gap ceilings and prices are unchanged. The investment
cadence floor is 2m20s instead of 2m30s for this no-reserve revision; the measured
minimum is 2m26s. The user explicitly accepted the faster pace while keeping
prices unchanged. This accepts quicker purchasing without slowing the model.
See [verification](../TESTING.md) for results and limits.

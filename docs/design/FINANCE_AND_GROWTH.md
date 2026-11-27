# Separate tills and customer-driven growth

Approved implementation direction, 27 November 2026. This replaces shared
street cash, renovation customer gates and fixed manager income. Other prices,
service clocks, finite visits and stock rules remain in force.

## Accounts

| Transaction | Account | Counts as trading? |
| --- | --- | --- |
| Drinks, hosted rounds, paid pool, bar fines, manager bonuses | Venue till | Yes |
| Operating costs, wages, stock, local raid fines | Venue till | Yes |
| Staff contracts, equipment, training, renovation | Venue till | No |
| Nightly tips | Venue till | No |
| Offline estimate | Venue till | No live sample |
| Leases, street marketing, upfront tour guide pay, district preparation/rewards, unattributed legacy actions | Company bank | No local sample |
| Explicit deposits and withdrawals | Transfer between bank and one till | No |

`bar.cash` is local money; `s.cash` is company money. A closed or insolvent venue
cannot borrow automatically. Cash & Bank offers presets, custom amounts and
Deposit surplus. Recommended working cash is two ordinary stock packs plus two
minutes of scheduled operating costs. A transfer must be positive and fully
covered by its source. Switching views never moves money.

Fund & buy revalidates the upgrade, transfers only the shortfall for price plus
its existing required reserve, and purchases. A stale displayed price cannot buy
the next tier. Physical stage, staff and Regulars Club requirements still apply.

The lease quote includes the lease itself and a startup float: ฿1,200 bartender
contract + ฿228 stock pack + two minutes of new overhead and one bartender's
฿24/minute wage. The lease is spent; the float moves to the new till. Other
venues' payroll does not inflate that property’s opening requirement.

## Renovation and loyalty

Renovations retain their prices, including final beer/hostess/gogo stages at
฿40,000/65,000/120,000. Only cash plus operating reserve gates construction.
A newly funded bar may renovate immediately, but still needs customers.

| Local loyalty rank | Happy visits | Regulars | Healthy shifts | Total appeal bonus |
| --- | ---: | ---: | ---: | ---: |
| Known locally | 70 | 10 | 8 | 5% |
| Neighbourhood favourite | 450 | 70 | 40 | 10% |

These bonuses replace rather than stack. The existing healthy-shift calculation
still excludes manager receipts and tips. Regulars Club keeps its own local
regular requirements. Hostess and gogo frontage now follows cumulative stage
caps 1/3/5, costs ฿900 × new tier and adds +2 appeal per tier.

## Grow the street

Street marketing requires one stage-two venue and uses company-bank cash.
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
are 2/3/3. An on-duty bartender, deliveries and purchase reserve remain required;
the eight-healthy-shift gate is removed. Overhead remains ฿12/minute.

Eligible margin is actual drink receipt minus FIFO consumed stock cost and any
consignment repayment, floored at zero per sale. Hosted drinks qualify. Paid
pool fees qualify with zero stock cost. Free games, bar fines, nightly tips,
transfers, stock returns and event rewards do not qualify. A sale settles the
bonus once, with integer hundredths retained as `manager_bonus_carry`.
For example, an ฿80 beer using ฿38 paid stock earns a ฿31.50 bonus at level 3;
the first sale pays ฿31 and carries 50 hundredths into the next qualifying sale.

The bonus enters local trading cashflow but has its own ledger field, separate
from drink and pool receipts and healthy-service margins. Empty rooms generate
no timer income. Offline projections use eligible estimated margins after demand,
service and stock limits, cap at eight hours, protect each starting till and
credit that venue only. An empty fridge cannot bootstrap offline income.

## Saves and verification

Schema 16 conserves pre-update `cash + reserve` exactly. It allocates each
venue's recommended working cash and puts the surplus in the company bank. If
money is insufficient, proportional integer shares and stable remainder order
allocate the available total. No venue, staff member, training, manager level,
paid inventory cost, customer plan or money is removed or refunded. Existing
schema-16 saves retain their chosen distribution. Fresh cash is ฿228 in Blue Hour
and zero in the bank. Practice remains isolated.

The till's five-second sample is local. Transfers, investments, tips and offline
claims do not enter it. All reports distinguish actual transactions from estimates.

Regression checks cover account conservation, shortage rejection, repeat-safe
migration, funded purchases, local closure, bonus carry and real-sale settlement.
Fresh pacing policies explicitly bank expansion money and invest in the current
bottleneck. Existing acceptance windows remain unchanged. Device playtesting is
still required to judge the feel beyond automated simulations.

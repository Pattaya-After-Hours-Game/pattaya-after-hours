# Agent guide — Pattaya After Hours

## Product goal

Build a cheeky, adult nightlife idle/incremental business game set on a fictional
Pattaya street. The player and co-owner Anong rescue the Blue Hour, earn a loyal
customer base, automate a viable bar, and eventually operate a mixed street of
beer bars, hostess bars and gogos. Everyday business comedy grows into
cartoon chaos, including Godzilla. The street continues after its first festival.

The central loop is:

**Attract customers → give them a reason to stay → fulfil their orders → earn a
profit → reinvest.**

The guiding design test is: **an empty bar needs customers, a busy bar needs
service, and a successful bar earns the right to expand.** New features should
make that loop clearer, more satisfying or more interesting.

## Read before changing the game

1. [README.md](README.md) — current overview, controls and documentation map.
2. [story.md](story.md) — premise, cast, tone, chapter arc and future story hooks.
3. [docs/ECONOMY.md](docs/ECONOMY.md) — model rules, progression and balance targets.
4. [DEVELOPMENT.md](DEVELOPMENT.md) and [docs/TESTING.md](docs/TESTING.md) — setup,
   code ownership, save handling and verification.

Use [docs/PLAYER_GUIDE.md](docs/PLAYER_GUIDE.md) when changing player-facing flows,
[art/README.md](art/README.md) for assets, and
[docs/MERGE_HANDOFF.md](docs/MERGE_HANDOFF.md) when reconciling branches.
Story hooks are not promises of implemented features. Check code and tests before
claiming behaviour exists; update the relevant documentation when it changes.

## Design commitments

- Demand, space, service and supply are separate limits. A drink sale needs a
  real order, stock and service. Clicking or hiring must not manufacture buyers.
  Venues compete for bounded shared street traffic. House beers cost ฿80/100/120
  in beer/Soi/gogo venues. House lager stock costs ฿38/38/36/34/32/30 at supplier
  levels 0–5; premium orders and promotions retain their separate rules. Fresh
  campaigns start with ฿228 and twelve drinks. Preserve saved quotes, budgets
  and paid inventory costs; never revalue an existing fridge or grant cash on update.
- The repeating profit cycle is seats → service → appeal → seats. New visitors
  plan one/two rounds, with one-round chances 20/40/10% by local/tourist/nightlife
  audience; opening guests plan two. Budget is house price × rounds + ฿100.
  Club OR birthday adds one round, max three. Drink the last round before leaving;
  active pool games/bounded pool queues can retain the guest. Satisfied one-round
  visits count happy. Never replace an existing saved visit with a new random plan.
  Beer-bar cumulative caps by stage are seating 3/5/7, sign 1/3/5, fridge 2/3/4,
  music 1/2/4 and staff training 2/4/6. Costs per tier N are 400N/900N/800N/1200N/400N.
  Compact-layout recovery applies at seating >=3. Hostess/gogo frontage also uses the 1/3/5 tier caps, ฿900 per tier number and +2 appeal; other venue tracks stay unchanged.
  Base traffic is 7.3 + 2 × max(0, highest owned beer sign − 1), one shared pool.
  Advice and visit details are read-only. Customer contribution uses consumed paid
  stock and excludes manager income, tips and investments; keep the till cashflow
  sample unchanged. See [profit-cycle rules](docs/design/PROFIT_CYCLE.md).
- Venue type 1 is labelled Hostess bar; numeric identity and production art stay
  unchanged. Lease bases are ฿12,000/24,000/60,000. Each earlier same-type purchase
  adds 25% of base, excluding the inherited slot-zero beer bar. Never refund old
  purchases. Every fourteenth day has a visible 10% offer, rotating hostess/beer/
  gogo. `street.lease_quote()` owns price, retained opening cash, affordability and
  cost estimates. Leases spend company-bank cash and transfer the quoted startup float into the new venue.
  Keep renovation prices and physical stage gates; customer milestones now earn loyalty.
- Pool costs **฿50 per game per table**, charged once at game start; new games last 30 seconds.
  Preserve saved remaining time for games already underway, including older 45-second games. Free Pool
  Night trades fees for attraction. Timers, capacity, customer budgets and
  promotion cooldowns still apply. Reloading must not duplicate rewards.
- Keep all three venue types useful, with three stages each. Renovation earns
  space and options; it does not automatically raise every drink's price.
  Local satisfaction, regulars and healthy operation earn loyalty appeal; cash funds renovation.
  Keep selected-venue renovation progress visible above Upgrades, including Ready
  only; show live locked reasons and keep navigation/readouts free of mutations.
  Loyalty ranks require 70/10/8 and 450/70/40 happy visits/regulars/healthy shifts,
  for +5% and +10% total appeal. These never block renovation;
  final renovations cost ฿40,000/65,000/120,000 by venue type.
- Bartenders serve; hosts and dancers attract; managers enable offline operation.
  Bartender contracts cost ฿1,200; host/dancer contracts cost ฿4,500 for ten game days, including closed/skipped/offline
  time. Switching a bartender to a specialist role charges the positive contract
  price difference prorated to the remaining term, with a shift reserve; no refund
  for switching back. Training belongs to the person and survives expiry/rehire. Base bartender
  service starts ready: sell one real order, then recover for 25 seconds, improving
  to 20/15 through training costing ฿400/800; stage two adds 12/10 seconds
  for ฿1,200/1,600 per person. Beer-bar stage three adds 8/6 seconds for
  ฿2,000/2,400. Keep the saved deadline through queue changes, owner
  clicks, rota/role changes and reloads. Staff precede purchased owner auto-serve. Owner automation is relief: serve
  when pending orders exceed available bartenders, or a guest has at most ten
  seconds left and no bartender can recover before their deadline. No eligible
  bartender means normal owner automation. Manual taps retain their own choice.
  Schema 9 preserves fractional staff deadlines and actual-sale counters; the
  bottom-right indicator and serving poses must reflect those sales, not decorative
  timer loops or offline estimates.
  Quiet trading still has costs. Preserve rotas, temporary closure and recovery
  instead of forcing idle-mode debt or an unrecoverable failure.
- Nida uses one separate frontage slot: ฿1,200/ten days, no drink commission,
  no hourly wage and no serving. Cancel old unpaid visit/order commitments and
  fractional carry; retain historical payments/reports without refunds. Live,
  premium, discounted and offline sales must all remain commission-free.
  Welcome and promoter attraction never stack. Faster Welcome only helps while
  the promoter is off duty/expired; it does not speed Chat or boost her appeal. Audience training is stage-gated,
  separate from service training, and persists after rehire. Keep renewal visible
  in the frontage section, with exact payroll/stock reserve and shortfall. Expiry
  must refresh controls independently of history text; never duplicate her slot.
- Buy stock in complete packs requiring cash and room: six for ฿228 at supplier
  levels 0/1, twelve for ฿432/408/384/360 at levels 2/3/4/5. Supplier upgrades
  cost ฿900/1,200/2,400/4,800/9,600. Preserve inventory purchase costs; discounts never refund old stock. Supplier
  automation retains its next operating charge. Bo’s consignment remains the
  recovery exception. Each fridge tier earns +1 extra reputation per ten happy
  departures, capped at 100, with no purchase/reload reward. Third beer-bar seating must hold twelve with pool and fans.
  The schema-7 migration preserves paid manager/supplier appointments as level 1 and grants no
  free music/auto-serve or higher levels. Manager levels cost ฿2,000/6,000/18,000
  and add 25/50/75% of earned drink and paid-pool gross margin. Use actual price
  less FIFO paid stock and consignment repayments, preserving fractional bonus carry.
  Includes hosted drinks; excludes bar fines, tips, transfers, returns and event rewards.
  No independent timer income. Keep bonuses separate from healthy-service progress.
  Stage gates remain 2/3/3, with a bartender, deliveries and reserve; no healthy-shift gate.
- Music costs ฿1,200 for 35→25-second repeats; stage-two better sound costs
  ฿2,400 and reaches 18 seconds (party 14). Beer-bar stage three adds ฿3,600/4,800
  tiers for 14/11 seconds (party 11/8). Preserve existing drinking deadlines,
  including the final round.
  Regulars Club has stage-two tiers ฿600/1,200/2,400, requiring 10/20/35 local
  regulars plus a stock-pack/operating reserve. New visitors join at 35/65/100%,
  adding one planned round and its house-price budget allowance, capped at three.
  Birthday and club never stack past three. Schema 13 saves visit plans/phases; pre-13 guests retain their legacy visit rules;
  old guests receive no extra round and old managers receive no refund. All
  sales still need orders, budgets, stock and service; membership persists per visit.
  Music preserves budgets and visit limits. Auto-serve costs ฿3,000 per venue and uses the SAME
  Serve deadline as manual clicks. Never award extra service for toggles/reloads.
  Till ฿/s is a five-second sample of actual net trading, excluding investments
  and offline claims; no simulation or accounting belongs in the HUD.
- Day seven's Blue Hour opening hosts Anong's Birthday, noon to normal 1am close.
  Later seventh-day openings rotate reunions, mixtape and thank-you nights. Keep
  the countdown/warning, free entry, finite shared traffic, real orders/budgets,
  normal prices and actual report. Only the flagship gets the party extra planned round (max three) and
  faster party repeat timing; closed venues gain no party attraction. Never replay
  party income offline or advance a party on the menu. Schema 8 preserves its
  ledger/date and guest patience, with no retroactive migration reward.
  Reputation boosts attraction only; it does not speed drinking. Music still
  improves party repeat timing. Birthday stories do not imply personal quests.
- The economy's pacing targets are acceptance criteria, not mandatory waiting
  timers. Use fresh campaigns for balance tests; preserve existing owned progress.
- Offline drink earnings remain demand/cost limited; manager income is separate.
  All offline earnings remain repeat-safe and capped at eight
  hours. They must not spend the opening cash reserve, replay promotions or
  advance unseen disasters. Label estimates separately from actual revenue.
- Keep Anong, the existing cast, district exploration and optional Toybox fights.
  Tours and crypto are not core progression requirements. Chapters replace a
  mandatory one-year ending; the festival does not end normal play.
- All staff and performers are adults. Private activity stays implied and
  off-screen. Hosts retain consent and availability rules. Keep the comedy in
  character and business situations, not dehumanising treatment of staff.
- Preserve the completed graphics refresh. Show actual customers, orders, roles,
  pool states and closures. Do not replace production assets with placeholders
  or decorative crowds that contradict the model.

## Separate finance and growth (approved 27 November 2026)

- `s.cash` is the company bank; `bar.cash` is the venue till. Local income/costs,
  tips, staff and upgrades use that till. Leases, street marketing and unattributed
  legacy/company actions use the bank. Never silently cover a shortfall.
- Cash & Bank offers explicit transfers. Fund & buy transfers only the shortfall
  for a quoted local upgrade and reserve, then purchases once. Navigation is pure.
  Recommended working cash is two packs plus two minutes of operating costs.
- New leases retain their existing prices. Transfer a startup float of ฿1,200 +
  ฿228 + two minutes of new overhead and one bartender's wage into the new till.
- Schema 16 conserves old `cash + reserve` exactly, allocating working floats and
  leaving surplus in the bank. Insufficient cash is apportioned proportionally
  with stable integer remainders. Preserve all owned assets; no refunds or gifts.
  Fresh campaigns put ฿228 in Blue Hour and zero in the company bank.
- Street marketing requires any stage-two venue. Ten incremental bank-funded
  prices: 2000/4000/8000/16000/30000/50000/80000/120000/180000/260000.
  Traffic increments: 2/3/4/6/8/10/12/15/20/25 potential visitors/minute.
  Each additional open property adds two potential visitors/minute, maximum seven.
  All compete for one bounded audience; forecasts never create actual sales.
- HUD Till and its five-second net sample belong to the selected venue. Transfers,
  investments, tips and offline claims do not enter the trading sample. Offline
  bonuses require estimated customer trade and protect each opening cash balance.
- See [finance and growth](docs/design/FINANCE_AND_GROWTH.md) for account routing.

## Implementation boundaries

This is a Godot/GDScript project, not a web app. Use the engine version pinned in
`.godot-version`; do not add a server or change the engine merely for convenience.

- `scripts/finance.gd` owns explicit transfers, total wealth and schema-16 cash allocation.
- `scripts/economy.gd` owns customers, orders, pool, promotions, costs and forecasts.
- `scripts/street.gd` owns the shared live clock, properties, chapters and events.
- `scripts/street_content.gd` holds balance, equipment, promotion and story data.
- `scripts/campaign.gd` owns saves, migration and legacy/tutorial compatibility.
- `scripts/main.gd`, `city.gd` and the art catalog present model state. They must
  not independently award ordinary sales, skip progression or duplicate ledgers.

Guided shifts use the same live customers, stock and clock. The practice tutorial
is isolated. Preserve save migrations and paid/free game identity. The Windows
update worker must never run the live economy or autosave a fresh campaign.

## Coordinating the next feature

Read [the current handover](docs/MERGE_HANDOFF.md) before assuming a chat's work
has reached main. Use the [research roadmap](docs/INCREMENTAL_GAME_ROADMAP.md) to
coordinate one gameplay feature at a time. Existing research proposals are not
shipped features or permission to implement the whole backlog. Changes made in
separate chats must pass combined tests before a build is called ready.

Owner actions start at ten seconds, with per-venue 8/6/4-second upgrades and a
stage-two 2-second pouring tier for ฿5,600. Welcome still caps at four seconds. Chat
shares Welcome's timer and always takes twenty seconds to recover. Staff clocks
remain independent. New Game / Resume must stay read-only and paused until the
player selects an option; no contract ageing, offline claim or autosave on the menu.

## Working and verifying

Inspect `git status`, the current branch and relevant worktrees first. Preserve
other work. The merge handover records a historical integration state; do not
assume its branch names or paths describe every future checkout. For requests
from Ryan (`rknell`), sync `main`, verify the change, then commit and push
directly to `main` unless he asks for a branch or pull request. For other
maintainers, follow their instructions. The release workflow runs on `main`.

For gameplay, save, integration or asset changes, run `tools/test.sh`. It isolates
saves and editor settings and includes the pacing suite. Never run destructive
save fixtures against a personal campaign. For visual changes, use
`tools/preview-art.sh` and inspect the affected states, including the economy
preview runner where relevant. A successful export is not a device playtest.
For docs-only work, check facts, local links and `git diff --check` instead of
re-running the game solely for prose.

Keep README, story, economy rules and tests aligned with the resulting behaviour.
Report what changed, what was verified and what remains unverified. Do not expand
a small task into every future story hook, reset saves to make tests pass, or
claim unpublished work is already in release downloads.

Anong's next-step guidance is a pure read of chapter requirements and business
state. Navigation may select a venue/tab and scroll, never purchase, pay rewards,
advance chapters/time, or run RNG. Retain the shared chapter predicates and
existing gates. Current active pacing bounds keep stage two at 28–45 minutes,
second property at 75–115 and stage three at 110–210. Measure the saving gaps as
well: first-manager wait at most 21 minutes and longest between-investment gap
at most 38 in baseline active policies. Stage-two flagship investment cadence
targets a 2.5–5-minute median in active
profit-cycle policies. The user confirmed these faster lower bounds while keeping
prices unchanged. These are balance checks, not wait timers.

Nightly street closure starts a free 15-second clean-up/countdown for all venues.
The model owns the automatic noon skip and cancellation; UI only presents/input.
Wait for all scheduled late trading to end, excluding temporary disaster closures
as a trigger. Stay here cancels for the current night without stopping cleaning;
manual skip remains available. Schema 10 preserves remaining time/cancellation.
No countdown on the menu/offline, or while district/arcade hides the cancel
control. Preserve normal skip contract ageing, owner closures, stock and dates.

Nightly tips are ฿10 per real served visit, once on its first drink. Use saved
customer.drinks and bar.tip_visits; ordinary close/open, pool, manager and offline
income never earn/pay tips. Count jars once per night before clean-up (or manual
night skip), retaining paid reports and the settlement marker in schema 11.
Keep tip receipts out of commission, drink counters, healthy-service margins and
the five-second trading sample. Older saves get no retroactive tips. Expose the
existing six-drink consignment recovery beside unaffordable empty stock; preserve
orders/cooldowns, staff-off rota and ฿14 per sale, with no cover/stock stacking.

Milestone pacing targets use nearest-minute comparisons; exact run times remain
reported. Saving-gap ceilings remain exact. Preserve Ryan's per-drink stock,
audience/price choices, paid-cost returns and matched-drink bonus tips alongside
the standard house-beer price ladder. Other drinks retain their own supply costs.

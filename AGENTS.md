# Agent guide — Pattaya After Hours

## Product goal

Build a cheeky, adult nightlife idle/incremental business game set on a fictional
Pattaya street. The player and co-owner Anong rescue the Blue Hour, earn a loyal
customer base, automate a viable bar, and eventually operate a mixed street of
beer bars, Soi-style venues and gogos. Everyday business comedy grows into
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
  Venues compete for bounded shared street traffic.
- Pool costs **฿50 per game per table**, charged once at game start. Free Pool
  Night trades fees for attraction. Timers, capacity, customer budgets and
  promotion cooldowns still apply. Reloading must not duplicate rewards.
- Keep all three venue types useful, with three stages each. Renovation earns
  space and options; it does not automatically raise every drink's price.
  Local satisfaction, regulars and healthy operation matter alongside cash.
- Bartenders serve; hosts and dancers attract; managers enable offline operation.
  Bartender contracts cost ฿1,200; host/dancer contracts cost ฿4,500 for ten game days, including closed/skipped/offline
  time. Switching a bartender to a specialist role charges the positive contract
  price difference prorated to the remaining term, with a shift reserve; no refund
  for switching back. Training belongs to the person and survives expiry/rehire. Base bartender
  service starts ready: sell one real order, then recover for 25 seconds, improving
  to 20/15 through training. Keep the saved deadline through queue changes, owner
  clicks, rota/role changes and reloads. Staff precede purchased owner auto-serve. Owner automation is relief: serve
  when pending orders exceed available bartenders, or a guest has at most ten
  seconds left and no bartender can recover before their deadline. No eligible
  bartender means normal owner automation. Manual taps retain their own choice.
  Schema 9 preserves fractional staff deadlines and actual-sale counters; the
  bottom-right indicator and serving poses must reflect those sales, not decorative
  timer loops or offline estimates.
  Quiet trading still has costs. Preserve rotas, temporary closure and recovery
  instead of forcing idle-mode debt or an unrecoverable failure.
- Nida uses one separate frontage slot: ฿1,200/ten days plus 10% of actual drink
  receipts, no hourly wage and no serving. Preserve existing visit/order commission
  commitments after rota/expiry and the saved fractional carry; exclude pool fees.
  Welcome and promoter attraction never stack. Faster Welcome only helps while
  the promoter is off duty/expired; it does not speed Chat or boost her appeal. Audience training is stage-gated,
  separate from service training, and persists after rehire. Keep renewal visible
  in the frontage section, with exact payroll/stock reserve and shortfall. Expiry
  must refresh controls independently of history text; never duplicate her slot.
- Buy stock in complete packs requiring cash and room: six for ฿84 at supplier
  levels 0/1, twelve for ฿144/120/96/72 at levels 2/3/4/5. Supplier upgrades
  cost ฿900/1,200/2,400/4,800/9,600. Preserve inventory purchase costs; discounts never refund old stock. Supplier
  automation retains its next operating charge. Bo’s consignment remains the
  recovery exception. Each fridge tier earns +1 extra reputation per ten happy
  departures, capped at 100, with no purchase/reload reward. Third beer-bar seating must hold twelve with pool and fans.
  The schema-7 migration preserves paid manager/supplier appointments as level 1 and grants no
  free music/auto-serve or higher levels. Manager income is an explicit exception
  to customer-based receipts: ฿10/20/40 per trading second at levels 1/2/3, with
  purchase prices ฿18,000/36,000/72,000. Keep it separate from drink/pool sales,
  commission, customer counters and healthy-service milestones. No closed income.
- Music costs ฿1,200 and shortens repeat-order timing 35→25 seconds; budgets and
  visit limits still apply. Auto-serve costs ฿3,000 per venue and uses the SAME
  Serve deadline as manual clicks. Never award extra service for toggles/reloads.
  Till ฿/s is a five-second sample of actual net trading, excluding investments
  and offline claims; no simulation or accounting belongs in the HUD.
- Day seven's Blue Hour opening hosts Anong's Birthday, noon to normal 1am close.
  Later seventh-day openings rotate reunions, mixtape and thank-you nights. Keep
  the countdown/warning, free entry, finite shared traffic, real orders/budgets,
  normal prices and actual report. Only the flagship gets the third drink and
  faster repeat timing; closed venues gain no party attraction. Never replay
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

## Implementation boundaries

This is a Godot/GDScript project, not a web app. Use the engine version pinned in
`.godot-version`; do not add a server or change the engine merely for convenience.

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
assume its branch names or paths describe every future checkout. Unless the user
asks otherwise, work on a feature branch and leave merging to `main` and release
publication to the maintainer. Follow the user's explicit task and scope.

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

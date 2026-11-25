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
  Staff contracts cost ฿4,500 for ten game days, including closed/skipped/offline
  time. Training belongs to the person and survives expiry/rehire. Base bartender
  service is one drink per 25 seconds, improving to 20/15 through training.
  Quiet trading still has costs. Preserve rotas, temporary closure and recovery
  instead of forcing idle-mode debt or an unrecoverable failure.
- The economy's pacing targets are acceptance criteria, not mandatory waiting
  timers. Use fresh campaigns for balance tests; preserve existing owned progress.
- Offline earnings remain demand/cost limited, repeat-safe and capped at eight
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

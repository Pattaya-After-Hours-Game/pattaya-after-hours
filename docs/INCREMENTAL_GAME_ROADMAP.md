# Incremental game research and feature roadmap

Research date: **25 November 2026**. Applies to **Pattaya After Hours**.

Restored during the 25 November consolidation from the earlier research chat.
This is a design backlog for coordinating future improvements to the street loop.
Current mechanics and measured numbers live in [ECONOMY.md](ECONOMY.md); this
document does not override them. The research citations below are the original
dated evidence, not a new market review. Read [README](../README.md) for current gameplay and
[DEVELOPMENT](../DEVELOPMENT.md) for setup and verification. Features below are
**proposals, not implemented functionality**. Recheck the code before claiming one:
this research inspected a working tree with substantial development already in progress.

## Start here: one feature at a time

**The whole project has a work-in-progress limit of ONE gameplay feature, across
both contributors and all chats/branches.** Implementation, testing, and review
all occupy that same slot. Two people can contribute to the same feature; they
must not independently start two roadmap items.

### Shared active feature

| Field | Current value |
| --- | --- |
| Active feature | Opening-arc pacing, training value and Anong’s next step |
| Status | REVIEW; local checks passed; prior feature shipped in v1.0.19 (`e644c55`) |
| Implementer | Codex in Build out Pattaya bar game |
| Reviewer / playtester | Codex verified tests and layout; independent device play pending |
| Shared claim location | This table in the agreed shared checkout or coordinating branch |
| Working branch / chat / PR | `codex/opening-arc-balance`; see [handover](MERGE_HANDOFF.md) |
| Scope and owned files | Price balance, read-only story guidance, fresh-campaign measurements, tests and docs |
| Next handoff / blocker | 42 campaigns, regressions and previews passed; ready for authorized main release; human play pending |
| Recommended next, when free | **IF-01 — Guided next goal** |
| Last updated | 2026-11-26 |

An empty or stale table is **not evidence that the other contributor is idle**.
Never overwrite an existing claim or abandon another contributor's unfinished work.

### Claim, build, review, finish

1. Read this table, the working tree diff, and the current handoff. Reconcile work
   already underway before taking a new item, including work outside this backlog.
2. When the slot is free, choose the highest-priority unblocked item. Record its
   ID, owner, reviewer, exact scope, file ownership, branch/chat, and acceptance
   criteria here. Change its backlog status to `IN PROGRESS`.
3. Make the claim visible to both contributors **before editing gameplay**. In a
   shared checkout, designate one writer for this table. With separate checkouts,
   agree on one coordinating branch and publish/sync the claim there; two private
   branch edits do not constitute a shared lock. Resolve simultaneous claims first.
4. The implementer builds the smallest complete slice. The other contributor
   reviews, playtests, or handles explicitly assigned files for **that same ID**.
   Avoid simultaneous edits to `scripts/main.gd`, shared economy code, or this table.
5. Put new ideas in the backlog. Do not quietly add them to the active feature.
   If blocked, keep the claim `BLOCKED`; explicitly park/handoff it before replacing
   it. An urgent fix can replace the slot after recording that handoff.
6. Set `REVIEW` when implementation is ready. Run appropriate checks, play the
   affected flow, and record outcomes. A separate reviewer is preferred; if
   unavailable, document who verified it and the remaining limitations.
7. Set `DONE` only after acceptance criteria pass and the result is integrated
   into the agreed shared branch/checkout. Record the commit/PR or handoff reference,
   tests, playtest result, and remaining issues. Clear the active claim, then choose
   the next feature. Finishing code alone does not free the slot.

## New user-requested design, 25 November 2026

The [seating, six-pack and promoter plan](design/PROMOTER_CAPACITY_PLAN.md) is a
design-only follow-up to the TV/patience fix (`0d7bb90`). It records confirmed
twelve-person furnished capacity and 10% all-drink commission, provisional tuning,
reproducible estimates and a frontage concept. It does not claim a gameplay
implementation slot or replace the historical shared claim above. Reconcile that
claim and pending changes with the maintainer before implementing this requested
slice; do not start other backlog items alongside it.

## What the research supports

Successful examples suggest a useful pattern: **make progress understandable,
let players automate work they understand, then reveal new decisions and rewards**.
There is no proven checklist that guarantees a hit. These sources mix practitioner
models and product descriptions, not controlled experiments. They inform our
hypotheses; our own player observations must decide what ships.

| Pattern | Evidence | Application to this game — our design inference |
| --- | --- | --- |
| A clear earn → invest → earn-faster loop | Cookie Clicker's official description centers on reinvesting cookies into production. [Cookie Clicker](https://store.steampowered.com/app/1454400/Cookie_Clicker/) | Make the benefit of a hire or renovation understandable before purchase. Let the first server visibly take over serving. |
| Costs and production create changing priorities | Pecorella models production versus costs and shows how multipliers can make earlier generators relevant again. [Math, Part I](https://www.kongregate.com/en/pages/the-math-of-idle-games-part-i) | Measure time to afford and incremental profit. Keep beer bars useful after gogos arrive; do not apply exponential costs blindly to our finite street. |
| New mechanics unfold instead of arriving all at once | A Dark Room's developer describes expanding mechanics revealed from a single starting button, and reports its later #1 App Store position. [Developer press kit](https://press.doublespeakgames.com/adr/index.html) | Introduce service, automation, a second venue, and festival planning in readable steps. Keep optional systems discoverable without making them the opening lesson. |
| Depth comes from connected decisions | Melvor's official description emphasizes skills that benefit one another, offline progression, and collection. [Melvor Idle](https://store.steampowered.com/app/1267910/Melvor_Idle/) | Test one venue specialization before adding more currencies or businesses. Choices should change where the player invests. |
| Return cadence should fit different schedules | Eric Guan argues for production timing that accommodates both frequent and infrequent check-ins. This is practitioner advice, not a measured retention guarantee. [Idle Game Design Principles](https://ericguan.substack.com/p/idle-game-design-principles) | Test active play, short returns, and overnight returns separately. Explain offline earnings and give a useful next action after returning. |
| Prestige can renew progression, but is a design choice | Pecorella explains resets that grant lasting boosts and compares different reward bases. [Math, Part III](https://www.kongregate.com/en/pages/the-math-of-idle-games-part-iii) | Consider an optional new-season experiment only after the existing festival arc works. Do not erase a player's street merely because other idlers reset. |
| Personality and continued discovery matter | Cookie Clicker advertises achievements, minigames, permanent upgrades, and continued development; A Dark Room emphasizes atmosphere and discovery. [Cookie Clicker](https://store.steampowered.com/app/1454400/Cookie_Clicker/), [A Dark Room](https://press.doublespeakgames.com/adr/index.html) | Make milestones deliver a visible venue change or an Anong/Dao/Anton story payoff. Add depth to the existing setting before unrelated minigames. |

As a reception snapshot on the research date, Steam displayed **96% positive
across 55,404 English reviews** for Cookie Clicker and **92% across 8,694 English
reviews** for Melvor Idle. These are language-filtered review counts, not sales,
retention, revenue, or proof that any individual mechanic caused success.
[Cookie Clicker reviews](https://store.steampowered.com/app/1454400/Cookie_Clicker/),
[Melvor Idle reviews](https://store.steampowered.com/app/1267910/Melvor_Idle/).

Our working definition of success: players understand the opening, enjoy making
investment decisions, return voluntarily, trust their saved progress, and have
something distinctive to tell friends about. Commercial success also depends on
distribution, presentation, audience fit, and ongoing support. This document does
not establish a monetization model or predict revenue.

## What we have now

The earlier research inspected the old guaranteed-sales prototype. Its ฿6,400
opening cash, four-second staff service, blanket stage price rises and guaranteed
offline formula are obsolete and have been removed from this current reference.

The combined game starts with ฿200 and real orders. Ten-second owner actions can
be upgraded, Chat can save an urgent order, and ฿4,500 staff contracts last ten
game days. Bartenders begin at 25 seconds per drink; personal training persists.
Demand, space, service and stock all limit sales. Pool costs ฿50 per game.
Clock/closing, costs, regulars, healthy shifts and reserves govern expansion.

We now have a paused New Game / Resume menu, schema-five saves, backup recovery,
per-venue forecasts, offline breakdowns and fifteen policy simulations. These
cover parts of IF-02, IF-03 and IF-04 below; they do not complete the proposed
human playtests or future goal-navigation features. Compare the current
[economy rules](ECONOMY.md), [player guide](PLAYER_GUIDE.md) and
[verification record](TESTING.md) before claiming an item.

## Ordered backlog

Statuses: `QUEUED`, `IN PROGRESS`, `REVIEW`, `BLOCKED`, `DONE`, `DEFERRED`.
No row below is a current implementation claim. Existing work takes precedence
until the shared active-feature table is reconciled.

| Order / ID | Feature | Status | Why / dependency |
| --- | --- | --- | --- |
| 1 / IF-01 | Guided next goal | QUEUED | Make the current game understandable before expanding it |
| 2 / IF-02 | Honest purchase previews | QUEUED | Help players compare investments; reuse IF-01's goal context |
| 3 / IF-03 | Progression pacing pass | QUEUED | Measure opening and overnight progression before adding multipliers |
| 4 / IF-04 | Return-session summary | QUEUED | Build on existing offline claim; use IF-01 and IF-03 findings |
| 5 / IF-05 | Milestone celebrations | QUEUED | Strengthen existing story/art payoffs without changing the economy |
| 6 / IF-06 | One venue specialization | QUEUED | Add a real choice after the base economy is understood |
| 7 / IF-07 | Event preparation clarity | QUEUED | Make preparation benefits and interruptions easier to judge |
| 8 / IF-08 | Optional new-season prototype | DEFERRED | Only if post-festival players want a replay loop; depends on pacing evidence |

Reorder based on observed player problems, documenting the reason. Do not start
the entire queue. Each item is a separate feature, review, and integration step.

### IF-01 — Guided next goal (recommended first)

**Hypothesis:** players will reach self-running service more reliably when they
can see the next prerequisite and jump directly to its control.

**Smallest slice:** a compact street goal card for the opening chapter. Show
completed/remaining requirements and one contextual action. Derive the state from
existing chapter logic: stage 2, ten drinks served, a manager, and an event survived;
expand the manager requirement into hire, deliveries, and management training.
Automatic drinks count too. Explain waiting for the reopening when that is the
remaining requirement. Later chapters may retain their existing summary initially.

**Touchpoints:** `scripts/street.gd` (`check_chapters`, read-only goal helper),
`scripts/main.gd` (`chapter_panel`, street UI/drawer navigation),
`scripts/street_content.gd` (copy), `tests/street_check.gd`, UI checks as appropriate.
Use shared requirement predicates so UI and chapter completion cannot drift.

**Acceptance:**

- A fresh game shows a useful action without opening the optional shift tutorial.
- Completing prerequisites in different orders updates the card correctly;
  loading an existing save reconstructs it without a new reward or forced reset.
- Navigation selects the correct venue/drawer without spending money. Costs and
  unmet prerequisites are readable; blocked actions do not silently fail.
- Ten automatically served drinks satisfy the same goal as manual serving.
- The card does not cover serving, property selection, or event controls at the
  960 × 540 base layout; keyboard, touch, and Back/Esc still work.
- Existing first-chapter checks pass. In an initial five-person playtest, aim for
  at least four players to find the next action unaided and appoint a manager
  within five minutes. This is a proposed usability gate, not an industry benchmark.

**Out of scope:** new rewards, rebalancing, analytics infrastructure, prestige,
and rewriting the optional tutorial.

### IF-02 — Honest purchase previews

**Slice:** hiring and renovation controls show cost, current → projected base net
rate, and the incremental difference. Show manager purchases as an **offline
unlock**, not a foreground multiplier; delivery automation as continuity, not free stock.

Calculate previews without mutating the live state, charging cash, writing saves,
advancing RNG, or triggering chapters. Reuse economy rules instead of copying
formulas into UI. Clearly distinguish normal steady-state rates from live event
rates and temporary closure/absence. A cash-only ETA may be
`max(0, cost − cash) / net_per_minute`, but display it only with its assumptions;
show a blocker for zero production or unfunded restocking. Non-cash gates need
their own explanation, not a false countdown.

**Touchpoints:** `street.gd`, `main.gd`, `tests/street_check.gd`.
**Acceptance:** quoted deltas agree with purchases under the stated assumptions;
closed/unmanaged/max-stage/absent-host cases are explained; previews do not alter
save state. Ask players to compare a hire with a renovation and explain the difference.

### IF-03 — Progression pacing pass

**Slice:** measure the existing economy, then make one justified set of pacing
changes if evidence calls for it. Do not introduce a new progression system here.
Use isolated saves and the real `Street` simulation; advance in chunks of at most
60 seconds because `tick()` clamps its argument. Trace purchases, time, cash,
stock shortages, chapter gates, and net rates.

Compare: (a) no tapping after the first hire, (b) comfortable occasional tapping,
(c) an interrupted session and 30-minute return, (d) an eight-hour return, and
(e) a fully developed street. Include a path that spends aggressively and a path
that preserves delivery cash. Test a full return → reinvest → next-goal sequence,
not just the size of an offline payout.

**Acceptance:** record before/after traces and proposed timings; a fresh campaign
can reach the festival without optional tours/crypto; no spending path used in the
guided opening creates an unexplained stock stall; existing save/claim behavior
passes regression tests. Decide explicitly whether overnight returns should fund
several upgrades or bypass most cash gates. If changing rewards, document the
effect on existing saves and player-facing explanations. A measured decision to
keep current values is a valid result.

**Touchpoints:** `street.gd`, `street_content.gd`, possibly starting values in
`campaign.gd`, and deterministic checks in `tests/street_check.gd`.

### IF-04 — Return-session summary

**Slice:** enhance the existing welcome-back panel with elapsed versus credited
time, per-venue net contributions, cap explanation, and a link to the next goal.
Explain zero production where useful without showing a modal on every brief resume.
Earnings are already credited before dismissal: never add a second claim transaction.

**Acceptance:** venue totals match credited income with a defined rounding rule;
same-timestamp resumes never pay twice; clock rollback pays nothing; tutorial saves
remain isolated; closures, unavailable hosts, events, and the calendar keep their
existing offline semantics. Dismissing or navigating the panel cannot duplicate income.

**Touchpoints:** `street.gd` (`claim_offline`), `main.gd` (welcome/resume),
`campaign.gd` only if persistence changes, existing offline regression checks.

### IF-05 — Milestone celebrations

**Slice:** add a brief, dismissible celebration for the first manager and completed
chapters using existing characters and artwork. Start with these few meaningful
moments, not a large achievement system. Provide a readable journal entry.

**Acceptance:** milestones fire once, including across reload/migration; no replayed
cash rewards; later-chapter saves do not receive a popup storm; celebrations leave
controls usable and respect existing audio settings. Players can explain what changed.
**Touchpoints:** chapter/manager transitions in `street.gd`, UI in `main.gd`,
existing art catalog in `art.gd`; save compatibility if new flags are needed.

### IF-06 — One venue specialization

**Slice:** prototype one reversible choice for beer bars, such as a steady regulars
focus versus an event-focused offer. Exact bonuses and switching rules follow
IF-03's model. Keep existing currencies and three venue identities.

**Acceptance:** test both choices across ordinary trade, low season, and a busy
event; each has a meaningful use case and neither dominates every tested scenario.
Players understand the tradeoff before choosing. Save defaults preserve old bars,
switching cannot generate money, and a poor choice does not require restarting.
**Touchpoints:** `street_content.gd`, `street.gd`, `main.gd`, save validation and tests.

### IF-07 — Event preparation clarity

**Slice:** show what the existing preparation action changes: expected modifier,
avoided closure, or extra monster time. Show the cost and existing protections.
Keep the current rules for this feature; frequency tuning becomes a separate
queued follow-up only if playtests establish interruption fatigue.

**Acceptance:** warning and active states display correct rules, preparation
charges once, unavailable actions explain why, and missed events remain recoverable.
No event runs during offline time. **Touchpoints:** event rules/content, event UI,
existing event and monster tests.

### IF-08 — Optional new-season prototype (deferred)

Only explore after players reach the festival and ask for more progression.
First compare a non-reset mastery path with a voluntary new-season reset on paper.
If testing a reset, define exactly what stays, what is lost, and what permanent
benefit is earned; preview that result and use an isolated prototype save.

**Acceptance before production:** evidence of demand; a demonstrably different or
faster second run; no repeated reset reward exploit; migration, backup/recovery,
and explicit confirmation. Never silently wipe the existing street. No production
reset implementation is authorized merely by this roadmap entry.

## Measurement and shipping discipline

For each feature, write down one hypothesis and its primary observation before
implementation. Start with a small observed playtest and manual timings; no analytics
service is necessary. Save notes with the feature ID, build/commit, participant count,
prior familiarity, device, actions observed, and what confused players.

| Question | Record |
| --- | --- |
| Does the opening make sense? | Time to first serve, first hire, first manager; help requests and wrong turns |
| Are purchases satisfying? | Whether players can predict the benefit; which upgrade they choose and why |
| Does the economy stall or skip ahead? | Time between meaningful purchases; stock stalls; chapters crossed per return |
| Is returning worthwhile? | What players buy after 30 minutes/eight hours; whether they can name their next goal |
| Is the game memorable? | Which venue, character, event, or visual change players recall without prompting |
| Do players want to return? | Voluntary next-day and next-week returns among invited testers, with actual counts |

With a larger consenting test group, define D1/D7 consistently as return on the
next calendar day / seventh calendar day after first play in a fixed timezone.
State the denominator, exclude cohorts that have not reached that day, and show
counts alongside percentages. Five testers can expose confusion; they cannot
establish reliable retention uplift. Do not invent baseline retention or copy
benchmarks from a different platform/business model.

For gameplay changes, follow [DEVELOPMENT](../DEVELOPMENT.md): run
`GODOT_BIN=/path/to/godot tools/test.sh` using the pinned engine, and
`git diff --check`. The wrapper isolates saves. Add focused regression coverage for
changed rules, migrations, or reward idempotence; manually play changed UI and
check mobile layout. Use `tools/preview-art.sh` for relevant visual checks.
Documentation-only edits need link/content and whitespace checks, not a game build.

Completion record template, appended when a feature actually finishes:

```text
Feature ID and title:
Implementer / reviewer:
Integrated commit, PR, or shared-checkout handoff:
Player-visible change:
Checks and device/layout playtests:
Observed result versus hypothesis (include participant count):
Known limitations / follow-up backlog IDs:
Decision: keep / revise / revert
```

## Boundaries for future feature selection

- Preserve offline play, reliable saves, readable controls, and the fictional
  setting. Existing artwork and character writing are assets to develop further.
- Favor voluntary returns over expiring rewards, broken streak penalties, or
  mandatory tapping. A long session alone is not proof that players are having fun.
- Do not add extra currencies, prestige layers, daily obligations, ad multipliers,
  or unrelated minigames to imitate another game's feature count.
- Keep adult activity off-screen and preserve hosts' ability to decline bookings.
- Marketing improvements should show the actual serve → automate → transform
  experience in screenshots or a short clip. Test the premise with incremental
  players and gather feedback; community posting/publication is a separate task.
- Every new proposal needs a player problem, smallest slice, evidence or explicit
  hypothesis, acceptance criteria, and a place in the queue. **One active feature.**

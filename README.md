# Pattaya After Hours

Start with six stools and a warm fridge. Build the Blue Hour into a thriving beer bar, then own a mixed street of hostess bars and gogos. Anong wants a business that lasts. Anton wants a bigger LED screen. Godzilla wants a cold one.

**[Get it on Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522io.github.rknell.pattayaafterhours%2522%252C%2522url%2522%253A%2522https%253A%252F%252Fgithub.com%252FPattaya-After-Hours-Game%252Fpattaya-after-hours%2522%252C%2522author%2522%253A%2522Pattaya-After-Hours-Game%2522%252C%2522name%2522%253A%2522Pattaya%2520After%2520Hours%2522%257D)** · **[Android APK](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest/download/PattayaAfterHours.apk)** · **[Desktop downloads](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest)**

![The Blue Hour and its neighborhood at dusk](docs/blue-hour.png)

The current source integrates Gabby and the expanded customer profit cycle, with
existing saves preserved. It includes the full customer cast, New Game / Resume, the day/night
clock, owner cooldowns/Chat and retained staff training. Day seven now brings a
free Anong’s Birthday celebration, followed by weekly neighbourhood parties. Recent updates add music, auto-serve, two-second pouring, supplier discounts,
manager income and a five-second ฿/s display, alongside
a twelve-person compact beer-bar layout, whole-pack deliveries and Nida, an adult
promoter who works outside the entrance. Purchased TVs appear on the wall and
waiting-order dots turn red as patience runs out. Source and release downloads
are tracked separately; the download links above select the latest published build.
See [the current handover](docs/MERGE_HANDOFF.md) for chat and branch status.

## Start playing

Open `project.godot` in **Godot 4.7.2** and press **F5**, or run from the checkout:

```sh
godot --path .
```

**Attract customers → give them a reason to stay → fulfil orders → earn a profit
→ reinvest.** You start with ฿228, twelve drinks and three opening customers.
Tap **Serve a drink** for a waiting order; use **Welcome customers** when quiet.
Both actions refill over ten seconds. In **Service**, buy **Faster pouring** and
**Better welcoming** to reduce each venue’s cooldowns to eight, six, then four
seconds. Pouring has an additional **two-second tier for ฿5,600**, available from
stage 2. **Have a chat** buys an urgent waiting guest ten more seconds; it shares
Welcome’s timer and takes twenty seconds to recover. No order means no sale. Open **Service** to see demand, service speed, occupancy,
stock, payroll and recent actual profit. Waiting-order bells respect Sound / Muted.

Inside the scene, customers stand on the public side of the bar, bartenders
work behind the counters, and yellow/gold dots above customers mark waiting orders.
Dots turn red with ten seconds or less before patience or visit time runs out;
comfortable seating and a successful chat extend that time.
The smaller passerby in the left street opening is background traffic, not an
extra customer. Messages sit above the room so the floor remains visible.
The customer cast includes older regulars and Indian, Korean, Black and Thai
visitors, with outfits ranging from scruffy holiday wear to tailored clubwear.
Looks stay consistent during each visit and do not determine spending behaviour.
Wall fans appear only after buying **Fans & comfortable seats**, including in
the property thumbnail; renovation alone does not install them.
Buying **Sports screen** installs a visible wall TV, also shown in the thumbnail.
Beer-bar stages 2 and 3 have fitted screens that stay dark until purchased.

House beers cost **฿80 at beer bars, ฿100 at hostess bars and ฿120 at gogos**.
Renovation does not raise these prices. House lager stock starts at ฿38 per drink, leaving
฿42/62/82 before wages and overhead. Happy Hour takes 20% off new
orders; the purchased premium menu unlocks mango cocktails at ฿30 above house lager.

Stock starts in **six-drink packs for ฿228**. Supplier level 2 switches both manual
and automatic deliveries to **twelve drinks for ฿432** (฿36 each). Levels 3–5
keep twelve-drink deliveries and lower the bill to ฿408/384/360. Every purchase
needs room and cash for the whole delivery; the button explains any shortfall.
Each fridge tier adds +1 reputation per ten satisfied visits, on top of the base +1. Stage-1 beer bars can buy a third seating level, **Compact layout
for ฿1,200**, reaching twelve customers even with pool and fans installed.

Save for signage, seating and a pool table, then invest in staff contracts. Pool is available at
beer-bar stage 1: **฿50 per table per 30-second game**, charged once. Free Pool
Night attracts visitors but gives up pool fees; Happy Hour, Pool Tournament and
Sports Night have their own costs and trade-offs. Promotions last two minutes,
then have a two-minute cooldown.

Bartenders serve orders; hosts and dancers attract visitors. Bartender hiring or rehiring
costs **฿1,200 for ten game days**, matching Nida’s upfront price; hosts and dancers
remain ฿4,500. Floor staff retain on-duty wages, and bartenders have no drink commission. A base bartender serves
one drink every **25 seconds**; individual training improves this to 20 and then
15 seconds, with training priced at ฿400 then ฿800. Stage two adds 12-second
and 10-second training for ฿1,200 and ฿1,600 per bartender. Help serve during a rush. Contracts expire, but each person's training
stays with them when rehired. Service shows the remaining term and rehire controls.
Closed hours, skipped nights and offline time count toward contracts.

In **Service → Frontage promoter**, hire **Nida for ฿1,200 per ten game days, with no commission**. She replaces Welcome taps, uses a separate roster slot
and never serves drinks. Her preview shows estimated demand and net
profit with and without owner service. Bringing more customers to an already
slow bar can lose money. Old unpaid commission commitments are cancelled; historical payments remain recorded. Promoters and dancers unlock separate audience training at stages
2 and 3 for ฿800 and ฿1,600; their skills survive rehire.

A two-note bell alerts you to waiting orders at the selected venue, repeating at
most once every ten seconds. **Sound / Muted** controls it along with game audio.
Staff cost money while on duty, even when the bar is quiet. Use the rota or temporarily close if
costs outrun sales. An owner-run recovery shift offers a way back from an empty
till. Renovations need satisfied customers, local regulars, healthy shifts and
cash for the next shift—not just a large bank balance.

Tap **Stock** or **Restock fridge** to compare popularity with profit per sale. Order a mixed delivery or buy a pack of one drink. The premium menu unlocks
Mango cocktails.

## Chase the next bottleneck

New customers plan one or two rounds; club members and birthday guests can plan
one extra, capped at three. They finish drinking the last round before leaving,
or finish their pool game. Music speeds drinking and turnover; it does not invent
buyers. A satisfied one-drink visit can earn a regular.

Beer bars now have several investments per stage: seating caps **3/5/7**, frontage
**1/3/5**, fridges **2/3/4**, music **1/2/4**, and bartender training **2/4/6**.
The next tier shows its stage requirement. Higher frontage grows one shared street
visitor pool. Other venue types keep their existing purchase limits.

**Service → Your profit cycle** separates actual customer profit from manager
income and explains the last shift's bottleneck. **Show visit plans** reveals
who is waiting, drinking or finishing pool. A cyan glass means drinking; the
existing yellow/red dot means a waiting order. See the
[profit-cycle design](docs/design/PROFIT_CYCLE.md) for tiers, prices and rules.

## Choose your next business

**Beer Bar → Hostess Bar → Gogo Bar** describes three different businesses.
First purchased leases cost **฿12,000 / ฿24,000 / ฿60,000**. The inherited Blue
Hour is excluded from the repeat premium. Each earlier purchase of the same type
adds **25% of that type's base price**, without compounding: beer bars cost
฿12,000, ฿15,000, ฿18,000, then ฿21,000. Renovation prices stay unchanged.

Empire separates **pay now**, **keep in till**, **total opening cash**, running
costs and estimated house-drink break-even. The reserve is not a second fee.
Shared street traffic and local renovation milestones still apply.

Retiring-owner offers are explicit: every fourteenth game day, one venue type
gets 10% off leases for that day, rotating Hostess → Beer → Gogo. Empire shows
the saving. Existing buildings, cash and stock receive no refunds or revaluation.

## Music, automation and management income

| Purchase | Price and effect |
| --- | --- |
| Music system / better sound | ฿1,200 for 35→25-second repeats; stage two adds ฿2,400 for 18 seconds; beer-bar stage three adds ฿3,600/4,800 for 14/11 seconds. Budgets, visit limits, stock and service still apply. |
| Regulars Club | Stage two: ฿600 / ฿1,200 / ฿2,400; 35% / 65% / 100% of new visitors plan and budget for an extra round, capped at three. Requires 10 / 20 / 35 local regulars. |
| Auto-serve | ฿3,000 per venue; uses the existing Serve timer as rush backup for bartenders, or covers the bar without them. Manual taps share it. |
| Two-second pouring | ฿5,600 after the existing pouring tiers, from venue stage 2. Welcome still stops at four seconds. |
| Manager levels 1 / 2 / 3 | ฿8,000 / ฿36,000 / ฿72,000 incremental purchases; ฿10 / ฿20 / ฿40 per game minute (real second) while open. Level 1 needs stage 2; later levels need stage 3. |
| Supplier levels 1–5 | ฿900 / ฿1,200 / ฿2,400 / ฿4,800 / ฿9,600; delivery prices ฿228 for 6, then ฿432 / ฿408 / ฿384 / ฿360 for 12. |

Manager income is separate from drink/pool receipts, uses no stock and pays no
drink commission. It stops on closure and does not grant satisfied customers.
Operating costs still apply. Managed offline estimates include it during legal
opening windows. Existing appointments are retained as level 1.

The **฿/s beneath the till** refreshes every five foreground seconds and shows
net street trading: receipts minus stock purchases, operating costs, commission
and fines. It excludes equipment/contract purchases, nightly tip counts and offline lump sums.
Nida now faces toward the street; a purchased music system has a playing/off
indicator. Sound/Muted remains independent of the business upgrade.

## Opening time, prep and late nights

The clock runs at **one game minute per real second**. Venues open at **12pm**
and normally close at **1am**: thirteen real minutes of trading. The date changes
at midnight; the **DAY** counter above the clock tracks your campaign from
**Day 1** onward and is kept in your save. Business reports still cover two real
minutes of trading.

Each venue has its own peak: **beer bars 5–9pm**, **Soi venues 7–11pm**, and
**gogos 10pm–2am**. Peak trade adds 50% attraction and doubles dirt per drink sold;
venues still compete for the same bounded street traffic. A gogo needs late
permission to serve the part of its peak after 1am.

In **Service**, choose **Stay open until 3am tonight** separately for each venue
before 1am. Late trading adds heat and risks a raid, a fine of **฿300 per venue
stage** (up to the cash available), and closure until noon. All venues shut by
3am; late permission resets each day. The screen shows current raid odds.

Use closed hours to clean, restock and adjust staffing. Cleaning takes fifteen
real seconds; nightly street clean-up now starts it automatically for everyone. Dirt from drink sales reduces
attraction by up to 25%. Once every venue stops trading after 1am, **Skip to
12pm** is available even with unfinished prep. Skipping cancels incomplete
cleaning and buys no stock. Noon never reverses your own closure or a shutdown
from insufficient cash.

## Build the street

| Venue | Identity | Three stages |
| --- | --- | --- |
| Beer bar | Affordable drinks, pool and regulars | Plastic Chairs & Big Dreams → The Local Favourite → Soi Institution |
| Hostess bar | Hosted nightlife and repeat visitors | Something Upstairs → The Busy Staircase → Soi Royalty |
| Gogo | Performances, tourist demand and premium orders | First Spotlight → Neon Showroom → Walking Street Headliner |

Own up to eight properties. Beer bars remain useful after new types unlock;
venues compete for shared street traffic. The five-chapter story takes you from
the Blue Hour reopening to the **After Hours Street Festival**, with Anong, Dao,
Pim, Mali, Bo and rival owner Anton. The street continues after the festival;
there is no forced one-year ending. All staff are adults, private activity stays
off-screen, and hosts retain control over bar-fine participation.

Street events include Navy visits, inspections, floods, Songkran, viral crowds,
low season, rival promotions and Godzilla. Warnings give time to prepare, and
setbacks are recoverable. Walk the district or visit **Events** for optional
Toybox sparring. Tours and legacy mining investments are not progression gates.

![Toybox with the finished fighter artwork](docs/toybox.png)

## Controls and saving

| Where | Controls |
| --- | --- |
| Street | **Serve a drink**, **Welcome customers**, **Have a chat**, property cards and the scrollable management tabs |
| Events | Pink warning banner or **Events**; prepare before the countdown, then **Face Godzilla** for a monster challenge |
| District | WASD/arrows to walk, E to enter, Esc to return; touch a destination on mobile |
| Toybox | A/D or arrows to move, W/Up to jump, S/Down to guard, J/K/L to jab/kick/Burst. On mobile, hold or slide on the left D-pad and tap attacks with your right thumb. |
| Godzilla | **Serve a shot** or Space; ten shots before the timer ends |

Each launch opens a **New Game / Resume** menu. **Resume** continues your saved
campaign and is disabled when no readable save or backup exists. **New Game**
starts over; if a save exists, confirm to permanently replace its progress and
remove its backup. There is one campaign slot per device. The street stays
paused on the menu, and offline estimates are claimed only when you resume.

The game autosaves after decisions and every fifteen seconds, and on normal
close or application pause. New games are saved immediately. Older campaigns
retain money, staff, venues and owned stages when migrated to save schema 13.
Schema 13 retains individual visit plans and expanded beer-bar tiers. Existing
visitors finish under their saved legacy stay, quotes and timers. Older
saves get no free purchases, extra rounds for existing guests or manager refunds.
Pre-clock saves start at noon on the existing day, with initially clean venues.
Schema 9 preserves staff cooldown deadlines and actual service counters. Older
partial work is converted once; existing purchases get no refund. Schema 8 retains celebration dates, active/last reports and visitor patience,
without retroactive party payouts. Schema 7 added purchased automation, music, supplier/manager levels, inventory
purchase costs and the five-second earnings sample. Existing supplier/manager
appointments become level 1; new upgrades must be bought. Schema 6 added
promoter contracts, audience training, commission commitments and
fractional offline accounting; schema 5 introduced action timers and Chat.
Existing venues receive no free compact layout, promoter or training. A fresh campaign is
needed to experience the revised progression from the beginning.

Business reports use two real minutes of trading. Viable managed venues receive
an estimate for up to eight real hours away, counting only projected noon–1am
windows and limited by demand, stock, service, cleanliness, venue peak hours and costs. Offline time
does not advance the live clock, cleaning, heat, raids or disasters. See **Journal**
for the estimate. Optional **Open managed shift** guidance uses the same live
customers and clock. **Tutorial** lets you practise stock deliveries, serving,
welcoming, Chat, hiring and closing in a separate practice shift. Tap or hover
over a top-bar stat for a quick explanation.

## Documentation

| Read this | For |
| --- | --- |
| [Agent guide](AGENTS.md) | Project goal, design commitments and instructions for future coding agents |
| [Story reference](story.md) | Premise, cast, chapters, venue identities, events and future story hooks |
| [Player guide](docs/PLAYER_GUIDE.md) | First shift, pool, promotions, expansion and recovery |
| [Economy specification](docs/ECONOMY.md) | Model rules, costs, local milestones, offline projection and measured pacing |
| [Developer setup](DEVELOPMENT.md) | Engine installation, code map, saves and platform builds |
| [Testing and release checks](docs/TESTING.md) | Automated coverage, visual checks and remaining device verification |
| [Art pipeline](art/README.md) | Asset provenance, packing, animation catalog and visual review |
| [Merge handover](docs/MERGE_HANDOFF.md) | Current chat audit, included branches and build handoff |
| [Research roadmap](docs/INCREMENTAL_GAME_ROADMAP.md) | Design research, future proposals and one-feature-at-a-time coordination |
| [Seating, six-packs and promoter plan](docs/design/PROMOTER_CAPACITY_PLAN.md) | Implemented design, trade-offs and original analytical estimates |
| [Changelog](CHANGELOG.md) | Progression, economy, graphics and documentation changes |

## Project status

The current source includes 76 runtime textures, twenty-five sprite atlases with
155 frames, nine interiors and nine matching exterior illustrations. Gameplay,
save migration, boot-menu isolation, action/staff timing and art/input regressions
are checked together with 48 fresh-campaign simulations, 60 paired celebration scenarios and 80 stage-two
income scenarios. The stage-two income pass adds smaller investments between
renovations and lowers the first manager price; measured timings are recorded
in [Testing](docs/TESTING.md). Optional promoter-first investment takes longer to repay;
service-first and manual routes remain viable. Mostly-idle play takes longer.
Device playtesting is still separate from tests and exports. See the
[verification record](docs/TESTING.md).

## Install

- **Android.** Use the Obtainium button, or add `https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours` as the source in Obtainium. The signed APK supports Android 7.0 and later on ARM64 and x86-64. Package ID is `io.github.rknell.pattayaafterhours`.
- **Linux x86-64.** Extract the ZIP and run `PattayaAfterHours.x86_64`.
- **Windows x86-64.** Right-click the ZIP, choose **Extract All**, then open `PattayaAfterHours.exe` in the new folder. Starting with v1.0.7, the game checks for updates when it opens. Choose **Update & restart** to install a new release. The executable is unsigned.
- **macOS Intel and Apple Silicon.** Extract the ZIP and open the app. The build is ad-hoc signed and has no Apple notarization.

APK signing certificate SHA-256

`4a72524dbe76197f4c5122f0f99c6967f7c969ac978fcae37d48dbd6432827c0`

## Development commands

Install matching export templates for release builds. See [developer setup](DEVELOPMENT.md) for installation and Android tooling.

```sh
GODOT_BIN=/path/to/godot tools/test.sh
GODOT_BIN=/path/to/godot tools/release.sh
```

For a signed Android export, set `ANDROID_HOME`, `JAVA_HOME`, `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. Keep the same signing key and increase Android's `version/code` for each published update. Keep the version in `project.godot` and the export presets in sync with the release tag. Windows updates use the published ZIP and `SHA256SUMS.txt`. The script writes packages and checksums to `dist/`.

The streets, businesses, characters, artwork, and arcade moves are original fictional content. The game and original assets are [MIT licensed](LICENSE). Godot and the bundled [DejaVu font](assets/DejaVu-LICENSE.txt) have their own notices.

Gabby is available in **Service → Team & Payroll → Hire Gabby**. Her ฿1,200
ten-day bartender contract uses a normal team slot. Each drink she actually
serves adds ฿5 to the nightly tip jar, alongside existing visit and drink bonuses.

## Staff contracts and waiting-order alerts

This update adds ten-day staff contracts, individual training that survives
rehiring, measured 25/20/15-second service, and a waiting-order bell. Hiring and
rehiring now cost ฿1,200 for bartenders (hosts/dancers remain ฿4,500); leases now follow the Beer/Hostess/Gogo ladder documented above, with room reserved for
the new hiring reserve and training costs. Existing hires and training migrate,
and offline projections stop crediting staff service at contract expiry. See the
[player guide](docs/PLAYER_GUIDE.md) and [economy rules](docs/ECONOMY.md).

## More room and a face out front

The compact layout, whole-pack stocking and Nida's contract now use the shared
economy, including guided shifts, save migration and managed estimates. Her four
production poses and portrait join the existing art; compact benches visibly mark
the third seating purchase. This update also brings the earlier TV installation
and urgent-order marker fixes into the same release branch.

## Easier first hire, colder beer and bulk buying

Bartender contracts now match Nida’s ฿1,200 upfront price, including renewals.
Saving for the bartender first reaches the hire in 4.2–4.7 minutes in three fresh
campaign tests. Existing training and contract time are preserved. Fridges earn extra reputation
through satisfied visits. Supplier level 2 buys twelve drinks at a cheaper unit
price, requiring all twelve spaces and the full ฿432 bill. Higher levels retain
the twelve-unit minimum. Saved inventory keeps its original paid cost.

Once Nida is on duty, faster Welcome offers no extra attraction. Those upgrades
only help when she is off duty or out of contract; Chat still recovers in twenty
seconds. Service now explains this beside the upgrade.

## A reason to reach day seven

**Anong's Birthday** is free, runs from noon on day seven until 1am, and is
advertised beforehand in Service, Events and the street banner. The Blue Hour
gets extra appeal, +40% shared street traffic, quicker repeat orders and up to
three drinks per visitor if their budget permits. New party visitors stay and
wait a little longer. Fill the fridge and prepare your service; normal prices,
costs and capacity still apply.

Regulars' reunions, Pim's mixtape parties and Bo's thank-you nights follow every
seven game days. Events and Journal show actual party trading and new regulars;
there is no payout button. Offline time cannot spend the event or replay its bonus.
[Design and balance](docs/design/WEEKLY_CELEBRATIONS.md) explain the trade-offs.

**Does reputation help?** Yes: it improves your share of visiting customers,
which can create more total orders. It does not increase each customer's budget
or order frequency. Music and celebrations affect repeat-order timing.

## See your bartender working

The bottom-right **BAR STAFF** indicator shows actual staff drinks served,
a short confirmation after each sale, readiness, cooldown and stock/rota problems.
Tap it to open Service. Staff sprites use their serving pose after actual sales.
Counters begin at hiring or this update and exclude owner taps and offline estimates.

A bartender starts ready. If an order and stock are available, she serves on the
next simulation tick, then recovers for 25 seconds (20/15 with basic training, 12/10 with stage-two training). Empty
queues and owner clicks do not restart her cooldown. Quiet time readies one
serve, never a burst of banked sales. Staff get first chance at an order when
purchased owner auto-serve is also ready; owner manual taps retain their own timer.
Auto-serve now costs **฿3,000**. Previously owned automation stays owned.

## Bartenders lead; the owner covers the rush

With auto-serve on, staff serve first. Quiet orders wait for the bartender;
owner automation helps when the queue exceeds the number of on-duty bartenders,
or a guest has ten seconds or less left and staff cannot recover in time.
Without an available contracted bartender it covers normal service. Manual taps
remain available and share the owner's unchanged cooldown. The price stays
฿3,000 while this division of work is evaluated.

Nida's **Rehire** button now sits directly under **Frontage promoter**, with the
full cash requirement and exact shortfall. Her ฿1,200 renewal also requires a
reserve for two minutes of payroll and one current-price delivery. For a basic
bar without other staff this means ฿1,464 cash: ฿1,200 paid, ฿264 retained.
Active contracts cannot be renewed early; use her rota if she is off duty.
Expiry refreshes the controls, and rehiring retains her training and roster slot.

## A clearer path, less saving between milestones

**Anong's Next Step**, near the top of Service, follows the real campaign: the
first rounds, a returning customer, renovation, the reopening, Dao's appointment,
expansion and the festival. **Show next step** opens the relevant tab or purchase
section without spending anything. Progress is read from the existing save;
there is no checklist payout or extra compulsory purchase.

Bartender training costs **฿400 / ฿800**, then **฿1,200 / ฿1,600** from stage two. The first manager costs **฿8,000**. Stage-three renovations cost **฿40,000 / ฿65,000 / ฿120,000** for
beer / Soi / gogo venues, requiring **450 happy visits, 70 regulars and 40 healthy
shifts at that venue**, plus the operating reserve. Stage-two gates and prices
are unchanged. Existing upgrades stay owned, with no retroactive refunds.

Regulars Club starts at **฿600** from stage two, giving regular visitors a reason
to stay for another paid round while you save for management. See the
[stage-two income design](docs/design/STAGE_TWO_INCOME.md) for the costs, limits
and measured trade-offs. Human feedback is still needed on the revised pacing.

## Closing clean-up and tomorrow's opening

After the last venue closes for the night, a free **15-second clean-up** starts
for all dirty venues, including those without a manager. A visible street button
counts down to noon. **Stay here** cancels the automatic jump for that night;
cleaning continues, and **Skip to 12pm** remains available when you are ready.
Even an already-clean street gives you the full fifteen-second choice.

The countdown waits for late-trading venues to finish. Daytime closure and a
temporary event closure cannot end an otherwise scheduled late night. It advances
only during foreground street play, never on the start menu or through offline
estimates; its countdown pauses while the street is hidden by district/arcade
views. Normal clock rules still apply. Schema 10 preserves the remaining time
and cancellation across reloads; older saves start with no pending countdown.

At zero, completed cleaning is retained and the existing skip moves the clock
to noon. Stock is not bought, no income is awarded, and contracts age through the
skipped hours as before. Owner-closed or cash-shortage-closed venues stay closed.
The date already advanced at midnight, so the jump does not add another day.

## Anong counts the tip jar

Each customer visit earns **฿10 on its first successfully served drink**. Extra
rounds do not tip again. Serving a guest’s requested specialty drink on their first round can add a **฿5 bonus**.
Anong counts the jars at nightly closure before the fifteen-second clean-up.
The fridge, Service and Journal show the pending amount and payout history. Cancelling the jump, reloading
or reopening the report cannot pay twice. Offline estimates earn no tips.

For **zero stock and too little cash for a pack**, Service now shows **Bo's
recovery delivery · 6 drinks** beside the stock control. It costs nothing upfront:
฿14 is repaid on each sale, staff go off duty and Anong covers two minutes of
overhead. Existing orders remain. That gets a ฿39 till trading again immediately;
nightly tips help fund the next opening. Normal deliveries still require the full
pack price and room. See the [tip/recovery design](docs/design/NIGHTLY_TIPS.md).

## Contract-only promotion and quicker pool

Nida now keeps only her ฿1,200 ten-day contract fee: no drink commission and no
hourly wage. Existing waiting orders and offline sales are also commission-free;
previously paid commission stays in historical reports without a refund.
New pool games take **30 seconds**, still **฿50 per table once at the start**.
Free Pool remains free. Games already underway retain their saved remaining time.

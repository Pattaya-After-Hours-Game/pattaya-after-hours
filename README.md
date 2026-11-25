# Pattaya After Hours

Start with six stools, a warm fridge and a sign that reads **BLUE HO**. Build the Blue Hour into a thriving beer bar, then own a mixed street of Soi-style bars and gogos. Anong wants a business that lasts. Anton wants a bigger LED screen. Godzilla wants a cold one.

**[Get it on Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522io.github.rknell.pattayaafterhours%2522%252C%2522url%2522%253A%2522https%253A%252F%252Fgithub.com%252FPattaya-After-Hours-Game%252Fpattaya-after-hours%2522%252C%2522author%2522%253A%2522Pattaya-After-Hours-Game%2522%252C%2522name%2522%253A%2522Pattaya%2520After%2520Hours%2522%257D)** · **[Android APK](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest/download/PattayaAfterHours.apk)** · **[Desktop downloads](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest)**

![The Blue Hour and its neighborhood at dusk](docs/blue-hour.png)

This source includes the full customer cast, New Game / Resume, the day/night
clock, owner cooldowns/Chat and retained staff training. Recent updates add music, auto-serve, two-second pouring, supplier discounts,
manager income and a five-second ฿/s display, alongside
a twelve-person compact beer-bar layout, six-pack deliveries and Nida, an adult
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
→ reinvest.** You start with ฿200, eighteen drinks and three opening customers.
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

Buy stock in complete **six-drink packs, starting at ฿84**. You need room for all six and
enough cash; the button explains any shortfall. Supplier automation uses the
same pack size; supplier levels 2–5 reduce pack prices to ฿72/60/48/36. Stage-1 beer bars can buy a third seating level, **Compact layout
for ฿1,200**, reaching twelve customers even with pool and fans installed.

Save for signage, seating and a pool table, then invest in staff contracts. Pool is available at
beer-bar stage 1: **฿50 per table per 45-second game**, charged once. Free Pool
Night attracts visitors but gives up pool fees; Happy Hour, Pool Tournament and
Sports Night have their own costs and trade-offs. Promotions last two minutes,
then have a two-minute cooldown.

Bartenders serve orders; hosts and dancers attract visitors. Their hiring or rehiring
costs **฿4,500 for ten game days**, plus on-duty wages. A base bartender serves
one drink every **25 seconds**; individual training improves this to 20 and then
15 seconds. Help serve during a rush. Contracts expire, but each person's training
stays with them when rehired. Service shows the remaining term and rehire controls.
Closed hours, skipped nights and offline time count toward contracts.

In **Service → Frontage promoter**, hire **Nida for ฿1,200 per ten game days plus
10% of drink receipts**. She replaces Welcome taps, uses a separate roster slot
and never serves drinks. Her preview shows estimated demand, commission and net
profit with and without owner service. Bringing more customers to an already
slow bar can lose money. Existing visit/order commissions remain due after she
goes off duty. Promoters and dancers unlock separate audience training at stages
2 and 3 for ฿800 and ฿1,600; their skills survive rehire.

A two-note bell alerts you to waiting orders at the selected venue, repeating at
most once every ten seconds. **Sound / Muted** controls it along with game audio.
Staff cost money while on duty, even when the bar is quiet. Use the rota or temporarily close if
costs outrun sales. An owner-run recovery shift offers a way back from an empty
till. Renovations need satisfied customers, local regulars, healthy shifts and
cash for the next shift—not just a large bank balance.

## Music, automation and management income

| Purchase | Price and effect |
| --- | --- |
| Music system | ฿1,200; repeat drink orders after 25 seconds instead of 35. Visitors still need budget, stock and service. |
| Auto-serve | ฿6,000 per venue; automatically uses the existing Serve timer. Manual taps share it. Toggle it in Service. |
| Two-second pouring | ฿5,600 after the existing pouring tiers, from venue stage 2. Welcome still stops at four seconds. |
| Manager levels 1 / 2 / 3 | ฿18,000 / ฿36,000 / ฿72,000 incremental purchases; ฿10 / ฿20 / ฿40 per game minute (real second) while open. Level 1 needs stage 2; later levels need stage 3. |
| Supplier levels 1–5 | ฿900 / ฿1,200 / ฿2,400 / ฿4,800 / ฿9,600; six-pack prices ฿84 / ฿72 / ฿60 / ฿48 / ฿36. |

Manager income is separate from drink/pool receipts, uses no stock and pays no
drink commission. It stops on closure and does not grant satisfied customers.
Operating costs still apply. Managed offline estimates include it during legal
opening windows. Existing appointments are retained as level 1.

The **฿/s beneath the till** refreshes every five foreground seconds and shows
net street trading: receipts minus stock purchases, operating costs, commission
and fines. It excludes equipment/contract purchases and offline lump sums.
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
real seconds; managers start it automatically. Dirt from drink sales reduces
attraction by up to 25%. Once every venue stops trading after 1am, **Skip to
12pm** is available even with unfinished prep. Skipping cancels incomplete
cleaning and buys no stock. Noon never reverses your own closure or a shutdown
from insufficient cash.

## Build the street

| Venue | Identity | Three stages |
| --- | --- | --- |
| Beer bar | Affordable drinks, pool and regulars | Plastic Chairs & Big Dreams → The Local Favourite → Soi Institution |
| Soi 6-style bar | Hosted nightlife and repeat visitors | Something Upstairs → The Busy Staircase → Soi Royalty |
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
| Toybox | A/D or arrows to move, W/Up to jump, S/Down to guard, J/K/L to jab/kick/Burst; mobile touch controls |
| Godzilla | **Serve a shot** or Space; ten shots before the timer ends |

Each launch opens a **New Game / Resume** menu. **Resume** continues your saved
campaign and is disabled when no readable save or backup exists. **New Game**
starts over; if a save exists, confirm to permanently replace its progress and
remove its backup. There is one campaign slot per device. The street stays
paused on the menu, and offline estimates are claimed only when you resume.

The game autosaves after decisions and every fifteen seconds, and on normal
close or application pause. New games are saved immediately. Older campaigns
retain money, staff, venues and owned stages when migrated to save schema 7.
Pre-clock saves start at noon on the existing day, with initially clean venues.
Schema 7 adds purchased automation, music, supplier/manager levels, inventory
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
customers and clock. **Tutorial** runs the older decision lessons in an isolated
practice campaign and never overwrites your campaign.

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

The current source includes 72 runtime textures, twenty-two sprite atlases with
149 frames, nine interiors and nine matching exterior illustrations. Gameplay,
save migration, boot-menu isolation, action/staff timing and art/input regressions
are checked together with thirty-nine fresh-campaign simulations. Baseline active
runs reach stage 2 in 34–37 minutes, a second venue in 135–147 minutes and stage 3
in 186–199 minutes. Optional promoter-first investment takes longer to repay;
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

## Staff contracts and waiting-order alerts

This update adds ten-day staff contracts, individual training that survives
rehiring, measured 25/20/15-second service, and a waiting-order bell. Hiring and
rehiring use the agreed ฿4,500 fee; the first Soi lease is ฿16,000 to accommodate
the new hiring reserve and training costs. Existing hires and training migrate,
and offline projections stop crediting staff service at contract expiry. See the
[player guide](docs/PLAYER_GUIDE.md) and [economy rules](docs/ECONOMY.md).

## More room and a face out front

The compact layout, whole-pack stocking and Nida's commission now use the shared
economy, including guided shifts, save migration and managed estimates. Her four
production poses and portrait join the existing art; compact benches visibly mark
the third seating purchase. This update also brings the earlier TV installation
and urgent-order marker fixes into the same release branch.

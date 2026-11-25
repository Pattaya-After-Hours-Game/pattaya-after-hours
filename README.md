# Pattaya After Hours

Start with six stools, a warm fridge and a sign that reads **BLUE HO**. Build the Blue Hour into a thriving beer bar, then own a mixed street of Soi-style bars and gogos. Anong wants a business that lasts. Anton wants a bigger LED screen. Godzilla wants a cold one.

**[Get it on Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522io.github.rknell.pattayaafterhours%2522%252C%2522url%2522%253A%2522https%253A%252F%252Fgithub.com%252FPattaya-After-Hours-Game%252Fpattaya-after-hours%2522%252C%2522author%2522%253A%2522Pattaya-After-Hours-Game%2522%252C%2522name%2522%253A%2522Pattaya%2520After%2520Hours%2522%257D)** · **[Android APK](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest/download/PattayaAfterHours.apk)** · **[Desktop downloads](https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours/releases/latest)**

![The Blue Hour and its neighborhood at dusk](docs/blue-hour.png)

The current source combines the customer economy and completed graphics refresh.
Release downloads are published separately; this README describes the source in
this checkout.

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
seconds. **Have a chat** buys an urgent waiting guest ten more seconds; it shares
Welcome’s timer and takes twenty seconds to recover. No order means no sale. Open **Service** to see demand, service speed, occupancy,
stock, payroll and recent actual profit.

Inside the scene, customers stand on the public side of the bar, bartenders
work behind the counters, and gold dots above customers mark waiting orders.
The smaller passerby in the left street opening is background traffic, not an
extra customer. Messages sit above the room so the floor remains visible.
The customer cast includes older regulars and Indian, Korean, Black and Thai
visitors, with outfits ranging from scruffy holiday wear to tailored clubwear.
Looks stay consistent during each visit and do not determine spending behaviour.
Wall fans appear only after buying **Fans & comfortable seats**, including in
the property thumbnail; renovation alone does not install them.

Save for signage, seating, a bartender and a pool table. Pool is available at
beer-bar stage 1: **฿50 per table per 45-second game**, charged once. Free Pool
Night attracts visitors but gives up pool fees; Happy Hour, Pool Tournament and
Sports Night have their own costs and trade-offs. Promotions last two minutes,
then have a two-minute cooldown.

Bartenders serve orders; hosts and dancers attract visitors. Staff cost money
while on duty, even when the bar is quiet. Use the rota or temporarily close if
costs outrun sales. An owner-run recovery shift offers a way back from an empty
till. Renovations need satisfied customers, local regulars, healthy shifts and
cash for the next shift—not just a large bank balance.

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
retain money, staff, venues and owned stages when migrated to save schema 5.
Pre-clock saves start at noon on the existing day, with initially clean venues.
Schema 5 preserves fractional action timers and chat allowances; old venues
start with unpurchased action upgrades. A fresh campaign is
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
| [Merge handover](docs/MERGE_HANDOFF.md) | Combined branch, test results and maintainer review notes |
| [Changelog](CHANGELOG.md) | Progression, economy, graphics and documentation changes |

## Project status

The current source includes 69 runtime textures, twenty-one sprite atlases with
145 frames, nine interiors and nine matching exterior illustrations. Gameplay,
save migration, art integrity, input and nine fresh-campaign pacing simulations
passed during the completed-art integration. Linux startup and Android debug
export/signature checks passed. Android device and Windows/macOS execution still
need target-platform playtesting. See the testing document for the verification
record and scope; export success is not device certification.

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

# Pattaya After Hours

Start with six stools, a warm fridge and a sign that reads **BLUE HO**. Build the Blue Hour into a thriving beer bar, then own a mixed street of Soi-style bars and gogos. Anong wants a business that lasts. Anton wants a bigger LED screen. Godzilla wants a cold one.

**[Get it on Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%257B%2522id%2522%253A%2522io.github.rknell.pattayaafterhours%2522%252C%2522url%2522%253A%2522https%253A%252F%252Fgithub.com%252Frknell%252Fpattaya-after-hours%2522%252C%2522author%2522%253A%2522rknell%2522%252C%2522name%2522%253A%2522Pattaya%2520After%2520Hours%2522%257D)** · **[Android APK](https://github.com/rknell/pattaya-after-hours/releases/latest/download/PattayaAfterHours.apk)** · **[Desktop downloads](https://github.com/rknell/pattaya-after-hours/releases/latest)**

![The Blue Hour and its neighborhood at dusk](docs/blue-hour.png)

## Play

Incident cards show odds and effects at a glance. Tap **Story** to read the setup. Results appear below the map, and **Shift log** in closeout opens the full decision history.

- **Serve → upgrade → hire → automate → expand.** Tap **Serve a drink** for immediate income. Hire servers, hosts or dancers to serve every four seconds; arrange deliveries, then appoint a manager for offline earnings. Select properties by tapping their buildings or through **Empire**.
- **Three types, three stages each.** Beer bars grow from plastic stools to live-music institutions. Soi-style bars add hosted drinks, bar fines and upstairs rooms. Gogos grow from a single pole to a headline showroom. Each stage has different artwork, earning power and a story beat. Adult activity stays off-screen; hosts choose whether to accept requests and are unavailable for the rest of the shift after accepting.
- **Own the soi.** Acquire up to eight separate properties. Beer bars stay beer bars; unlock Soi venues at 20 reputation and gogos at 45. Finish the opening chapter before expanding. Tours and crypto are never required.
- **Milestone story.** Reopen the Blue Hour, give Dao the keys, buy another bar, enter Anton's neon arms race, then bring all three types to stage 3 for the **After Hours Street Festival**. Completing the festival leaves the street open for continued play and repeat events. There is no forced one-year ending.
- **Prepare for the unexpected.** Blackouts, Navy shore leave, inspections, floods, Songkran, a viral bar crawl, low season, Anton's promotions and Godzilla arrive with a 60-second warning. Tap the pink event banner or open **Events** to prepare. Ordinary events last 90 seconds. Monster events offer a timed serving challenge; damage causes a short, recoverable closure.
- **Idle income.** A foreground street shift lasts two minutes; host availability resets at the next shift. Managed venues earn up to eight hours of offline net profit. Offline time never advances events or the calendar. Existing closures and unavailable hosts remain paused while away. Live net rates include stock, wages and overhead; restocking still needs cash in the till.
- **Optional managed shifts.** Scroll down in **Service** to **Open managed shift** for the original early-service/rush/last-call simulation, with its own stock, rota and weekly bills. Street time pauses during those decisions. **Tutorial** teaches this optional mode in an isolated practice save.
- **Keep exploring.** Walk the district, book voluntary tours, or visit Events for Toybox sparring and the arcade circuit. Existing mining rigs remain available under Empire.

The game plays offline and autosaves after decisions and every 15 seconds. Version-one campaigns automatically retain their finances, staff, capped renovations and second lease in the new street model. Previously ended campaigns reopen. Saves retain a backup; the tutorial never overwrites your campaign.

| Where | Controls |
| --- | --- |
| Street | Click/tap **Serve a drink**; tap a property to select it. Scroll the right panel for upgrades and management. |
| Street events | Tap the pink banner or open **Events**. Prepare before the countdown; use **Face Godzilla** when a monster arrives. |
| District | WASD/arrows to walk, E to enter, Esc to return. On touch, tap a destination. |
| Toybox | A/D or arrows to move, W/Up to jump, S/Down to guard, J to jab, K to kick, L to Burst. Android has touch controls. |
| Godzilla | Click/tap **Serve a shot** or press Space. Ten shots before the timer expires; preparation adds four seconds. |

## Install

- **Android.** Use the Obtainium button, or add `https://github.com/rknell/pattaya-after-hours` as the source in Obtainium. The signed APK supports Android 7.0 and later on ARM64 and x86-64. Package ID is `io.github.rknell.pattayaafterhours`.
- **Linux x86-64.** Extract the ZIP and run `PattayaAfterHours.x86_64`.
- **Windows x86-64.** Extract the ZIP and run `PattayaAfterHours.exe`. The executable is unsigned.
- **macOS Intel and Apple Silicon.** Extract the ZIP and open the app. The build is ad-hoc signed and has no Apple notarization.

APK signing certificate SHA-256

`4a72524dbe76197f4c5122f0f99c6967f7c969ac978fcae37d48dbd6432827c0`

## Build from source

Open `project.godot` in Godot **4.7.2** and press F5. Install matching export templates for release builds.

```sh
GODOT_BIN=/path/to/godot tools/test.sh
GODOT_BIN=/path/to/godot tools/release.sh
```

For a signed Android export, set `ANDROID_HOME`, `JAVA_HOME`, `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. Keep the same signing key and increase Android's `version/code` for each published update. The script writes packages and checksums to `dist/`.

The streets, businesses, characters, artwork, and arcade moves are original fictional content. The game and original assets are [MIT licensed](LICENSE). Godot and the bundled [DejaVu font](assets/DejaVu-LICENSE.txt) have their own notices.

## Development update — 25 November 2026

Implemented **From One Bar to the Whole Soi**, turning the Blue Hour campaign into a playable idle bar business:

- Added beer bars, Soi 6-style bars and gogos, each with three upgrade stages, distinct interiors, better earning potential and new story beats.
- Added click-to-serve income, automated staff service, paid stock deliveries, managers and up to eight hours of offline net earnings.
- Added eight separately owned street properties, reputation-based venue unlocks, adult host preferences and shift-based availability after accepted bar-fine requests.
- Added five milestone chapters featuring Anong, Dao, Pim, Mali, Bo and Anton, culminating in a repeatable After Hours Street Festival.
- Added advance warnings and preparation for blackouts, Navy visits, inspections, floods, Songkran, viral crowds, low season, rival promotions and Godzilla. Setbacks are recoverable, and offline time never advances disasters.
- Added version-two saves with migration of existing campaigns; removed the mandatory one-year ending while retaining optional managed shifts, district exploration, tours and Toybox fights.
- Added economy, progression, event, offline-income, migration and UI regression tests, plus a graphical preview harness covering all nine venue stages and festival states.

Validation includes the automated Godot suite and rendered desktop previews. Android device playtesting and longer-term economy balancing remain follow-up work. The separate artwork refresh is not included in this gameplay update.

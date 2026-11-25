# Developer setup and handover

For the premise and cast, see [story.md](story.md). For gameplay help, see the
[player guide](docs/PLAYER_GUIDE.md). [Testing and release checks](docs/TESTING.md)
records coverage and remaining platform verification.

Pattaya After Hours is an offline Godot/GDScript game. The entry point is
`project.godot` → `main.tscn` → `scripts/main.gd`. There is no web server,
database, npm install, Python virtual environment, or .NET dependency.

## Requirements

| Work | Required tools |
| --- | --- |
| Edit, play, and test | **Godot 4.7.2 standard build**, Git; Bash for repository scripts |
| Linux installer | Linux x86-64, `curl`, `unzip`, `sha256sum`, `awk`; internet for downloads |
| Desktop exports | Matching **4.7.2.stable export templates**, `zip`, `unzip` |
| Android debug export | Templates, JDK 17, Android SDK with platform-tools and compatible build-tools |
| Android release export | Android tooling plus the existing release signing key and credentials |
| Regenerate audio | Python 3 and FFmpeg; neither is needed to play or run tests |

The engine version is pinned in `.godot-version`. Use the standard build:
all game logic is GDScript. The project uses the GL Compatibility renderer,
a 960 × 540 logical canvas, and landscape mobile orientation.

## Fresh Linux x86-64 machine

Clone the repository, then run from its root:

```sh
git clone https://github.com/Pattaya-After-Hours-Game/pattaya-after-hours.git
cd pattaya-after-hours
tools/setup-linux.sh --templates
export PATH="$HOME/.local/bin:$PATH"
export GODOT_BIN="$HOME/.local/bin/godot-$(cat .godot-version)"
"$GODOT_BIN" --version
tools/test.sh
"$GODOT_BIN" --editor --path .
```

Press **F5** in Godot to play and **F8** to stop. The editor includes a
GDScript editor and debugger. To play directly, use `"$GODOT_BIN" --path .`.

`tools/setup-linux.sh` without `--templates` installs only the editor, which
is enough for coding and tests. Both modes verify downloads against the
committed SHA-256 manifest. Downloads are cached for reuse. Allow roughly
4 GB for downloaded archives, the editor, and extracted templates, plus
space for exported builds.

The installer uses these user-owned locations and needs no sudo:

- Editor: `~/.local/opt/godot/4.7.2/`
- Command: `~/.local/bin/godot-4.7.2`
- Convenience command: `~/.local/bin/godot`, created only if that path is unused
- Templates: `${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.7.2.stable/`
- Archives: `${XDG_CACHE_HOME:-$HOME/.cache}/pattaya-after-hours/setup/`

It does not edit shell startup files or install Android/Java tooling. If
`godot` resolves to another version, use `GODOT_BIN` explicitly as above.

On Windows, macOS, or Linux ARM, install the matching editor from the
[official 4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable),
import `project.godot`, and install matching templates through **Editor →
Manage Export Templates**. The shell scripts require a Bash environment;
the Linux installer itself only supports x86-64 Linux.

## Daily development and checks

```sh
tools/test.sh
git diff --check
git status --short
```

Set `GODOT_BIN` if the pinned editor is not the default `godot` command.
The test script imports assets, then runs `tests/check.gd`, nine target campaigns plus six no-chat comparisons in
`tests/economy_balance.gd`, and twelve feature/alternative campaigns in
`tests/promoter_balance.gd`, plus fifteen music/automation/supplier/early-hire campaigns in
`tests/automation_balance.gd` (42 total), then 60 paired ordinary/party scenarios
in `tests/celebration_balance.gd`. It uses temporary
data and configuration directories, preserving your campaign and editor
settings. Run this wrapper rather than running the test script directly:
the tests deliberately create, corrupt, and remove test saves.

Coverage includes all 51 incident cards and their responses, a campaign continuing beyond 365 days, weekly accounts, deterministic save/reload and backup recovery,
management tabs, district navigation, combat damage/guard behavior, tutorial
isolation, Godzilla success/failure, all street chapters, offline income caps,
legacy migration, host availability and announced events. These are headless checks; also play
the affected screens when changing visuals, controls, audio, or mobile layout.

## Code map and gameplay

| File | Responsibility |
| --- | --- |
| `scripts/main.gd` | Programmatically built management UI, tabs, tutorial, audio, minigame transitions, Godzilla timer |
| `scripts/campaign.gd` | Campaign dictionary, actions, service simulation, accounting, endings, RNG, saves |
| `scripts/street.gd` | Shared clock/calendar, nightly hours, raids, properties, chapters and events |
| `scripts/economy.gd` | Trading availability, cleaning, customers, pool, promotions, ledgers and offline projections |
| `scripts/street_content.gd` | Venue stages/peaks, clock/raid tuning, chapter goals, event stories and host preferences |
| `scripts/content.gd` | Six staff profiles, events, tours, weather, 51 incident cards, 15 story beats |
| `scripts/city.gd` | Layered venue interiors, available workers, event treatments and Godzilla |
| `scripts/district.gd` | Walkable neighborhood and links back to management tabs |
| `scripts/windows_updates.gd` | Windows release checks, verified executable staging and update worker |
| `scripts/fight.gd` | Mali's Toybox fights, three opponents, AI, keyboard/touch controls and timed sprite states |
| `tests/check.gd` | Campaign and UI regression checks |
| `tools/audio.py` | Rebuilds the committed music and sound effects |

The default `plan` phase is the live customer economy, with two-real-minute
trading reports and a clock advancing one game minute per real second. Midnight,
not the report boundary, advances the calendar. `scripts/economy.gd` owns shared arrivals, occupancy, orders, pool games,
stock, timed payroll, promotions and forecasts. Manual clicks and bartenders can
only serve real orders. Hosts and dancers attract customers. The UI reports
actual net separately from forecast automatic income. See [the economy guide](docs/ECONOMY.md).

Guided shifts share the same customers, stock and ledger, with decisions at 0,
40 and 80 seconds. The original incident-based shift is retained only for isolated
tutorial practice and completing older in-progress saves. Godzilla is announced
through the street event system, including the repeatable festival.

Milestone chapters replace the day-based story schedule. The old story cards
remain readable for saved incidents. Debt no longer forces a game over; idle
trade can fund repayment in Empire. The campaign continues past day 365.

GDScript composes the generated texture catalog with live customers, pool timers,
role-aware staff animation and event effects.
Keep mouse, keyboard, touch, scrolling, and Android back behavior in mind
when changing interface code.

## Saves and settings

On default Linux installations, campaign files live at:

```text
~/.local/share/godot/app_userdata/Pattaya After Hours/
    campaign.json
    campaign.backup
    settings.cfg
```

Godot's `user://` path varies by OS and `XDG_DATA_HOME`. Back up both campaign
files before experimenting with save changes. Writes use a temporary file,
preserve a backup, and store RNG state so decisions resume deterministically.
Staff records retain individual training, service progress and contract minutes.
Old staff inherit their venue training; their missing contract fields migrate to
a ten-day term before normal offline catch-up. Expiry keeps the record available
for manual rehire. Regenerate the original waiting bell with
`python3 tools/order-chime.py` (standard library only).
Campaign fights reload at the beginning of the bout.

Changes to the save flow must preserve the boot menu's read-only state: startup probes the save and
backup, but only Resume claims offline time and checkpoints it. New Game and
in-game restart write a fresh campaign immediately without retaining the old
campaign as a recovery backup. No simulation, autosave or application-resume
claim runs while the boot menu is open.

Schema 5 adds `tick_fraction`, per-venue action levels and refill durations, and
per-customer chat state. Action deadlines are fractional foreground seconds;
`_restore_numbers` preserves these explicit fields while restoring legacy integers.
`Street.advance(delta)` drives fixed one-second simulation steps from frame time.
Do not run both `advance` and `tick` for the same elapsed interval.

Changes to the save dictionary need compatibility handling; the current schema
version is 7. Promoter roster/commission fields and fractional offline accounting
are migrated without granting purchases. Keep whole-pack delivery and commission
settlement inside `economy.gd`; UI/animation code must not mint receipts.
Manager income is a separate model-owned receipt, not a drink. Stock lots retain
paid costs across supplier upgrades. The five-second net sampler runs only in
the shared foreground clock; UI reads its last sample without awarding anything. `Street.new(state)` migrates version-one/two
properties, stages, hires and finances. Older stage-2+ beer bars receive their
pool table; queues start empty. Existing version-three pool games gain stable
table IDs without changing fees or timers. Load validates
the street shape, v4 clock/prep fields, v5 action timers/levels and v6 promoter/
commission fields plus v7 automation, tier, inventory-cost and rate-sample fields
before accepting a save. Version-three
queues, stock, promotions, paid/free pool identity, money and owned progress are
preserved; migration starts at noon on the existing day with clean venues. New
saves retain nightly permissions, raid counters, cleaning progress, heat cooling
and the separate offline projection cursor. Raids request an immediate save
after the completed live tick. Offline credit is claimed in the UI
on choosing Resume or resuming an active application and saved immediately;
foreground saves move the timestamp watermark forward. Tutorials remain isolated.

## Desktop builds

```sh
env -u ANDROID_HOME -u JAVA_HOME tools/release.sh
```

This exports Linux x86-64, Windows x86-64, and universal macOS archives into
ignored `dist/`, adds license notices, produces `SHA256SUMS.txt`, and runs a
headless smoke test of the Linux executable. It does not publish releases.
Windows is unsigned; macOS uses ad-hoc signing and is not notarized. Building
those archives on Linux does not replace testing them on their target OS.

## Android development and releases

Install JDK 17, for example [Eclipse Temurin](https://adoptium.net/temurin/releases/?version=17),
and the [Android SDK command-line tools](https://developer.android.com/studio#command-tools).
In Godot **Editor Settings → Export → Android**, configure:

- Java SDK Path: the JDK directory containing `bin/java` and `bin/keytool`.
- Android SDK Path: the SDK directory containing `platform-tools/adb`.

For this pinned engine, API 36 and build-tools 36.1.0 are the setup used on
this machine. With command-line tools installed, they can be installed using:

```sh
export JAVA_HOME="$HOME/.local/opt/java/temurin-17"  # Adjust for your JDK.
export ANDROID_HOME="$HOME/Android/Sdk"             # Adjust for your SDK.
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  --sdk_root="$ANDROID_HOME" \
  "platform-tools" "platforms;android-36" "build-tools;36.1.0"
mkdir -p dist
godot-4.7.2 --headless --path . --export-debug Android dist/PattayaAfterHours-debug.apk
```

The current preset uses prebuilt APK templates (`gradle_build/use_gradle_build=false`),
so custom Gradle, NDK, and CMake setup is not needed for this workflow.
Godot creates a local debug keystore. A debug APK cannot update an installed
release APK signed with a different key. Use a separate test device/profile
when preserving an existing installation's data matters.

For a release, obtain the existing signing key through the project's secure
handover channel. Set `ANDROID_HOME`, `JAVA_HOME`, and:

```text
GODOT_ANDROID_KEYSTORE_RELEASE_PATH
GODOT_ANDROID_KEYSTORE_RELEASE_USER
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

Then run `tools/release.sh`. Do not put credentials in commands committed to
Git. Retain the existing package ID and signing identity, and increase
Android `version/code` before publishing. The existing release script enables
Android when both SDK/JDK variables are set and requires release credentials;
use the desktop-only command above when those credentials are unavailable.

References: [Godot Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
and [4.7.2 Android exporter source](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/export/export_plugin.cpp).
The pinned source is authoritative for version-specific SDK defaults.

## Automatic releases

Every push to `main` runs the campaign checks and exports the Windows, Linux,
macOS and signed Android builds. GitHub publishes a release after the files and
checksums are ready. The workflow run number sets the patch version and Android
version code without committing version changes. Retry a failed run from the
Actions tab to reuse its version.

The `game-release` GitHub environment is limited to `main`. Its
`ANDROID_KEYSTORE_BASE64` and `ANDROID_KEYSTORE_PASSWORD` secrets provide the
existing Android signing identity. The workflow checks the APK against the
published signing certificate before release. Manual exports still work as
shown above. Avoid hand-numbering public releases in parallel with the workflow.

## What to include in the repository

- `project.godot`, `main.tscn`, all `scripts/*.gd`, and their `.gd.uid` files.
- Original `assets/`, including the font, audio, icons, and `.import` sidecars.
  Godot generates the imported cache separately under `.godot/`.
- `tests/`, executable `tools/` scripts, `.godot-version`, the checksum
  manifest, and `.github/workflows/test.yml`.
- `export_presets.cfg` with portable options and no signing secrets.
- `README.md`, this guide, screenshots in `docs/`, and license notices for
  the game, Godot, and bundled font.
- Any new source assets, generation scripts, and licenses needed to reproduce
  a change. Document additional dependencies and the command used to verify it.

Keep `.godot/`, `dist/`, personal saves, editor settings, downloaded engines,
SDKs, JDKs, signing keys, passwords, and local environment files out of Git.
The current ignore rules exclude build caches, exports, and common keystore
extensions; add appropriate rules before introducing other local files.

When upgrading Godot, update `.godot-version`, `project.godot` feature version,
this guide/README, installer checksums, the CI version checksum, and any
version-specific settings filename in `tools/release.sh` together. Reinstall
matching templates and run tests plus exports before handing over.

## This machine

Prepared on **25 November 2026**, Ubuntu 26.04.1 x86-64:

- Original graphics workspace: `/home/zak/projects/pattaya-after-hours`.
- Consolidated gameplay/art/build checkout: `/home/zak/projects/pattaya-release-integration`.
  Check `git branch --show-current` before editing or building.
- Godot: `/home/zak/.local/bin/godot-4.7.2` (also available as `godot`).
- Matching templates installed in the standard user template directory.
- JDK 17: `/home/zak/.local/opt/java/temurin-17`.
- Java commands (`java`, `javac`, `keytool`, `jar`, `jarsigner`) linked in
  `/home/zak/.local/bin` for terminal use.
- Existing Android SDK: `/home/zak/Android/Sdk`; paths configured in Godot.
- Application-menu shortcut: **Pattaya After Hours — Godot Editor**.
- No production Android signing key was installed as part of setup.

Verified during setup: the full automated suite passes; tests preserve the
real editor settings; the game starts with hardware OpenGL rendering; Linux,
Windows, and macOS release archives build and pass their checksum checks;
the exported Linux game passes its headless smoke test; and the Android
debug APK builds and passes `apksigner verify`. Windows/macOS execution and
Android device playtesting remain target-device checks.

Generated builds are available in local `dist/` and are intentionally not
tracked. The combined changes are committed on a development branch; setup/build commands
do not publish a release.

Open the application shortcut or run:

```sh
godot-4.7.2 --editor --path /home/zak/projects/pattaya-release-integration
```

## Artwork and visual checks

Final textures live in `assets/art/`; `scripts/art.gd` is the shared catalog.
Generation receipts, reference images and packing recipes live in `art/`, which
is excluded from imports and exports. See [art/README.md](art/README.md).

```sh
python3 tools/prepare_art.py
GODOT_BIN=godot tools/test.sh
tools/preview-art.sh /tmp/pattaya-art-preview
python3 tools/review_art.py /tmp/pattaya-art-review
```

The preview runner creates its own temporary save directory. It covers all nine
venue stages, eight properties, staff absence and closures, every event, drawers,
tutorial and managed shifts, district destinations and walking directions,
fighter states, and monster outcomes. Use `PATTAYA_PREVIEW_FILTER='fight-*'` (or comma-separated patterns) to
capture one group. Set `PATTAYA_PREVIEW_RESOLUTION=1560x720` to check a wider
landscape window. Run with a graphical display; the headless renderer cannot
capture production artwork. `tools/review_art.py` makes light/dark alpha-edge
sheets and atlas playback GIFs; in-engine captures remain authoritative.

The Linux export smoke test also uses isolated user data. Desktop exports and
an Android debug package are local verification artifacts, not publication.

The economy-specific preview runner is selected with
`PATTAYA_PREVIEW_SCRIPT=tests/preview_economy.gd tools/preview-art.sh /tmp/economy-review`.
It covers pool timers, promotions, recovery and the same real-customer UI. Both
preview runners use realistic role assignments and customer fixtures; they do
not substitute decorative crowds for actual occupancy.

## Calendar celebrations and save schema eight

Street owns celebration start/end, the two-day reminder and story rotation.
Economy applies the flagship's temporary demand/timing rules and records actual
transactions. The UI reads countdown/report state and City draws temporary
bunting over existing art. Keep menu/countdown reads pure and exclude calendar
bonuses from offline forecasts. Save schema 8 added the active/last ledger
and guest patience; v7 ownership and money remain intact. Use the `party-*`
economy preview group and celebration regressions when changing this flow.

## Staff readiness and save schema nine

Staff recovery is a saved `service_ready` deadline on the foreground action clock.
Economy settles one real order, then records that person's next deadline,
`last_served` and `drinks_served`. UI and City only read these fields. Keep staff
before owner auto-serve in the live tick, without changing manual action timers.
Schema 9 preserves fractional deadlines and converts old partial work once.
`tests/staff_ready_check.gd` covers ready service, toggle/reload protection, stock,
queue sharing, owner separation and migration. The `staff-ready-*` economy preview
group checks the bottom-right indicator, real serving poses and purchase price.

Owner relief dispatch belongs to `economy.gd::owner_relief_needed`, called after
staff service. UI status reads this predicate without settling sales. Renewal
quotes use `rehire_offer` for both validation and frontage UI; contract state is
part of `street_ui_state` so expiry does not depend on a changed history notice.
No save schema change is needed for these rules.

`street.gd::chapter_requirements` supplies chapter advancement and next-step
readiness. `next_goal` is read-only guidance; `main.gd::show_next_goal` navigates
and scrolls only. The balance runner records manager timing and gaps between
purchases that improve the business (excluding routine stock and renewals).
`tests/balance_guidance_check.gd` covers price/reserve boundaries, saved ownership,
local milestones, guidance purity and UI navigation. No schema change is needed.

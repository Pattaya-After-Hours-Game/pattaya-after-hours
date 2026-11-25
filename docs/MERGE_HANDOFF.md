# Merge handover for rknell

The consolidated branch is **`codex/ready-for-main`**. It contains the complete
progression, customer economy, finished artwork and documentation, plus the
latest upstream Windows updater. Merge this branch once; the older feature
branches do not need separate merges afterward. `main` has not been changed by
this integration, and no release/tag has been published.

## Included histories

| Input | Tested revision | Relationship |
| --- | --- | --- |
| `codex/pattaya-idle-progression` | `93735b4` | Already an ancestor of customer-economy; preserved in the combined history |
| `codex/customer-economy` | `750a1e4` | Economy, complete graphics and the new documentation commit |
| Upstream `main` | `87a0107` | Windows updater and release metadata, explicitly merged into the integration branch |

The original graphics checkout had uncommitted work. Its finished art was
integrated in `1f97b70`; the original checkout was left intact. No unrelated
uncommitted workspace changes were discarded or swept into this merge.

## Merge decisions

- Keep the customer-driven economy, version-three saves, role-aware staff,
  guided shifts and finished full-width graphics interface.
- Keep upstream's Windows updater and version `1.0.7` / Android code `8`, using
  the new `assets/art/` icon paths. A subsequent release still needs a new version
  and tag; the merge does not claim to publish one.
- Place Update in the new header without covering the till or serving controls.
- Disable the live clock and save notifications inside the headless update
  worker. Without this integration fix, the worker could advance and autosave
  an uninitialised campaign while waiting to replace the executable.
- Keep both test sets: customer economy/art/input/pacing and Windows update
  validation, executable staging and restart-path checks.

## Verification

Verified on 25 November 2026 with Godot 4.7.2:

| Target | Result |
| --- | --- |
| Progression branch's `tools/test.sh` | Passed |
| Customer-economy branch's `tools/test.sh` | Passed, including all nine pacing simulations |
| Upstream main's `tools/test.sh` | Passed, including Windows updater unit checks |
| Combined branch's `tools/test.sh` | Passed, including art integrity, update-worker isolation, input and all nine pacing simulations |
| Updated header | Rendered and inspected; update, till, tutorial and live service controls remain accessible |
| Linux, Windows and macOS exports | All built; package checksums produced |
| Exported Linux executable | Passed isolated headless startup |
| Documentation | Local links checked; `git diff --check` clean |

Tests used isolated saves and editor configuration. Input branches were tested
separately; their suites intentionally describe their own historical behaviour.
The combined suite verifies the final endless customer-economy campaign.

Remaining platform checks: actual Windows updating/restart/rollback, Windows and
macOS playtesting, and Android device playtesting. Unit checks and successful
exports do not establish those behaviours on real devices. See
[TESTING.md](TESTING.md) for the broader release checklist.

## Review and try it

```sh
git fetch origin
git switch --track origin/codex/ready-for-main
tools/test.sh
godot --path .
```

If that local branch already exists, switch to it and fast-forward from origin
instead of creating it again. The local integration checkout on this machine is
`/home/zak/projects/pattaya-after-hours-economy`; its current branch is
`codex/ready-for-main`.

Start with [README.md](../README.md) and [story.md](../story.md). Important code
review areas are `scripts/economy.gd`, save migration in `scripts/campaign.gd`,
the live clock in `scripts/street.gd`, and worker-mode handling in
`scripts/main.gd`. Older released binaries do not understand version-three saves;
back up a campaign before testing a downgrade or rollback.

Review the combined branch against `main`, then merge through the repository's
normal PR process. If `main` advances, merge the new upstream commits into the
integration branch and repeat affected checks before approval. Source branches
have been retained; there is no need to delete them as part of review.

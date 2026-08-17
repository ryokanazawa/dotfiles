---
name: karuta-release-install
description: Archive the current HEAD of Karuta with the Release configuration, verify the signature, architectures, and hash, replace /Applications/Karuta.app, and launch it. Use when asked to export Karuta, install it on the local machine, swap in a Release build, or reinstall the latest version. Developer ID signing, notarization, and distribution are out of scope.
disable-model-invocation: true
---

# Export and install Karuta

Archive the current `HEAD` of `/Users/ryo/Developer/Karuta` with the Release configuration, verify the signature, replace `/Applications/Karuta.app`, and launch it. Do not modify the source, Git history, or working tree.

The procedure is fixed. Do not call an advisor. Decisions at each stage are covered by the scripts' exit codes and output. Run the three scripts in order, and if any completion criterion fails along the way, stop there.

`$OUT` does not survive across shells, so step 1 writes the drop-off location to `/private/tmp/Karuta-Export.latest` and steps 2 and 3 read it. Do not rewrite the scripts.

## Step 1: Archive and export

Run with permission and in the background, wait for the completion notification, and read the output file (takes a few minutes).

```sh
set -uo pipefail
ROOT=/Users/ryo/Developer/Karuta
OUT=$(mktemp -d /private/tmp/Karuta-Export.XXXXXX)
printf '%s\n' "$OUT" > /private/tmp/Karuta-Export.latest
echo "OUT=$OUT"
git -C "$ROOT" status -sb | tee "$OUT/status1.txt" || exit 1
git -C "$ROOT" rev-parse HEAD | tee "$OUT/head1.txt" || exit 1
git -C "$ROOT" status --porcelain=v1 --untracked-files=all > "$OUT/worktree1.txt" || exit 1
if [ -s "$OUT/worktree1.txt" ]; then
  echo "Working tree is not clean; cannot guarantee artifacts identical to the current HEAD"
  cat "$OUT/worktree1.txt"
  exit 1
fi
git -C "$ROOT" log -1 --oneline --decorate
security find-identity -v -p codesigning
xcodebuild -project "$ROOT/Karuta.xcodeproj" -scheme Karuta -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -archivePath "$OUT/Karuta.xcarchive" archive >"$OUT/archive.log" 2>&1
build_exit=$?
echo "build_exit=$build_exit"
grep -E '\*\* ARCHIVE (SUCCEEDED|FAILED) \*\*|: error:' "$OUT/archive.log" | tail -40
printf 'warning_count='; grep -c 'warning:' "$OUT/archive.log" || true
test "$build_exit" -eq 0 || exit 1
mkdir -p "$OUT/Export"
ditto "$OUT/Karuta.xcarchive/Products/Applications/Karuta.app" "$OUT/Export/Karuta.app"
ls -d "$OUT/Export/Karuta.app"
```

Completion criteria: the working tree is clean, `build_exit=0`, `** ARCHIVE SUCCEEDED **`, and `ls` prints `$OUT/Export/Karuta.app`.

Refer to signing identities by the actual values from `security find-identity`. Do not call `Apple Development` a `Developer ID Application`. Report `warning_count` separately from the success result. `git status -sb` and `git rev-parse HEAD` are also saved to files so step 3 can cross-check them inside the script.

The filter uses `: error:` because Swift function signatures (such as `(value: T?, error: AXError)`) false-positive on plain `error:`. Real xcodebuild errors are in `file:line:column: error:` format, so none are missed.

## Step 2: Verification

Run normally.

```sh
set -uo pipefail
OUT=$(cat /private/tmp/Karuta-Export.latest)
APP="$OUT/Export/Karuta.app"
EXPECTED_BUNDLE_ID=jp.co.rigato.karuta
EXPECTED_TEAM=5SF8ZY3PT8
test -d "$APP" || { echo "Export missing: $APP"; exit 1; }

codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 \
  || { echo "Signature verification failed for the export"; exit 1; }
codesign -d --verbose=2 "$APP" 2>&1 \
  | grep -E '^(Identifier|Authority|TeamIdentifier)=' \
  | tee "$OUT/signature2.txt" \
  || { echo "Cannot get signature info for the export"; exit 1; }
grep -Fxq "Identifier=$EXPECTED_BUNDLE_ID" "$OUT/signature2.txt" \
  || { echo "Bundle ID mismatch"; exit 1; }
grep -Eq '^Authority=Apple Development:' "$OUT/signature2.txt" \
  || { echo "Not signed with Apple Development"; exit 1; }
grep -Fxq "TeamIdentifier=$EXPECTED_TEAM" "$OUT/signature2.txt" \
  || { echo "Team ID mismatch"; exit 1; }

archs=$(lipo -archs "$APP/Contents/MacOS/Karuta") \
  || { echo "Cannot get architectures"; exit 1; }
echo "archs=$archs"
case " $archs " in *' arm64 '*) ;; *) echo "arm64 missing"; exit 1;; esac
case " $archs " in *' x86_64 '*) ;; *) echo "x86_64 missing"; exit 1;; esac
ls -ld /Applications/Karuta.app 2>&1 || true
pgrep -x Karuta | while read -r p; do echo "running pid=$p $(ps -p "$p" -o comm=)"; done
echo "Verification complete"
```

Completion criteria: exit code 0 and `Verification complete`, `valid on disk`, `satisfies its Designated Requirement`, `Identifier=jp.co.rigato.karuta`, `Authority=Apple Development: ...`, `TeamIdentifier=5SF8ZY3PT8`, and both `x86_64` and `arm64` in `archs`.

`codesign` writes results to stderr, so do not remove `2>&1`. If the architectures are only `arm64`, the completion criteria are not met. Report it plainly, then either drop the arch specification from `-destination` or re-archive with `ARCHS="arm64 x86_64"`.

The `pgrep` line is a preview of what step 3 will terminate. Even if the `/Applications` version is not running, a DerivedData Debug build may be running under the same Bundle ID.

## Step 3: Replace and launch

Run with permission. Termination, backup, placement, re-verification, launch, and confirmation all happen in one script. It automatically restores the old version only when the `ditto` placement itself fails. For failures after that (signature re-verification, `open`, launch, hashes, `git status`), it does not auto-restore; it stops with the backed-up old version left at `$OLD` (`$OUT/OldVersion/Karuta.app`). Restoration is manual, and `fail` prints that path. On a fresh install where `/Applications/Karuta.app` never existed, there is no old version to back up, so `fail` prints "no old version" and the temp directory path instead.

```sh
set -uo pipefail
ROOT=/Users/ryo/Developer/Karuta
OUT=$(cat /private/tmp/Karuta-Export.latest)
EXPECTED_BUNDLE_ID=jp.co.rigato.karuta
EXPECTED_TEAM=5SF8ZY3PT8
case "$OUT" in
  *..*|/private/tmp/Karuta-Export.*/*) echo "Unexpected OUT: $OUT"; exit 1;;
  /private/tmp/Karuta-Export.?*) ;;
  *) echo "Unexpected OUT: $OUT"; exit 1;;
esac
NEW="$OUT/Export/Karuta.app"
OLD="$OUT/OldVersion/Karuta.app"
test -d "$NEW" || { echo "Export missing"; exit 1; }
test -s "$OUT/status1.txt" || { echo "Step 1's status1.txt missing/empty: $OUT"; exit 1; }
test -s "$OUT/head1.txt" || { echo "Step 1's head1.txt missing/empty: $OUT"; exit 1; }
test -s "$OUT/signature2.txt" || { echo "Step 2's signature2.txt missing/empty: $OUT"; exit 1; }
[ -e "$OLD" ] && { echo "Old version already exists. Start over from step 1: $OUT"; exit 1; }

fail() {
  if [ -d "$OLD" ]; then
    echo "$1 (old version: $OLD)"
  else
    echo "$1 (no old version, fresh install. Temp directory: $OUT)"
  fi
  exit 1
}

wait_gone() {
  local n=0
  while pgrep -x Karuta >/dev/null; do
    n=$((n + 1)); [ "$n" -ge 24 ] && return 1
    sleep 0.5
  done
  return 0
}
signal_all() {
  local sig="$1" p
  local pids=($(pgrep -x Karuta))
  for p in "${pids[@]}"; do
    ps -p "$p" -o comm= | grep -q '/Karuta\.app/Contents/MacOS/Karuta$' \
      || { echo "Unexpected process pid=$p"; return 1; }
    echo "$sig pid=$p ($(ps -p "$p" -o comm=))"
    kill -"$sig" "$p"
  done
  return 0
}

osascript -e 'tell application id "jp.co.rigato.karuta" to quit' >/dev/null 2>&1 || true
if ! wait_gone; then
  signal_all TERM || exit 1
  if ! wait_gone; then
    signal_all KILL || exit 1
    wait_gone || { echo "Cannot terminate: $(pgrep -x Karuta)"; exit 1; }
  fi
fi
echo "Processes terminated"

mkdir -p "$OUT/OldVersion"
if [ -d /Applications/Karuta.app ]; then
  mv /Applications/Karuta.app "$OLD" || exit 1
fi
if ! ditto "$NEW" /Applications/Karuta.app; then
  rm -rf /Applications/Karuta.app
  [ -d "$OLD" ] && mv "$OLD" /Applications/Karuta.app
  echo "Placement failed; restored the old version"; exit 1
fi

codesign --verify --deep --strict --verbose=2 /Applications/Karuta.app 2>&1 \
  || fail "Signature verification failed for the installed version"
codesign -d --verbose=2 /Applications/Karuta.app 2>&1 \
  | grep -E '^(Identifier|Authority|TeamIdentifier)=' \
  | tee "$OUT/signature3.txt" \
  || fail "Cannot get signature info for the installed version"
grep -Fxq "Identifier=$EXPECTED_BUNDLE_ID" "$OUT/signature3.txt" \
  || fail "Bundle ID mismatch for the installed version"
grep -Eq '^Authority=Apple Development:' "$OUT/signature3.txt" \
  || fail "Installed version is not signed with Apple Development"
grep -Fxq "TeamIdentifier=$EXPECTED_TEAM" "$OUT/signature3.txt" \
  || fail "Team ID mismatch for the installed version"
diff -q "$OUT/signature2.txt" "$OUT/signature3.txt" >/dev/null \
  || fail "Signature info differs between the export and the installed version"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f /Applications/Karuta.app \
  || fail "Launch Services registration failed"
open /Applications/Karuta.app || fail "open failed"

n=0
until pgrep -x Karuta >/dev/null; do
  n=$((n + 1)); [ "$n" -ge 24 ] && fail "Did not launch"
  sleep 0.5
done
pid=$(pgrep -x Karuta | head -1)
[ -n "$pid" ] || fail "Exited immediately after launch"
echo "Launched pid=$pid ($(ps -p "$pid" -o comm=))"
ps -p "$pid" -o comm= | grep -q '/Applications/Karuta\.app/Contents/MacOS/Karuta$' \
  || fail "The launched process is not the /Applications version"

sum_new=$(shasum -a 256 "$NEW/Contents/MacOS/Karuta" | cut -d' ' -f1) \
  || fail "SHA-256 computation failed for the export"
sum_installed=$(shasum -a 256 /Applications/Karuta.app/Contents/MacOS/Karuta | cut -d' ' -f1) \
  || fail "SHA-256 computation failed for the installed version"
[ -n "$sum_new" ] || fail "Export SHA-256 is empty"
[ -n "$sum_installed" ] || fail "Installed version SHA-256 is empty"
echo "sha256=$sum_new"
[ "$sum_new" = "$sum_installed" ] || fail "SHA-256 mismatch $sum_new / $sum_installed"

git -C "$ROOT" status -sb | tee "$OUT/status3.txt" \
  || fail "Failed to get the final git status"
git -C "$ROOT" rev-parse HEAD | tee "$OUT/head3.txt" \
  || fail "Failed to get the final HEAD"
diff -q "$OUT/status1.txt" "$OUT/status3.txt" >/dev/null \
  || fail "git status differs from step 1"
diff -q "$OUT/head1.txt" "$OUT/head3.txt" >/dev/null \
  || fail "HEAD differs from step 1"

if [ -d "$OLD" ]; then
  # /private/tmp is periodically cleaned by the OS, so the old version,
  # which must be kept until approval, is moved to a permanent location
  # under Application Support.
  backup_root="$HOME/Library/Application Support/Karuta/backups"
  mkdir -p "$backup_root" || { echo "Cannot create the old-version retention directory: $backup_root"; exit 1; }
  backup=$(mktemp -d "$backup_root/Karuta-Backup.XXXXXX") \
    || { echo "Cannot create the old-version retention directory: $backup_root"; exit 1; }
  mv "$OLD" "$backup/Karuta.app" \
    || { rmdir "$backup" 2>/dev/null || true; echo "Cannot move the old version to the retention directory: $OLD"; exit 1; }
  echo "Old version saved to: $backup/Karuta.app (do not delete until explicit approval)"
fi
rm -rf "$OUT" || { echo "Cannot remove the temp directory: $OUT"; exit 1; }
rm -f /private/tmp/Karuta-Export.latest \
  || { echo "Cannot remove the temp pointer: /private/tmp/Karuta-Export.latest"; exit 1; }
echo "Removed the temp directory: $OUT"
find /private/tmp -maxdepth 1 -name 'Karuta-Export.*' -exec echo "Leftover: {}" \;
echo "Done"
```

Completion criteria: `Done` is printed. The launched PID's executable is `/Applications/Karuta.app/Contents/MacOS/Karuta`, the installed version also passes signature verification with the same Bundle ID, Apple Development Authority, and Team ID, the SHA-256 of both binaries matches, and `HEAD` and `git status -sb` are the same as in step 1. If any of these fails, the script `exit 1`s there, and the old version and verification materials remain.

Only when all completion criteria are met does the script delete `$OUT` — including the archive, export, and logs — and `/private/tmp/Karuta-Export.latest`. If there is an old version, it is first moved to `~/Library/Application Support/Karuta/backups/Karuta-Backup.*/Karuta.app` and the path is reported. The old version is kept until the user explicitly approves deletion (`/private/tmp` is not used because the OS cleans it periodically). On failure, `$OUT` is not deleted, so it stays usable for restoring the old version and inspecting logs. If a `Leftover:` line appears, it was left by another run.

Termination escalates AppleScript quit → `TERM` → `KILL`, waiting up to 12 seconds at each stage. TERM can take a few seconds, so do not shorten the waits. `KILL` is the last resort but must not be skipped; skipping it can stop things before replacement, leaving only the `/Applications` version quit.

If you terminated something other than the `/Applications` version (a DerivedData Debug build), that means you killed the user's in-development instance. State it explicitly in the report as an action outside the procedure.

## Boundaries

- `Apple Development` signing is for local on-device verification. Developer ID signing, notarization, and distribution for shipping are separate requests. Checking Gatekeeper or notarization is out of scope.
- To guarantee artifacts identical to the current `HEAD`, step 1 stops if the working tree is not clean. Installing uncommitted changes is out of scope for this skill; request it separately.
- On success, delete the export temp directory and keep only the old version in a separate backup location. Delete the old version only after explicit approval. On failure, do not delete it; report the path.
- If any of signature, termination, replacement, launch, or hash verification is unmet, do not report completion.
- `/private/tmp/Karuta-Export.latest` is shared between runs. Do not run two instances of this skill at the same time.
- After a failure, do not re-run step 3 alone. It would clobber the already-backed-up old version, so the script stops with `Old version already exists`. To retry, start from step 1.

---
name: xcode-build
description: Open the Xcode project of the current git worktree in Xcode and build it from the command line, reporting errors verbatim. Use when the user asks to open Xcode, build the current worktree, or check that the app still compiles.
---

# xcode-build — open the working worktree in Xcode and build it

Open the Xcode project of the worktree you are currently working in with `xed`, then build it with `xcodebuild` and report the result. Only open the GUI; run the build and judge success/failure on the CLI side (agents cannot type into Xcode, so Cmd+B cannot be pressed).

The build is **read-only**. Do not touch the source; report errors verbatim and stop. Treat fixes as a separate request.

## Procedure

### 1. Check the worktree root and repository conventions

```sh
git rev-parse --show-toplevel   # $ROOT hereafter
```

This works the same in the main checkout or a linked worktree, so "the worktree you are working in" needs no special treatment.

Next, check whether the repository's `CLAUDE.md` / `AGENTS.md` / `README.md` specify build command conventions. **If there are conventions, use them with top priority.** The following are the defaults when the project specifies nothing.

### 2. Identify the build container

Look only directly under the worktree root. Digging deeper picks up the contents of submodules, `Pods/`, and `*.playground`, so the default is `-maxdepth 1`.

```sh
find "$ROOT" -maxdepth 1 \( -name "*.xcworkspace" -o -name "*.xcodeproj" -o -name "Package.swift" \) | sort
```

The priority order is:

1. `*.xcworkspace` (the workspace is correct with CocoaPods or multi-project setups)
2. `*.xcodeproj`
3. `Package.swift` (a standalone Swift Package)

Only when there are 0 hits directly under the root, expand one level down, excluding `Pods/`, `Carthage/`, `.build/`, and `*.playground/` subtrees. If multiple candidates still remain, confirm with the user.

### 3. Open in Xcode

```sh
xed "$CONTAINER"          # .xcworkspace / .xcodeproj
xed "$ROOT"               # for Package.swift only, open the whole directory
```

If the same container is already open, that window comes to the front. Opening it early lets the user work in Xcode while waiting for the build.

### 4. Decide the scheme

```sh
xcodebuild -list -json -workspace "$CONTAINER"   # for a workspace
xcodebuild -list -json -project "$CONTAINER"     # for an xcodeproj
xcodebuild -list -json                           # in the directory with Package.swift
```

- If there is one, use it.
- If there are several, pick the main app matching the repository name / product name (e.g. for the `Karuta` repository, `Karuta`. `*Tests` / `*UITests` / `*Watch App` are not the main app).
- If no match decides it, let the user choose.
- If `schemes` is empty, no shared scheme is configured and `xcodebuild` cannot pick one. Report that the user needs to enable Shared in Xcode's Manage Schemes, and stop. Do not create a scheme file yourself.

### 5. Choose the destination from candidates

**Do not guess from the project name; list candidates first, then decide.** For example, `Karuta` looks like an iOS app from its name but is actually a macOS app; passing `generic/platform=iOS Simulator` fails with `error: Unable to find a destination matching...`.

```sh
# The choice among -workspace / -project / omitted is the same as in step 4
xcodebuild -showdestinations -project "$CONTAINER" -scheme "$SCHEME" \
  | grep -o 'platform:[^,}]*' | sort -u
```

Extracting only `platform:` gives the candidate axes regardless of how many simulators or runtimes exist (one line `platform:macOS` for a macOS-only app; two lines `platform:iOS` and `platform:iOS Simulator` for an iOS app). Look at what comes out and choose. The list goes to stdout, so unless you insert `2>&1`, mistakes like a wrong scheme name appear on stderr as-is.

| Among the candidates | What to specify |
|---|---|
| `platform:macOS` only | omit the destination |
| `platform:iOS Simulator` | `-destination 'generic/platform=iOS Simulator'` |
| `platform:watchOS Simulator` | `-destination 'generic/platform=watchOS Simulator'` |
| Swift Package (`Package.swift`) | omit |

A simulator generic destination can build without code signing. A real-device destination (`generic/platform=iOS`) requires signing, so use it only when the user explicitly asks. In a multi-platform setup where both iOS and macOS appear, if the user did not name a target, pick the app's primary platform and write the reason in the report.

### 6. Build

The output is long, so write the log to `/tmp/xcodebuild.log` and judge success/failure by the exit code. Writing and reading happen in separate shell invocations, so fix the path to make sure both match.

```sh
# Replace -workspace/-project and the destination with what was decided in steps 2 and 5
xcodebuild build \
  -workspace "$CONTAINER" \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS Simulator' \
  > /tmp/xcodebuild.log 2>&1; echo "exit=$?"
```

- Do not add `-derivedDataPath`. DerivedData is hash-partitioned by container path, so it is already separate per worktree; with the default, the same cache the GUI build uses stays warm.
- Add `clean` only when the user asks for a clean build.

Extract the following from the log to read. Mixing warnings into the same grep drowns out the error lines, so take errors first and count warnings separately.

```sh
grep -n -E "error:|BUILD (SUCCEEDED|FAILED)|The following build commands failed" /tmp/xcodebuild.log | head -40
grep -c "warning:" /tmp/xcodebuild.log
```

Exit code 0 and `** BUILD SUCCEEDED **` mean success.

### 7. Report

- The path of the container opened, the scheme and destination used
- Build success/failure
- On failure, the error lines verbatim (`file:line:column` and message). Do not round them off into a summary
- If there are warnings, the count and a representative example

## On failure

- **Stuck on Swift Package resolution / lock error**: the Xcode GUI is resolving packages at the same time. Wait a few tens of seconds and re-run once; if it still fails, tell the user to wait for Xcode's resolution to finish.
- **`Unable to find a destination matching...`**: go back to step 5 and re-choose from the candidates.
- **Code signing error**: the destination is for a real device. Switch to a simulator generic destination.
- **Build error**: report verbatim and stop. Proceed to fixing only if the request includes "make the build pass."
- **No Xcode project found**: tell the user this worktree is not an Xcode project. If there is only `Package.swift`, suggest `swift build`.

## Completion criteria

- The target container is open in Xcode.
- `xcodebuild` returned exit code 0 and `BUILD SUCCEEDED`, or the failure details were reported with the verbatim errors.
- The source is untouched.

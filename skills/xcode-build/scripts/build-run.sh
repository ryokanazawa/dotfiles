#!/bin/bash
# build-run.sh [scheme] — worktree の Xcode プロジェクトをビルドし、シミュレータで起動する。
# Xcode.app は起動しない。Simulator.app は起動する（それが成果物なので）。
#
# 失敗時の対処:
#   Unable to find a destination matching  → platform 軸の判定ミス。$PLATFORMS を確認する
#   コード署名エラー                        → 実機向け destination になっている。simulator へ
#   Swift Package の解決で止まる / lock     → Xcode が同時に解決中。数十秒待って1回だけ再実行
#   Xcode プロジェクトが見つからない        → Package.swift だけなら swift build を提案する
#   スキームが空                            → 共有スキーム未設定。Manage Schemes で Shared にしてもらう
# 全ログは /tmp/xcodebuild.log に残る。

set -uo pipefail

# シェル env が別プロジェクトの Xcode ビルドコンテキストで汚染されていることがあるので
# （deployment target 衝突 / Asset Catalog エラーの原因）、クリーン env で自分を張り直す。
if [ -z "${XCB_CLEAN:-}" ]; then
  # xcode-select -p は継承した DEVELOPER_DIR をそのまま返すので、汚染値を持ち込まないよう外す
  DEVDIR=$(env -u DEVELOPER_DIR xcode-select -p 2>/dev/null)
  case "$DEVDIR" in
    */CommandLineTools*|"") echo "error: xcode-select が Xcode.app を指していない ($DEVDIR)" >&2; exit 1 ;;
  esac
  exec env -i XCB_CLEAN=1 HOME="$HOME" USER="$USER" LANG=ja_JP.UTF-8 \
    PATH=/usr/bin:/bin:/usr/sbin:/sbin DEVELOPER_DIR="$DEVDIR" \
    /bin/bash "$0" "$@"
fi

LOG=/tmp/xcodebuild.log
STATE=/tmp/xcode-build-last.env   # 直近の起動情報（--logs 用）

# --logs [all] [行数] : 直近に起動したアプリの stdout/stderr と os_log を出す。
# 既定は「独自 subsystem を持つ行」だけに絞る（Logger(subsystem:category:) の出力）。
# 素通しすると WebKit / Security / Accessibility の雑音が数百行来てトークンを食う。
# senderImagePath で絞る手は使えない（Swift の Logger は 0 件になる）。nil subsystem の
# 行は `subsystem CONTAINS "."` で落ちる。all を付ければ素通し。
if [ "${1:-}" = "--logs" ]; then
  [ -f "$STATE" ] || { echo "error: まだ起動していない。先にスキーム指定で実行する" >&2; exit 1; }
  . "$STATE"
  PRED="processImagePath ENDSWITH \"$EXENAME\""
  if [ "${2:-}" = "all" ]; then N="${3:-50}"
  else N="${2:-50}"; PRED="$PRED AND subsystem CONTAINS \".\" AND NOT subsystem BEGINSWITH \"com.apple\""; fi
  echo "=== stdout/stderr: $APPLOG ==="
  if [ -s "$APPLOG" ]; then tail -n "$N" "$APPLOG"; else echo "(空 — print() を使っていないなら os_log 側を見る)"; fi
  echo "=== os_log 直近5分 ($DEVNAME) ==="
  xcrun simctl spawn "$UDID" log show --style compact --last 5m --predicate "$PRED" 2>/dev/null \
    | tail -n "$N"
  echo "(システムログも見るなら: $0 --logs all)"
  exit 0
fi

ROOT=$(git rev-parse --show-toplevel) || exit 1
cd "$ROOT" || exit 1

# --- コンテナ: workspace > xcodeproj > Package.swift、ルート直下のみ ---
CONTAINER=$(find "$ROOT" -maxdepth 1 -name "*.xcworkspace" | head -1)
FLAG=-workspace
[ -z "$CONTAINER" ] && { CONTAINER=$(find "$ROOT" -maxdepth 1 -name "*.xcodeproj" | head -1); FLAG=-project; }
[ -z "$CONTAINER" ] && { echo "error: ルート直下に .xcworkspace / .xcodeproj がない" >&2; exit 1; }

# --- スキーム: 引数優先。無ければ1つだけのときに限り自動 ---
SCHEME="${1:-}"
if [ -z "$SCHEME" ]; then
  SCHEMES=$(xcodebuild -list "$FLAG" "$CONTAINER" 2>/dev/null | awk '/Schemes:/{f=1;next} f&&NF{$1=$1;print}')
  [ "$(printf '%s\n' "$SCHEMES" | wc -l)" -eq 1 ] && SCHEME="$SCHEMES"
  [ -z "$SCHEME" ] && { echo "error: スキームを指定すること。候補:" >&2; printf '%s\n' "$SCHEMES" >&2; exit 1; }
fi

PLATFORMS=$(xcodebuild -showdestinations "$FLAG" "$CONTAINER" -scheme "$SCHEME" 2>/dev/null \
  | grep -o 'platform:[^,}]*' | sort -u)

setting() { awk -F' = ' -v k="$1" '$1 ~ "^ +"k"$" {print $2; exit}' <<<"$SETTINGS"; }

build() {  # $@ = 追加の xcodebuild 引数
  xcodebuild build "$FLAG" "$CONTAINER" -scheme "$SCHEME" "$@" >"$LOG" 2>&1
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "BUILD FAILED (exit=$rc)"; grep -E "error:|The following build commands failed" "$LOG" | head -40
    exit $rc
  fi
  SETTINGS=$(xcodebuild -showBuildSettings "$FLAG" "$CONTAINER" -scheme "$SCHEME" "$@" 2>/dev/null)
  # ここで落ちると APP="/" が組み立って simctl install / open へ進むため、
  # 成果物パスを解決できない時点で止める
  if [ -z "$SETTINGS" ]; then
    echo "error: -showBuildSettings の取得に失敗した（成果物パスを解決できない）" >&2
    exit 1
  fi
}

report() {
  echo "container: $CONTAINER"
  echo "scheme:    $SCHEME"
  echo "BUILD SUCCEEDED  warnings=$(grep -c 'warning:' "$LOG")  loglines=$(wc -l <"$LOG" | tr -d ' ')"
}

case "$PLATFORMS" in
  *"iOS Simulator"*|*"watchOS Simulator"*|*"tvOS Simulator"*)
    # iOS を最優先。watch/TV 単体スキームのときだけそちらへ倒す
    case "$PLATFORMS" in
      *"iOS Simulator"*)    SIMKIND=iOS;     SIMMATCH=iPhone ;;
      *"watchOS Simulator"*) SIMKIND=watchOS; SIMMATCH="Apple Watch" ;;
      *)                    SIMKIND=tvOS;    SIMMATCH="Apple TV" ;;
    esac

    # 起動中のシミュレータを優先。無ければ最新ランタイムの既定機種を boot する。
    BOOTED=$(xcrun simctl list devices booted \
      | awk -v m="$SIMMATCH" '/^-- /{rt=$0;gsub(/^-- | --$/,"",rt);next} $0 ~ m && /\(Booted\)/{print rt "|" $0; exit}')
    if [ -z "$BOOTED" ]; then
      BOOTED=$(xcrun simctl list devices available \
        | awk -v k="$SIMKIND" -v m="$SIMMATCH" '/^-- /{s=($0 ~ "-- " k);rt=$0;gsub(/^-- | --$/,"",rt);next} s && $0 ~ m {last=rt "|" $0} END{print last}')
      [ -z "$BOOTED" ] && { echo "error: 利用可能な $SIMKIND シミュレータがない" >&2; exit 1; }
      NEEDBOOT=1
    fi
    RUNTIME=${BOOTED%%|*}
    DEVLINE=${BOOTED#*|}
    UDID=$(sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/' <<<"$DEVLINE")
    DEVNAME=$(sed -E 's/^ *(.*[^ ]) +\([0-9A-Fa-f-]{36}\).*/\1/' <<<"$DEVLINE")
    [ -n "${NEEDBOOT:-}" ] && xcrun simctl boot "$UDID"
    open -a Simulator

    build -destination "platform=$SIMKIND Simulator,id=$UDID"
    APP="$(setting BUILT_PRODUCTS_DIR)/$(setting WRAPPER_NAME)"
    BID=$(setting PRODUCT_BUNDLE_IDENTIFIER)
    EXENAME=$(setting EXECUTABLE_NAME)
    report
    echo "simulator: $DEVNAME ($RUNTIME)"
    xcrun simctl install "$UDID" "$APP" || exit 1

    # --stdout/--stderr のパスはシミュレータ内で解決されるので、渡すのはゲスト側の /tmp。
    # 読むのはホスト側の実体 (.../data/tmp) なので、APPLOG 側で対応するパスへ変換しておく。
    # これが無いとユーザーが毎回ターミナルで log を追う羽目になる。
    APPLOG="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data/tmp/xcode-build-app.log"
    rm -f "$APPLOG"
    echo "launch:    $(xcrun simctl launch --terminate-running-process \
      --stdout=/tmp/xcode-build-app.log --stderr=/tmp/xcode-build-app.log "$UDID" "$BID")"
    echo "applog:    $APPLOG"
    printf 'UDID=%q\nEXENAME=%q\nDEVNAME=%q\nAPPLOG=%q\n' "$UDID" "$EXENAME" "$DEVNAME" "$APPLOG" >"$STATE"
    echo "logs:      $0 --logs   # stdout/stderr と os_log をまとめて出す"
    ;;
  *macOS*)
    build
    APP="$(setting BUILT_PRODUCTS_DIR)/$(setting WRAPPER_NAME)"
    report
    # APP="/" の穴は build() 内の SETTINGS 空チェックで塞がり済み。ここでは
    # バンドル (.app) 以外の成果物 (CLI ツール等) も正当なので -e で確認する
    [ -e "$APP" ] || { echo "error: 成果物が見つからない: $APP" >&2; exit 1; }
    # 起動対象の署名を可視化する。できたてのビルドはふつう ad-hoc 署名で、
    # 同じ bundle id で保存済み Keychain 項目があるアプリを起動すると
    # 認証ダイアログや信頼状態の混乱を招きうるため、Authority=（証明書
    # 署名）が無ければ警告して判断を呼び手に残す
    SIGN=$(codesign -dv "$APP" 2>&1)
    echo "codesign:"
    # パイプの終了状態は sed のもの (常に 0) なので、grep の空振りは
    # `|| echo` では拾えない。一度だけ grep して中身の有無で分ける
    SIGNLINES=$(grep -E 'Signature|Authority|TeamIdentifier|Identifier=' <<<"$SIGN")
    if [ -n "$SIGNLINES" ]; then
      sed 's/^/  /' <<<"$SIGNLINES"
    else
      echo "  (署名情報なし: $SIGN)"
    fi
    if ! grep -q 'Authority=' <<<"$SIGN"; then
      echo "warning:   証明書による署名がない (ad-hoc または未署名)。"
      echo "           同じ bundle id の保存済み Keychain 項目がある場合は起動影響を確認すること。"
    fi
    open "$APP" && echo "launch:    $APP"
    ;;
  *)
    build
    report
    echo "note:      シミュレータ候補がないのでビルドのみ ($PLATFORMS)"
    ;;
esac

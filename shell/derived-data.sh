# derived-data — Xcode の DerivedData から孤児を見つける deep module。
#
# Interface:
#   derived_data_root                    → DerivedData の既定パス
#   derived_data_workspace_dir <dir>     → その DerivedData が指すプロジェクトの親ディレクトリ
#   derived_data_orphans [root]          → 孤児の DerivedData を1行1パスで出力
#
# 孤児 = info.plist の WorkspacePath の親ディレクトリが存在しないもの。
# worktree を消しても DerivedData は残るため、worktree 運用では際限なく溜まる。
#
# bash / zsh 両対応。読むだけで消さない。削除は呼び出し側（prune-derived-data.sh）の責務。

derived_data_root() {
  printf '%s\n' "$HOME/Library/Developer/Xcode/DerivedData"
}

# WorkspacePath は .xcodeproj / .xcworkspace までを含む。判定に使うのはその親。
# プロジェクトファイルは gitignore されていたり生成物だったりするので、
# 「worktree が消えたか」は親ディレクトリの有無で見る。
derived_data_workspace_dir() {
  local dir="$1"
  [ -n "$dir" ] || return 1
  local plist="$dir/info.plist"
  [ -f "$plist" ] || return 1

  local workspace
  workspace="$(plutil -extract WorkspacePath raw -o - "$plist" 2>/dev/null)" || return 1
  [ -n "$workspace" ] || return 1

  printf '%s\n' "${workspace%/*}"
}

derived_data_orphans() {
  local root="${1:-$(derived_data_root)}"
  [ -d "$root" ] || return 0

  local dir workspace_dir
  for dir in "$root"/*/; do
    [ -d "$dir" ] || continue
    dir="${dir%/}"

    # info.plist を持たないものは共有キャッシュ（ModuleCache.noindex など）。対象外。
    workspace_dir="$(derived_data_workspace_dir "$dir")" || continue

    [ -d "$workspace_dir" ] || printf '%s\n' "$dir"
  done
}

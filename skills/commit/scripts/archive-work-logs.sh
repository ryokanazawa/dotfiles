#!/bin/zsh
# ~/.claude/skills/commit/scripts/archive-work-logs.sh
# Archives todo/lessons logs with shared policy before commit.
# Works from the current working directory (project root); references sibling scripts via ${0:A:h}.

set -euo pipefail

script_dir="${0:A:h}"
max_lines="${1:-1000}"

archive_if_dated() {
  local source_file="$1"
  local archive_root="$2"
  local source_title="$3"
  local archive_title="$4"

  if [[ ! -f "$source_file" ]]; then
    return
  fi

  if grep -Eq '^## .*(20[0-9]{2}-?[0-9]{2}-?[0-9]{2}|#[0-9]+ [0-9]{8})' "$source_file"; then
    "$script_dir/archive-task-log.sh" \
      --source "$source_file" \
      --archive-root "$archive_root" \
      --max-lines "$max_lines" \
      --source-title "$source_title" \
      --archive-title "$archive_title"
  fi
}

validate_if_present() {
  local source_file="$1"
  local archive_root="$2"

  if [[ ! -f "$source_file" ]]; then
    return
  fi

  "$script_dir/validate-task-archive.sh" \
    --source "$source_file" \
    --archive-root "$archive_root" \
    --max-lines "$max_lines"
}

archive_if_dated tasks/todo.md tasks/archive "TODO" "TODO Archive"
archive_if_dated tasks/lessons.md tasks/archive/lessons "Lessons" "Lessons Archive"

validate_if_present tasks/todo.md tasks/archive
validate_if_present tasks/lessons.md tasks/archive/lessons

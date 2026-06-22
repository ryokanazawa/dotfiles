#!/bin/zsh
# scripts/validate-task-archive.sh
# Validates daily markdown archive layout and catches oversized or misfiled logs.
# Falls back to line-budget-only when the source has no dated headings (e.g. lessons.md).

set -euo pipefail

source_file="tasks/todo.md"
archive_root="tasks/archive"
max_lines=1000

usage() {
  cat <<'EOF'
Usage: scripts/validate-task-archive.sh [--source PATH] [--archive-root PATH] [--max-lines N]
EOF
}

extract_date() {
  local heading="$1"
  local raw_date
  raw_date=$(printf '%s\n' "$heading" | sed -nE 's/.*(20[0-9]{2}-?[0-9]{2}-?[0-9]{2}).*/\1/p')
  printf '%s\n' "${raw_date//-/}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      source_file="$2"
      shift 2
      ;;
    --archive-root)
      archive_root="$2"
      shift 2
      ;;
    --max-lines)
      max_lines="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$source_file" ]]; then
  echo "Source file not found: $source_file" >&2
  exit 1
fi

if [[ ! "$max_lines" =~ '^[0-9]+$' ]] || (( max_lines < 20 )); then
  echo "--max-lines must be an integer >= 20" >&2
  exit 1
fi

# 日付見出しがない source(例: lessons.md)は行数上限のみを検証
if ! grep -Eq '^## .*(20[0-9]{2}-?[0-9]{2}-?[0-9]{2}|#[0-9]+ [0-9]{8})' "$source_file"; then
  source_lines=$(wc -l < "$source_file")
  if (( source_lines > max_lines )); then
    echo "Source file exceeds line limit ($source_lines > $max_lines): $source_file" >&2
    exit 1
  fi
  if [[ -d "$archive_root" ]]; then
    for archive_file in "$archive_root"/**/*.md(.N); do
      archive_lines=$(wc -l < "$archive_file")
      if (( archive_lines > max_lines )); then
        echo "Archive file exceeds line limit ($archive_lines > $max_lines): $archive_file" >&2
        exit 1
      fi
    done
  fi
  echo "Task archive validation passed (line budget only)"
  exit 0
fi

# 以下、日付見出しがある source(todo.md)向けのフル検証
todo_dates=$(rg '^## ' "$source_file" | while IFS= read -r heading; do extract_date "$heading"; done | awk 'NF > 0')
if [[ -z "$todo_dates" ]]; then
  echo "No dated task headings found in $source_file" >&2
  exit 1
fi

source_line_count=$(wc -l < "$source_file")
if (( source_line_count > max_lines )); then
  echo "Source file exceeds line limit ($source_line_count > $max_lines): $source_file" >&2
  exit 1
fi

keep_date=$(printf '%s\n' "$todo_dates" | sort -r | head -n 1)
old_todo_dates=$(printf '%s\n' "$todo_dates" | awk -v keep="$keep_date" '$0 != keep')
if [[ -n "$old_todo_dates" ]]; then
  echo "Found archived dates still present in $source_file:" >&2
  printf '%s\n' "$old_todo_dates" | sort -u >&2
  exit 1
fi

archive_files=("$archive_root"/20??????/*.md(.N))
if (( ${#archive_files[@]} == 0 )); then
  echo "Task archive validation passed (no archive files yet)"
  exit 0
fi

for archive_file in "${archive_files[@]}"; do
  line_count=$(wc -l < "$archive_file")
  if (( line_count > max_lines )); then
    echo "Archive file exceeds line limit ($line_count > $max_lines): $archive_file" >&2
    exit 1
  fi

  archive_date="${archive_file:h:t}"
  if [[ ! "${archive_file:t}" =~ '^[0-9][0-9]\.md$' ]]; then
    echo "Archive file must use NN.md naming: $archive_file" >&2
    exit 1
  fi

  explicit_dates=$(rg '^## ' "$archive_file" | while IFS= read -r heading; do extract_date "$heading"; done | awk 'NF > 0' | sort -u)
  if [[ -n "$explicit_dates" ]]; then
    while IFS= read -r explicit_date; do
      if [[ "$explicit_date" != "$archive_date" ]]; then
        echo "Archive file date mismatch ($explicit_date != $archive_date): $archive_file" >&2
        exit 1
      fi
    done <<< "$explicit_dates"
  fi
done

echo "Task archive validation passed"

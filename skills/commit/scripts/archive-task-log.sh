#!/bin/zsh
# scripts/archive-task-log.sh
# Archives dated work-log entries from a markdown file into daily files.
# Keeps the newest date in source and trims to max lines by moving oldest same-day blocks.

set -euo pipefail
setopt typesetsilent

source_file="tasks/todo.md"
archive_root="tasks/archive"
keep_date=""
max_lines=1000
source_title="TODO"
archive_title="TODO Archive"

usage() {
  cat <<'USAGE'
Usage: scripts/archive-task-log.sh [--source PATH] [--archive-root PATH] [--keep-date YYYYMMDD] [--max-lines N] [--source-title TITLE] [--archive-title TITLE]
USAGE
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
    --keep-date)
      keep_date="$2"
      shift 2
      ;;
    --max-lines)
      max_lines="$2"
      shift 2
      ;;
    --source-title)
      source_title="$2"
      shift 2
      ;;
    --archive-title)
      archive_title="$2"
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

tmp_dir=$(mktemp -d /tmp/brushpass-task-archive.XXXXXX)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

blocks_dir="$tmp_dir/blocks"
date_lists_dir="$tmp_dir/date-lists"
mkdir -p "$blocks_dir" "$date_lists_dir"

awk -v outdir="$blocks_dir" '
BEGIN {
  block = 0
  file = ""
}
/^## / {
  block += 1
  file = sprintf("%s/%04d.md", outdir, block)
}
{
  if (file != "") {
    print > file
  }
}
' "$source_file"

if ! ls "$blocks_dir"/*.md >/dev/null 2>&1; then
  echo "No task entries found in $source_file" >&2
  exit 1
fi

if [[ -z "$keep_date" ]]; then
  keep_date=$(
    for block_file in "$blocks_dir"/*.md(.N); do
      extract_date "$(sed -n '1p' "$block_file")"
    done | awk 'NF > 0' | sort -r | head -n 1
  )
fi

if [[ -z "$keep_date" ]]; then
  echo "Unable to determine keep date" >&2
  exit 1
fi

current_date=""
for block_file in "$blocks_dir"/*.md(.N); do
  heading=$(sed -n '1p' "$block_file")
  block_date=$(extract_date "$heading")
  if [[ -n "$block_date" ]]; then
    current_date="$block_date"
  fi
  if [[ -z "$current_date" ]]; then
    echo "Block has no date context: $block_file" >&2
    exit 1
  fi
  printf '%s\n' "$block_file" >> "$date_lists_dir/$current_date.txt"
done

keep_list="$date_lists_dir/$keep_date.txt"
if [[ ! -f "$keep_list" ]]; then
  echo "Keep date $keep_date has no entries" >&2
  exit 1
fi

mkdir -p "$archive_root"

# Keep newest blocks that fit in source max lines; move remaining same-day blocks to archive.
keep_lines_budget=$((max_lines - 2))
if (( keep_lines_budget <= 0 )); then
  echo "--max-lines is too small to keep source header" >&2
  exit 1
fi

trimmed_keep_list="$tmp_dir/keep-trimmed.txt"
overflow_keep_list="$tmp_dir/keep-overflow.txt"
: > "$trimmed_keep_list"
: > "$overflow_keep_list"

keep_blocks=("${(@f)$(cat "$keep_list")}")
if (( ${#keep_blocks[@]} == 0 )); then
  echo "Keep date $keep_date has no block entries" >&2
  exit 1
fi

used_lines=0
for block_file in "${keep_blocks[@]}"; do
  block_lines=$(wc -l < "$block_file")
  if (( block_lines + 2 > max_lines )); then
    echo "Task entry is too large for line limit: $block_file" >&2
    exit 1
  fi
  if (( used_lines + block_lines <= keep_lines_budget )); then
    printf '%s\n' "$block_file" >> "$trimmed_keep_list"
    used_lines=$((used_lines + block_lines))
  else
    printf '%s\n' "$block_file" >> "$overflow_keep_list"
  fi
done

if [[ ! -s "$trimmed_keep_list" ]]; then
  echo "Newest day cannot fit into $max_lines lines; split the top entry in $source_file" >&2
  exit 1
fi

new_source="$tmp_dir/new-source.md"
printf '# %s\n\n' "$source_title" > "$new_source"
while IFS= read -r block_file; do
  cat "$block_file" >> "$new_source"
done < "$trimmed_keep_list"

source_line_count=$(wc -l < "$new_source")
if (( source_line_count > max_lines )); then
  echo "Source still exceeds max lines after trim ($source_line_count > $max_lines)" >&2
  exit 1
fi

collect_existing_archive_blocks() {
  local archive_date="$1"
  local out_list="$2"
  local target_dir="$archive_root/$archive_date"
  : > "$out_list"

  local existing_parts
  existing_parts=("$target_dir"/*.md(Nn))
  if (( ${#existing_parts[@]} == 0 )); then
    return
  fi

  local split_dir="$tmp_dir/existing-$archive_date"
  mkdir -p "$split_dir"

  awk -v outdir="$split_dir" '
  BEGIN {
    block = 0
    file = ""
  }
  /^## / {
    block += 1
    file = sprintf("%s/%04d.md", outdir, block)
  }
  {
    if (file != "") {
      print > file
    }
  }
  ' "${existing_parts[@]}"

  for block_file in "$split_dir"/*.md(.N); do
    printf '%s\n' "$block_file" >> "$out_list"
  done
}

write_archive_parts() {
  local archive_date="$1"
  local incoming_list="$2"

  if [[ ! -s "$incoming_list" ]]; then
    return
  fi

  local existing_list="$tmp_dir/existing-list-$archive_date.txt"
  collect_existing_archive_blocks "$archive_date" "$existing_list"

  local merged_list="$tmp_dir/merged-list-$archive_date.txt"
  cat "$incoming_list" > "$merged_list"
  if [[ -s "$existing_list" ]]; then
    cat "$existing_list" >> "$merged_list"
  fi

  local target_dir="$archive_root/$archive_date"
  mkdir -p "$target_dir"
  local existing_parts
  existing_parts=("$target_dir"/*.md(N))
  if (( ${#existing_parts[@]} > 0 )); then
    rm -f "${existing_parts[@]}"
  fi

  local part=1
  local current_file="$target_dir/$(printf '%02d.md' "$part")"
  local current_lines=0

  write_header() {
    local header
    if (( part == 1 )); then
      header="# $archive_title: $archive_date"
    else
      header="# $archive_title: $archive_date (Part $part)"
    fi
    printf '%s\n\n' "$header" > "$current_file"
    current_lines=2
  }

  write_header

  while IFS= read -r block_file; do
    local block_lines
    block_lines=$(wc -l < "$block_file")
    if (( block_lines + 2 > max_lines )); then
      echo "Task entry is too large for archive part limit: $block_file" >&2
      exit 1
    fi
    if (( current_lines + block_lines > max_lines && current_lines > 2 )); then
      part=$((part + 1))
      current_file="$target_dir/$(printf '%02d.md' "$part")"
      write_header
    fi
    cat "$block_file" >> "$current_file"
    current_lines=$((current_lines + block_lines))
  done < "$merged_list"
}

# Archive all non-keep dates from source.
for date_list in "$date_lists_dir"/*.txt(.N); do
  archive_date="${date_list:t:r}"
  if [[ "$archive_date" == "$keep_date" ]]; then
    continue
  fi
  write_archive_parts "$archive_date" "$date_list"
done

# Archive overflowed same-day blocks when source would exceed max lines.
if [[ -s "$overflow_keep_list" ]]; then
  write_archive_parts "$keep_date" "$overflow_keep_list"
fi

mv "$new_source" "$source_file"

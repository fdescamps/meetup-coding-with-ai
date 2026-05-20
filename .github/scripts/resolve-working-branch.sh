#!/usr/bin/env bash
set -euo pipefail

issue_number=""
issue_title=""
provided_branch=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue-number)
      issue_number="${2:-}"
      shift 2
      ;;
    --issue-title)
      issue_title="${2:-}"
      shift 2
      ;;
    --working-branch)
      provided_branch="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

normalize_provided_branch() {
  local value
  value="$(trim "$1")"

  # Normalize branch refs from manual input.
  value="${value#refs/heads/}"

  # Collapse duplicate prefixes such as sdlc/sdlc/42-foo.
  while [[ "$value" == sdlc/sdlc/* ]]; do
    value="sdlc/${value#sdlc/sdlc/}"
  done

  if [[ "$value" != sdlc/* ]]; then
    value="sdlc/$value"
  fi

  printf '%s' "$value"
}

slugify_title() {
  local raw="$1"

  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
  raw="$(printf '%s' "$raw" | sed -E 's/[^a-z0-9]+/-/g')"
  raw="$(printf '%s' "$raw" | sed -E 's/^-+//; s/-+$//; s/-+/-/g')"

  if [[ -z "$raw" ]]; then
    raw="issue"
  fi

  printf '%s' "${raw:0:50}"
}

if [[ -n "$(trim "$provided_branch")" ]]; then
  printf '%s\n' "$(normalize_provided_branch "$provided_branch")"
  exit 0
fi

if [[ -z "$(trim "$issue_number")" ]]; then
  echo "Missing required argument: --issue-number" >&2
  exit 1
fi

if [[ -z "$(trim "$issue_title")" ]]; then
  echo "Missing required argument: --issue-title (when --working-branch is not provided)" >&2
  exit 1
fi

slug="$(slugify_title "$issue_title")"
printf 'sdlc/%s-%s\n' "$issue_number" "$slug"

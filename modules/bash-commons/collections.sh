#!/bin/bash

set -e

# Returns 0 if the given needle is in the given haystack; returns 1 otherwise.
function array_contains {
  local readonly needle="$1"
  shift
  local readonly haystack=($@)

  local item
  for item in "${haystack[@]}"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}
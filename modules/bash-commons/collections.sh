#!/bin/bash

set -e

# Returns successfully if the given needle is in the given haystack; exits with an error otherwise.
function array_contains {
  local readonly needle="$1"
  shift
  local readonly haystack=($@)

  local item
  for item in "${haystack[@]}"; do
    if [[ "$item" == "$needle" ]]; then
      return
    fi
  done

  exit 1
}
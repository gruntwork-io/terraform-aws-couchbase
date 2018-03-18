#!/bin/bash

set -e

function file_exists {
  local readonly file="$1"
  [[ -f "$file" ]]
}

function file_contains_text {
  local readonly text="$1"
  local readonly file="$2"
  grep -q "$text" "$file"
}

function append_text_to_file {
  local readonly text="$1"
  local readonly file="$2"

  echo -e "\n$text" | sudo tee -a "$file"
}

# Replace a line of text in a file. Only works for single-line replacements.
function replace_text_in_file {
  local readonly original_text_regex="$1"
  local readonly replacement_text="$2"
  local readonly file="$3"

  sudo sed -i -e "s|$original_text_regex|$replacement_text|" "$file"
}

function replace_or_append_in_file {
  local readonly original_text_regex="$1"
  local readonly replacement_text="$2"
  local readonly file="$3"

  if $(file_exists "$file") && $(file_contains_text "$original_text_regex" "$file"); then
    replace_text_in_file "$original_text_regex" "$replacement_text" "$file"
  else
    append_text_to_file "$replacement_text" "$file"
  fi
}

#
# Usage: join SEPARATOR ARRAY
#
# Joins the elements of ARRAY with the SEPARATOR character between them.
#
# Examples:
#
# join ", " ("A" "B" "C")
#   Returns: "A, B, C"
#
function join {
  local readonly separator="$1"
  shift
  local readonly values=("$@")

  printf "%s$separator" "${values[@]}" | sed "s/$separator$//"
}

function string_contains {
  local readonly haystack="$1"
  local readonly needle="$2"

  [[ "$haystack" == *"$needle"* ]]
}

function multiline_string_contains {
  local readonly haystack="$1"
  local readonly needle="$2"

  echo "$haystack" | grep -q "$needle"
}
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

  echo -e "\n$text" | sudo tee -a "$file" > /dev/null
}

# Replace a line of text in a file. Only works for single-line replacements.
function replace_text_in_file {
  local readonly original_text_regex="$1"
  local readonly replacement_text="$2"
  local readonly file="$3"

  sudo sed -i "s|$original_text_regex|$replacement_text|" "$file" > /dev/null
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

function to_uppercase {
  local readonly str="$1"
  echo "$str" | awk '{print toupper($0)}'
}

# Strip the prefix from the given string. Supports wildcards.
#
# Example:
#
# strip_prefix "foo=bar" "foo="  ===> "bar"
# strip_prefix "foo=bar" "*="    ===> "bar"
#
# http://stackoverflow.com/a/16623897/483528
function strip_prefix {
  local readonly str="$1"
  local readonly prefix="$2"
  echo "${str#$prefix}"
}

# Strip the suffix from the given string. Supports wildcards.
#
# Example:
#
# strip_prefix "foo=bar" "=bar"  ===> "foo"
# strip_prefix "foo=bar" "=*"    ===> "foo"
#
# http://stackoverflow.com/a/16623897/483528
function strip_suffix {
  local readonly str="$1"
  local readonly suffix="$2"
  echo "${str%$suffix}"
}
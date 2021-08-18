#!/bin/sh

# set values from config file to variables
function set_config_values() {
  revert=false
  types=(build ci docs feat fix perf refactor style chore test)
  min_length=5
  max_length=52
}

# build the regex pattern based on the config file
function build_regex() {
  set_config_values

  regexp="^(Merge .*|("

  if $revert; then
    regexp="${regexp}revert: )?(\w+)("
  fi

  for type in "${types[@]}"
  do
    regexp="${regexp}$type|"
  done

  regexp="${regexp%|})(\(.*\))?: "

  regexp="${regexp}.{$min_length,$max_length})$"
}

# Print out a standard error message which explains
# how the commit message should be structured
function print_error() {
  echo "\n\x1B[1m\x1B[31m[INVALID COMMIT MESSAGE]"
  echo "------------------------\033[0m\x1B[0m"
  echo "\x1B[1mValid types:\x1B[0m \x1B[34m${types[@]}\033[0m"
  echo "\x1B[1mMax length (first line):\x1B[0m \x1B[34m$max_length\033[0m"
  echo "\x1B[1mMin length (first line):\x1B[0m \x1B[34m$min_length\033[0m\n"
}

# get the first line of the commit message
INPUT_FILE=$1
START_LINE=`head -n1 $INPUT_FILE`

build_regex

if [[ ! $START_LINE =~ $regexp ]]; then
  # commit message is invalid according to config - block commit
  print_error
  exit 1
fi

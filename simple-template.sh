#!/bin/bash
set -eu

usage() {
  test "${1:-}" != '--flags' ||
    { declare -f parse_args | sed -Ene 's!\s*(--?[a-zA-Z0-9][a-zA-Z0-9| -]*)\)!\1!p'; return 0; }
  echo "Flags:"; usage --flags
}
parse_args() {
  # _O_K1=false _O_K2=true _O_K3=str
  while test $# -gt 0; do local arg=$1; shift; case "$arg" in
    --) break ;;
    -h|--help) usage; exit 0 ;;
    -v|--verbose) set -x ;;
    # your options
    -*) echo 1>&2 "Bad args: $arg"; exit 1 ;;
    *) set -- "$arg" "$@"; break ;;
  esac; done
  ARGV=( "$@" )
}
parse_args "$@"; set -- "${ARGV[@]}"
test $# -ne 0 && { echo 1>&2 "Bad args: $*"; exit 1; }

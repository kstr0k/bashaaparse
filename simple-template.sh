#!/bin/bash
test $(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 5) )) -eq 1 || exit 1
set -euo pipefail
shopt -s inherit_errexit nullglob globstar # extglob already on in [[ ]] but not ${x#*} ${x/*/}

usage() {
  test "${1:-}" != '--flags' ||
    { declare -f parse_args | sed -Ene 's!\s*(--?[a-zA-Z0-9][a-zA-Z0-9| -]*)\)!\1!p'; return 0; }
  test "${1:-}" != '--defaults' ||
    { declare -p | sed -Ene 's/^declare -[^ ]* _O_(.*)/\1/p'; return 0; }
  echo "Flags:"; usage --flags
  echo "Defaults:"; usage --defaults
}
parse_args() {
  # _O_K1=false _O_K2=true _O_K3=: _O_K4=str  # ternary boolean possible (e.g. --force)
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

errexit_call() {  # args: { RCVAR | '' } CMD ARG... # disable -e, re-enable in subshell, call $@, save exit code # simply calling `func || ...` disables -e for entire func # calling `func` directly under -e prevents checking / ignoring error
  if [[ $1 = '' ]]; then local _RC; else test _RC = "$1" || local -n _RC=$1; fi; shift
  local -; set +e
  (set -e; "$@"); _RC=$?  # returns 0
}

main() {
  test $# -eq 0 || { echo 1>&2 "Bad args: $*"; exit 1; }
}

parse_args "$@"
main "${ARGV[@]}"

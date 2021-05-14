#!/bin/bash
test $(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 5) )) -eq 1 || exit 1
set -euo pipefail
shopt -s inherit_errexit nullglob globstar # extglob already on in [[ ]] but not ${x#*} ${x/*/}
# bashaaparse boilerplate version $(git log -1 --pretty=%h $0)

### remove testing & extra comments:
### sed -Ee '/^\s*##/d'       # vim: :g,^\s*##,d
### enable them:
### sed -Ee 's/^(\s*)##/\1/'  # vim: :%s,^\(\s*\)##,\1,

usage() {
  test "${1:-}" != '--flags' || {
    local pastr=$(declare -f parse_args)
    sed -Ene 's!\s*(--?[a-zA-Z0-9][a-zA-Z0-9| :-]*)\)!\1!p' <<<"$pastr"
    sed -Ene 's!\s*(--?([a-zA-Z0-9][a-zA-Z0-9:-]*))=\*\)!\1=\U\2!p' <<<"$pastr";  # ...=* opts
    return 0
  }
  test "${1:-}" != '--defaults' ||
    { declare -p | sed -Ene 's/^declare -[^ ]* _O_(.*)/\1/p'; return 0; }

  ### positional arg help here
  echo "Flags:"; usage --flags
  echo "Defaults:"; usage --defaults
}
parse_args() {
  ### _O_K1=false _O_K2=true _O_K3=: _O_K4=str  # defaults; ternary logic possible (e.g. --auto)
  while test $# -gt 0; do local arg=$1; shift; case "$arg" in
    --) break ;;
    -h|--help) usage; exit 0 ;;
    -v|--verbose) set -x ;;
    ### naively-parsed / boolean options
    ##-b|--bool|--bool-description) _O_BOOL=true ;;
    ##-s|--str|--str-description:) _O_STR=$1; shift ;;

    ### least code + clearest auto-help: no separate arg, no shortopt (skip to '=*' opts)

    ### separate arg for '...=*': with shortopt
    ##-t|--test-t1) set -- --test-t1="$1" "${@:2}" ;;
    ### ... or less code, but shows separately in help (use next section) ...
    ##-T) set -- --test2 "$@" ;;

    ### separate arg for '...=*': no- or separate- shortopt
    ##--test2) ;& --test-opt-t3)
    ##  set -- "$arg"="$1" "${@:2}" ;;

    ### all '=*' options; don't merge patterns for help & `complete -F _longopt $0`
    ##--test-t1=*) ;& --test2=*) ;& --test-opt-t3=*)
    ##  arg=${arg#--}; local k=${arg%%=*}; arg=${arg#*=}; k=${k//-/_}
    ##  printf -v "_O_${k^^}" '%s' "$arg" ;;

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
  ##usage --defaults  # inspect parse_args results
  test $# -eq 0 || { echo 1>&2 "Bad args: $*"; exit 1; }
}

parse_args "$@"
main "${ARGV[@]}"

### ./simple-template.sh --test-t1 '1 $SHELL' -T 0 --test-opt-t3=x  # test

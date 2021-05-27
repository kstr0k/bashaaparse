#!/bin/bash
#test $(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )) -eq 1 || exit 1

__usage() {  # args: header footer
  local - flags; set -f +o braceexpand
  flags=$(declare -p | sed -Ene 's/^declare -\S*\s+_O_([^=]+)=.*/\1/p')
  printf '%s'  "${1:+${1%$'\n'}$'\n'}"  # add \n only if missing
  test -z "$flags" || printf -- '--%s=ARG\n'  ${flags//_/-}
  printf '%s'  "${2:+${2%$'\n'}$'\n'}"
}
__parse_args() {
  test $# -gt 0 || set -- --
  if ! __process_arg "$@"; then
    case "$1" in
      -v) set -x ;;
      -h|--help|--usage|-'?') __usage 'Options:'; exit 0 ;;
      --*=*)
        local k=${1%%=*}; k=${k#--}; printf -v "_O_${k//-/_}" '%s'  "${1#--*=}"
        ;;
      --noop) return 0 ;;
      --no-?*) __parse_args "--${1#--no-}=false" "${@:2}"; return ;;
      --?*)    __parse_args "$1=true"            "${@:2}"; return ;;
      --) shift ;& *) __main "$@"; return $? ;;
    esac
  fi
  shift; __parse_args "$@"
}

### override these
__main() {
  __usage 'Options:' "Args: ${*@Q}" 1>&2
}
__process_arg() {  # if $1 handled, return 0; exit to stop processing
  return 1;
}
### end override
### (. ~/src/bashaaparse/min-template.sh; __parse_args -v --test-opt=x 1 2)  # test

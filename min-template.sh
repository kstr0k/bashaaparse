#!/bin/bash
#test $(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )) -eq 1 || exit 1
### sed -e '/##bash:/d' -e '/##sh:/{s/^\([[:space:]]*\)#*/\1/;s/[[:space:]]*##*sh:$//}' <min-template.sh  # bash -> sh
### vim bash -> sh: g/##bash:$/d | %s/^\(\s\+\)##\(.\{-}\)\s\+##sh:$/\1\2/
### (. ~/src/bashaaparse/min-template.sh; __parse_args -v --test-opt=x 1 2)  # test

__usage() {  # args: header footer
  local flags
  flags=$(declare -p | sed -ne 's/^declare -[^[:space:]]*[[:space:]]*_O_\([^=]*\)=.*/--\1/; t p; d; :p; s/_/-/g; p;')  ##bash:
  ##flags=$(set | sed -ne 's/^_O_\([^=]*\)=.*/--\1/; t p; d; :p; s/_/-/g; p')  ##sh:
  printf '%s'${1:+'\n'}  "${1:-}"  # add \n only if missing
  test -z "$flags" || printf '%s=ARG\n'  $flags
  printf '%s'${2:+'\n'}  "${2:-}"
}
__parse_args() {
  local k
  test $# -gt 0 || set -- --
  if ! __process_arg "$@"; then
    case "$1" in
      -v) set -x ;;
      -h|--help|--usage|-'?') __usage 'Options:'; exit 0 ;;
      --*=*) k=${1%%=*}; k=_O_${k#--}
        printf -v "${k//-/_}" '%s'  "${1#--*=}"  ##bash:
        ##k=$k-; while :; do case "$k" in  ##sh:
        ##  *-) k=${k%%-*}_${k#*-} ;;  ##sh:
        ##   *) eval "${k%_}=\${1#--*=}"; break ;;  ##sh:
        ##esac; done  ##sh:
        ;;
      --exit) return 0 ;;
      --no-?*) k=$1; shift; __parse_args "--${k#--no-}=false" "$@"; return ;;
      --?*)    k=$1; shift; __parse_args "$k=true"            "$@"; return ;;
      --) shift; __main "$@"; return $? ;;
      *)         __main "$@"; return $? ;;
    esac
  fi
  shift; __parse_args "$@"
}

### override these
__main() {
  __usage 'Options:' "Args: $(test $# -eq 0 || printf '{%s} ' "$@")" 1>&2
}
__process_arg() {  # if $1 handled, return 0; exit to stop processing
  return 1;
}
### end override

#!/usr/bin/env bash
### vim bash -> sh: g/##bash:$/d | %s/^\(\s\+\)##\(.\{-}\)\s\+##sh:$/\1\2/
### (. ~/src/bashaaparse/min-template.sh; __parse_args -v --test-opt=x 1 2)  # test

__usage() {  # args: header footer
  local flags p1; p1='_O_\([^=]*\)=.*/--\2/; t p; d; :p; s/_/-/g; p'
  flags=$(declare -p | sed -ne 's/^'"${ZSH_VERSION+typeset}${BASH_VERSION+declare}"' \(-[^[:space:]]\)*[[:space:]]*'"$p1")  ##bash:
  ##flags=$(set | sed -ne 's/^\(\)'"$p1")  ##sh:
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
__parse_args_debug_main() {
  __usage 'Options:' "Args: $(test $# -eq 0 || printf '{%s} ' "$@")" 1>&2
}
__process_arg() {  # if $1 handled, return 0; exit to stop processing
  case "$1" in
    ----gen=*) local sh osh src; src=$0; sh=${1#----gen=}; osh=ba$sh; osh=${osh#baba}
      src=${ZSH_VERSION+${(%):-%x}}${BASH_VERSION+${BASH_SOURCE}}  ##bash:
      sed <"$src" -n \
        -e "/##$osh:/d" -e "s/[[:space:]]*##$sh:$//; "'t s; p; d; :s; s/^\([[:space:]]*\)#*/\1/; p'
      return 0 ;;
  esac; return 1
}
__main() { __parse_args_debug_main "$@"; }
### end override

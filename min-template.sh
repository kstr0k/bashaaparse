#!/bin/sh
### vim bash -> sh: g/##bash:$/d | %s/^\(\s\+\)##\(.\{-}\)\s\+##sh:$/\1\2/
### (. ~/src/bashaaparse/min-template.sh; __parse_args -v --test-opt=x 1 2)  # test
### bash -uec '. ./min-template.sh; __parse_args ----gen=sh-strip >mt.sh'  # generate sh version
#shellcheck disable=SC3028,SC3043

__usage() {  # args: header footer
  local flags p1='_O_\([^=]*\)=.*/--\2=ARG/' p2=tp p3=d p4=:p p5='s/_/-/g;p'
  #if [ "${BASH_VERSION:-}" ]; then flags=$(compgen -v | sed -n -e 's/_/-/g' -e 's/^-O-\(.*\)/--\1=ARG/p')  ##bash:
  #elif [ "${ZSH_VERSION:-}" ]; then flags=$(declare -p | sed -n -e '/^typeset /bl1' -e '/^export /bl1' -e d -e :l1 -e 's/[^[:space:]]\{1,\}[[:space:]]\{1,\}\(-[^[:space:]]*[[:space:]]\{1,\}\)*'"$p1" -e "$p2" -e "$p3" -e "$p4" -e "$p5"); fi  ##bash:
  flags=$(set | sed -n -e 's/^\(\)'"$p1" -e "$p2" -e "$p3" -e "$p4" -e "$p5")  ##sh:
  printf '%s'${1:+'\n'}  "${1:-}"  # add \n only if missing
  test -z "$flags" || printf '%s\n' "$flags"
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
        #printf -v "${k//-/_}" '%s'  "${1#--*=}" ;;  ##bash:
        k=$k-; while :; do case "$k" in  ##sh:
          *-) k=${k%%-*}_${k#*-} ;;  ##sh:
           *) eval "${k%_}=\${1#--*=}"; break ;;  ##sh:
        esac; done ;;  ##sh:
      --exit) return 0 ;;
      --no-?*) k=$1; shift; __parse_args "--${k#--no-}=false" "$@"; return ;;
      --?*)    k=$1; shift; __parse_args "$k=true"            "$@"; return ;;
      --) shift; __main "$@"; return $? ;;
      *)         __main "$@"; return $? ;;
    esac
  fi
  shift; __parse_args "$@"
}

### override / remove these as desired
__parse_args_debug_main() {
  if [ "${_O___gen:-}" ]; then
      local sh osh src strip; strip=false; src=${_O_src:-}
      : "${src:=${BASH_VERSION+${BASH_SOURCE:-}}}"  # could be bash only; keep it in sh, in case sourced from bash
      [ -z "${ZSH_VERSION:-}" ] || eval ': "${src:=${(%):-%x}}"'  # ditto; yash breaks without eval even with unexec'ed subshell
      case "${src##*/}" in bash|zsh|sh) unset Bad && : "${Bad?source "$src" (use --src=)}" ;; esac
      sh=${_O___gen#----gen=}; [ "${sh%%*-strip}" ] || { sh=${sh%-strip}; strip=true; }
      osh=ba$sh; osh=${osh#baba}
      local s1="/##$osh:"'$/{s/\(^[[:space:]]*\)/\1#/p;d;}' s2='\1'
      if $strip; then s1="/##$osh:"'$/d'; s2=''; fi
      (set -x; sed <"$src" -n -e '1{s@^\(#!\).*'"@\1/bin/$sh@p;d;}" -e "$s1" -e 's/\([[:space:]]*##'"$sh"':\)$/'"$s2"'/' -e ts -e 'p;d' -e :s -e 's/^\([[:space:]]*\)#*/\1/' -e p)
  fi
  __usage 'Options:' "Args:$(test $# -eq 0 || printf ' {%s}' "$@")" 1>&2
}
__process_arg() {  # if $1 handled, return 0; exit to stop processing
  return 1
}
__main() { __parse_args_debug_main "$@"; }
### end override

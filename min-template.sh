#!/bin/sh
### vim bash -> sh: g/##bash:$/d | %s/^\(\s\+\)##\(.\{-}\)\s\+##sh:$/\1\2/  ##strip1:
### (. ~/src/bashaaparse/min-template.sh; __parse_args -v --test-opt=x 1 2)  # test
### bash -uec '. ./min-template.sh; __parse_args ----gen=sh-strip >mt.sh'  # generate sh version  ##stripn:
#shellcheck disable=SC3028,SC3043

__usage() {  # args: <help-option> header footer
  local vs=false; [ "$1" != '-?' ] || vs=true; shift
  local flags p='/^_O_/!d;/[^[:alnum:]_]/d;h;s/_/-/g;s/^-O-/--/;s/$/=ARG/p'
  ! "$vs" || p=${p%';s'*}';G;s/\n/[='\''$/;s/$/'\'']/p'
  #flags=$({ [ -z "${BASH_VERSION:-}" ] || compgen -v; [ -z "${ZSH_VERSION:-}" ] || emulate zsh -c 'zmodload zsh/parameter; print -rl -- ${(k)parameters}'; } | sed -n -e "$p")  ##bash:
  flags=$(set | sed -n -e '/=/!d;s/=.*//' -e "$p")  # posh fails: no =.*  ##sh:
  printf '%s'${1:+'\n'}  "${1:-}"
  test -z "$flags" || { ! "$vs" || eval flags="\"$flags\""; printf '%s\n' "$flags"; }
  printf '%s'${2:+'\n'}  "${2:-}"
}
__parse_args() {
  local k; test $# -gt 0 || set -- --
  if ! __process_arg "$@"; then case "$1" in
      -v) set -x ;;
      -h|--help|--usage|-'?') __usage "$1" 'Options:'; exit 0 ;;
      --*=*) k=${1%%=*}; k=_O_${k#--}
        case "$k" in *[![:alnum:]_-]*) unset Bad; : "${Bad?arg "$k"}";; esac
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
  esac; fi
  shift; __parse_args "$@"
}

### override / remove these as desired
__process_arg() { return 1; }  # if $1 handled, return 0; exit to stop processing
__main() { __parse_args_debug_main "$@"; }
__parse_args_debug_main() {
  if [ "${_O___gen:-}" ]; then  ##strip1:
      local sh osh src strip; strip=false; src=${_O_src:-}
      sh=${_O___gen#----gen=};
      case "$sh" in *-strip) sh=${sh%-strip}; strip=true ;; esac
      [ -r "${BASH_SOURCE:-}" ] && exec <"$BASH_SOURCE" ||
        :  # zsh ${(%):%x}; sh: impossible
      osh=ba$sh; osh=${osh#baba}
      local s1="/##$osh:"'$/{s/\(^[[:space:]]*\)/\1#/p;d;}' s2='\1'
      set -- -n; if "$strip"; then
        s1="/##$osh:"'$/d'; s2=''; set -- "$@" -e '/##strip1:$/,/##stripn:$/d'
      fi
      local from='#'; ! "$strip" || from=$from' stripped'
      from="$from $sh"' min-template.sh (https://gitlab.com/kstr0k/bashaaparse)'
      set -- "$@" -e '1{s@^\(#!\).*'"@\1/bin/$sh@p;s@.*@$from@p;d;}" \
        -e "$s1" -e 's/\([[:space:]]*##'"$sh"':\)$/'"$s2"'/' -e ts -e 'p;d' \
        -e :s -e 's/^\([[:space:]]*\)#*/\1/;p'
      (set -x; sed "$@"); exit 0
  fi  ##stripn:
  __usage '' 'Options:' "Args:$(test $# -eq 0 || printf ' {%s}' "$@")" 1>&2
}
__abspath_arg0() {  # args: outvar [relpath]
  [ "$1" = d ] || local d; d=${ZSH_ARGZERO:-$0}
  case "$d" in /*) ;; *) d=$PWD/$d ;; esac
  if [ $# -ge 2 ]; then d=${d%/*}; d=${d:-/}${1#*=}; fi
  [ "$1" = d ] || eval "$1=\$d"
}
### end override

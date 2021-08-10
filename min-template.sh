#!/bin/sh
### vim bash -> sh: g/##bash:$/d | %s/^\(\s\+\)##\(.\{-}\)\s\+##sh:$/\1\2/
### (. ~/src/bashaaparse/min-template.sh; __parse_args -v --test-opt=x 1 2)  # test
### bash -uec '. ./min-template.sh; __parse_args ----gen=sh-strip >mt.sh'  # generate sh version
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
      (set -x; sed <"$src" -n -e '1{s@^\(#!\).*'"@\1/bin/$sh@p;d;}" -e "$s1" -e 's/\([[:space:]]*##'"$sh"':\)$/'"$s2"'/' -e ts -e 'p;d' -e :s -e 's/^\([[:space:]]*\)#*/\1/;p')
  fi
  __usage '' 'Options:' "Args:$(test $# -eq 0 || printf ' {%s}' "$@")" 1>&2
}
__process_arg() { return 1; }  # if $1 handled, return 0; exit to stop processing
__main() { __parse_args_debug_main "$@"; }
### end override

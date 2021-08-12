#!/bin/sh
### vim bash -> sh: g/##bash:$/d | %s/^\(\s\+\)##\(.\{-}\)\s\+##sh:$/\1\2/  ##strip1:
### (. ~/src/bashaaparse/min-template.sh; __parse_args -v --test-opt=x 1 2)  # test
### bash -uec '. ./min-template.sh; __parse_args ----gen=sh-strip >mt-s_sh.sh'  # generate sh version  ##stripn:
#shellcheck disable=SC3028,SC3043

__usage() {  # args: <help-option> header footer
  local vs=false; [ "$1" != '-?' ] || vs=true; shift
  local flags p='/^_O_/!d;/[^[:alnum:]_]/d;h;s/_/-/g;s/^-O-/--/;s/$/=ARG/p'
  ! "$vs" || p=${p%';s'*}';G;s/\n/[='\''$/;s/$/'\'']/p'
  #flags=$(if [ "${BASH_VERSION:-}" ]; then compgen -v; elif [ "${ZSH_VERSION:-}" ]; then emulate zsh -c 'zmodload zsh/parameter; print -rl -- ${(k)parameters}'; fi | sed -n -e "$p")  ##bash:
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
        case "$k" in (*[![:alnum:]_-]*) unset Bad; : "${Bad?arg "$k"}";; esac
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
__process_arg() { return 1; }  # if $1 handled return 0; exit to stop processing
__main() { __min_template_debug_main "$@"; }
__min_template_debug_main() {
  if [ "${_O___gen:-}" ]; then  ##strip1:
    set -eu
    local sh osh strip=false url='https://gitlab.com/kstr0k/bashaaparse'
    sh=${_O___gen#----gen=}
    case "$sh" in (*-strip) sh=${sh%-strip}; strip=true ;; esac
    if [ -z "${_O_src:-}" ]; then  # sh: impossible
      if [ -r "${BASH_SOURCE:-}" ]; then _O_src=$BASH_SOURCE
      #elif [ "$ZSH_VERSION" ]; then _O_src=${(%):-%x}  # yash breaks; eval ''
      else _O_src=http://; fi
    fi
    case "$_O_src" in
      ('#!'*) exec <<EOSTR
$_O_src
EOSTR
        _O_src=- ;;
      (http://*|https://*|ftp://*) _O_src=$(
        [ "$_O_src" != 'http://' ] || _O_src=$url'/-/raw/master/min-template.sh'
        set -- "$_O_src"; exec 2>/dev/null
        curl -s "$@" || { set -- wget -O- -q "$@"; "$@" || busybox "$@"; })
exec <<EOGET
$_O_src
EOGET
        _O_src=- ;;
    esac
    [ -z "${_O_src:-}" ] || [ "${_O_src:-}" = - ] || exec <"$_O_src"
    osh=ba$sh; osh=${osh#baba}
    local s1="/##$osh:"'$/{s/\(^[[:space:]]*\)/\1#/p;d;}' s2='\1'
    set -- -n; if "$strip"; then
      s1="/##$osh:"'$/d'; s2=''; set -- "$@" -e '/##strip1:$/,/##stripn:$/d'
    fi
    local from='#'; ! "$strip" || from=$from' stripped'
    from="$from $sh min-template.sh ($url)"
    set -- "$@" -e '1{s@^\(#!\).*'"@\1/bin/$sh@p;s@.*@$from@p;d;}" \
      -e "$s1" -e 's/\([[:space:]]*##'"$sh"':\)$/'"$s2"'/' -e ts -e 'p;d' \
      -e :s -e 's/^\([[:space:]]*\)#*/\1/;p'
    (set -x; sed "$@"); exit 0
  fi  ##stripn:
  __usage '' 'Options:' "Args:$(test $# -eq 0 || printf ' {%s}' "$@")" 1>&2
}
# busybox-like muxer; minimizes fork/exec cost (subshells, $(), external cmds)
__min_template_util() {
case "$1" in
  # like outvar=$(realpath "$(dirname "$path")")/relpath, but no fork/exec cost
  (abspath_resolve_ref) shift  # args: outvar path [relpath]
    [ "$1" = f ] || local f; f=$2
    case "$f" in /*) ;; *) f=$PWD/$f ;; esac
    if [ $# -ge 2 ]; then f=${f%/*}; f=${f%/}/$3; fi
    [ "$1" = f ] || eval "$1=\$f"
    ;;
  # like cmd=$(which try1 || which try 2 ...)
  (which1) shift  # args: WHICH_CMD TRY..; echoes path; $_R4_which1 = ok-TRY
    local which="${1:-command -v}"; shift  # $1='...>/dev/null' to use only _R4_
    while [ $# -gt 0 ]; do
      if eval "$which" '"$1"' 2>/dev/null; then _R4_which1=$1; return 0; fi
    shift; done; return 1 ;;
esac
}
### end override

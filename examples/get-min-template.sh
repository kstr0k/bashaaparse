#!/bin/sh

# run directly, source from script, or copy/paste

# copied from min-template -- unavailable when bootstapping
__min_template_abspath_arg0_ref() {  # args: outvar [relpath]
  [ "$1" = f ] || local f; f=${ZSH_ARGZERO:-$0}
  case "$f" in /*) ;; *) f=$PWD/$f ;; esac
  if [ $# -ge 2 ]; then f=${f%/*}/"$2"; fi
  [ "$1" = f ] || eval "$1=\$f"
}

# get missing min-template.sh
__min_template_get() {
  local mt='https://gitlab.com/kstr0k/bashaaparse/-/raw/master/min-template.sh'
  mt=$(set -- "$mt"; exec 2>/dev/null
    curl -s "$@" || { set -- wget -O- -q "$@"; "$@" || busybox "$@"; })
  (eval "$mt";  __parse_args --src="$mt" ----gen=sh-strip)
}
while [ $# -gt 0 ]; do case "${1:-}" in
  --) shift; break ;;
  -v) set -x; shift ;;
  --help) cat <<'EOH'
Usage:
  get-min-template.sh ARGS..
  . get-min-template.sh ARGS..  # source in another script
Can be sourced from sh / bash / zsh scripts.
Args: [-v] --get={ - | ./RELPATH | ../RELPATH | PATH } [--load] [--] ...
  --get=-: print to stdout
  --get=...: download & save stripped sh min-template to file (no overwrite)
    RELPATH is relative to sourcing script (or myself if invoked directly)
    A PATH not starting with ./ or ../ is left as-is ($PWD/... avoids RELPATH)
  --load (only after --get=...): load min-template from --get= path (use with .)
  --: stop processing
In scripts, to download if missing & load:
    set -- --get=./min-template.sh --load -- "$@"; . get-min-template.sh
    __main() { ... }
    __parse_args "$@"  # args unchanged
EOH
    shift ;;
  --get=-) shift; __min_template_get ;;
  --get=./*|--get=../*)
    __min_template_abspath_arg0_ref __min_template_arg "${1#*=}"
    shift; set -- "--get=$__min_template_arg" "$@" ;;
  --get=*)
    [ -r "${1#*=}" ] || __min_template_get >"${1#*=}"
    [ "${2:-}" != --load ] || . "${1#*=}"
    shift ;;
  --load) shift ;;  # only modifies preceding --get=
  *) break ;;
esac; done

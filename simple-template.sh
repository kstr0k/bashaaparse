#!/bin/bash
test $(( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) )) -eq 1 || exit 1
set -euo pipefail #; set -o braceexpand
shopt -s inherit_errexit nullglob globstar # extglob already on in [[ ]] but not ${x#...} ${x/.../} /bin/*([^-])
# bashaaparse boilerplate version $("$0" --version)
### remove testing & extra comments:
### sed -Ee '/^\s*##/d'  # vim: :g,^\s*##,d
### enable & test:
### sed -Ee 's/^(\s*)##/\1/' simple-template.sh | bash -s -- --test-t1 '1 $SHELL' --bool -s '* what '\''a'\'' "day"!' -T 0 --test-opt-t3=x -g --no-dash --bad
### uncomment in vim: :%s,^\(\s*\)##,\1,

parse_args() {
  ##_O_K1=false _O_K2=true _O_K3=: _O_K4='str '\''v'\'' "*"'  # defaults; ternary logic possible (e.g. --auto)
  while test $# -gt 0; do local arg=$1; shift; case "$arg" in
    --) break ;;
    -h|--help) usage; exit 0 ;;
    -v|--verbose) set -x ;;
    -V|--version) usage --version; exit 0 ;;
    ### 1. explicitly-parsed / boolean options
    ##-b|--bool|--bool-description) _O_BOOL=true ;;
    ##-s|--str|--str-description:) _O_STR=$1; shift ;;
    ### least code + clearest auto-help: no separate args, no shortopts (skip to 3.)

    ### 2.1 shortopts for booleans (show separately in help; add longopt to 3.)
    ##-g) set -- --use-git "$@" ;;
    ### 2.2.1 separate arg for '...=*': with shortopt
    ##-t|--test-t1) set -- --test-t1="$1" "${@:2}" ;;
    ### 2.2.2 or less code (shows separately in help; add longopt to 3.) ...
    ##-T) set -- --test2 "$@" ;;
    ### 2.3 separate arg for '...=*': no- or separate- shortopt
    ##--test2) ;& --test-opt-t3)
    ##  set -- "$arg"="$1" "${@:2}" ;;

    ### 3. all --bool, --no-bool, '=*' options; don't merge patterns for help & `complete -F _longopt $0`
    ##--test-t1=*) ;& --test2=*) ;& --test-opt-t3=*) ;& --use-git) ;& --no-dash)
    ##  usage --process1 "$arg" ;;

    -*) usage --dieusage 1 "Bad args: $arg" ;;
    *) set -- "$arg" "$@"; break ;;
  esac; done
  ARGV=( "$@" )
}
usage() {
  if test $# -eq 0; then cat <<EOHELP; return 0; fi
Usage: $(basename -- "$BASH_SOURCE") [OPTION...]
Options:
$(usage --flags)
Defaults:
$(usage --defaults)
EOHELP

  case "$1" in  # serve as all-purpose helper function
    --die) local rc=$2; shift 2; [[ $* = '' ]] || echo 1>&2 "$*"; exit "$rc" ;;  # stderr
    --dieusage) usage 1>&2; shift; test $# -lt 2 || set -- "$1" $'\n'"$2" "${@:3}"; usage --die "$@" ;;
    --flags)  # optional indent str: '', '*   ' etc. (default: 2 spaces) # goes as-is into sed 's!!...!' replacement
      local pastr; pastr=$(declare -f parse_args)
      sed -Ene 's!^\s*(--?[a-zA-Z0-9][a-zA-Z0-9| :-]*)\)!'"${2:-  }"'\1!p' <<<"$pastr"
      sed -Ene 's!^\s*(--?([a-zA-Z0-9][a-zA-Z0-9:-]*))=\*\)!'"${2:-  }"'\1=\U\2!p' <<<"$pastr";  # ...=* opts
      ;;
    --defaults) declare -p | sed -Ene 's!^declare -[^ ]* _O_(.*)!'"${2:-  }"'\1!p' ;;
    --process1)
      local arg=${2#--} k; k=${arg%%=*}
      if test "$k" = "$arg"; then
        ### boolean --do-so or --no-do-so # remove if unneeded
        if [[ $k = no-* ]]; then k=${k#no-}; arg=false; else arg=true; fi
      else arg=${arg#*=}
      fi
      k=${k//-/_}; printf -v "_O_${k^^}" '%s' "$arg" ;;
    --mes)  # 0=$F 1=$SYMF 2=D 3=SYMD 4=$B 5=$SYMB # SYM = symlinks preserved
      __ME=( "$(realpath -- "$BASH_SOURCE")" "$(realpath -sm -- "$BASH_SOURCE")" )
      local DME; mapfile -t -d '' DME < <(dirname -z "${__ME[@]}"); __ME+=( "${DME[@]}" )
      mapfile -t -d '' DME < <(basename -az "${__ME[@]:0:2}"); __ME+=( "${DME[@]}" )
      ;;
    --me) local __ME; usage --mes; echo "$__ME" ;;
    --version)
      local __ME; usage --mes
      git 2>/dev/null -C "${__ME[2]}" -P log -1 --pretty=%h:%at "${__ME[4]}"  ||
        stat -c %Z "$__ME"  # no git
      ;;
    *) usage --die 1 "Internal error: $1" ;;
  esac
  return 0
}

errexit_call() {  # args: { RCVAR | '' } CMD ARG... # disable -e, re-enable in subshell, call $@, save exit code # simply calling `func || ...` disables -e for entire func # calling `func` directly under -e prevents checking / ignoring error
  if [[ $1 = '' ]]; then local _RC; else test _RC = "$1" || local -n _RC=$1; fi; shift
  local -; set +e
  (set -e; "$@"); _RC=$?  # returns 0
}

main() {
  ##usage --defaults  # inspect parse_args results
  test $# -eq 0 || usage --dieusage 1 "Bad args: $*"
}

parse_args "$@"
main "${ARGV[@]}"

#!/bin/sh
set -u
cd -- "$(dirname -- "$0")"
. ./k9s0ke_t3st_lib.sh

## --- HOWTO / SETUP

# curl -s https://gitlab.com/kstr0k/t3st/-/raw/master/git-t3st-setup | sh
# prove [-e $shell] [-v]
## Automatically test several shells:
# git [-c t3st.prove-shells='...'] t3st-prove [-v]
# git config t3st.prove-shells 'dash,bash,busybox sh,zsh#,bash --posix,bash44,bash32,zsh --emulate sh,zsh --emulate ksh,mksh,yash'


# --- INFRASTRUCTURE

# figure out sed implementations
__mask_sed() {
  case "$1" in
    ''|'sed'|'sed '*) return 0 ;;  # avoid infinite loop
  esac
  eval "sed() { $1 \"\$@\"; }"
}
__find_seds() {
  __MIN_T_SEDS= __busybox_sed= __gsed_posix= __gsed=
  local pathsed; pathsed=$(command -v sed || :)
  # busybox sh with builtin sed: command -v -> sed, which -> /path/to
  [ "${pathsed#/}" != "${pathsed}" ] || pathsed=$(which sed)
  for __Tsed in "$pathsed" gsed sed 'busybox sed' psed; do
    command -v "${__Tsed%% *}" >/dev/null 2>&1 || continue
    case "$(__mask_sed "$__Tsed"; sed </dev/null --help 2>&1)" in
      *'using GNU software:'*) : "${__gsed:=$__Tsed}"; : "${__gsed_posix:=$__Tsed --posix}" ;;
      'BusyBox v'*) : "${__busybox_sed:=$__Tsed}" ;;
      *) __MIN_T_SEDS="$__MIN_T_SEDS,$__Tsed" ;;
      '') continue ;;
    esac
    __MIN_T_SEDS="$__MIN_T_SEDS,$__busybox_sed,$__gsed,$__gsed_posix"
  done
}
if [ -z "${__MIN_T_SEDS:-}" ]; then __find_seds; fi

# abbreviations
TTT()   { k9s0ke_t3st_one "$@"; }
TTT_e() { k9s0ke_t3st_one errexit=true "$@"; }
TTTnl=$k9s0ke_t3st_nl
  # min-template.sh test helper
TTT_mint() {
  # default pp= replaces stdout with stderr log; can be overriden
  local __min_t_stderr; __min_t_stderr=$k9s0ke_t3st_tmp_dir/stderr.log
  # repeated code
  local __Th='__mask_sed "$__Tsed"; exec 2>"$__min_t_stderr"'
  local __Tpp='cat "$__min_t_stderr"'

  local __Tseds __Tsed; __Tseds=$__MIN_T_SEDS',';  # try various sed's
  while [ "$__Tseds" ] ; do
    __Tsed=${__Tseds%%,*}; __Tseds=${__Tseds#*,}; [ "$__Tsed" ] || continue
    TTT spec="dash-mint + '$__Tsed'" pp="$__Tpp" hook_test_pre='. "$__min_t_dash"; '"$__Th" "$@";
    [ "${BASH_VERSION:-}${ZSH_VERSION:-}" ] || continue
    TTT spec="bash-mint + $__Tsed" pp="$__Tpp" hook_test_pre='. "$__min_t_bash"; '"$__Th" "$@";
  done
  rm -f "$__min_t_stderr"
}


# --- TESTS

k9s0ke_t3st_enter

k9s0ke_t3st_mktemp __min_t_dash; export __min_t_dash
k9s0ke_t3st_mktemp __min_t_bash; export __min_t_bash
TTT_e nl=false hook_test_pre='__mask_sed "${__gsed_posix:-}"; exec >"$__min_t_bash"' spec='# TODO : try to generate bash version' \
 -- eval '. ../min-template.sh; __parse_args ----gen=bash --src=../min-template.sh'
TTT_e nl=false hook_test_pre='exec >"$__min_t_dash"' spec='# TODO : try to generate sh version' \
 -- bash -euc '. "$__min_t_bash"; __parse_args ----gen=sh --src=../min-template.sh'

TTT_mint out="Options:$TTTnl--opt-1-x=ARG${TTTnl}Args: {1 2} { 3 }" \
  -- __parse_args --opt-1-x='_O_opt2 X' '1 2' ' 3 '
TTT_mint out="Options:$TTTnl--opt-1-x[=' x $TTTnl y z ']" pp= \
  -- __parse_args --opt-1-x=" x $TTTnl y z " '-?'
TTT_mint out="Options:$TTTnl--opt-1-x=ARG${TTTnl}Args: {1 2} {3}" spec+=' # TODO : support vars containing "\n_O_"' \
  -- __parse_args --opt-1-x="$TTTnl"_O_opt2= '1 2' '3'
TTT_mint pp= out="xy" \
  -- eval '__parse_args --opt-1-x=xx --opt2=y; echo "${_O_opt_1_x%x}$_O_opt2"'
TTT_mint pp= out="--opt-1-x=ARG$TTTnl--opt2-=ARG" \
  -- eval '__parse_args --opt_1-x=xx --opt2_=y; grep ^--opt-1 "$__min_t_stderr"; grep ^--opt2- "$__min_t_stderr"'

k9s0ke_t3st_leave

# vim: set ft=sh:

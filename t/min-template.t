#!/bin/sh
cd "${0%/*}"/
. ./k9s0ke_t3st_lib.sh
set -u

TTT()   { k9s0ke_t3st_one "$@"; }
TTT_e() { k9s0ke_t3st_one errexit=true "$@"; }
TTTnl=$k9s0ke_t3st_nl

TTT_mint() {
  # default pp= replaces stdout with stderr log; can be overriden
  local __min_t_stderr; __min_t_stderr=$k9s0ke_t3st_tmp_dir/stderr.log
  TTT pp='cat "$__min_t_stderr"' hook_test_pre='. "$__min_t_dash"; exec 2>"$__min_t_stderr"' "$@";
  [ -z "${BASH_VERSION:-}${ZSH_VERSION:-}" ] ||
    TTT pp='cat "$__min_t_stderr"' hook_test_pre='. "$__min_t_bash"; exec 2>"$__min_t_stderr"' "$@";
  rm -f "$__min_t_stderr"
}

k9s0ke_t3st_enter

k9s0ke_t3st_mktemp __min_t_dash; export __min_t_dash
k9s0ke_t3st_mktemp __min_t_bash; export __min_t_bash
TTT_e nl=false hook_test_pre='exec >"$__min_t_dash"' spec='# TODO : try to generate sh version' \
 -- bash -uec '. ../min-template.sh; __parse_args ----gen=sh --src=../min-template.sh'
TTT_e nl=false hook_test_pre='exec >"$__min_t_bash"' spec='# TODO : try to generate bash version' \
 -- bash -uec '. ../min-template.sh; __parse_args ----gen=bash --src=../min-template.sh'

TTT_mint out="Options:$TTTnl--opt-1-x=ARG${TTTnl}Args: {1 2} {3}" \
  -- __parse_args --opt-1-x=xx '1 2' '3'
TTT_mint pp= out="xy" \
  -- eval '__parse_args --opt-1-x=xx --opt2=y; echo "${_O_opt_1_x%x}$_O_opt2"'

k9s0ke_t3st_leave

# prove [-v] [-e $shell] hello-t3st.t
# prove [...] [-r] t/
# git t3st-prove [-...] # if set up
# git t3st-setup        # update / repair

# vim: set ft=sh:

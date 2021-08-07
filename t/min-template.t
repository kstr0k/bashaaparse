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
  local __Tsed=$__real_sed
  local __Th='__mask_sed; exec 2>"$__min_t_stderr"'
  for __Tsed in "$__real_sed" "$(! $__sed_has_posix || echo __posix_sed)" "${__MIN_T_SED:-}"; do
    [ "$__Tsed" ] || continue
    TTT spec="dash-mint + $__Tsed" pp='cat "$__min_t_stderr"' hook_test_pre='. "$__min_t_dash"; '"$__Th" "$@";
    [ -z "${BASH_VERSION:-}${ZSH_VERSION:-}" ] ||
      TTT spec="bash-mint + $__Tsed" pp='cat "$__min_t_stderr"' hook_test_pre='. "$__min_t_bash"; '"$__Th" "$@";
  done
  rm -f "$__min_t_stderr"
}

__real_sed=$( if [ "${POSH_VERSION:-}" ]; then which sed; else command -v sed; fi)
__sed_has_posix=$( [ "$__real_sed" != sed ] && (sed --posix -e :x </dev/null >/dev/null 2>&1) && echo true || echo false )
if $__sed_has_posix; then
  __posix_sed() { "$__real_sed" --posix "$@"; }
  __mask_sed() { sed() { eval "$__Tsed \$@"; }; }  # avoid nested eval
else
  __posix_sed() { sed "$@"; }
  __mask_sed() { :; }
fi

k9s0ke_t3st_enter

k9s0ke_t3st_mktemp __min_t_dash; export __min_t_dash
k9s0ke_t3st_mktemp __min_t_bash; export __min_t_bash
TTT_e nl=false hook_test_pre='__Tsed=__posix_sed; __mask_sed; exec >"$__min_t_bash"' spec='# TODO : try to generate bash version' \
 -- eval '. ../min-template.sh; __parse_args ----gen=bash --src=../min-template.sh'
TTT_e nl=false hook_test_pre='exec >"$__min_t_dash"' spec='# TODO : try to generate sh version' \
 -- bash -euc '. "$__min_t_bash"; __parse_args ----gen=sh --src=../min-template.sh'

TTT_mint out="Options:$TTTnl--opt-1-x=ARG${TTTnl}Args: {1 2} {3}" \
  -- __parse_args --opt-1-x=xx '1 2' '3'
TTT_mint pp= out="xy" \
  -- eval '__parse_args --opt-1-x=xx --opt2=y; echo "${_O_opt_1_x%x}$_O_opt2"'
TTT_mint pp= out="--opt-1-x=ARG$TTTnl--opt2-=ARG" \
  -- eval '__parse_args --opt_1-x=xx --opt2_=y; grep ^--opt-1 "$__min_t_stderr"; grep ^--opt2- "$__min_t_stderr"'

k9s0ke_t3st_leave

# prove [-v] [-e $shell] hello-t3st.t
# prove [...] [-r] t/
# git t3st-prove [-...] # if set up
# git t3st-setup        # update / repair

# vim: set ft=sh:

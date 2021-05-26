#!/bin/bash -neu

# Copyright 2021 Alin Mr. <almr.oss@outlook.com>. Licensed under the MIT license (https://opensource.org/licenses/MIT).

# Minimally viable bash associative array-based argparser

# @k9s0ke bashaap
__k9s0ke_bashaap_chkver() {
  local __k9s0ke_BASHAAP_VERSION=2.1.0  # MAJOR.minor.patch
  [[ ${BASH_VERSINFO[0]} -gt 4 ]] || [[ ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -ge 4 ]] ||
    { echo 1>&2 "bash too old"; return 1; }
  [[ $1 = '----v'* ]] || return 1
  local v=${1#----v}; [[ $v = [0-9]* ]] ||  # required by user, string
    { echo 1>&2 "Bad bashaap args: $*"; return 1; }
  local vpat='^([^.]+)\.([^.+])'  # regex for MAJOR.minor
  [[ $__k9s0ke_BASHAAP_VERSION =~ $vpat ]] || return 1; local pv=( "${BASH_REMATCH[@]}" )  # provided version
  [[ $v =~ $vpat ]]                        || return 1; local rv=( "${BASH_REMATCH[@]}" )  # required version
  [[ ${rv[1]} -eq ${pv[1]} && ${rv[2]} -le ${pv[2]} ]] ||  # provided MAJOR = required, minor >= required
    { echo 1>&2 "ERROR: mismatched bashaap version (need $v, got $__k9s0ke_BASHAAP_VERSION)"; return 1; }
  return 0
}
__k9s0ke_bashaap_chkver "$@"

# --- x8 --- start here to embed script ---
# embedded bashaaparse; see https://gitlab.com/kstr0k/bashaaparse
__k9s0ke_amember() {
  local h ndl=$1; shift
  for h; do test "$ndl" = "$h" && return 0; done
  return 1
}

__k9s0ke_aappend() {
  test _f = "$1" || local -n _f=$1; shift
  test _t = "$1" || local -n _t=$1; shift
  local k; for k in "${!_f[@]}"; do _t[$k]=${_f[$k]}; done
}

__k9s0ke_on_switch() {
  test _n = "$1" || local -n _n=$1; shift; _n=0
  case "$1" in -h|--help) __k9s0ke_print_help; exit 0 ;; esac
  local s=${1#--}
  if __k9s0ke_amember "$s" "${!CLI_OPTS_bool[@]}"; then  # TODO: --arg=val
    _n=1; CLI_OPTS_bool["$s"]=y
  elif __k9s0ke_amember "${s#no-}" "${!CLI_OPTS_bool[@]}"; then
    _n=1; CLI_OPTS_bool["${s#no-}"]=
  elif   __k9s0ke_amember "$s" "${!CLI_OPTS[@]}"; then
    _n=2; CLI_OPTS["$s"]="$2"
  else return 1
  fi; return 0
}

__k9s0ke_print_help() {
local s
cat <<EOF
Usage: ${_USAGE:-$(basename "$0") [<option> ...] [...]}

Options:
     --help
EOF
for s in "${!CLI_OPTS[@]}"; do cat <<EOF
     --$s <$s>
EOF
done
for s in "${!CLI_OPTS_bool[@]}"; do cat <<EOF
     --$s
  --no-$s
EOF
done
}

__k9s0ke_argloop() {
  test 'ARGV' = "$1" || local -n ARGV=$1; shift
  local NSHIFT
  while test ${#ARGV[@]} -gt 0; do local arg="${ARGV[0]}"; ARGV=( "${ARGV[@]:1}" ); case "$arg" in
    --) break ;;
    -v) ARGV=( '--verbose' "${ARGV[@]}" ) ;;
    -*)
      if __k9s0ke_on_switch NSHIFT "$arg" "${ARGV[@]}"; then ARGV=( "${ARGV[@]:$(( NSHIFT - 1 ))}" )
      else echo 1>&2 "Bad args: $arg"; exit 1
      fi
      ;;
    *)  ARGV=( "$arg" "${ARGV[@]}" ); break ;;
  esac; done
  __k9s0ke_aappend CLI_OPTS_bool CLI_OPTS #; declare 1>&2 -p CLI_OPTS CLI_OPTS_bool
}

__k9s0ke_read_cfg() {
  test -r "$1" || return 1
  local kv _n
  while IFS= read -r kv; do
    __k9s0ke_on_switch _n "${kv%%=*}" "${kv#*=}"
  done <"$1"
}
# @k9s0ke: end bashaap


# vim: set ft=bash:

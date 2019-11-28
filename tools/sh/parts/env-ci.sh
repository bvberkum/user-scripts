#!/usr/bin/env bash

: "${ci_stages:=}"
: "${stages_done:=}"

: "${BRANCH_NAME:="$(git rev-parse --abbrev-ref HEAD)"}"

travis_ci_timer_ts=
test -n "${TRAVIS_TIMER_START_TIME:-}" &&
  travis_ci_timer_ts=$(echo "$TRAVIS_TIMER_START_TIME"|sed 's/\([0-9]\{9\}\)$/.\1/') ||
    : "${TRAVIS_TIMER_START_TIME:=$($gdate +%s%N)}"

: "${TRAVIS_BRANCH:=$BRANCH_NAME}"
: "${TRAVIS_JOB_ID:=-1}"
: "${TRAVIS_JOB_NUMBER:=-1}"
: "${TRAVIS_BUILD_ID:=}"
: "${GIT_COMMIT:="$(git rev-parse HEAD)"}"
: "${TRAVIS_COMMIT_RANGE:=}"
: "${BUILD:=".build"}" ; B=$BUILD

: "${SHIPPABLE:=}"

: "${dckr_pref:=}"
: "${USER:="`whoami`"}"
test  "$USER" = "treebox" && : "${dckr_pref:="sudo "}"

: "${U_S:="$HOME/.basher/cellar/packages/dotmpe/user-scripts"}"
: "${u_s_version:="feature/docker-ci"}"
: "${package_build_tool:="redo"}"
: "${sh_tools:="$CWD/tools/sh"}"
: "${ci_tools:="$CWD/tools/ci"}"
# XXX: rename or reserve or something
: "${script_util:="$sh_tools"}"
export scriptname=${scriptname:-"`basename -- "$0"`"}

: "${verbosity:=4}"
: "${LOG:="$CWD/tools/sh/log.sh"}"
: "${INIT_LOG:=$LOG}"

# Sync: U-S:

#!/usr/bin/env bash
set -euo pipefail

ci_announce 'Initializing for build-stats and statusdir-cache'

ci_announce "Logging into docker hub $DOCKER_USERNAME"
# NOTE: use stdin to prevent user re-prompt; but cancel build on failure
echo "$DOCKER_PASSWORD" | \
  ${dckr_pref}docker login --username $DOCKER_USERNAME --password-stdin

mkdir -p ~/.statusdir/{logs,tree,index}

sh_include env-docker-cache

echo u_s_ledge_lib_loaded=$u_s_ledge_lib_loaded
echo u_s_dckr_lib_loaded=$u_s_dckr_lib_loaded
u_s_dckr_lib_loaded= \
u_s_ledge_lib_loaded= \
lib_load u_s-dckr u_s-ledge

ci_announce "Looking for image at hub..."

ledge_exists && {

  ci_announce "Found image, extracting build log."
  ledge_refreshlogs || return

  ci_announce 'Retrieved logs'
}

test -s "$builds_log" && {
  ci_announce "Existing builds log found, last three logs (of $(wc -l "$builds_log"|awk '{print $1}')) where:"
  tail -n 3 "$builds_log" || true
} ||
  ci_announce "No existing builds log found"

# TODO: gather results into log uid:Jn7E
test -s "$results_log" && {
  ci_announce "Existing results log found; last three logs (of $(wc -l "$results_log"|awk '{print $1}')) where:"
  tail -n 3 "$results_log" || true
} ||
  ci_announce "No existing results log found"

# Add new build-announce log line
printf '%s %s %s %s %s %s\n' "$TRAVIS_TIMER_START_TIME" \
 "$TRAVIS_JOB_ID" \
 "$TRAVIS_JOB_NUMBER" \
 "$TRAVIS_BRANCH" \
 "$TRAVIS_COMMIT_RANGE" \
 "$TRAVIS_BUILD_ID" >>"$builds_log"
ci_announce 'New builds log:'
tail -n 1 "$builds_log"
wc -l "$builds_log" || true

trueish "${announce:-}" && {

  ledge_pushlogs

} || true

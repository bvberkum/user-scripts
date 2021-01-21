#!/usr/bin/env bash

sh_debug_exit()
{
  local exit=$? ; test $exit -gt 0 || return 0
  test ${quiet:-0} -eq 0 && {
    sync
    {
      echo '------ sh-debug-exit: Exited: '$exit  >&2
      # NOTE: BASH_LINENO is no use at travis, 'secure'
      echo "At $BASH_COMMAND:$LINENO"
      echo "In 0:$0 base:${base-} scriptname:${scriptname-}"
    } >&2
    test "${SUITE-}" = "CI" || return $exit
    #sleep 5 # Allow for buffers to clear? [Travis]
  }
  return $exit
}

test ${debug_exit_off:-${quiet-0}} -eq 1 || trap sh_debug_exit EXIT
# Id: U-S:

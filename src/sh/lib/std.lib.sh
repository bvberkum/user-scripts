#!/bin/sh

# std: logging and dealing with the shell's stdio decriptors


std_lib_load()
{
  test -n "$uname" || uname="$(uname -s)"
}

std_lib_init()
{
  test -x "$(which readlink)" || error "readlink util required for stdio-type" 1
  test -x "$(which file)" || error "file util required for stdio-type" 1
}

std_lib_check()
{
  std_iotype_check
}

std_iotype_check()
{
  case "$uname" in

    Linux | CYGWIN_NT-* ) ;;
    Darwin ) ;;

    * ) error "No stdio-type for $uname" ;;
  esac
  return 1
}

get_stdio_type()
{
  local io= pid=
  test -n "$1" && io=$1 || io=1
  case "$uname" in

    Linux | CYGWIN_NT-* )
        test -n "$2" && pid=$2 || pid=$$
        test -e /proc/$pid/fd/${io} || error "No $uname FD $io"
        if readlink /proc/$pid/fd/$io | grep -q "^pipe:"; then
          export stdio_${io}_type=p
        elif file $( readlink /proc/$pid/fd/$io ) | grep -q 'character.special'; then
          export stdio_${io}_type=t
        else
          export stdio_${io}_type=f
        fi
      ;;

    Darwin )

        test -e /dev/fd/${io} || error "No $uname FD $io"
        if file /dev/fd/$io | grep -q 'named.pipe'; then
          export stdio_${io}_type=p
        elif file /dev/fd/$io | grep -q 'character.special'; then
          export stdio_${io}_type=t
        else
          export stdio_${io}_type=f
        fi
      ;;

    * ) error "No stdio-type for $uname" ;;
  esac
}

var_log_key()
{
  test -n "$log_key" || {
    test -n "$log" && {
      log_key="$log"
    } || {
      test -n "$base" || base=$scriptname
      test -n "$base" && {
        test -n "$scriptext" || scriptext=.sh
        log_key=$base$scriptext
      } || echo "Cannot get var-log-key" 1>&2;
    }
  }
}

# stdio helper functions
log()
{
  var_log_key
  printf -- "[$log_key] $1\n"
  unset log_key
}

err()
{
  # TODO: turn this on and fix tests warn "err() is deprecated, see stderr()"
  log "$1" 1>&2
  test -z "$2" || exit $2
}

stderr()
{
  case "$(echo $1 | tr 'A-Z' 'a-z')" in
    warn*|err*|notice ) err "$1: $2" "$3" ;;
    * ) err "$2" "$3" ;;
  esac
}

# std-v <level>
# if verbosity is defined, return non-zero if <level> is below verbosity treshold
std_v()
{
  test -z "$verbosity" && return || {
    test $verbosity -ge $1 && return || return 1
  }
}

std_exit()
{
  test "$1" != "0" -a -z "$1" && return 1 || exit $1
}

emerg()
{
  std_v 1 || std_exit $2 || return 0
  stderr "Emerg" "$1" $2
}
crit()
{
  std_v 2 || std_exit $2 || return 0
  stderr "Crit" "$1" $2
}
error()
{
  std_v 3 || std_exit $2 || return 0
  stderr "Error" "$1" $2
}
warn()
{
  std_v 4 || std_exit $2 || return 0
  stderr "Warning" "$1" $2
}
note()
{
  std_v 5 || std_exit $2 || return 0
  stderr "Notice" "$1" $2
}
std_info()
{
  std_v 6 || std_exit $2 || return 0
  stderr "Info" "$1" $2
}
debug()
{
  std_v 7 || std_exit $2 || return 0
  stderr "Debug" "$1" $2
}

#!/usr/bin/env bash

sh_include() # Parts...
{
  test $# -gt 0 || return
  true ${sh_include_path:="{$ci_tools,$sh_tools,$U_S/tools/{ci,sh}}/{parts,boot}"} || return

  for part in $*
  do
    for base in $(eval echo $sh_include_path)
    do test -e "$base/$part.sh" && break || continue
    done

    test -e "$base/$part.sh" ||
      print_err error "" "no sh_include $part" "$?" 1

    . "$base/$part.sh" ||
      print_err error "" "at sh_include $part" "$?" $?
  done
}

alias sh-parts=sh_include

# Id: U-S:

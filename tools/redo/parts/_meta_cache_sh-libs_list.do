#!/usr/bin/env bash

## Annotate shell libraries

# TODO:add dependency for each script file on this target,
# keep a simple list with lib src names and grep title label and head comment
# as rest-line for sh-files.

lib_require statusdir-uc src match package build-htd std sys-htd vc-htd ctx-index

#build_sd_cache "$(basename $1)" "$hostname-$APP_ID_BREV" "$(basename "$3")"
test ! -e "$1" -o -s "$1" || rm "$1"
#test ! -e "$1.bup" || {
#  cat "$1.bup" >"$3"
#  exit
#}

true "${index_action:="$( test -e "$1" && echo update-index || echo init )"}"
generator=list_lib_sh_files \
    index_update files-index $index_action "$1" -- "" 4 "4d" "$1" "$3"

echo "Listed $(wc -l "$3"|awk '{print $1}') shell libraries"  >&2
#build_sd_commit "$(basename $3)" "$hostname-$APP_ID_BREV" "$(basename "$1")"
build-stamp <$3
#
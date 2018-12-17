redo-ifchange "sh-files.list"
# XXX: cleanup "$REDO_BASE/build.lib.sh" "$REDO_BASE/package.yaml"

(
  U_S=$REDO_BASE . $REDO_BASE/tools/sh/init.sh

  scriptname="do:$REDO_PWD:$1"
  cd "$REDO_BASE" &&
  lib_load build-htd && lib_init && build_init &&
  build_package_script_lib_list >"$REDO_PWD/$3"
  test -s "$REDO_PWD/$3" || {
    error "No libs found!" 1
  }
)

echo "Listed $(wc -l "$3"|awk '{print $1}') sh libs "  >&2
redo-stamp <"$3"

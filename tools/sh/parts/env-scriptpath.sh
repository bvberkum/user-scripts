#!/bin/sh


# XXX: not sure where/how/why to put this but keeping a cache to capture
# pipeline result value
ENV_D_SCRIPTPATH=$UCACHE/user-env/$$-SCRIPTPATH.txt

support_libs="user-scripts user-scripts-support user-scripts-incubator user-conf"
            #script-mpe user-scripts user-scripts-support user-conf
base_dirs="$HOME/project $HOME/build/bvberkum $HOME/build/user-tools $HOME/lib/sh"

# Pipe interesting paths to SCRIPTPATH-builder
{
  for basedir in $base_dirs
  do
    for supportlib in $support_libs
    do
      test -d "$basedir/$supportlib" || continue
      echo "$basedir/$supportlib"
    done
  done

  # FIXME: script-path legacy, soem for cleanup
  test -d $HOME/bin && echo $HOME/bin
  test -d $HOME/lib/sh && echo $HOME/lib/sh
  test -d $HOME/.conf && echo $HOME/.conf/script

  true

} | while read path
do
  for base in /script/lib /commands /contexts $sh_src_base
  do
    test -d "$path$base" || continue
    echo "$path$base"
  done
done | tr '\n' ':' | sed 's/:$/\
/' | {

  read SCRIPTPATH

  # FIXME: script-path legacy, soem for cleanup
  test -d $HOME/bin && SCRIPTPATH=$SCRIPTPATH:$HOME/bin
  test -d $HOME/lib/sh && SCRIPTPATH=$SCRIPTPATH:$HOME/lib/sh
  test -d $HOME/.conf && SCRIPTPATH=$SCRIPTPATH:$HOME/.conf/script

  echo $SCRIPTPATH >"$ENV_D_SCRIPTPATH"
}
read SCRIPTPATH_ <"$ENV_D_SCRIPTPATH"
rm "$ENV_D_SCRIPTPATH"
unset ENV_D_SCRIPTPATH

test -n "$SCRIPTPATH" && {

  SCRIPTPATH=$SCRIPTPATH_:$SCRIPTPATH
} || {

  SCRIPTPATH=$SCRIPTPATH_
}
unset SCRIPTPATH_
export SCRIPTPATH

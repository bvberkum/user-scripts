#!/usr/bin/env bash
#
# Provisioning and project init helpers

usage()
{
  echo 'Usage:'
  echo '  ./tools/sh/parts/init.sh <function name>'
}
usage-fail() { usage && exit 2; }


init-git()
{
  test -x "$(which git)" || return
  init-git-hooks || return
  init-git-submodules || return
}

init-git-hooks()
{
  test -e .git/hooks/pre-commit || {
    rm .git/hooks/pre-commit || true
    ln -s ../../tools/git/hooks/pre-commit.sh .git/hooks/pre-commit || return
  }
}

init-git-submodules()
{
  test -e .git/modules || {
    git submodule update --init || return
  }
}

check-git()
{
  test -x "$(which git)" || return
  test -h .git/hooks/pre-commit &&
  test -d .git/modules
}

init-basher()
{
  git clone https://github.com/basherpm/basher.git ~/.basher/
  export PATH=$PATH:$HOME/.basher/bin:$HOME/.basher/cellar/bin
}

check-basher()
{
  basher help >/dev/null
}

init-redo()
{
  basher install apenwarr/redo
}

check-redo()
{
  local r=''
  test -x "$(which redo)" || return
  redo -h 2>/dev/null || r=$?
  test "$r" = "97" || init-err "redo:-h:err:$r"
  # Must not be in parent dir, or targets become mixed with other projects, and harder to track
  # FIXME: only available after run; chicken-and-the-egg problem
  #test -d .redo/ || init-err "redo:repo"
}

init-bats()
{
  $LOG info "" "Installing bats..."

  : "${BATS_VERSION:=master}"
  : "${BATS_REPO:="https://github.com/bats-core/bats-core.git"}"
  : "${BATS_PREFIX:=$VND_GH_SRC/bats-core/bats-core}"

  test -d $BATS_PREFIX/.git || {

    mkdir -vp "$(dirname "$BATS_PREFIX")"
    test ! -e $BATS_PREFIX || {
      rm -rf $BATS_PREFIX || return
    }

    git clone "$BATS_REPO" $BATS_PREFIX || return $?
  }

  (
    cd $BATS_PREFIX &&
    git checkout "$BATS_VERSION" -- && ./install.sh $PREFIX
  )
}

check-bats()
{
  bats --version >/dev/null
}

check-github-release()
{
  github-release --version >/dev/null
}

init-github-release()
{
  go get github.com/aktau/github-release
}

init-deps()
{
  test -d "$VND_GH_SRC" -a -w "$VND_GH_SRC" || return

  test $# -eq 1 || set -- dependencies.txt

  grep -v '^\s*\(#.*\|\s*\)$' "$1" |
  while read installer supportlib version
  do
    $LOG "info" "" "Checking $intaller $supportlib..." "$version"

    : "${version:="master"}"

    ns_name="$(dirname "$supportlib")"
    test -d "$VND_GH_SRC/$ns_name" || mkdir -p "$VND_GH_SRC/$ns_name"

    # Create clone at path, check for Git dir to not be fooled by any cache/mount
    test -e "$VND_GH_SRC/$supportlib/.git" || {

      test ! -e "$VND_GH_SRC/$supportlib" || rm -rf "$VND_GH_SRC/$supportlib"
      git clone --quiet https://github.com/$supportlib "$VND_GH_SRC/$supportlib" || return
    }

    cd "$VND_GH_SRC/$supportlib" && { {
        git fetch --quiet "origin" &&
        git fetch --tags --quiet "origin"
      } || {
        $LOG "error" "$?" "Error retrieving from origin" "$supportlib"
      }
      git reset --quiet --hard origin/$version || {
        $LOG "error" "$?" "Error resetting to $version" "$supportlib"
      }
    }
    $LOG "note" "" "Checked $intaller $supportlib..." "$version"
  done
}

init-symlinks()
{
  test -d "$VND_GH_SRC" -a -w "$VND_GH_SRC" &&
    $LOG note ci:install "Using Github vendor dir" "$VND_GH_SRC" ||
    $LOG error ci:install "Writable Github vendor dir expected" "$VND_GH_SRC" 1

  # Give private user-script repoo its place
  # TODO: test user-scripts instead/also +U_s +script_mpe
  test -d $HOME/bin/.git || {
    test "$USER" = "travis" || return 100

    rm -rf $HOME/bin || true
    ln -s $HOME/build/bvberkum/script-mpe $HOME/bin
  }
}


init-err()
{
  $LOG error "" "failed during init" "$*"
  print_red "sh:init" "failed at '$*'" >&2
  exit 1
}


# Groups

check()
{
  default >/dev/null || init-err default

  git describe >/dev/null ||
    init-err "git describe: CWD should be GIT checkout and have tags in repo"
}

default()
{
  check-git || init-err git
  check-basher || init-err basher
  check-bats || init-err bats
  # XXX: check-redo || init-err redo
  check-github-release || init-err github-release
  test -n "$VND_GH_SRC" || init-err VND-GH-SRC
  for helper in bats-assert bats-file bats-support
  do
    test -d $VND_GH_SRC/ztombol/$helper || init-err $helper
  done
}

all()
{
  init-git || init-err git $?

  # XXX which github-release >/dev/null || {
  test -x "$(which github-release)" || {
    init-github-release || init-err github-release $?
  }
  test -x "$(which basher)" || {
    init-basher || init-err basher $?
  }
  test -x "$(which redo)" || {
    init-redo || init-err redo $?
  }

  BATS_VERSION_="$(bats --version)"
  { test -x "$(which bats)" && fnmatch "Bats 1.1.*" "$BATS_VERSION_"
  } || {
    echo $LOG warn "" "Found $BATS_VERSION_, getting 1.1..."

    echo PREFIX=$HOME/.local init-bats || return
    PREFIX=$HOME/.local init-bats || return
  }

  for helper in bats-assert bats-file bats-support
  do
    test -d $VND_GH_SRC/ztombol/$helper || {
      mkdir -vp "$VND_GH_SRC/ztombol"
      $LOG info "" "Adding test-helper $helper..."
      git clone --depth 15 \
        https://github.com/ztombol/$helper.git $VND_GH_SRC/ztombol/$helper ||
        return
    }
  done
}


# Main

type req_subcmd >/dev/null 2>&1 || . "${ci_util:="tools/ci"}/env.sh"
# Fallback func-name to init namespace to avoid overlap with builtin names
main_ "init" "$@"

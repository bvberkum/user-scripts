#!/bin/sh

# Logger: arg-to-colored ansi line output
# Usage:
#   log.sh [Line-Type] [Header] [Msg] [Ctx] [Exit]


DEBUG=${DEBUG:-}
test -z "$verbosity" && {
    test -n "$DEBUG" && verbosity=7 || verbosity=6
}

logger_stderr_num() # Level-Name
{
  case "$1" in
      emerg ) echo 1 ;;
      crit  ) echo 2 ;;
      error ) echo 3 ;;
      warn|warning  ) echo 4 ;;
      note|notice  ) echo 5 ;;
      info  ) echo 6 ;;
      debug ) echo 7 ;;
      * ) return 1 ;;
  esac
}

lvl=$(logger_stderr_num "$1")

test -z "$lvl" || {
  test $verbosity -ge $lvl || {
    test -n "$5" && exit $5 || {
      exit 0
    }
  }
}


# left align first columnt at:
test -n "$FIRSTTAB" || FIRSTTAB=24

if [ -z "$CS" ]
then
	echo "make: warning, using dark colorscheme (set CS to override)" 1>&2
	CS=dark
fi
COLOURIZE=yes

# Shell colors
if [ "$COLOURIZE" = "yes" ]
then

  bold="$(tput bold)"
  underline="$(tput smul)"
  standout="$(tput smso)"

  normal="$(tput sgr0)"

	if [ "$CS" = "light" ]
	then
		# primary, black
    c0="$(tput setaf 0)"
		# pale (inverted white)
    c7="$standout$(tput setaf 7)"
		# hard (bright black, ie. dark gray)
    c9="$bold$0"
	else
		# primary, pale white
    c0="$(tput setaf 0)"
		# pale (normal white, ie. light gray)
    c7="$(tput setaf 7)"
		# hard (bold white)
    c9="$bold$7"
	fi
	# warning color, red
  c1="$bold$(tput setaf 1)"
	# ok color, green
  c2="$(tput setaf 2)"
  c21="$bold$c2"
	# running, orange
  c3="$(tput setaf 3)"
  c31="$bold$c3"
	# updated, blue
  c4="$(tput setaf 4)"
  c41="$bold$c4"
fi
## Make output strings
mk_title_blue="$c7$c41%s$c7:$c0"
mk_title_blue_faint="$c7$c4%s$c7:$c0"
mk_p_trgt_blue="$c41[$c7%s$c41]$c0"
#mk_p_trgt_blue_faint="$c4[$c7%s$c4]$c0"
mk_trgt_blue="$c41<$c7%s$c41>$c0"
#mk_trgt_blue_faint="$c4<$c7%s$c4>$c0"
mk_trgt_yellow="$c31<$c7%s$c31>$c0"
#mk_trgt_yellow_faint="$c3<$c7%s$c3>$c0"
mk_p_trgt_yellow="$c31[$c7%s$c31]$c0"
mk_p_trgt_yellow_faint="$c3[$c7%s$c3]$c0"
mk_p_trgt_green="$c21[$c7%s$c21]$c0"
mk_trgt_green="$c21<$c7%s$c21>$c0"
#mk_trgt_green_faint="$c2<$c7%s$c2>$c0"
mk_trgt_red="$c1<$c7%s$c1>$c0"
mk_p_trgt_red="$c1[$c7%s$c1]$c0"
mk_updtd="$c4<$c7%s$c4>$c0"


__log()
{
	linetype=$(echo $1|tr 'A-Z' 'a-z')
	targets=$(echo "$2")
	trgt_len=${#targets}
	msg=$3
	sources=$(echo "$4")

	if [ -n "$sources" ];
	then
		sources=$(printf "$mk_trgt_blue" "$sources")
		msg="$msg $sources"
	fi
	case "$linetype" in
		header | header1) # blue
			#targets=$(printf "$mk_title_blue" "$targets")
			targets=$(printf "$mk_p_trgt_blue" "$targets")
			;;
		header2 )
			targets=$(printf "$mk_title_blue" "$targets")
			;;
		header3 )
			targets=$(printf "$mk_title_blue_faint" "$targets")
			;;
		debug )
			targets="";
			trgt_len=0
				#$(printf "$mk_p_trgt_yellow_faint" "$targets")
			;;
		verbose | warn*  )
			targets=$(printf "$mk_p_trgt_yellow_faint" "$targets")
			;;
		attention | crit* )
			targets=$(printf "$mk_p_trgt_yellow" "$targets")
			;;
		file[_-]target )
			targets=$(printf "$mk_trgt_yellow" "$targets")
			;;
		file[_-]ok )
			targets=$(printf "$mk_trgt_green" "$targets")
			;;
		file[_-]warn* )
			targets=$(printf "$mk_trgt_yellow" "$targets")
			;;
		file[_-]err* ) # red
			targets=$(printf "$mk_trgt_red" "$targets")
			;;
		err* | fatal | fail* ) # red
			targets=$(printf "$mk_p_trgt_red" "$targets")
			;;
		 ok | "done" | info | *  )
			targets=$(printf "$mk_p_trgt_green" "$targets")
			;;
	esac
	case "$linetype" in
		file[_-]error|file[_-]warn*|file[_-]target|file[_-]ok|header|header1|header2|header3|debug|info|attention|error|verbose)
			;;
		fatal|ok|'done'|* )
			if [ -n "$msg" ]
			then msg="$c9$1$c0, $msg";
			else msg="$c9$1$c0"; fi
			;;
	esac
	if [ -n "$msg" -a -z "$sources" ]
	then
		msg="$msg.";
	fi
	len=$(expr $FIRSTTAB - $trgt_len)
	case "$linetype" in
		debug)
			len=$(expr $len + 2)
			;;
		'header2'|header3)
			len=$(expr $len + 1)
			;;
	esac
	if [ $len -lt 0 ]; then len=0; fi
	# FIXME: should use printf
	padd=" ";
	padding=''
	while [ ${#padding} -lt $len ]; do
		padding="$padd$padding"
	done;
	printf " %s%s %s%s\n" "$padding" "$targets" "$msg" "$c0$normal"
}


# Start in stream mode or print one line and exit.
if test "$1" = '-'
then
	export IFS="	"; # tab-separated fields for $inp
	while read lt t m s;
	do
		__log "$lt" "$t" "$m" "$s";
	done
else
  case "$1" in
    demo )
        set -- demo "Test message line" "123"
      	__log "error" "$@"
      	__log "warn" "$@"
      	__log "note" "$@"
      	__log "info" "$@"
      	__log "debug" "$@"
      	__log "ok" "$@"
      	__log "fail" "$@"
      ;;
    * )
      	__log "$1" "$2" "$3" "$4"
      ;;
  esac
fi

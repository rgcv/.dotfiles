#!/bin/sh
# see https://tools.suckless.org/dmenu/scripts/run-recent
# requires:
#   dmenu (obviously)
#   dmenu_path (comes with dmenu)
# end a command with ; to run in a terminal
set -eu

terminal="${TERMINAL-termite} -e"
cachedir="${XDG_CACHE_HOME-$HOME/.cache}/dmenu"
[ -d "$cachedir" ] || mkdir -p "$cachedir"
cache="$cachedir/recent"

touch "$cache"

most_used=$(sort "$cache" | uniq -c | sort -r | awk '{print $2}')
run=$( (echo "$most_used"; dmenu_path | grep -vxF "$most_used") | dmenu -i "$@")
{ echo "$run"; head -n 99 "$cache"; } > "$cache.$$" && mv "$cache.$$" "$cache"

case $run in
  *\!) $terminal "${run%%!}" ;;
  *)   $run ;;
esac

#!/bin/sh
# loosely based on https://github.com/pavanjadhaw/betterlockscreen
# requires:
#   bc (bc, numerical computation)
#   convert (imagemagick, capture and pixelate)
#   i3lock (i3lock)
#   xdpyinfo (xorg-xdpyinfo, screen information)
#   xset (xorg-xset, dpms control)
# uses:
#   playerctl (playerctl, to pause before lock)
#   xgetres (xgetres, retrieve X resource values)
set -eu
pgrep i3lock && exit

bgcolor=${COLOR_BACKGROUND-$(xgetres i3.color0 || echo "#000000")} # black
bgcolor=${bgcolor#\#} # trim potential leading #

has_sleep_lock() { [ -e "/dev/fd/${XSS_SLEEP_LOCK_FD--1}" ]; }
pre_lock() {
  pkill -xu "$USER" -USR1 dunst
  if has_sleep_lock; then playerctl pause || true; fi
}

lock() {
  read -r w h <<EOF
$(xdpyinfo | awk -F'x| *' '/dimensions:/ {print $3,$4}')
EOF

  opts= # i3 opts
  opts="$opts -c $bgcolor"
  opts="$opts -u" # hide indicator
  opts="$opts -t" # tile the image (multihead)
  opts="$opts -i /dev/stdin --raw=${w}x${h}:rgb"

  # shellcheck disable=SC2086
  convert x:root \
    -depth 8 \
    -background opaque \
    -scale 2.5% -scale 4000% \
    rgb:- |
  i3lock $opts "$@"
}

post_lock() {
  pkill -xu "$USER" -USR2 dunst
}

pre_lock
if has_sleep_lock; then
  kill_i3lock() { pkill -xu "$USER" "$@" i3lock; }
  eval "lock ${XSS_SLEEP_LOCK_FD}<&-"
  eval "exec ${XSS_SLEEP_LOCK_FD}<&-"
  while kill_i3lock -0; do sleep 0.5; done
else
  trap 'kill %%' TERM INT
  lock -n &
  wait
fi
post_lock

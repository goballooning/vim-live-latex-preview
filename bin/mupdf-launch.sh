#!/bin/bash

texfile="$2"
mupdf "$1" &>/dev/null &
mupid="$!"
muwinid="0"
nummps=$(xdotool search --pid $mupid --class MuPDF | wc -l)
until [ $nummps -gt 0 ] ; do
    sleep 0.1
    nummps=$(xdotool search --pid $mupid --class MuPDF | wc -l)
done
echo -n "$(xdotool search --pid $mupid --class MuPDF | head -n1)" 
# try to return focus to GVIM
xdotool search --class --name "${texfile}.*GVIM" windowactivate &>/dev/null
exit 0

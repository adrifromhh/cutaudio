#!/bin/bash

# Verbose mode
#verbose="TRUE"

syntax="cutaudio.sh INPUT OUTPUT LENGTH TITLE"

if [[ $# -lt 4 ]]; then
    echo "-- Too few arguments --"
    echo "Please specify at least an input file, output file and a duration for resulting chunks"
    echo "Syntax: $syntax"
    exit 1
elif [[ $# -gt 4 ]]; then
	echo "--- Too many arguments ---"
	echo "Syntax: $syntax"
	exit 1
fi

input=$1
output=$2
duration=$3
TITLE=$4

INPUTDIR=$(dirname "${input}")
INPUTTYPE=${input##*.}
OUTPUTDIR=$(dirname "${output}")
OUTPUTFILE=$(basename "${output}")
OUTPUTNAME=$(basename "${output}")
OUTPUTNAME=${OUTPUTNAME%.*}
OUT="$OUTPUTDIR/$OUTPUTNAME"

if [[ $verbose ]]; then
	echo "Input:         $input"
	echo "Output:        $output"
	echo "Duration:      $duration"
	echo "Title:         $title"
	echo ""
	echo "INPUTDIR:      $INPUTDIR"
	echo "INPUTTYPE:     $INPUTTYPE"
	echo "OUTPUTDIR:     $OUTPUTDIR"
	echo "OUTPUTFILE:    $OUTPUTFILE"
	echo "OUTPUTNAME:    $OUTPUTNAME"
	echo "OUT:           $OUT"
	echo ""
fi

# ------------------------------------------------------
# DETERMINE LENGTH OF INPUT FILE
# And extract how many decimal digits the filename needs
# ------------------------------------------------------

filelength=$( ffprobe -v error -show_entries format=duration \
			-of default=noprint_wrappers=1:nokey=1 $input )
filelength=${filelength%.*}
n=$((($filelength / $duration) + 1))
if   [[ $n -lt 10 ]]; then digits=1
elif [[ $n -lt 100 ]]; then digits=2
elif [[ $n -lt 1000 ]]; then digits=3
else echo "Error: You're trying to process a darn huge file :O"
fi

if [[ $verbose ]]; then
	echo "Filelength:    $filelength"
	echo "Output files:  $n"
	echo "Digits:        $digits"
fi

# ------------------------------------
# CUT FILES IN CHUNKS / STRIP METADATA
# ------------------------------------

ffmpeg  -i $input -map 0 -map_metadata -1 -f segment -segment_time $duration -c copy $OUT-%"$digits"d."$INPUTTYPE"

# ----------------
# REPLACE METADATA
# ----------------

n="1"
for i in $OUT*; do 
    title="$TITLE Part $n"
    ffmpeg -i $i -map 0 -metadata title="$title" -c copy -y /tmp/cutaudio-tmp."$INPUTTYPE"
    mv -f /tmp/cutaudio-tmp."$INPUTTYPE" "$i"
    n=$((n + 1))
done

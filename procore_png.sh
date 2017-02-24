#!/usr/bin/env sh
GNUPLOT="/usr/local/bin/gnuplot"
COMPILE="./compile.rb"
OUTFILE="tests.png"
RESOLUTION="0.1"
"$COMPILE" -g -r procore/procore --resolution "$RESOLUTION" |
  "$GNUPLOT" -e "set terminal png size 800,600; set logscale y; set title 'procore/procore test suite runtime'; set xlabel 'seconds'; set ylabel '# tests'; plot '<cat' notitle" > "$OUTFILE" &&
    echo "$OUTFILE" written

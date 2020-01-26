#!/bin/bash
qqwing --generate --compact --difficulty any | sed 's/\./0/g' | sed 's/\(.\{1\}\)/\1 /g' > .sudoku.txt
cat .sudoku.txt
time ./sudoku < .sudoku.txt
rm .sudoku.txt

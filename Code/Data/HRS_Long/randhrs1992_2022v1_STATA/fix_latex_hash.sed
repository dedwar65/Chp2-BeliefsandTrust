#!/bin/sed -f
# Fix LaTeX # characters in interaction terms
# Replace # with \times in variable names but preserve # in macro definitions

# Replace # in interaction terms (but not in \def\sym#1)
s/\([0-9]\)\.year_\([0-9]\+\)#c\.\([a-zA-Z_]*\)/\1.year_\2\\times c.\3/g
s/\([0-9]\)\.year_\([0-9]\+\)#\([a-zA-Z_]*\)/\1.year_\2\\times \3/g

# Replace any remaining # in variable names (but not in \def\sym#1)
s/\([^\\]\)#\([^1]\)/\1\\times \2/g

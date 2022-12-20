#! /bin/bash

cat combined.txt |
awk '/JSR #..../ && length($5) == 3 {print $5, $6}' |
sort -u |
uniq >jsr.txt

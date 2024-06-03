#!/bin/bash

for i in *besthit; do
	col1=$(awk '{print$1}' "$i")
	col2=$(sed 's/.*\.._\(.*\)_[[].*/\1/' "$i")
	paste <(printf %s "$col1") <(printf %s "$col2") > "${i/.txt.besthit/.table}"
done

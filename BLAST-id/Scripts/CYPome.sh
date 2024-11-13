#!/bin/bash

echo -e "ID\tCYP2\tCYP3\tCYP4\tCYPM" > CYPome.tsv

for i in blast/*p450; do
	base="$(basename "$i" .p450)"
	cyp2=$(grep "$base" GeneTable.tsv | grep "CYP2" | wc -l)
	cyp3=$(grep "$base" GeneTable.tsv | grep "CYP3" | wc -l)
	cyp4=$(grep "$base" GeneTable.tsv | grep "CYP4" | wc -l)
	cypm=$(grep "$base" GeneTable.tsv | grep "CYPM" | wc -l)

	echo -e "$base\t$cyp2\t$cyp3\t$cyp4\t$cyp4" >> CYPome.tsv
done

#!/bin/bash

dir=$1
names=$2

declare -A protein_dict

while IFS=$'\t' read -r gene right_protein; do
    protein_dict["$gene"]="$right_protein"
done < "$names"

for file in "$dir"/*table.tsv; do
	output_file="${file/.table.tsv/.tsv}"

	while IFS=$'\t' read -r gene protein; do
    	if [[ -n "${protein_dict[$protein]}" ]]; then
        	echo -e "$gene\t${protein_dict[$protein]}"
    	else
        	echo -e "$gene\t$protein"
    	fi
	done < "$file" > "$output_file"
done

echo "Substitution completed. Check the output.txt file for results."

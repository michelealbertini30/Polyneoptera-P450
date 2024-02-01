#!/bin/bash

gene_names_file="$1"
fasta_file="$2"

while IFS= read -r gene_name; do
    # Find the gene in the fasta file and append it to the temporary file
	awk -v gene="$gene_name" '/^>/ {if (p) printf ""; p=0} p; $1 == ">" gene {p=1; print}' "$fasta_file" >> temp.file.aa
done < "$gene_names_file"

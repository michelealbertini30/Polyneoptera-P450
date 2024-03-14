#!/bin/bash

# Directory containing input fasta files
input_dir=$1
true_genes_file=$2

# Check if input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Input directory $input_dir not found."
    exit 1
fi

if [ ! -f "$true_genes_file" ]; then
    echo "True genes file $true_genes_file not found."
    exit 1
fi

# Iterate over each fasta file in the input directory
for input_fasta_file in "$input_dir"/*.augustus.aa; do
    # Extract the base name of the input file without the .augustus.aa extension
    base_name=$(basename "$input_fasta_file" .augustus.aa)

    # Create a temporary file to store the filtered fasta
    temp_file=$(mktemp)

    # Read true genes into an associative array for quick lookup
    declare -A true_genes
    while IFS= read -r gene; do
        true_genes["$gene"]=1
    done < "$true_genes_file"

    # Read the input fasta file and filter out genes not in the true genes list
    current_gene=""
    print_gene=false
    while IFS= read -r line; do
        if [[ $line == ">"* ]]; then
            current_gene="${line:1}"
            if [ -n "${true_genes[$current_gene]}" ]; then
                print_gene=true
                echo "$line" >> "$temp_file"
            else
                print_gene=false
            fi
        else
            if [ "$print_gene" = true ]; then
                echo "$line" >> "$temp_file"
            fi
        fi
    done < "$input_fasta_file"

    # Rename the temporary file to use the base name of the input file
    final_file="${base_name}.filtered.fa"
    mv "$temp_file" "$final_file"

    echo "Filtered file created: $final_file"
done

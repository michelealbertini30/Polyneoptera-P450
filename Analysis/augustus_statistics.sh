#!/bin/bash

output_file="augustus_statistics.log"

echo -e "File\t\tN.hits\t\tUnique" > "$output_file"

for file in augustus/*.augustus.gff; do
    if [ -e "$file" ]; then
        filename=$(basename "$file" .augustus.gff)

        echo "Processing $filename"

        result1=$(grep -c "start gene" "$file")
        result2=$(grep -A 1 "start gene" "$file" | awk '/MP/ {print $1}' | sort -u | wc -l)

        echo -e "$filename\t\t$result1\t\t$result2" >> "$output_file"
    fi
done

echo "Results written to $output_file"

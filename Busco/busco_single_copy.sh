#!/bin/bash
for file in $(find . -name "full_table.tsv"); do
	grep -v "^#" ${file} | awk '$2=="Complete" {print $1}' >> complete_busco_ids.txt

done

sort complete_busco_ids.txt | uniq -c | awk '$1 > 36 {print $2}' > final_busco_ids.txt



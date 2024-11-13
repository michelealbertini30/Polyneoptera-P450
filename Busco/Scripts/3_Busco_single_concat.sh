#!/bin/bash
while read line; do
#	cat ????_${line}.fna >> ${line}_nt.fasta;
	cat busco_aa/????_${line}.faa >> ${line}_aa.fasta;

done < final_busco_ids.txt

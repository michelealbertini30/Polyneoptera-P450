#!/bin/bash

while read line;
	do

	if echo $line | grep -qv "#";
		then

		ref=$(echo $line | awk '{print $1}')
		ids=$(echo $line | awk '{print $2}')

		datasets download genome accession $ref --include genome --dehydrated --filename $ref.zip

		unzip $ref -d $ref
		datasets rehydrate --directory $ref

		cp $ref/ncbi_dataset/data/$ref/*.fna Genomes/$ids.fna
	fi
	done < $1

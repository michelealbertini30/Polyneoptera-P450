#!/bin/bash

for dir in $(find . -type d -name "single_copy_busco_sequences"); do
	sppname=$(basename $(dirname $(dirname $(dirname $dir))));
	abbrv=${sppname%.busco};
	echo $sppname

	for file in ${dir}/*.faa; do
		filename=$(basename $file);
		cp $file busco_aa/${abbrv}_${filename}
		sed -i 's/^>/>'${abbrv}'|/g' busco_aa/${abbrv}_${filename}
		cut -f 1 -d ":" busco_aa/${abbrv}_${filename} | tr '[:lower:]' '[:upper:]' > busco_aa/${abbrv}_${filename}.1
		mv busco_aa/${abbrv}_${filename}.1 busco_aa/${abbrv}_${filename}
	done

#	for file in ${dir}/*.fna; do
#		filename=$(basename $file);
#		cp $file busco_nt/${abbrv}_${filename}
#		sed -i 's/^>/>'${abbrv}'|/g' busco_nt/${abbrv}_${filename}
#		cut -f 1 -d ":" busco_nt/${abbrv}_${filename} | tr '[:lower:]' '[:upper:]' > busco_nt/${abbrv}_${filename}.1
#		mv busco_nt/${abbrv}_${filename}.1 busco_nt/${abbrv}_${filename}
#	done
done

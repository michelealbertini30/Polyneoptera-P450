#!/bin/bash

ref=$(awk '{print $1}' $1 | grep -v "#" | tr "\n" " ")
ref=${ref%?}

for rf in $ref
	do
		unzip $rf -d $rf
		datasets rehydrate --directory $rf
	done

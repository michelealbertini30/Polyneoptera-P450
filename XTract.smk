configfile: 'logs/config.smk.yaml'
miniprot_cores=config['Run']['Miniprot_cores']
agat_exp=config['Run']['Agat_expansion']

getAnnoFasta=config['Scripts']['getAnnoFasta']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
	input:
		expand('miniprot_gff/{sample}.gff', sample = sample),
		expand('agat_cds/{sample}.cds.fna', sample = sample),
		expand('augustus/{sample}.augustus.gff', sample = sample),
		expand('augustus/{sample}.augustus.aa', sample = sample),
		expand('augustus/{sample}.augustus.codingseq', sample = sample),
		expand('interproscan/{sample}.augustus.aa.tsv', sample = sample),
		expand('Genes/{sample}.fa', sample = sample),
		expand('Genes/{sample}.truep450.txt', sample = sample),
		'logs/augustus_statistics.log',
#		'training/Merged.gb',
#		'p450.combined.fa'		

rule miniprot:
        input:
                genome = 'Genomes/{sample}.fna',
                proteins = 'refNCBI/UniProt_P450_RInsecta.fasta'
        threads:
                config['Run']['Threads']
        output:
                'miniprot_gff/{sample}.gff'
        shell:
                'miniprot -t{miniprot_cores} --gff {input.genome} {input.proteins} > {output}'

rule agat_exp:
        input:
                genomes = 'Genomes/{sample}.fna',
                miniprot = rules.miniprot.output
        output:
                'agat_cds/{sample}.cds.fna'
        shell:
                'agat_sp_extract_sequences.pl --gff {input.miniprot} --fasta {input.genomes} -t cds --up {agat_exp} --down {agat_exp} -o {output}'

### AUGUSTUS TRAINING ###

#rule gff2gb:
#	input:
#		genome = 'Genomes/{sample}.fna',
#		miniprot = rules.miniprot.output
#	output:
#		'training/{sample}.gb'
#	shell:
#		'perl training/Scripts/gff2gbSmallDNA.pl {input.miniprot} {input.genome} 16000 {output}'
#
#rule gb_merge:
#	input:
#		gb = expand('training/{sample}.gb', sample = sample)
#	output:
#		'training/Merged.gb'
#	shell:
#		'cat {input.gb} > {output}'
#
#
##############################

rule augustus:
        input:
                protein_coordinates = rules.agat_exp.output
        output:
                'augustus/{sample}.augustus.gff'
        shell:
                'augustus --species=fly --protein=on --codingseq=on --genemodel=complete {input.protein_coordinates} > {output}'

rule augustus_statistics:
        input:
                augustus_hits = expand('augustus/{sample}.augustus.gff', sample = sample)
        output:
                'logs/augustus_statistics.log'
	shell:
		'''
		echo -e "File\t\tN.hits\t\tUnique" > {output}

		for file in {input.augustus_hits}; do
			if [ -e "$file" ]; then
				filename=$(basename "$file" .augustus.gff)

				result1=$(grep -c "start gene" "$file")
				result2=$(grep -A 1 "start gene" "$file" | awk '/MP/ {{print $1}}' | sort -u | wc -l)

				echo -e "$filename\t\t$result1\t\t$result2" >> {output}
			fi
		done

		'''

rule augustus_extract:
	input:
		augustus_hits = rules.augustus.output
	output:
		aa = 'augustus/{sample}.augustus.aa',
		codingseq = 'augustus/{sample}.augustus.codingseq'
	shell:
		'''
		perl {getAnnoFasta} {input.augustus_hits} | tee {output.aa}
		perl {getAnnoFasta} {input.augustus_hits} | tee {output.codingseq}
		'''

rule interproscan:
	input:
		augustus_aa = 'augustus/{sample}.augustus.aa'
	output:
		interpro = 'interproscan/{sample}.augustus.aa.tsv'
	shell:
		'''
		../interproscan-5.65-97.0/interproscan.sh -i {input.augustus_aa} -f tsv -o {output.interpro}
		'''

rule interpro_filter1:
	input:
		interpro = 'interproscan/{sample}.augustus.aa.tsv'
	output:
		trueP450 = 'Genes/{sample}.truep450.txt'
	shell:
		'''
		for file in {input.interpro}; do
			if [ -e "$file" ]; then

				result=$(awk '/P450/ {{print $1}}' "$file" | sort -u)
				echo -e "$result" > {output.trueP450}

			fi
		done		
		'''

rule interpro_filter2:
	input:
		augustus_aa = 'augustus/{sample}.augustus.aa',
		true_genes = 'Genes/{sample}.filtered.txt'
	output:
		final_genes = 'Genes/{sample}.fa'
	shell:
		'''
		input_fasta_file={input.augustus_aa}
		true_genes={input.true_genes}

		if [ ! -f "$input_fasta_file" ]; then
			echo "Input fasta file $input_fasta_file not found."
			exit 1
		fi

		if [ ! -f "$true_genes_file" ]; then
			echo "True genes file $true_genes_file not found."
			exit 1
		fi

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
				current_gene="${{line:1}}"
				if [ -n "${{true_genes[$current_gene]}}" ]; then
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
		mv "temp_file" {output.final_genes}

		'''

#rule reformat_combine:
#	input:
#		augustus_aa = expand('augustus/{sample}.augustus.aa', sample = sample)
#	output:
#		'p450.combined.fa'
#	shell:
#		'''
#		for file in {input.augustus_aa}; do
#			if [ -e "$file" ]; then
#				filename=$(basename "$file" .augustus.aa)
#				
#				sed "s/t1/$filename/g" {input.augustus_aa} >> {output}
#			fi
#		done
#		'''


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
		expand('interproscan/tsv/{sample}.augustus.aa.tsv', sample = sample),
		expand('interproscan/gff/{sample}.augustus.aa.gff3', sample = sample),
#		expand('Genes/{sample}.filtered.fa', sample = sample),
		expand('Genes/{sample}.truep450.txt', sample = sample),
		expand('Genes/{sample}.filtered.cdhit.fa', sample = sample),
		expand('Genes/{sample}.filtered.cdhit.reformat.fa', sample = sample),
		expand('Mafft/{sample}.mafft.fa', sample = sample),
		'logs/augustus_statistics.log'
				

rule miniprot:
        input:
                genome = 'Genomes/{sample}.fna',
                proteins = 'UniProt_P450_Reviewed_Insecta.fasta'
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

rule interproscan_tsv:
	input:
		augustus_aa = 'augustus/{sample}.augustus.aa'
	output:
		interpro = 'interproscan/tsv/{sample}.augustus.aa.tsv'
	shell:
		'''
		../interproscan-5.65-97.0/interproscan.sh -i {input.augustus_aa} -f tsv -o {output.interpro}
		'''

rule interproscan_gff:
        input:
                augustus_aa = 'augustus/{sample}.augustus.aa'
        output:
                interpro = 'interproscan/gff/{sample}.augustus.aa.gff3'
        shell:
                '''
                ../interproscan-5.65-97.0/interproscan.sh -i {input.augustus_aa} -f gff3 -o {output.interpro}
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

#rule interpro_filter2:
#	input:
#		augustus_aa = 'augustus/{sample}.augustus.aa',
#		true_genes = 'Genes/{sample}.truep450.txt'
#	output:
#		genes = 'Genes/{sample}.filtered.fa'
#	shell:
#		'bash Scripts/Interpro.filter.sh {input} {output}'

rule cdhit:
	input:
		genes = 'Genes/{sample}.filtered.fa'
	output:
		final_genes = 'Genes/{sample}.filtered.cdhit.fa'
	shell:
		'cd-hit -i {input.genes} -o {output.final_genes} -c 1.00'

rule reformat_combine:
	input:
		genes = 'Genes/{sample}.filtered.cdhit.fa'
	output:
		reformat = 'Genes/{sample}.filtered.cdhit.reformat.fa'
	shell:
		'''
		for file in {input.genes}; do
			filename=$(basename "$file" .filtered.cdhit.fa)

			sed "s/t1/$filename/g" {input.genes} > {output.reformat}

               done

		'''
rule mafft:
	input:
		genes = 'Genes/{sample}.filtered.cdhit.reformat.fa'
	output:
		aligned = 'Mafft/{sample}.mafft.fa'
	shell:
		'mafft --auto {input.genes} > {output.aligned}'

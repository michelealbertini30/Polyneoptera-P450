configfile: 'logs/config.smk.yaml'
expansion=config['Run']['Expansion']

getAnnoFasta=config['Scripts']['getAnnoFasta']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
	input:
		expand('miniprot_gff/{sample}.gff', sample = sample),
		expand('fai/{sample}.fai', sample = sample),
		expand('bedtools/{sample}.bed', sample = sample),
		expand('bedtools/{sample}.merge.bed', sample = sample),
		expand('bedtools/{sample}.merge.slop.bed', sample = sample),
		expand('bedtools/{sample}.fasta', sample = sample),
		expand('augustus/{sample}.augustus.gff', sample = sample),
		expand('augustus/{sample}.augustus.aa', sample = sample),
		expand('augustus/{sample}.augustus.codingseq', sample = sample),
		expand('interproscan/tsv/{sample}.augustus.aa.tsv', sample = sample),
		expand('interproscan/gff/{sample}.augustus.aa.gff3', sample = sample),
		expand('Genes/{sample}.filtered.fa', sample = sample),
		expand('Genes/{sample}.truep450.txt', sample = sample),
		expand('Genes/{sample}.filtered.reformat.fa', sample = sample),
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

rule gff2bed:
	input:
		gff = 'miniprot_gff/{sample}.gff'
	output:
		bed = 'bedtools/{sample}.bed'
	shell:
		'agat_convert_sp_gff2bed.pl -g {input.gff} -o {output.bed}'

rule bed_sort:
	input:
		bed = 'bedtools/{sample}.bed'
	output:
		sort = 'bedtools/{sample}.sorted.bed'
	shell:
		'sort -k1,1 -k2,2n {input.bed} > {output.sort}'

rule bedtools_merge:
	input:
		bed = 'bedtools/{sample}.sorted.bed'
	output:
		merged = 'bedtools/{sample}.merge.bed'
	shell:
		'bedtools merge -c 1 -o collapse -i {input.bed} -delim "|" > {output.merged}'

rule samtools_fai:
	input:
		fna = 'Genomes/{sample}.fna'
	output:
		fai = 'fai/{sample}.fai'
	shell:
		'samtools faidx {input.fna} -o {output.fai}'

rule bedtools_slop:
	input:
		merged = 'bedtools/{sample}.merge.bed',
		fai = 'fai/{sample}.fai'
	output:
		slopped = 'bedtools/{sample}.merge.slop.bed'
	shell:
		'bedtools slop -b {exp} -i {input.merged} -g {input.fai} > {output.slopped}'

rule bedtools_getfasta:
	input:
		gen = 'Genomes/{sample}.fna',
		slopped = 'bedtools/{sample}.merge.slop.bed'
	output:
		fasta = 'bedtools/{sample}.fasta'
	shell:
		'bedtools getfasta -fi {input.gen} -bed {input.slopped} > {output.fasta}'

rule augustus:
        input:
                fasta = 'bedtools/{sample}.fasta'
        output:
                'augustus/{sample}.augustus.gff'
        shell:
                'augustus --species=fly --protein=on --codingseq=on --genemodel=complete {input.fasta} > {output}'

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
		interpro = 'interproscan/tsv/{sample}.augustus.aa.tsv'
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
                fasta = 'augustus/{sample}.augustus.aa',
                txt = 'Genes/{sample}.truep450.txt'
        output:
                'Genes/{sample}.filtered.fa'
        shell:
                'bash Scripts/Interpro_filter_smk.sh {input.fasta} {input.txt} {output}'

rule reformat_combine:
	input:
		genes = 'Genes/{sample}.filtered.fa'
	output:
		reformat = 'Genes/{sample}.filtered.reformat.fa'
	shell:
		'''
		for file in {input.genes}; do
			filename=$(basename "$file" .filtered.fa)

			sed "s/t1/$filename/g" {input.genes} > {output.reformat}

               done

		'''
rule mafft:
	input:
		genes = 'Genes/{sample}.filtered.reformat.fa'
	output:
		aligned = 'Mafft/{sample}.mafft.fa'
	shell:
		'mafft --dash {input.genes} > {output.aligned}'

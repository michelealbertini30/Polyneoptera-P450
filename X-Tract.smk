configfile: 'logs/config.smk.yaml'
exp=config['Run']['Expansion']

getAnnoFasta=config['Scripts']['getAnnoFasta']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
	input:
		expand('miniprot_gff/{sample}.gff', sample = sample),
		expand('fai/{sample}.fai', sample = sample),
		expand('bedtools/{sample}.bed', sample = sample),
		expand('bedtools/{sample}.merge.bed', sample = sample),
		expand('bedtools/{sample}.slop.bed', sample = sample),
		expand('bedtools/{sample}.fasta', sample = sample),
		expand('augustus/{sample}.augustus.gff', sample = sample),
		expand('augustus/{sample}.augustus.aa', sample = sample),
		expand('augustus/{sample}.augustus.codingseq', sample = sample),
		expand('augustus/{sample}.augustus.nt', sample = sample),
		expand('interproscan/tsv/{sample}.augustus.aa.tsv', sample = sample),
#		expand('interproscan/gff/{sample}.augustus.aa.gff3', sample = sample),
		expand('Genes/{sample}.filtered.aa', sample = sample),
		expand('Genes/{sample}.filtered.nt', sample = sample),
		expand('Genes/{sample}.truep450.txt', sample = sample),
		expand('Genes/{sample}.filtered.reformat.aa', sample = sample),
		expand('Genes/{sample}.cdhit.aa', sample = sample),
#		expand('Mafft/{sample}.mafft.fa', sample = sample),
				
rule miniprot:
        input:
                genome = 'Genomes/{sample}.fna',
                proteins = 'UniProt_P450_Reviewed_Insecta.fasta'
        threads:
                config['Run']['Threads']
        output:
                'miniprot_gff/{sample}.gff'
        shell:
                'miniprot --gff {input.genome} {input.proteins} > {output}'

rule gff2bed:
	input:
		gff = 'miniprot_gff/{sample}.gff'
	output:
		bed = 'bedtools/{sample}.bed'
	shell:
		'agat_convert_sp_gff2bed.pl -g {input.gff} -o {output.bed}'

rule samtools_fai:
        input:
                fna = 'Genomes/{sample}.fna'
        output:
                fai = 'fai/{sample}.fai'
        shell:
                'samtools faidx {input.fna} -o {output.fai}'

rule bedtools_slop:
        input:
                bed = 'bedtools/{sample}.bed',
                fai = 'fai/{sample}.fai'
        output:
                slopped = 'bedtools/{sample}.slop.bed'
        shell:
                'bedtools slop -b {exp} -i {input.bed} -g {input.fai} > {output.slopped}'

rule bed_sort:
	input:
		bed = 'bedtools/{sample}.slop.bed'
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

rule bedtools_getfasta:
	input:
		gen = 'Genomes/{sample}.fna',
		slopped = 'bedtools/{sample}.merge.bed'
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

#rule interproscan_gff:
#        input:
#                augustus_aa = 'augustus/{sample}.augustus.aa'
#        output:
#                interpro = 'interproscan/gff/{sample}.augustus.aa.gff3'
#        shell:
#                '''
#                ../interproscan-5.65-97.0/interproscan.sh -i {input.augustus_aa} -f gff3 -o {output.interpro}
#                '''

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

rule interpro_filter_aa:
        input:
                fasta = 'augustus/{sample}.augustus.aa',
                txt = 'Genes/{sample}.truep450.txt'
        output:
                'Genes/{sample}.filtered.aa'
        shell:
                'bash Scripts/Interpro_filter_smk.sh {input.fasta} {input.txt} {output}'

rule interpro_filter_nt:
        input:
                fasta = 'augustus/{sample}.augustus.nt',
                txt = 'Genes/{sample}.truep450.txt'
        output:
                'Genes/{sample}.filtered.nt'
        shell:
                'bash Scripts/Interpro_filter_smk.sh {input.fasta} {input.txt} {output}'

rule reformat_combine:
	input:
		genes = 'Genes/{sample}.filtered.aa'
	output:
		reformat = 'Genes/{sample}.filtered.reformat.aa'
	shell:
		'''
		for file in {input.genes}; do
			filename=$(basename "$file" .filtered.aa)

			sed "s/t1/$filename/g" {input.genes} > {output.reformat}

               done

		'''

rule cdhit:
	input:
		genes = 'Genes/{sample}.filtered.reformat.aa'
	output:
		'Genes/{sample}.cdhit.aa'
	shell:
		'cd-hit -i {input.genes} -c 1.00 -S 1 -o {output}'

rule mafft:
	input:
		genes = 'Genes/{sample}.cdhit.aa'
	output:
		aligned = 'Mafft/{sample}.mafft.fa'
	shell:
		'mafft --dash {input.genes} > {output.aligned}'

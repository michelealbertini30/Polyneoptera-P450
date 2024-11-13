	configfile: 'logs/config.smk.yaml'
exp=config['Run']['Expansion']
getAnnoFasta=config['Scripts']['getAnnoFasta']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
	input:
		expand('miniprot_gff/{sample}.gff', sample = sample),
		expand('agat_cds/{sample}.agat.fa', sample = sample),
		expand('augustus/{sample}.augustus.gff', sample = sample),
		expand('augustus/{sample}.augustus.aa', sample = sample),
		expand('augustus/{sample}.augustus.codingseq', sample = sample),
		expand('interproscan/tsv/{sample}.augustus.aa.tsv', sample = sample),
#		expand('interproscan/gff/{sample}.augustus.aa.gff3', sample = sample),
		expand('Genes/{sample}.filtered.fa', sample = sample),
		expand('Genes/{sample}.trueP450.txt', sample = sample),
		expand('Genes/{sample}.filtered.reformat.fa', sample = sample),
		expand('Genes/{sample}.cdhit.fa', sample = sample),
#		expand('Mafft/{sample}.mafft.fa', sample = sample),

rule miniprot:
        input:
                genome = 'Genomes/{sample}.fna',
                proteins = 'UniProt_all_P450.fasta'
        output:
                'miniprot_gff/{sample}.gff'
        threads: 20
	shell:
                'miniprot -M0 -k5 --gff {input.genome} {input.proteins} > {output}'

rule agat:
	input:
		genome = 'Genomes/{sample}.fna',
		gff = 'miniprot_gff/{sample}.gff'
	output:
		agat = 'agat_cds/{sample}.agat.fa'
	shell:
		'agat_sp_extract_sequences.pl -g {input.gff} -f {input.genome} -t cds --up {exp} --down {exp} -o {output.agat}'		

rule reduction:
	input:
		'agat_cds/{sample}.agat.fa'
	output:
		'agat_cds/{sample}.agat.cdhit.fa'
	shell:
		'cd-hit -i {input} -c 0.99 -o {output}'

rule augustus:
        input:
                fasta = 'agat_cds/{sample}.agat.cdhit.fa'
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
		perl {getAnnoFasta} {input.augustus_hits} > {output.aa}
		'''

rule interproscan_tsv:
	input:
		augustus_aa = 'augustus/{sample}.augustus.aa'
	output:
		interpro = 'interproscan/tsv/{sample}.augustus.aa.tsv'
	shell:
		'''
		/home/STUDENTI/michele.albertini/interproscan-5.65-97.0/interproscan.sh -i {input.augustus_aa} -f tsv -o {output.interpro}
		'''

rule interproscan_gff:
        input:
                augustus_aa = 'augustus/{sample}.augustus.aa'
        output:
                interpro = 'interproscan/gff/{sample}.augustus.aa.gff3'
        shell:
                '''
                /home/STUDENTI/michele.albertini/interproscan-5.65-97.0/interproscan.sh -i {input.augustus_aa} -f gff3 -o {output.interpro}
                '''

rule interpro_filter1:
	input:
		'interproscan/tsv/{sample}.augustus.aa.tsv'
	output:
		'Genes/{sample}.trueP450.txt'
	shell:
		'''
		for file in {input}; do
			if [ -e "$file" ]; then

				result=$(awk '/P450 |CYP / {{print $1}}' "$file" | sort -u)
				echo -e "$result" > {output}

			fi
		done		
		'''

rule interpro_filter2:
        input:
                fasta = 'augustus/{sample}.augustus.aa',
                txt = 'Genes/{sample}.trueP450.txt'
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

rule cdhit:
	input:
		'Genes/{sample}.filtered.reformat.fa'
	output:
		'Genes/{sample}.cdhit.fa'
	shell:
		'cd-hit -i {input} -c 1.00 -o {output}'

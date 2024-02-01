configfile: 'config.smk.yaml'
miniprot_cores=config['Run']['Miniprot_cores']
agat_exp=config['Run']['Agat_expansion']

getAnnoFasta=config['Scripts']['getAnnoFasta']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
	input:
		expand('augustus/{sample}.augustus.gff', sample = sample),
		'augustus_statistics.log',
		expand('augustus/{sample}.augustus.aa', sample = sample),
		expand('augustus/{sample}.augustus.codingseq', sample = sample),
		'training/Merged.gb',
		'p450.combined.fa'		

rule miniprot:
        input:
                genome = 'Genomes/{sample}.fna',
                proteins = 'UniProt_P450_RInsecta.fasta'
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

rule gff2gb:
	input:
		genome = 'Genomes/{sample}.fna',
		miniprot = rules.miniprot.output
	output:
		'training/{sample}.gb'
	shell:
		'perl training/Scripts/gff2gbSmallDNA.pl {input.miniprot} {input.genome} 16000 {output}'

rule gb_merge:
	input:
		gb = expand('training/{sample}.gb', sample = sample)
	output:
		'training/Merged.gb'
	shell:
		'cat {input.gb} > {output}'


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
                'augustus_statistics.log'
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

rule augustus_combine:
	input:
		augustus_aa = expand('augustus/{sample}.augustus.aa', sample = sample)
	output:
		'p450.combined.fa'
	shell:
		'''
		for file in {input.augustus_aa}; do
			if [ -e "$file" ]; then
				filename=$(basename "$file" .augustus_aa)
				
				sed "s/t1/$filename/g" {input.augustus_aa} >> {output}
			fi
		done
		'''

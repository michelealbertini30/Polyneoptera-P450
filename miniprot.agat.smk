configfile: 'config.yaml'
miniprot_cores=config['Run']['Miniprot_cores']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
	input: expand('agat_cds/{sample}.cds.fna', sample = sample)


rule miniprot:
	input:
		genomes = 'Genomes/{sample}.fna',
		proteins = 'UniProt_P450_RInsecta.fasta'
	threads:
		config['Run']['Threads']
	output:
		'miniprot_gff/{sample}.gff'
	shell:
		'miniprot -t{miniprot_cores} --gff {input.genomes} {input.proteins} > {output}'

rule agat:
        input:
                genomes = 'Genomes/{sample}.fna',
                miniprot=rules.miniprot.output
        output:
                'agat_cds/{sample}.cds.fna'
        shell:
                'agat_sp_extract_sequences.pl --gff {input.miniprot} --fasta {input.genomes} -t cds -o {output}'


rule miniprot2:
	input:
		genomes = 'Genomes/{sample}.fna',
		agat_fasta=rules.agat.output
	threads:
		config['Run']['Threads']
	output:
		'miniprot_sec_iter/{sample}.gff'
	shell:
		'miniprot -t{miniprot_cores} --gff {input.genomes} {input.agat_fasta} > {output}'

rule agat_sec_iter:
	input:
		genomes = 'Genomes/{sample}.fna',
		miniprot2=rules.miniprot2.output
	output:
		'agat_cds2/{sample}.cds.fna'
	shell:
		'agat_sp_extract_sequences.pl --gff {input.miniprot2} --fasta {input.genomes} -t cds -o {output}'

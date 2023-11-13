configfile: 'config.yaml'
miniprot_cores=config['Run']['Miniprot_cores']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
	input: expand('miniprot/{sample}.gff', sample = sample)


rule first_iteration:
	input:
		genomes = 'Genomes/{sample}.fna',
		proteins = 'UniProt_P450_RInsecta.fasta'

	threads:
		config['Run']['Threads']

	output:
		'miniprot/{sample}.gff'

	shell:
		'miniprot -t{miniprot_cores} --gff {input.genomes} {input.proteins} > {output}'

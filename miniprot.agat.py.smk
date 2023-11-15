configfile: 'config.yaml'
miniprot_cores=config['Run']['Miniprot_cores']

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
                miniprot = 'miniprot_gff/{sample}.gff'

        output:
                'agat_cds/{sample}.cds.fna'

        shell:
                'agat_sp_extract_sequences.pl --gff {input.miniprot} --fasta {input.genomes} -t cds -o {output}'

rule gather_fna:
	output:
		"fna_list.txt"
	
	run:
		with open(output[0], "w") as f:
			for sample in expand("{sample}", sample=glob_wildcards("Genomes/{sample}.fna")):
				f.write(f"Genomes/{sample}.fna\n")

rule gather_gff:
	input:
		expand("miniprot_gff/{sample}.gff", sample=open("fna_list.txt").read().strip().split("\n"))
	
	output:
		"gff_list.txt"
	
	run:
		with open(output[0], "w") as f:
			for sample in expand("{sample}", sample=glob_wildcards("miniprot_gff/{sample}.gff")):
				f.write(f"miniprot_gff/{sample}.gff\n")

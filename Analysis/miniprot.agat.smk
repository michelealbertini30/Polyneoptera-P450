configfile: 'config.yaml'
miniprot_cores=config['Run']['Miniprot_cores']

sample = glob_wildcards('Genomes/{sample}.fna')[0]


rule all:
        input: expand('augustus/{sample}.augustus.gff', sample = sample), 'augustus_statistics.log'


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
                miniprot = rules.miniprot.output
        output:
                'agat_cds/{sample}.cds.fna'
        shell:
                'agat_sp_extract_sequences.pl --gff {input.miniprot} --fasta {input.genomes} -t cds --up 16000 --down 16000 -o {output}'


rule augustus:
        input:
                protein_coordinates = rules.agat.output
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

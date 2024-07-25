configfile: 'log/RevBLAST.config.yml'
blast_db=config['Files']['Blast_Database']

sample = glob_wildcards('Genes/{sample}.cdhit.fa')[0]


rule all:
        input:
                expand('blast/{sample}.rblastp.txt', sample = sample),
                expand('blast/{sample}.top', sample = sample),
                expand('blast/{sample}.map1', sample = sample),
                expand('blast/{sample}.crd', sample = sample),
                expand('blast/{sample}.loci', sample = sample),
                expand('blast/{sample}.merge', sample = sample),
                expand('blast/{sample}.p450', sample = sample),
		expand('Final_Genes/{sample}.trueP450.txt', sample = sample),
		expand('Final_Genes/{sample}.filtered.fa', sample=sample)

rule reverse_blast:
        input:
                'Genes/{sample}.cdhit.fa'
        output:
                'blast/{sample}.rblastp.txt'
        shell:
                'blastp -query {input} -db {blast_db} -outfmt 6 -out {output}'


rule best_hit:
        input:
                'blast/{sample}.rblastp.txt'
        output:
                'blast/{sample}.top'
        shell:
                'bash Scripts/Filter.blast.sh {input} {output}'

rule id_mapping:
        input:
                blast = 'blast/{sample}.top',
                id = 'IDs/P450.id'
        output:
                'blast/{sample}.map1'
        shell:
                'bash Scripts/ID_mapping_smk.sh {input.blast} {input.id} {output}'

rule rev_coordinates:
        input:
                augustus = '../augustus/{sample}.augustus.gff',
                miniprot = '../miniprot_gff/{sample}.gff',
                blast = 'blast/{sample}.map1'
        output:
                'blast/{sample}.crd'
        shell:
                '''
                while read line; do

                        MP=$(grep -w "$line" {input.augustus} | grep -v "#" | cut -f1 | sort -u)
                        CRD=$(grep "$MP" {input.miniprot} | grep "mRNA" | cut -f 3,4,5)
                        paste <(printf %s "$line") <(printf %s "$CRD") >> {output}

                done< <(cut -f1 {input.blast} | awk -F "." '{{print $1}}')
                '''

rule loci_association:
        input:
                'blast/{sample}.crd'
        output:
                'blast/{sample}.loci'
        shell:
                'bash Scripts/locus_association.sh {input} {output}'


rule merge:
        input:
                crd = 'blast/{sample}.crd',
                loci = 'blast/{sample}.loci',
                map = 'blast/{sample}.map1'
        output:
                'blast/{sample}.merge'
        shell:
                '''
                id=$(cut -f1 {input.map})
                file1=$(cut -f2,3,4 {input.crd})
                file2=$(cut -f2 {input.loci})
                file3=$(cut -f2,3,4,5,6,7,8,9,10,11,12 {input.map})

                paste <(printf %s "$id") <(printf %s "$file1") <(printf %s "$file2") <(printf %s "$file3") > {output}
                '''

rule filtering:
        input:
                'blast/{sample}.merge'
        output:
                'blast/{sample}.p450'
        shell:
                '''
                sort -k5,5 -k16,16r {input} | awk  '!seen[$5]++' > {output}
                '''

rule naming:
	input:
		'blast/{sample}.p450'
	output:
		'Final_Genes/{sample}.trueP450.txt'
	shell:
		'''
		base=$(basename {input} .p450)
		cut -f1 {input} | sed 's/"$base"/t1/g' > {output}
		'''

rule extracting:
        input:
                fasta = '../Genes/{sample}.filtered.reformat.fa',
                txt = 'Final_Genes/{sample}.trueP450.txt'
        output:
                'Final_Genes/{sample}.filtered.fa'
        shell:
                'bash ../Scripts/Interpro_filter_smk.sh {input.fasta} {input.txt} {output}'

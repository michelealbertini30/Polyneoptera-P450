# **Evolution of Gene Family P450 in Polyneopterans**

This project aims to study the evolution of Cytochome P450 (or CYPs) in Polyneopterans with particular focus on gene destiny after a duplication.


<div style="background-color: #f2f2f2; padding: 10px; border: 3px solid #ddd; border-radius: 2px;">

![](https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/P450cycle.svg/750px-P450cycle.svg.png)

</div>

---


## Table of contents
1. [About the project](#about)
2. [Setup and Genome download](#setup)
3. [Bioinformatic Tools](#tools)

## <a name="about"></a> About the project
Cytochrome P450 (or CYPs) are a superfamily of enzymes containing heme as a cofactor that mostly function as monooxygenases. These proteins oxidize steroids, fatty acids and xenobiotics, but are also involved in hormone syntesis and breakdown.

Genes encoding P450 enzymes, and the enzymes themselves, are designated with the root symbol CYP for the superfamily, followed by a number indicating the gene family, a capital letter indicating the subfamily, and another number for the individual gene.

The organisms analyzed are Polyneopterans, which represent one of the major lineages of winged insects, comprising 40.000 extant species including families: Blattodea, Mantodea, Phasmatodea, Embioptera, Grylloblattodea, Mantophasmatodea, Orthoptera, Plecoptera, Dermaptera and Zoraptera.

## <a name="setup"></a> Setup and Genome download
All Polyneoptera Genomes available were selected (including only one species for genus) to build the [genome dataset](https://github.com/michelealbertini30/Polyneoptera-P450/blob/main/Scripts/refseq_genomes.tsv). All genomes were downloaded from [NCBI](https://www.ncbi.nlm.nih.gov/) using the following script:

```
mkdir Genomes
while read line;
        do

        if echo $line | grep -qv "#";
                then

                ref=$(echo $line | awk '{print $1}')
                ids=$(echo $line | awk '{print $2}')

                datasets download genome accession $rf --include genome --dehydrated --filename $rf.zip

                unzip $rf -d $rf
		datasets rehydrate --directory $rf

                cp $ref/ncbi_dataset/data/$ref/*.fna Genomes/$ids.fna
        fi

done < refseq_genomes.tsv
```
\
Next, a [protein database](https://github.com/michelealbertini30/Polyneoptera-P450/blob/main/UniProt_P450_RInsecta.fasta) was created on [UniProt](https://www.uniprot.org/) with all the annotated and reviewed P450 in the Insect class.

## <a name="tools"></a> Bioinformatic tools
Here is a complete list of all major softwares used during this project:
* [Miniprot](https://github.com/lh3/miniprot)\
Miniprot aligns a protein sequence against a genome with affine gap penalty, splicing and frameshift. It is primarily intended for annotating protein-coding genes in a new species using known genes from other species.

* [Agat](https://github.com/NBISweden/AGAT)\
**A**nother **G**tf/**G**ff **A**nalysis **T**oolkit: Suite of tools to handle gene annotation in any GTF/GFF format.

* [GeneRax](https://github.com/BenoitMorel/GeneRax)\
Parallel tool for species tree-aware maximum likelihood based gene family tree inference under gene duplication, transfer and loss.

\
Throught the entire project we chose to use [Snakemake](https://snakemake.github.io/) as primary scripting method in order to make the code more efficient when running computationally heavy analysis and ensuring an easy way to introduce new genome or protein samples without having to re-run the entire analysis.

To setup snakemake:
```
conda create -n snake-env
conda activate snake-env
mamba install -c bioconda snakemake
```
To run a snakefile:
```
snakemake --cores 10 --snakefile snakefile.smk
```

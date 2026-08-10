#!/bin/bash

# RNA-Seq Alignment & Quantification Pipeline (VMware/HGFS Optimized Syntax)
#---------------------------------------------------------------------------

# Stop script execution immediately if any command fails
set -e


echo "Started Running Pipeline"

SECONDS=0

# Step 0: Settings
echo "Setting Up Working Environment"

# Force jump to local HGFS mount point directory
cd /mnt/hgfs/rnaseq_counts_pipeline
mkdir -p data HISAT2 quants

# STEP 1: Run fastqc
echo "Running Quality Assessment & Trimming"

fastqc data/sample.fastq -o data/

# Step 1.1: Quality Filtering via Conda wrapper using trimmomatic to trim reads with poor quality
trimmomatic SE -phred33 data/sample.fastq data/sample_trimmed.fastq -threads 4 TRAILING:10 

# in case removal of adapter is required
# trimmomatic SE -phred33 data/sample.fastq data/sample_trimmed.fastq ILLUMINACLIP:adapters.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

echo "Trimmomatic finished running!"

fastqc data/sample_trimmed.fastq -o data/

# STEP 2: Stream alignments directly into coordinate-sorted binary records
echo "Aligning Reads to Human Reference Genome"

# get the genome indices
# wget https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz
# tar -xvf grch38_genome.tar.gz

# run alignment
hisat2 -q --rna-strandness R -x HISAT2/grch38/genome -U data/sample_trimmed.fastq | samtools sort -o HISAT2/sample_trimmed.bam

echo "HISAT2 finished running!"


# STEP 3: Run featureCounts - Quantification

echo "Quantifying Gene Expression Levels"                                                      

featureCounts -S 2 -a quants/Homo_sapiens.GRCh38.116.gtf -o quants/sample_featurecounts.txt HISAT2/sample_trimmed.bam
echo "featureCounts finished running!"

# Complete Pipeline Success Log
echo "SUCCESS: RNA-Seq Pipeline completed processing layout."

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
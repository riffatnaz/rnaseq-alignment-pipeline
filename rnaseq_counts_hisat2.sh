#!/bin/bash

# RNA-Seq Alignment & Quantification Pipeline (VMware/HGFS Optimized Syntax)
#---------------------------------------------------------------------------

# Stop script execution immediately if any command fails
set -e

echo "Started Running Pipeline"

SECONDS=0

# CONFIGURATION PARAMETERS

# check README.md for instructions to find strandedness
# Options: "reverse", "forward", or "unstranded"
LIBRARY_TYPE="reverse"

# Automatically resolve the correct tool parameters based on library layout
if [ "$LIBRARY_TYPE" == "reverse" ]; then
    HISAT2_STRAND="--rna-strandness R"
    FC_STRAND="-s 2"
elif [ "$LIBRARY_TYPE" == "forward" ]; then
    HISAT2_STRAND="--rna-strandness F"
    FC_STRAND="-s 1"
else
    HISAT2_STRAND="" # Unstranded requires no explicit flag configuration in HISAT2
    FC_STRAND="-s 0"
fi

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

# run alignment
hisat2 -q $HISAT2_STRAND -x HISAT2/grch38/genome -U data/sample_trimmed.fastq | samtools sort -o HISAT2/sample_trimmed.bam

echo "HISAT2 finished running!"


# STEP 3: Run featureCounts - Quantification

echo "Quantifying Gene Expression Levels"                                                      

featureCounts $FC_STRAND -a quants/Homo_sapiens.GRCh38.116.gtf -o quants/sample_featurecounts.txt HISAT2/sample_trimmed.bam
echo "featureCounts finished running!"

# Complete Pipeline Success Log
echo "SUCCESS: RNA-Seq Pipeline completed processing layout."

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

# rnaseq-alignment-pipeline
An automated, end-to-end RNA-Seq preprocessing and quantification pipeline utilizing HISAT2 for genomic alignment and featureCounts for gene expression matrix generation. It is optimized for VMware.

## One-Time Host Sharing & Guest Mounting
If shared folders disappear or look blank after a VM reboot, execute this:
```bash
sudo vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other -o uid=\$(id -u)
```

## Script Permissions
Permissions stick to the file permanently. Execute once to make the script runnable:
```bash
chmod +x scripts/rnaseq_counts_hisat2.sh
```

## Reference Data Acquisition Commands
Run these commands manually **before** running the script to download and extract your required reference data files.

### 1. Download & Extract HISAT2 Genome Indexes (GRCh38)
```bash
cd /mnt/hgfs/rnaseq_counts_pipeline/HISAT2
wget https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz
tar -xvf grch38_genome.tar.gz
```

### 2. Download & Unzip Genome Annotation File (Ensembl Release 116 GTF)
```bash
cd /mnt/hgfs/rnaseq_counts_pipeline/quants
wget https://ftp.ensembl.org/pub/release-116/gtf/homo_sapiens/Homo_sapiens.GRCh38.116.gtf.gz
gunzip Homo_sapiens.GRCh38.116.gtf.gz
```

## How to Check Library Strandedness
If you inherit unlabelled data, use `infer_experiment.py` from the **RSeQC** library on a tiny subset of your data to figure it out:

```bash
# 1. Install RSeQC inside your environment
conda install -c bioconda rseqc -y

# 2. Check strandedness using your unzipped GTF and an alignment file
infer_experiment.py -i HISAT2/sample_trimmed.bam -r quants/Homo_sapiens.GRCh38.116.gtf
```

### How to interpret the RSeQC output logs:
* If fraction of reads explained by **"1++,1--,2+-,2-+"** is high (>0.8) $\rightarrow$ **Stranded-Forward** (`LIBRARY_TYPE="forward"`).
* If fraction of reads explained by **"1+-,1-+,2++,2--"** is high (>0.8) $\rightarrow$ **Stranded-Reverse** (`LIBRARY_TYPE="reverse"`).
* If both fractions are roughly equal (~0.5 each) $\rightarrow$ **Unstranded** (`LIBRARY_TYPE="unstranded"`).

## Standard Workflow Execution
Make sure your raw input file inside the `data` folder is named **`sample.fastq`**, then run:
```bash
cd /mnt/hgfs/rnaseq_counts_pipeline/scripts
./rnaseq_counts_hisat2.sh
```

## Data Inspection & Verification Commands
Do not put these in the main pipeline script. Run them manually to look at your data:

### 1. View Processed Reads (FASTQ Text)
```bash
head -n 20 data/sample_trimmed.fastq
```

### 2. Decode Binary Mappings (BAM Format)
```bash
samtools view -h HISAT2/sample_trimmed.bam | less
```

### 3. Review Final Gene Counts Matrix
```bash
head -n 30 quants/sample_featurecounts.txt
```

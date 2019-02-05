#WDL data processing
#Add your FASTQ files paths to fastq_list.txt
#It runs FASTQC, adapter trimming, BWA alignment
#and generates some metrics.

workflow data_processing{

File FASTQ_LIST
Array[Array[File]] samples = read_tsv(FASTQ_LIST)
File SCATTER_CALLING_INTERVALS_LIST
Array[File] scatter_intervals = read_lines(SCATTER_CALLING_INTERVALS_LIST)
File fastqc
File cutadapt
File bwa
File samtools
File gatk
File refFasta
File refIndex
File refDict
File refAMB
File refANN
File refBWT
File refPAC
File refSA
File dbsnp38
File dbsnp38_index
File phase1snps
File phase1snps_index
File mills
File mills_index

scatter (sample in samples){
    
    call fastQC{
        input:
            fastqc = fastqc,
            fastq1 = sample[1],
            fastq2 = sample[2]
    }

    call trimming{
        input:
            cutadapt = cutadapt,
            fastq1 = sample[1],
            fastq2 = sample[2],
            sampleName = sample[0]
    }
        
    call bwa_mapping{
        input:
            ref = refFasta,
            ind = refIndex,
            dict = refDict,
            amb = refAMB,
            ann = refANN,
            bwt = refBWT,
            pac = refPAC,
            sa = refSA,
            bwa = bwa,
            samtools = samtools,
            sampleName = sample[0],
            fastq1_cutadapt = trimming.fastq1_cutadapt,
            fastq2_cutadapt = trimming.fastq2_cutadapt
    }

    call MarkDuplicates{
        input:
            gatk = gatk,
            sampleName = sample[0],
            BAM_FILE = bwa_mapping.bam_file,
            BAM_FILE_INDEX = bwa_mapping.bam_file_index
    }

    call CollectAlignmentSummaryMetrics{
        input:
            gatk = gatk,
            sampleName = sample[0],
            bam_file = bwa_mapping.bam_file,
            bam_file_index = bwa_mapping.bam_file_index
    }
  
    call CollectInsertSizeMetrics{
        input:
            gatk = gatk,
            sampleName = sample[0],
            bam_file = bwa_mapping.bam_file,
            bam_file_index = bwa_mapping.bam_file_index
    }
  }

scatter (interval in scatter_intervals){
    call BaseRecalibrator{
        input:
            gatk = gatk,
            refFasta = refFasta,
            refIndex = refIndex,
            refDict = refDict,
            dedup_bam = MarkDuplicates.bam_dedup,
            dbsnp38 = dbsnp38,
            dbsnp38_index = dbsnp38_index,
            phase1snps = phase1snps,
            phase1snps_index = phase1snps_index,
            mills = mills,
            mills_index = mills_index,
            interval_list = interval,
    }

    call applyBQSR{
        input:
            gatk = gatk,
            refFasta = refFasta,
            refIndex = refIndex,
            refDict = refDict,
            dedup_bam = MarkDuplicates.bam_dedup,
            interval_list = interval,
            bqsr = BaseRecalibrator.baseRecal
    }
  }
}

task fastQC{
    File fastqc
    File fastq1
    File fastq2
        
    command {
        ${fastqc} ${fastq1} ${fastq2}
    }

    output {

    }
}

task trimming{
    File cutadapt
    File fastq1
    File fastq2
    String sampleName

    command {
        ${cutadapt} \
        -a CTGTCTCTTGATCACA \
        -A TGTGATCAAGAGACAG \
        -m 22 \
        -o ${sampleName}_R1_cutadapt.fastq.gz \
        -p ${sampleName}_R2_cutadapt.fastq.gz \
        ${fastq1} ${fastq2}
    }

    output {
        File fastq1_cutadapt = "${sampleName}_R1_cutadapt.fastq.gz"
        File fastq2_cutadapt = "${sampleName}_R2_cutadapt.fastq.gz"
    }
}

task bwa_mapping{
    File ref
    File ind
    File dict
    File amb
    File ann
    File bwt
    File pac
    File sa
    File bwa
    File samtools
    String sampleName
    File fastq1_cutadapt
    File fastq2_cutadapt

    command {
        ${bwa} mem \
            -R "@RG\tID:"${sampleName}"\tLB:"${sampleName}"\tSM:"${sampleName}"\tPL:ILLUMINA" \
            -t 20 \
            ${ref} \
            ${fastq1_cutadapt} ${fastq2_cutadapt} \
            | ${samtools} view -@ 20 -bSho - | samtools sort -@ 20 - -o ${sampleName}.bam

        samtools index -@ 2 ${sampleName}.bam
    }

    output {
        File bam_file = "${sampleName}.bam"
        File bam_file_index = "${sampleName}.bam.bai"
    }
}


task MarkDuplicates{
    File gatk
    File BAM_FILE
    File BAM_FILE_INDEX
    String sampleName

    command {
        java -jar ${gatk} MarkDuplicates \
            -I ${BAM_FILE} \
            -M ${sampleName}_metrics.txt \
            -O ${sampleName}_dedup_reads.bam
    }

    output {
        File bam_dedup = "${sampleName}_dedup_reads.bam"
    }
}

task CollectAlignmentSummaryMetrics{
    File bam_file
    File bam_file_index
    File gatk
    String sampleName

    command {
        java -jar ${gatk} CollectAlignmentSummaryMetrics \
            -I ${bam_file} \
            -O ${sampleName}_alignment_metrics.txt
    }

    output {
        File alignment_metrics = "${sampleName}_alignment_metrics.txt"
    }
}

task CollectInsertSizeMetrics{
    File bam_file
    File bam_file_index
    File gatk
    String sampleName

    command{
        java -jar ${gatk} CollectInsertSizeMetrics \
            -I ${bam_file} \
            -O ${sampleName}_insert_metrics.txt \
            -H ${sampleName}_insert_size_histogram.pdf
    }

    output {
        File insert_metrics = "${sampleName}_insert_metrics.txt"
        File histogram = "${sampleName}_insert_size_histogram.pdf"
    }
}

task BaseRecalibrator{
    File gatk
    File refFasta
    File refIndex
    File refDict
    Array[File] dedup_bam
    File dbsnp38
    File dbsnp38_index
    File phase1snps
    File phase1snps_index
    File mills
    File mills_index
    File interval_list

    command {
    for file in ${sep=' ' dedup_bam}; do
        samtools index -@ 2 $file
        
        filename=$(basename $file)
        output_filename=$(echo "$filename" | cut -f 1 -d '_')
        
        java -jar ${gatk} BaseRecalibrator \
		  -R ${refFasta} \
		  -I $file \
		  --use-original-qualities \
		  --known-sites ${dbsnp38} \
		  --known-sites ${phase1snps} \
		  --known-sites ${mills} \
		  -L ${interval_list} \
          -O $output_filename"_base_recal.txt"
    done
    }

    output {
        Array[File] baseRecal = glob("*_base_recal.txt")
    }
}

task applyBQSR{
    File gatk
    File refFasta
    File refIndex
    File refDict
    Array[File] dedup_bam
    File interval_list
    Array[File] bqsr

    command {
    for file in ${sep=' ' dedup_bam}; do
        for file1 in ${sep=' ' bqsr}; do

            filename=$(basename $file)
            output_filename=$(echo "$filename" | cut -f 1 -d '_')

            filename1=$(basename $file1)
            output_filename1=$(echo "$filename1" | cut -f 1 -d '_')

            if [ "$output_filename" = "$output_filename1" ]; then
            
            samtools index -@ 2 $file
            
            java -jar ${gatk} ApplyBQSR \
                -R ${refFasta} \
                -I $file \
                -L ${interval_list} \
                -O $output_filename"_recal.bam" \
                -bqsr $file1 \
                --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30 \
                --add-output-sam-program-record \
                --use-original-qualities
            else 
                continue
            fi
        done
    done
    }

    output {
        Array[File] bam_recal = glob("*_recal.bam")
    }
}


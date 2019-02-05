#WDL somatic variant calling using Mutect2 from GATK

workflow mutect_variant_calling{

File BAM_LIST
Array[File] BAM_FILE_LIST = read_lines(BAM_LIST)
File SCATTER_CALLING_INTERVALS_LIST
Array[File] scatter_intervals = read_lines(SCATTER_CALLING_INTERVALS_LIST)
File samtools
File gatk
File refFasta
File refIndex
File refDict


scatter (interval in scatter_intervals){
    call MuTect2{
        input:
            gatk = gatk,
            refFasta = refFasta, 
            refIndex = refIndex, 
            refDict = refDict,
            interval_list = interval,
            recal_bam = BAM_FILE_LIST
    }
  }
}

task MuTect2{
    File gatk
    File refFasta
    File refIndex
    File refDict
    File interval_list
    Array[File] recal_bam

    command {
        for file in ${sep=' ' recal_bam}; do
            samtools index -@ 2 $file

            filename=$(basename $file)
            output_filename=$(echo "$filename" | cut -f 1 -d '_')
            
            java -jar ${gatk} Mutect2 \
                -I $file \
                -R ${refFasta} \
                -L ${interval_list} \
                -tumor $output_filename \
                -O $output_filename".vcf"
        done
    }

    output {

    }
}
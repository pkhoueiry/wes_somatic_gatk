#WDL somatic variant calling using Mutect2 from GATK
#Tumor/Normal

workflow mutect_variant_calling{

File SCATTER_CALLING_INTERVALS_LIST
Array[File] scatter_intervals = read_lines(SCATTER_CALLING_INTERVALS_LIST)
File tumor
Array[File] tumor_samples = read_lines(tumor)
File normal
Array[File] normal_samples = read_lines(normal)
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
            samtools = samtools,
            interval_list = interval,
            tumors = tumor_samples,
            normals = normal_samples
    }

    call filterMutectCalls{
        input:
            gatk = gatk,
            refFasta = refFasta,
            refIndex = refIndex,
            refDict = refDict,
            interval_list = interval,
            rawVCFs = MuTect2.raw_vcfs,
            rawVCFsIndex = MuTect2.raw_vcfs_index,
            statsVCFs = MuTect2.stats

    }
  }
}

task MuTect2{
    File gatk
    File refFasta
    File refIndex
    File refDict
    File interval_list
    File samtools
    Array[File] tumors
    Array[File] normals

    command {
		for file in ${sep=' ' tumors}; do
			for file1 in ${sep=' ' normals}; do
				filename=$(basename $file)
				output_filename=$(echo "$filename" | cut -f 1 -d '-')

				filename1=$(basename $file1)
                                output_filename1=$(echo "$filename1" | cut -f 1 -d '-')

				if [ "$output_filename" == "$output_filename1" ]
				then

				${samtools} index -@ 2 $file
				${samtools} index -@ 2 $file1

				java -jar ${gatk} Mutect2 \
					-I $file \
					-tumor $output_filename"-T" \
					-I $file1 \
					-normal $output_filename"-N" \
					-R ${refFasta} \
					-L ${interval_list} \
					-O $output_filename"_tumor_normal_calls.vcf"
				else
                                    continue
                                fi
			done
		done	
    }

    output {
	Array[File] raw_vcfs = glob("*_tumor_normal_calls.vcf")
	Array[File] raw_vcfs_index = glob("*_tumor_normal_calls.vcf.idx")
	Array[File] stats = glob("*_tumor_normal_calls.stats")

    }
}

task filterMutectCalls{

    File gatk
    File refFasta
    File refIndex
    File refDict
    File interval_list
    Array[File] rawVCFs
    Array[File] rawVCFsIndex
    Array[File] statsVCFs

    command {
                for file in ${sep=' ' rawVCFs}; do
                    filename=$(basename $file)
                    output_filename=$(echo "$filename" | cut -f 1 -d '_')

                    java -jar ${gatk} IndexFeatureFile -F $file

                    java -jar ${gatk} FilterMutectCalls \
                        -R ${refFasta} \
                        -V $file \
                        -L ${interval_list} \
                        -O $output_filename"_filtered_tumor_normal_calls.vcf"
                done

    }

    output {

    }
}

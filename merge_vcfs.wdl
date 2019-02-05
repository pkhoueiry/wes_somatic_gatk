#WDL gathering GVCFs and genotyping
#Takes list of GVCFs for many samples
#we need to assign samples names and text file for each sample
#listing full path of GVCFs

workflow mergevcfs{

File VCF_samples_lists
Array[File] vcfs_all_samples = read_lines(VCF_samples_lists)
File gatk
File tabix
File refFasta
File refIndex
File refDict

call MergeVcfs{
        input:
            gatk = gatk,
            tabix = tabix,
            refFasta = refFasta, 
            refIndex = refIndex, 
            refDict = refDict,
            vcfs_all_samples = vcfs_all_samples
    }
}

task MergeVcfs{
    File gatk
    File tabix
    File refFasta
    File refIndex
    File refDict
    Array[File] vcfs_all_samples

    command {
        for file in ${sep=' ' vcfs_all_samples}; do

            filename=$(basename $file)
            output_filename=$(echo "$filename" | cut -f 1 -d '.')

            java -jar ${gatk} MergeVcfs \
                -I $file \
                -O $output_filename".vcf"
        done
    }

    output {
        Array[File] merged_gvcfs = glob("*.vcf")
    }
}
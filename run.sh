#!/bin/bash
#WES Somatic pipeline

help () {
	echo -en "usage: $(basename $0) /path/project/directory"
    echo " You have to specify project directory."
}

projectDir=$1
cd $projectDir

if [ "$#" -ne 1 ]; then
    help
    exit 1
fi

if [ ! -d "${projectDir}"/fastq ] || [ ! -d "${projectDir}"/lists ]; then
    echo "There is missing directories - fastq or/and lists"
    echo "Check README.md for detailed help"
    exit 1
else {
    time (
    read -p 'Do you want to perform read trimming? (Y|N): ' choice

    java -jar ~/software/cromwell-36.jar \
        run ~/scripts/wes-somatic-scatter-gather/splitting_bed_file.wdl \
        --inputs ~/scripts/wes-somatic-scatter-gather/bwa_and_gatk_wdl.json

    wait

    ~/scripts/wes-somatic-scatter-gather/listing_intervals.sh ${projectDir}

    wait

    if [ "$choice" = "Y" ] || [ "$choice" = "y" ] || [ "$choice" = "Yes" ] || [ "$choice" = "yes" ] || [ "$choice" = "YES" ]; then
    printf -- '\033[33m You have chosen to trim adapters... \033[0m\n';

    java -jar ~/software/cromwell-36.jar \
        run ~/scripts/wes-somatic-scatter-gather/data_processing.wdl \
        --inputs ~/scripts/wes-somatic-scatter-gather/bwa_and_gatk_wdl.json

    wait

    else
    printf -- '\033[33m Trimming skipped... \033[0m\n';
    java -jar ~/software/cromwell-36.jar \
        run ~/scripts/wes-somatic-scatter-gather/data_processing_without_trimming.wdl \
        --inputs ~/scripts/wes-somatic-scatter-gather/bwa_and_gatk_wdl.json

    wait
    fi

    ~/scripts/wes-somatic-scatter-gather/preparing_bams.sh ${projectDir}

    wait

    java -jar ~/software/cromwell-36.jar \
        run ~/scripts/wes-somatic-scatter-gather/mutect2_variant_calling.wdl \
        --inputs ~/scripts/wes-somatic-scatter-gather/bwa_and_gatk_wdl.json

    wait

    ~/scripts/wes-somatic-scatter-gather/preparing_vcfs.sh ${projectDir}

    wait

    java -jar ~/software/cromwell-36.jar \
        run ~/scripts/wes-somatic-scatter-gather/merge_vcfs.wdl \
        --inputs ~/scripts/wes-somatic-scatter-gather/bwa_and_gatk_wdl.json

    wait


    rm -rf ${projectDir}/allvcfs/
        )
    }
fi
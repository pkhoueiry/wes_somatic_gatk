#!/bin/bash

projectDir=$1

#create directory for bam files, where I gather all bam files in one directory
mkdir ${projectDir}/bam

for f in ${projectDir}/cromwell-executions/data_processing/*/call-applyBQSR/shard-*/execution/*.bam; do
    foldername="$f";
    file=${foldername##*/}
    parent=${foldername#*"${foldername%/*/"$file"}"/}
    shard=${foldername#*"${foldername%/*/"$parent"}"/}
    folder=$(echo "$shard" | cut -f 1 -d'/');

    filename=$(basename $f);
    filename1=$(echo "$filename" | cut -f 1 -d '.');
    echo $filename1;
    mkdir "$projectDir/bam/$folder/"; 
    ln -P $f "$projectDir/bam/$folder/";
    #ln -P $f "${projectDir}/bam/";
done

mkdir ${projectDir}/merged_bams/
for gf in ${projectDir}/bam/shard-*/*.bam; do
    parent_name=$gf;
    echo ${parent_name};

    file=${parent_name##*/}
    parent_dir=${parent_name#*"${parent_name%/*/"$file"}"/}
    shard=${foldername#*"${foldername%/*/"$parent"}"/}
    echo $shard;
    parent=$(echo "$parent_dir" | cut -f 1 -d'/');
    file_name=$(basename $gf);
    filename2=$(echo "$file_name" | cut -f 1 -d '.');
    name=${parent}_${filename2};
    mv $gf "$projectDir/merged_bams/$name.bam";
done

rm -rf ${projectDir}/bam

#get samples names
cut -f 1 ${projectDir}/lists/fastq_list.txt > ${projectDir}/lists/samples_names.txt

#merging bam files
echo "Merging BAM files..."
while IFS= read -r line; do
    echo "merging $line"
    /home/pklab/software/samtools-1.8/samtools merge -@ 30 ${projectDir}/merged_bams/"$line".bam ${projectDir}/merged_bams/shard*_"$line"_*.bam
    rm ${projectDir}/merged_bams/shard-*_"$line"_*.bam
    mv ${projectDir}/merged_bams/"$line".bam ${projectDir}/merged_bams/"$line"_recal_dedup.bam
done < ${projectDir}/lists/samples_names.txt

mv ${projectDir}/merged_bams/ ${projectDir}/bam/

if [ "$tumor_normal_choice" = 2 ]; then
    printf -- '\033[36m Preparing Tumor/Normal samples list... \033[0m\n';
    while read p; do
        echo $p | sed 's/-.//g' >> ${projectDir}/lists/tumor_normal_samples_1.txt
    done < ${projectDir}/lists/samples_names.txt

    sort ${projectDir}/lists/tumor_normal_samples_1.txt | uniq > ${projectDir}/lists/tumor_normal_samples_2.txt

    while read p; do
        echo -e "$p\t/${projectDir}/bam/$p-T_recal_dedup.bam\t/${projectDir}/bam/$p-N_recal_dedup.bam" >> ${projectDir}/lists/bam_list.txt
    done < ${projectDir}/lists/tumor_normal_samples_2.txt

    rm -f ${projectDir}/lists/tumor_normal_samples_1.txt
    rm -f ${projectDir}/lists/tumor_normal_samples_2.txt

    cut -f 1 ${projectDir}/lists/bam_list.txt > ${projectDir}/lists/samples.txt
    cut -f 2 ${projectDir}/lists/bam_list.txt > ${projectDir}/lists/tumor.txt
    cut -f 3 ${projectDir}/lists/bam_list.txt > ${projectDir}/lists/normal.txt

else
    printf -- '\033[36m Preparing Tumor only samples list... \033[0m\n';
    for f in ${projectDir}/bam/*.bam ; do
        echo "$f" >> ${projectDir}/lists/bam_list.txt; 
    done

fi

echo "BAMs are ready"

#!/bin/bash
projectDir=$1

##create a directory called "vcfs" where we gather all vcfs in one place by creating hard link
echo ${projectDir}/
mkdir ${projectDir}/vcfs/

if [ "$tumor_normal_choice" == 2 ]; then
for f in ${projectDir}/cromwell-executions*/mutect_variant_calling*/*/call-filterMutectCalls/shard-*/execution/*.vcf; do 
    foldername="$f";
    
    file=${foldername##*/}
    parent=${foldername#*"${foldername%/*/"$file"}"/}
    shard=${foldername#*"${foldername%/*/"$parent"}"/}
    
    folder=$(echo "$shard" | cut -f 1 -d'/');

    filename=$(basename $f);
    filename1=$(echo "$filename" | cut -f 1 -d '.');
    echo $filename1;
    mkdir "$projectDir/vcfs/$folder/"; 
    ln -P $f "$projectDir/vcfs/$folder/";
done

else
for f in ${projectDir}/cromwell-executions*/mutect_variant_calling*/*/call-MuTect2/shard-*/execution/*.vcf; do 
    foldername="$f";
    
    file=${foldername##*/}
    parent=${foldername#*"${foldername%/*/"$file"}"/}
    shard=${foldername#*"${foldername%/*/"$parent"}"/}
    
    folder=$(echo "$shard" | cut -f 1 -d'/');

    filename=$(basename $f);
    filename1=$(echo "$filename" | cut -f 1 -d '.');
    echo $filename1;
    mkdir "$projectDir/vcfs/$folder/"; 
    ln -P $f "$projectDir/vcfs/$folder/";
done
fi

##after gathering vcfs, we do rename them according to their location
##then we remove the "vcfs" directory created above
mkdir ${projectDir}/allvcfs/
for gf in ${projectDir}/vcfs/shard-*/*.vcf; do
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
    mv $gf "$projectDir/allvcfs/$name.vcf";
done

rm -rf ${projectDir}/vcfs

#create a list of gvcfs full paths
for f in ${projectDir}/allvcfs/*.vcf ; do
    echo "$f" >> ${projectDir}/lists/vcfs.txt; 
done

#get samples names
rm -f ${projectDir}/lists/samples_names.txt

if [ "$tumor_normal_choice" == 2 ]; then
	mv ${projectDir}/lists/samples.txt ${projectDir}/lists/samples_names.txt
else
	rm -f ${projectDir}/lists/samples_names.txt
	cut -f 1 ${projectDir}/lists/fastq_list.txt > ${projectDir}/lists/samples_names.txt
fi

#from the list created above, we just split each sample in a text file

if [ "$tumor_normal_choice" == 2 ]; then
while IFS= read -r line; do
        line+="_filtered_tumor_normal_calls.vcf"
        grep -F "${line}" ${projectDir}/lists/vcfs.txt >> ${projectDir}/lists/$line.list;
done < ${projectDir}/lists/samples_names.txt

for f in ${projectDir}/lists/*.vcf.list; do 
        bn=$(basename $f | cut -f 1 -d"."); mv $f ${projectDir}/lists/$bn.list;
done

else
while IFS= read -r line; do
	line+=".vcf"
	grep -F "${line}" ${projectDir}/lists/vcfs.txt >> ${projectDir}/lists/$line.list;
done < ${projectDir}/lists/samples_names.txt

for f in ${projectDir}/lists/*.vcf.list; do 
        bn=$(basename $f | cut -f 1 -d"."); mv $f ${projectDir}/lists/$bn.list;
done
fi

#we create list of lists
for f in ${projectDir}/lists/*.list ; do
    echo $f >> ${projectDir}/lists/vcfs_samples_lists.txt
done


echo "VCFs are ready"

WES Somatic scatter-gather pipeline

This pipeline runs by just invoking run.sh <projectDirectory> in command line.
the <projectDir> should have the following structure:
    
    1- "fastq" directory which contains FASTQ files. FASTQ files should have the following naming style:
        sampleName_R1.fastq.gz and sampleName_R2.fastq.gz
    
    2- "lists" directory which contains two files:
        - "fastq_list.txt"
        - "hg_38_intervals.bed"

            "fastq_list.txt" is a tab separated file and should contain all samples required for analysis:
                sampleName1    sampleName1_R1.fastq.gz    sampleName1_R2.fastq.gz
                sampleName2    sampleName2_R1.fastq.gz    sampleName2_R2.fastq.gz

            "hg_38_intervals.bed" is an intervals file in BED format.

        Finally, we have to specify the path of both "fastq_list.txt" and "hg_38_intervals.bed" in the JSON file

We can invoke each WDL and shell scripts separately.
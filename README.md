WES Somatic scatter-gather pipeline

This pipeline runs by just invoking run.sh <projectDirectory> in command line.
the <projectDir> should have the following structure:
    
    1- "fastq" directory which contains FASTQ files. FASTQ files should have the following naming style:
        sampleName_R1.fastq.gz and sampleName_R2.fastq.gz
    
    2- "lists" directory which contains two files:
        - "fastq_list.txt"
        - "intervals.bed"

            "fastq_list.txt" is a tab separated file and should contain all samples required for analysis:
                sampleName1    sampleName1_R1.fastq.gz    sampleName1_R2.fastq.gz
                sampleName2    sampleName2_R1.fastq.gz    sampleName2_R2.fastq.gz

            "intervals.bed" is an intervals file in BED format.

        "adapters.txt" should contain the adapters:
            AAAAAAAAAAA
            TTTTTTTTTTT

        Second, we have to specify the path of "fastq_list.txt", "scatter_calling_intervals.txt" and "adapters.txt" in the JSON file.

        Finally, we have to specify adapters in case we choose to do read trimming.
        In the first line we put the adapter to be trimmed from the first read (forward) and the second line the adapter to be trimmed from the second read (reverse).

We can invoke each WDL and shell scripts separately.
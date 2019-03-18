WES Somatic scatter-gather pipeline

This pipeline runs by just invoking `run.sh /path/to/projectDir` in command line.
the projectDir should have the following structure:
    
    1- "fastq" directory which contains FASTQ files. FASTQ files should have the following naming style:
        sampleName_R1.fastq.gz and sampleName_R2.fastq.gz
    
    2- "lists" directory which contains three files:
        - "fastq_list.txt"
        - "intervals.txt"
        - "adapters.txt"

            "fastq_list.txt" is a tab separated file and should contain all samples required for analysis:
                sampleName1    sampleName1_R1.fastq.gz    sampleName1_R2.fastq.gz
                sampleName2    sampleName2_R1.fastq.gz    sampleName2_R2.fastq.gz

            "intervals.txt" is an intervals file in TXT format for scattering.

            "adapters.txt" should hold adapters to be trimmed.
            first line should contain first read adapter (forward) and the second
            line should contain second read adapter (reverse)

            AAAAAAAAAAAA
            TTTTTTTTTTTT

We have to specify the path of all resources in the JSON file if this pipeline is used outside the Docker.*

We can invoke each WDL and shell scripts separately.

*If we use the Docker, all you need is to use "fastq_list.txt", "scatter_calling_intervals.txt" and "adapters.txt"
from "sample_lists" directory.
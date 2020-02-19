## Whole Exome Sequencing Pipeline - Somatic Analysis
#### Using the Scatter-Gather technique provided by Broad Institute

Whole Exome Sequencing (WES) pipelines are built using WDL scripts (Workflow Description Language) provided by Broad Institute. 

The pipelines follow the best practices proposed by Broad Institute and use open-source state-of-the-art tools. The following diagram summarizes the germline and somatic analysis (tumor only and tumor/normal):

![alt text](wes_workflow/wes_pipelines.png "Whole Exome Sequencing Pipelines")

The pipelines consist of WDL scripts that run the analysis and shell scripts that act as intermediate steps. The pipelines are tested successfully using the following list of properly installed tools and dependencies: 

    Java 8 
    Cromwell v36 
    FastQC v0.11.5 
    BWA 0.7.17-r1194-dirty 
    Cutadapt 1.18 
    Samtools 1.8 – should be installed in the PATH 
    GATK-4.0.11.0 
    Tabix 0.2.5 

Also, you should download the human reference genome and create its index using BWA. In addition, some databases should be downloaded too: 

    dbsnp
    phase1snps 
    Mills_and_1000G_gold_standard 
    HapMap 
    Omni 
    Axiom 

You can download the reference genome and its index, the intervals and the databases listed above from resources directory provided by Broad Institute from the following link: 

https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/?pli=1

Each one of the WDL and shell scripts can be invoked independently by providing the project directory as argument.
  
the `projectDir` should have the following structure:  

1- "fastq" directory which contains FASTQ files. FASTQ files should have the following naming style:
    sampleName_R1.fastq.gz and sampleName_R2.fastq.gz

2- "lists" directory which contains three files:

        - "fastq_list.txt"
        - "intervals.txt"
        - "adapters.txt"

        "fastq_list.txt" is a tab separated file and should contain all samples required for analysis.
        first column refers to sample name, second and third columns refer to full paths of 
        forward and reverse FASTQ files respectively:
            sampleName1    sampleName1_R1.fastq.gz    sampleName1_R2.fastq.gz
            sampleName2    sampleName2_R1.fastq.gz    sampleName2_R2.fastq.gz

        In the case of somatic analysis having tumor/normal samples, samples should be named
        in the following format (the order of samples in this file does not matter):

            sampleName1-T	sampleName1-T_R1.fastq.gz	sampleName1-T_R2.fastq.gz
            sampleName1-N	sampleName1-N_R1.fastq.gz	sampleName1-N_R2.fastq.gz
            sampleName2-T	sampleName2-T_R1.fastq.gz	sampleName2-T_R2.fastq.gz
            sampleName2-N	sampleName2-N_R1.fastq.gz	sampleName2-N_R2.fastq.gz
        
&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;*where 'T' refers to 'Tumor' and 'N' refers to 'Normal'*

        "intervals.txt" should contain a list of full path of all intervals in BED format:
        path/to/intervals/scattered_calling_intervals/temp_0001_of_50/scattered.interval_list
        path/to/intervals/scattered_calling_intervals/temp_0002_of_50/scattered.interval_list
        path/to/intervals/scattered_calling_intervals/temp_0003_of_50/scattered.interval_list
        path/to/intervals/scattered_calling_intervals/temp_0004_of_50/scattered.interval_list
        path/to/intervals/scattered_calling_intervals/temp_0005_of_50/scattered.interval_list

        "adapters.txt" should hold adapters to be trimmed.
        first line should contain first read adapter (forward) and the second
        line should contain second read adapter (reverse) 

To run the pipeline, you must specify full paths for each tool and database in the JSON file. Once done, you can invoke the pipeline using the following command:  

`/path/to/run.sh /path/to/project/directory /path/to/cromwell.jar`

Note that a Docker image is available upon request. 

To use the Docker image, you must prepare the ‘project directory’ as mentioned above and invoke the Docker image using the following command:  

`docker run -it -v /path/to/project/directory/:/data/ pklab/wes_pipelines `

*We can invoke each WDL and shell scripts separately.*  
*If we use the Docker, all you need is to use "fastq_list.txt", "intervals.txt" and "adapters.txt" from "sample_lists" directory.*
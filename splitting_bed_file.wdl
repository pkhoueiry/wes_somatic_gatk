#WDL somatic variant calling - splitting bed file

workflow splitting{
    File gatk
    File bed
    File refFasta
    File refIndex
    File refDict
    File refAMB
    File refANN
    File refBWT
    File refPAC
    File refSA
    Int scatter_count


    call splitIntervals{
        input:
            gatk = gatk,
            bed = bed,
            refFasta = refFasta,
            refIndex = refIndex,
            refDict = refDict,
            scatter_count = scatter_count
    }
}

task splitIntervals{
    File gatk
    File bed
    File refFasta
    File refIndex
    File refDict
    Int scatter_count

    command {
        java -jar ${gatk} SplitIntervals \
            -R ${refFasta} \
            -L ${bed} \
            -scatter ${scatter_count} \
            -O .
    }

    output {

    }
}
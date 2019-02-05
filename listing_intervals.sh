#!/bin/bash
projectDir=$1

for f in ${projectDir}/cromwell-executions/splitting/*/call-splitIntervals/execution/*.intervals; do
    echo $f >> ${projectDir}/lists/intervals.txt
done
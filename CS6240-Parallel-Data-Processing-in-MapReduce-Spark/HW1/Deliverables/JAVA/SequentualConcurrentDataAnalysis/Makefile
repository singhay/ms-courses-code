#!/bin/bash
#Author: Ayush Singh, 001621833

if [ $# -eq 1 ]
then
    java -jar out/artifacts/SequentualConcurrentDataAnalysis_jar/SequentualConcurrentDataAnalysis.jar $1
else
    echo "Since input file path is missing, running program on file comprising of 10k lines from source dataset"
    java -jar out/artifacts/SequentualConcurrentDataAnalysis_jar/SequentualConcurrentDataAnalysis.jar src/main/resources/10k.csv.gz 
fi

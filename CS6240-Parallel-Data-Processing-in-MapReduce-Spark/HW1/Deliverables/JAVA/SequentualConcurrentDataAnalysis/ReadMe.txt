Author: Ayush Singh, 001621833

To run the program simply execute the provided Makefile in the root dir
Expected Arguments: Input File Path
Assumptions: Input file format is GZIP
Run Command in Bash: ./Makefile
If no arguments are passed, program runs on a sub Dataset already present
in resources dir of src dir else if argument is provided program runs on 
input dataset.

.
├── Makefile
├── out
│   └── artifacts
│       └── SequentualConcurrentDataAnalysis_jar
│           └── SequentualConcurrentDataAnalysis.jar
├── ReadMe.txt
├── SequentualConcurrentDataAnalysis.iml
└── src
    ├── main
    │   ├── java
    │   │   └── com
    │   │       └── cs6240
    │   │           ├── Fibonacci
    │   │           │   ├── CoarseLock.java
    │   │           │   ├── Fibonacci.java
    │   │           │   ├── FineLock.java
    │   │           │   ├── NoLock.java
    │   │           │   ├── NoSharing.java
    │   │           │   ├── RunFib.java
    │   │           │   └── Sequential.java
    │   │           ├── Main.java
    │   │           └── Original
    │   │               ├── CoarseLock.java
    │   │               ├── FineLock.java
    │   │               ├── NoLock.java
    │   │               ├── NoSharing.java
    │   │               ├── RunOrig.java
    │   │               └── Sequential.java
    │   └── resources
    │       └── 10k.csv.gz
    └── META-INF
        └── MANIFEST.MF

12 directories, 20 files


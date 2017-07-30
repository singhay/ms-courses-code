Use the makefile in the src directory to publish commands 
But you have to go into each project directory and edit its makefile with
your own aws and hadoop properties
.
├── output
│   ├── InMapperCombiner
│   │   ├── part-r-00000
│   │   ├── part-r-00001
│   │   ├── part-r-00002
│   │   ├── part-r-00003
│   │   ├── part-r-00004
│   │   ├── part-r-00005
│   │   ├── part-r-00006
│   │   ├── part-r-00007
│   │   ├── part-r-00008
│   │   └── _SUCCESS
│   ├── NoCombiner
│   │   ├── part-r-00000
│   │   ├── part-r-00001
│   │   ├── part-r-00002
│   │   ├── part-r-00003
│   │   ├── part-r-00004
│   │   ├── part-r-00005
│   │   ├── part-r-00006
│   │   ├── part-r-00007
│   │   ├── part-r-00008
│   │   └── _SUCCESS
│   ├── SecondarySort
│   │   ├── part-r-00000
│   │   ├── part-r-00001
│   │   ├── part-r-00002
│   │   ├── part-r-00003
│   │   ├── part-r-00004
│   │   ├── part-r-00005
│   │   ├── part-r-00006
│   │   ├── part-r-00007
│   │   ├── part-r-00008
│   │   └── _SUCCESS
│   └── WithCombiner
│       ├── part-r-00000
│       ├── part-r-00001
│       ├── part-r-00002
│       ├── part-r-00003
│       ├── part-r-00004
│       ├── part-r-00005
│       ├── part-r-00006
│       ├── part-r-00007
│       ├── part-r-00008
│       └── _SUCCESS
├── ReadMe.txt
├── Report.pdf
├── src
│   ├── InMapperCombiner
│   │   ├── InMapperCombiner.iml
│   │   ├── Makefile
│   │   ├── output
│   │   │   ├── part-r-00000
│   │   │   ├── part-r-00001
│   │   │   ├── part-r-00002
│   │   │   ├── part-r-00003
│   │   │   ├── part-r-00004
│   │   │   ├── part-r-00005
│   │   │   ├── part-r-00006
│   │   │   ├── part-r-00007
│   │   │   ├── part-r-00008
│   │   │   └── _SUCCESS
│   │   ├── pom.xml
│   │   ├── src
│   │   │   └── main
│   │   │       ├── java
│   │   │       │   ├── Main.java
│   │   │       │   └── META-INF
│   │   │       │       └── MANIFEST.MF
│   │   │       └── resources
│   │   │           └── log4j.properties
│   │   └── target
│   │       ├── classes
│   │       │   ├── log4j.properties
│   │       │   ├── Main.class
│   │       │   ├── Main$Map.class
│   │       │   └── Main$Reduce.class
│   │       ├── generated-sources
│   │       │   └── annotations
│   │       ├── InMapperCombiner-1.0.jar
│   │       ├── maven-archiver
│   │       │   └── pom.properties
│   │       ├── maven-status
│   │       │   └── maven-compiler-plugin
│   │       │       └── compile
│   │       │           └── default-compile
│   │       │               ├── createdFiles.lst
│   │       │               └── inputFiles.lst
│   │       └── original-InMapperCombiner-1.0.jar
│   ├── Makefile
│   ├── NoCombiner
│   │   ├── Makefile
│   │   ├── NoCombiner.iml
│   │   ├── pom.xml
│   │   ├── src
│   │   │   └── main
│   │   │       ├── java
│   │   │       │   ├── Main.java
│   │   │       │   └── META-INF
│   │   │       │       └── MANIFEST.MF
│   │   │       └── resources
│   │   │           └── log4j.properties
│   │   └── target
│   │       ├── classes
│   │       │   ├── log4j.properties
│   │       │   ├── Main.class
│   │       │   ├── Main$Map.class
│   │       │   └── Main$Reduce.class
│   │       ├── generated-sources
│   │       │   └── annotations
│   │       ├── maven-archiver
│   │       │   └── pom.properties
│   │       ├── maven-status
│   │       │   └── maven-compiler-plugin
│   │       │       └── compile
│   │       │           └── default-compile
│   │       │               ├── createdFiles.lst
│   │       │               └── inputFiles.lst
│   │       ├── NoCombiner-1.0.jar
│   │       └── original-NoCombiner-1.0.jar
│   ├── SecondarySort
│   │   ├── Makefile
│   │   ├── pom.xml
│   │   ├── SecondarySort.iml
│   │   └── src
│   │       └── main
│   │           ├── java
│   │           │   ├── CompositeKeyComparator.java
│   │           │   ├── CompositeKey.java
│   │           │   ├── Main.java
│   │           │   ├── META-INF
│   │           │   │   └── MANIFEST.MF
│   │           │   ├── NaturalKeyGroupingComparator.java
│   │           │   └── NaturalKeyPartitioner.java
│   │           └── resources
│   │               └── log4j.properties
│   └── WithCombiner
│       ├── Makefile
│       ├── pom.xml
│       ├── src
│       │   └── main
│       │       ├── java
│       │       │   ├── Main.java
│       │       │   └── META-INF
│       │       │       └── MANIFEST.MF
│       │       └── resources
│       │           └── log4j.properties
│       └── WithCombiner.iml
└── syslog
    ├── InMapperCombiner
    ├── NoCombiner
    ├── SecondarySort
    ├── WithCombiner
    └── WithCombiner.gz

50 directories, 104 files

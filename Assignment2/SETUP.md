# Assignment 2 Setup (Mac)

## 1) Extracted location

Your files are extracted here:

`/Users/hamzakhamissa/assignment2/Assignment2`

## 2) Quick environment check

```bash
cd /Users/hamzakhamissa/assignment2/Assignment2
./check-env.sh
```

## 3) Start Elasticsearch (Part 1)

1. Start Docker Desktop.
2. Run:

```bash
cd /Users/hamzakhamissa/assignment2/Assignment2/Part1
./start-es.sh
```

3. Confirm:

```bash
curl http://localhost:9200
```

Stop when needed:

```bash
./stop-es.sh
```

## 4) Run Lucene demo (Part 2)

```bash
cd /Users/hamzakhamissa/assignment2/Assignment2/Part2
. ./setclasspath.sh
javac *.java
java MyIndexFiles -docs documents/
java MySearchFiles < testcases.txt
```

## 5) Java version note

This assignment asks for JDK 17. Your machine currently has Java 20/25 and the provided Lucene 8.7.0 demo compiles/runs successfully with it.
If you want strict version matching, install JDK 17 and switch `JAVA_HOME` before compiling.


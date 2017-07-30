package main.java.com.cs6240.Fibonacci;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.zip.GZIPInputStream;

public class RunFib {
    private final int NUMBER_OF_RUNS;
    private final int NUMBER_OF_THREADS;
    private static HashMap<String, Float[]> noSharingMap = new HashMap<>();

    public RunFib(Integer NUMBER_OF_RUNS, Integer NUMBER_OF_THREADS) {
        this.NUMBER_OF_RUNS = NUMBER_OF_RUNS;
        this.NUMBER_OF_THREADS = NUMBER_OF_THREADS;
    }

    public void run(List<String> records) {

        long startTime, endTime, netTime;
        double seqAvgTime = 0, noLockAvgTime = 0, coarseLockAvgTime = 0,
                fineLockAvgTime = 0, noSharingAvgTime = 0;
        double seqMinTime = 99999, noLockMinTime = 99999, coarseLockMinTime = 99999,
                fineLockMinTime = 99999, noSharingMinTime = 99999;
        double seqMaxTime = -99999, noLockMaxTime = -99999, coarseLockMaxTime = -99999,
                fineLockMaxTime = -99999, noSharingMaxTime = -99999;

        List<List<String>> splitList = partition(records, NUMBER_OF_THREADS);


        System.out.print
                ("\n+------------------------------------------------------+");
        System.out.print
                ("\n|NAME          AVERAGE    MINIMUM    MAXIMUM    SPEEDUP|");
        System.out.print
                ("\n+------------------------------------------------------+");

        /**
         * SEQUENTIAL version created an object of class Sequential
         */
        Sequential seqObj = new Sequential(records);
        for (int i = 0; i < NUMBER_OF_RUNS; i++) {
            startTime = System.currentTimeMillis();
            seqObj.calcAvg();
            endTime = System.currentTimeMillis();
            netTime = endTime - startTime;
            seqAvgTime += netTime;
            seqMaxTime = Math.max(seqMaxTime, netTime);
            seqMinTime = Math.min(seqMinTime, netTime);
        }
        System.out.printf("\n|SEQ           %-8.2f   %-8.2f   %-8.2f   %-7.3f|",
                seqAvgTime / NUMBER_OF_RUNS, seqMinTime, seqMaxTime, 1.000);


        // NO LOCKS
        Thread[] noLockThreads = new Thread[NUMBER_OF_THREADS];
        for (int j = 0; j < NUMBER_OF_RUNS; j++) {
            startTime = System.currentTimeMillis();
            for (int i = 0; i < NUMBER_OF_THREADS; i++) {
                Thread t = new Thread(new NoLock(splitList.get(i)));
                noLockThreads[i] = t;
                noLockThreads[i].start();
            }
            for (int i = 0; i < NUMBER_OF_THREADS; i++) {
                try {
                    noLockThreads[i].join();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            endTime = System.currentTimeMillis();
            netTime = endTime - startTime;
            noLockAvgTime += netTime;
            noLockMaxTime = Math.max(noLockMaxTime, netTime);
            noLockMinTime = Math.min(noLockMinTime, netTime);
        }
        System.out.printf("\n|NO-LOCK       %-8.2f   %-8.2f   %-8.2f   %-7.3f|",
                noLockAvgTime / NUMBER_OF_RUNS, noLockMinTime,
                noLockMaxTime, seqAvgTime / noLockAvgTime);


        // COARSE LOCKS
        Thread[] coarseLockThreads = new Thread[NUMBER_OF_THREADS];
        for (int j = 0; j < NUMBER_OF_RUNS; j++) {
            startTime = System.currentTimeMillis();
            for (int i = 0; i < coarseLockThreads.length; i++) {
                Thread t = new Thread(new CoarseLock(splitList.get(i)));
                coarseLockThreads[i] = t;
                coarseLockThreads[i].start();
            }
            for (int i = 0; i < NUMBER_OF_THREADS; i++) {
                try {
                    coarseLockThreads[i].join();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            endTime = System.currentTimeMillis();
            netTime = endTime - startTime;
            coarseLockAvgTime += netTime;
            coarseLockMaxTime = Math.max(coarseLockMaxTime, netTime);
            coarseLockMinTime = Math.min(coarseLockMinTime, netTime);
        }
        System.out.printf("\n|COARSE-LOCK   %-8.2f   %-8.2f   %-8.2f   %-7.3f|",
                coarseLockAvgTime / NUMBER_OF_RUNS, coarseLockMinTime,
                coarseLockMaxTime, seqAvgTime / coarseLockAvgTime);


        // FINE LOCKS
        Thread[] fineLockThreads = new Thread[NUMBER_OF_THREADS];
        for (int j = 0; j < NUMBER_OF_RUNS; j++) {
            startTime = System.currentTimeMillis();
            for (int i = 0; i < NUMBER_OF_THREADS; i++) {
                Thread t = new Thread(new FineLock(splitList.get(i)));
                fineLockThreads[i] = t;
                fineLockThreads[i].start();
            }
            for (int i = 0; i < NUMBER_OF_THREADS; i++) {
                try {
                    fineLockThreads[i].join();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            endTime = System.currentTimeMillis();
            netTime = endTime - startTime;
            fineLockAvgTime += netTime;
            fineLockMaxTime = Math.max(fineLockMaxTime, netTime);
            fineLockMinTime = Math.min(fineLockMinTime, netTime);
        }
        System.out.printf("\n|FINE-LOCK     %-8.2f   %-8.2f   %-8.2f   %-7.3f|",
                fineLockAvgTime / NUMBER_OF_RUNS, fineLockMinTime,
                fineLockMaxTime, seqAvgTime / fineLockAvgTime);


        // NO SHARING
        Thread[] noSharingThreads = new Thread[NUMBER_OF_THREADS];
        NoSharing[] listOfNoSharingObjs = new NoSharing[NUMBER_OF_THREADS];
        for (int j = 0; j < NUMBER_OF_RUNS; j++) {
            startTime = System.currentTimeMillis();
            for (int i = 0; i < NUMBER_OF_THREADS; i++) {
                listOfNoSharingObjs[i] = new NoSharing(splitList.get(i));
                noSharingThreads[i] = new Thread(listOfNoSharingObjs[i]);
                noSharingThreads[i].start();
            }
            for (int i = 0; i < NUMBER_OF_THREADS; i++) {
                try {
                    noSharingThreads[i].join();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            reduce(listOfNoSharingObjs);
            endTime = System.currentTimeMillis();
            netTime = endTime - startTime;
            noSharingAvgTime += netTime;
            noSharingMaxTime = Math.max(noSharingMaxTime, netTime);
            noSharingMinTime = Math.min(noSharingMinTime, netTime);
        }
        System.out.printf("\n|NO-SHARING    %-8.2f   %-8.2f   %-8.2f   %-7.3f|",
                noSharingAvgTime / NUMBER_OF_RUNS, noSharingMinTime,
                noSharingMaxTime, seqAvgTime / noSharingAvgTime);


        System.out.print
                ("\n+------------------------------------------------------+");

    }

    private void reduce(NoSharing[] listOfNoSharingObjs) {
        Float[] otherMapCountById, h1MapCountById, combinedAvgAndCount;
        Float combinedCountOfId, combinedSumOfId;
        HashMap<String, Float[]> tmpStationCountAvg;
        for (int i = 0; i < NUMBER_OF_THREADS; i++) {
            tmpStationCountAvg = listOfNoSharingObjs[i].getAvgTemp();
            for (String key : tmpStationCountAvg.keySet()) {
                if (noSharingMap.containsKey(key)) {
                    otherMapCountById = tmpStationCountAvg.get(key);
                    h1MapCountById = noSharingMap.get(key);
                    combinedCountOfId = otherMapCountById[1] + h1MapCountById[1];
                    combinedSumOfId = otherMapCountById[0] * otherMapCountById[1] +
                            h1MapCountById[0] * h1MapCountById[1];
                    combinedAvgAndCount = new Float[]{combinedSumOfId / combinedCountOfId,
                            combinedCountOfId};
                    noSharingMap.put(key, combinedAvgAndCount);
                } else {
                    noSharingMap.put(key, tmpStationCountAvg.get(key));
                }
            }
        }
    }


    /**
     * Open and read a file, and return the lines in the file
     * as a list of Strings.
     */
    private static List<String> loadFile(String filename) {
        List<String> records = new ArrayList<>();

        try {
            System.out.print("Reading file " + filename);
            GZIPInputStream gzip = new GZIPInputStream(new FileInputStream(filename));
            BufferedReader reader = new BufferedReader(new InputStreamReader(gzip));
            String line;
            while ((line = reader.readLine()) != null) {
                records.add(line);
            }
            reader.close();
            return records;
        } catch (IOException e) {
            System.err.format("Exception occurred trying to read '%s'.",
                    filename);
            e.printStackTrace();
            return null;
        }
    }


    /**
     * Returns List of the List argument passed to this function with size = chunkSize
     *
     * @param records input list to be portioned
     * @param chunkSize maximum size of each partition
     * @param <T> Generic type of the List
     * @return A list of Lists which is portioned from the original list
     */
    public static <T>List<List<T>> partition(final List<T> records, final int
            chunkSize )
    {
        final List<List<T>> parts = new ArrayList<List<T>>();
        final int chopSize = records.size() / chunkSize;
        int leftOver = records.size() % chopSize;
        int split = chopSize;

        for( int i = 0, iT = records.size(); i < iT; i += split )
        {
            if( leftOver > 0 ) {
                leftOver--;
                split = chopSize + 1;
            } else {
                split = chopSize;
            }
            parts.add( new ArrayList<T>( records.subList( i, Math.min( iT, i + split ) ) ) );
        }
        return parts;
    }
}

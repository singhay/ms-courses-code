package main.java.com.cs6240.Original;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RunOrig {

    private final int NUMBER_OF_RUNS;
    private final int NUMBER_OF_THREADS;
    private HashMap<String, Float[]> noSharingMap = new HashMap<>();

    public RunOrig(Integer NUMBER_OF_RUNS, Integer NUMBER_OF_THREADS) {
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

        System.out.print("\n+------------------------------------------------------+");
        System.out.print("\n|NAME          AVERAGE    MINIMUM    MAXIMUM    SPEEDUP|");
        System.out.print("\n+------------------------------------------------------+");

        /** SEQUENTIAL
         * Below creates an object of Seq class which helps calculate
         * average in sequential manner
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


        /** NO LOCKS
         * Create an array of Threads of the size of NUMBER_OF_THREADS
         * Following that we iterate to create new threads, add them to
         * array and then start the Thread.
         * After that we iterate over the Thread array to put a barrier
         * so as to move forward with other operations
         * The above process is repeated 10 times in order to normalize
         * over irregular runs of all the following programs printing
         * numerous stats after successful run.
         */
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

//        System.out.println("\nMiscount b/w SEQ & NO-LOCK " + compare(seqObj.getAvgTemp(), new NoLock(splitList.get(0)).getAvgTemp()));
//        System.out.println("\nMiscount b/w SEQ & COARSE-LOCK " + compare(seqObj.getAvgTemp(), new CoarseLock(splitList.get(0)).getAvgTemp()));
//        System.out.println("\nMiscount b/w SEQ & FINE-LOCK " + compare(seqObj.getAvgTemp(), new
// FineLock
//                (splitList.get(0)).getAvgTemp()));
    }

    public Integer compare(HashMap<String, Float[]> m1, Map<String, Float[]> m2) {
        Integer misCount = 0;
        for (String key : m1.keySet()) {
            if (m2.containsKey(key)) {
                if (!(m1.get(key)[1].equals(m2.get(key)[1]))) {
                    misCount++;
                }
            } else misCount++;
        }
        return misCount;
    }


    private  void reduce(NoSharing[] listOfNoSharingObjs) {
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
     * Returns List of the List argument passed to this function with size = chunkSize
     *
     * @param ts input list to be portioned
     * @param chunkSize maximum size of each partition
     * @param <T> Generic type of the List
     * @return A list of Lists which is portioned from the original list
     */
    private <T>List<List<T>> partition(final List<T> ts, final int chunkSize)
    {
        final List<List<T>> parts = new ArrayList<List<T>>();
        final int chopSize = ts.size() / chunkSize;
        int leftOver = ts.size() % chopSize;
        int split = chopSize;

        for( int i = 0, iT = ts.size(); i < iT; i += split )
        {
            if( leftOver > 0 ) {
                leftOver--;
                split = chopSize + 1;
            } else {
                split = chopSize;
            }
            parts.add( new ArrayList<T>( ts.subList( i, Math.min( iT, i + split ) ) ) );
        }
        return parts;
    }

}

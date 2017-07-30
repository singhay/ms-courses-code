package main.java.com.cs6240.Original;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.StringJoiner;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Created by Ayush Singh on 1/12/17.
 */
class FineLock implements Runnable{
    private final List<String> input;

        private static ConcurrentHashMap<String, Float[]> avgTemp = new ConcurrentHashMap<>(8,0.9f, 1);
//    private static Map<String, Float[]> avgTemp = new HashMap<>();
    private static final Float MISSING_VALUE_LABEL = -9999f;

    FineLock(List<String> input) {
        this.input = input;
    }

    private void calcAvg() {
        for (String s : input) {
            String[] parts = s.split("\\s*,\\s*");
            String id = parts[0];
            String element = parts[2];
            Float value = Float.parseFloat(parts[3]);
            Float[] stationAvgCount = new Float[2];
            stationAvgCount[0] = value;
            stationAvgCount[1] = 1f;
            if (element.equals("TMAX") && !value.equals(MISSING_VALUE_LABEL)) {
                synchronized (id) {
                    stationAvgCount = avgTemp.putIfAbsent(id, stationAvgCount);
                }
                if (stationAvgCount == null) {
                    synchronized (id) {
                        stationAvgCount = avgTemp.get(id);
                        stationAvgCount[0] = ((stationAvgCount[1] * stationAvgCount[0]) + value) / (stationAvgCount[1] + 1f);
                        stationAvgCount[1] = stationAvgCount[1] + 1f;
                        avgTemp.put(id, stationAvgCount);
                    }
                }
            }
        }
    }

    public Map<String, Float[]> getAvgTemp(){
        return avgTemp;
    }

    public void run() {
        calcAvg();
    }
}

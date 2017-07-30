package main.java.com.cs6240.Fibonacci;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by Ayush Singh on 1/12/17.
 */
class FineLock implements Runnable {
    private final List<String> input;
    private static ConcurrentHashMap<String, Float[]> avgTemp = new ConcurrentHashMap<>(8,
            0.9f, 1);
    private static final Float MISSING_VALUE_LABEL = -9999f;
    private static final Integer FIBONACCI_N = 17;

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
                stationAvgCount = avgTemp.putIfAbsent(id, stationAvgCount);
                if (stationAvgCount != null) {
                    Float totalCount = stationAvgCount[1];
                    Float currentAvg = stationAvgCount[0];
                    stationAvgCount[1] = totalCount + 1;
                    Fibonacci.compute(FIBONACCI_N);
                    stationAvgCount[0] = ((totalCount * currentAvg) + value) / stationAvgCount[1];
                    avgTemp.put(id, stationAvgCount);
                }
            }
        }
    }

    public static ConcurrentHashMap<String, Float[]> getAvgTemp() {
        return avgTemp;
    }

    public void run() {
        calcAvg();
    }
}

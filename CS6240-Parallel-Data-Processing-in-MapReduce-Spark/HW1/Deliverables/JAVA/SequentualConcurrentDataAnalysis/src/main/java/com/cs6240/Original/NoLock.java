package main.java.com.cs6240.Original;

import java.util.HashMap;
import java.util.List;

/**
 * Created by Ayush Singh on 1/12/17.
 */
class NoLock implements Runnable{
    private final List<String> input;
    private static final HashMap<String, Float[]> avgTemp = new HashMap<>();
    private static final Float MISSING_VALUE_LABEL = -9999f;

    NoLock(List<String> input) {
        this.input = input;
    }

    private void calcAvg() {
        for (String s : input) {
            String[] parts = s.split("\\s*,\\s*");
            String id = parts[0];
            String element = parts[2];
            Float value = Float.parseFloat(parts[3]);
            Float[] stationAvgCount = new Float[2];
            if (element.equals("TMAX") && !value.equals(MISSING_VALUE_LABEL)) {
                try {
                    if (avgTemp.containsKey(id)) {
                        Float totalCount = avgTemp.get(id)[1];
                        Float currentTmaxAvg = avgTemp.get(id)[0];
                        stationAvgCount[0] = ((totalCount * currentTmaxAvg) + value)
                                / totalCount + 1;
                        stationAvgCount[1] = totalCount + 1;
                    } else {
                        stationAvgCount[0] = value;
                        stationAvgCount[1] = 1f;
                    }
                } catch (NullPointerException e) {
                    continue;
                }
                avgTemp.put(id, stationAvgCount);
            }
        }
    }

    public HashMap<String, Float[]> getAvgTemp() {
        return avgTemp;
    }

    public void run() {
        calcAvg();
    }
}

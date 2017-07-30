package main.java.com.cs6240.Original;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Created by Ayush Singh on 1/12/17.
 */
class NoSharing implements Runnable {
    private final List<String> input;
    private HashMap<String, Float[]> avgTemp = new HashMap<>();
    private static final Float MISSING_VALUE_LABEL = -9999f;

    NoSharing(List<String> input) {
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
                if (avgTemp.containsKey(id)) {
                    Float currentAvg = avgTemp.get(id)[0];
                    Float totalCount = avgTemp.get(id)[1];
                    stationAvgCount[0] = ((totalCount * currentAvg) + value) / totalCount + 1;
                    stationAvgCount[1] = totalCount + 1;
                } else {
                    stationAvgCount[0] = value;
                    stationAvgCount[1] = 1f;
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

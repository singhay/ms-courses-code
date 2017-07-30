package main.java.com.cs6240.Fibonacci;

import java.util.HashMap;
import java.util.List;

/**
 * Created by Ayush Singh on 1/12/17.
 */
class Sequential {
    private final List<String> input;
    private static final HashMap<String, Float[]> avgTemp = new HashMap<>();
    private static final Float MISSING_VALUE_LABEL = -9999f;
    private static final Integer FIBONACCI_N = 17;

    Sequential(List<String> input) {
        this.input = input;
    }

    public void calcAvg() {
        for (String s : input) {
            String[] parts = s.split("\\s*,\\s*");
            String id = parts[0];
            String element = parts[2];
            Float value = Float.parseFloat(parts[3]);
            Float[] stationAvgCount = new Float[2];
            if (element.equals("TMAX") && !value.equals(MISSING_VALUE_LABEL)) {
                if (avgTemp.containsKey(id)) {
                    Float currentCount = avgTemp.get(id)[1];
                    Float currentAvg = avgTemp.get(id)[0];
                    Fibonacci.compute(FIBONACCI_N);
                    stationAvgCount[0] = ((currentCount * currentAvg) + value) / currentCount + 1;
                    stationAvgCount[1] = currentCount + 1;
                } else {
                    stationAvgCount[0] = value;
                    stationAvgCount[1] = 1f;
                }
                avgTemp.put(id, stationAvgCount);
            }
        }
    }

    public static HashMap<String, Float[]> getAvgTemp() {
        return avgTemp;
    }
}

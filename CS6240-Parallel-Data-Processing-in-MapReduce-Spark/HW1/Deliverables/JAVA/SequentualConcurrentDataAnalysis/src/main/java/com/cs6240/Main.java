package main.java.com.cs6240;

import main.java.com.cs6240.Fibonacci.RunFib;
import main.java.com.cs6240.Original.RunOrig;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.GZIPInputStream;

/**
 * Created by Ayush Singh on 1/14/17.
 * Goals: Gain hands on experience with parallel computation
 *  and synchronization primitives in a single machine shared memory environment.
 *
 *  This program calculates the average temperature for each station ID from
 *  a publicly available weather dataset. The documentations state the dataset
 *  contains missing info, so those are taken care of you.
 *
 *  The core formulae at the heart of the program is calculating average which
 *  in this case I've decided to program as a running one rather than iterating
 *  over the data structure and calculating once all over again.
 *  Average = ((Current_Average + Current_Count) + New_Value) / (Current_Count + 1)
 *
 *  Speedup is calculated by diving average time of sequential by average time of
 *  corresponding version of the program.
 *
 *  The program outputs two table. First one has fibonacci(17) calculating
 *  wherever temperature value is added while the other one is Vanilla.
 */
public class Main {

    private static final int NUMBER_OF_RUNS = 10;
    private static final int NUMBER_OF_THREADS = 7;

    public static void main(String[] args) {

        RunOrig orig = new RunOrig(NUMBER_OF_RUNS, NUMBER_OF_THREADS);
        RunFib fib = new RunFib(NUMBER_OF_RUNS, NUMBER_OF_THREADS);
        List<String> records;
        if (args.length < 1) {
            System.out.println("You need to specify file path as argument in " +
                    "GZIP format!" +
                    "!");
            System.exit(1);
        } else {
            records = loadFile(args[0]);
            if (records != null) {
                System.out.print("\nFile Loaded with " + records.size() + " " + "records\n");
                System.out.printf("\nNumber of WORKER THREADS: %d", NUMBER_OF_THREADS);
                System.out.printf("\nNumber of PROGRAM ITERATIONS: %d", NUMBER_OF_RUNS);
                System.out.print("\nAll time units henceforth are in milliseconds (ms)");
                System.out.print("\n\nFIBONACCI(17)");
                fib.run(records);
                System.out.print("\n\nORIGINAL");
                orig.run(records);
                System.out.print("\n\n");
            } else {
                System.out.print("\nFile has zero records");
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
}

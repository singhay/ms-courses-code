import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

import java.io.IOException;
import java.util.LinkedHashMap;

public class Main {
    private static final String MISSING_VALUE_LABEL = "-9999";

    public static class Map extends Mapper<Object, Text, CompositeKey, Text>{

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            FileSplit fileSplit = (FileSplit) context.getInputSplit();
            String fileName = fileSplit.getPath().getName();
            String[] parts = value.toString().split("\\s*,\\s*");
            String id = parts[0];
            String element = parts[2];
            String temp = parts[3];
            Integer year = Integer.parseInt(fileName.replace(".csv", ""));
            CompositeKey compositeKey = new CompositeKey(id, year);
            String output = element + "," + temp;
            if (element.equals("TMAX") || element.equals("TMIN") && !element.equals(MISSING_VALUE_LABEL)) {
                context.write(compositeKey, new Text(output));
            }
        }
    }

    public static class Reduce extends Reducer<CompositeKey,Text,Text,NullWritable> {

        public void reduce(CompositeKey key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            String output;
            String[] parts;
            Integer temp;
            Integer[] x;
            // Linked, to preserve order which is guaranteed by Secondary Sort
            LinkedHashMap<Integer, Integer[]> m = new LinkedHashMap<>(10);
            for (Text val : values) {
                parts = val.toString().split("\\s*,\\s*");
                temp = Integer.parseInt(parts[1]);
                if (m.containsKey(key.getYear())) {
                    x = m.get(key.getYear());
                    if (parts[0].equals("TMAX")) {
                        if (x[3] > 0)
                            temp += x[2];
                        m.put(key.getYear(), new Integer[]{x[0], x[1], temp, ++x[3]});
                    } else {
                        if (x[1] > 0)
                            temp += x[0];
                        m.put(key.getYear(), new Integer[]{temp, ++x[1], x[2], x[3]});
                    }
                } else {
                    if (parts[0].equals("TMAX")) {
                        m.put(key.getYear(), new Integer[]{0, 0, temp, 1});
                    } else {
                        m.put(key.getYear(), new Integer[]{temp, 1, 0, 0});
                    }
                }
            }
            output = key.getStationId() + ", [";
            for (java.util.Map.Entry<Integer,  Integer[]> entry : m.entrySet()) {
                Integer[] e = entry.getValue();
                output += "(" + entry.getKey() + ", " + (float)e[0]/e[1] + "," +
                        " " + (float)e[2]/e[3] +  "),";
            }
            output = output.substring(0, output.length() - 1) + "]";

            context.write(new Text(output), NullWritable.get());
        }
    }

    public static void main(String[] args) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");
        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        if (otherArgs.length != 2) {
            System.err.println("Usage: SecondarySort <in> <out>");
            System.exit(1);
        }

        Job job = Job.getInstance(conf);
        job.setJarByClass(Main.class);
        job.setMapperClass(Map.class);
        job.setPartitionerClass(NaturalKeyPartitioner.class);
        job.setGroupingComparatorClass(NaturalKeyGroupingComparator.class);
        job.setSortComparatorClass(CompositeKeyComparator.class);
        job.setReducerClass(Reduce.class);
        job.setMapOutputKeyClass(CompositeKey.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        FileInputFormat.setInputPaths(job, new Path(otherArgs[0]));
        Path outPath = new Path(otherArgs[1]);
        FileOutputFormat.setOutputPath(job, outPath);
        outPath.getFileSystem(conf).delete(outPath, true);
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
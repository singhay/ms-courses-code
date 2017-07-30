import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map.Entry;

public class Main {

    public static class Map extends Mapper<Object, Text, Text, Text>{

        HashMap<String, Integer[]> globalMeanMap = new HashMap<>();

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String[] parts = value.toString().split("\\s*,\\s*");
            String id = parts[0];
            String element = parts[2];
            Integer temp = Integer.parseInt(parts[3]);
            // Array of size 4 in order TMIN, TMIN_COUNT, TMAX, TMAX_COUNT
            Integer[] t;
            if (globalMeanMap.containsKey(id)) {
                t = globalMeanMap.get(id);
                if (element.equals("TMAX")) {
                    if (t[3] > 0)
                        temp += t[2];
                    globalMeanMap.put(id, new Integer[]{t[0], t[1], temp, ++t[3]});
                }
                if (element.equals("TMIN")) {
                    if (t[1] > 0)
                        temp += t[0];
                    globalMeanMap.put(id, new Integer[]{temp, ++t[1], t[2], t[3]});
                }
            } else {
                if (element.equals("TMAX")) {
                    globalMeanMap.put(id, new Integer[]{0, 0, temp, 1});
                }
                if (element.equals("TMIN")) {
                    globalMeanMap.put(id, new Integer[]{temp, 1, 0, 0});
                }
            }
        }

        protected void cleanup(Context context) throws IOException, InterruptedException {
            for (Entry<String, Integer[]> entry : globalMeanMap.entrySet()) {
                Integer[] t = entry.getValue();
                context.write(new Text(entry.getKey()),
                        new Text(t[0] + "," + t[1] + "," + t[2] + "," + t[3]));
            }
        }
    }

    public static class Reduce extends Reducer<Text,Text,Text,NullWritable> {

        public void reduce(Text key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            String[] p;
            Integer tmaxSum   = 0;
            Integer tmaxCount = 0;
            Integer tminSum   = 0;
            Integer tminCount = 0;
            for (Text val : values) {
                p = val.toString().split("\\s*,\\s*");
                tminSum   += Integer.parseInt(p[0]);
                tminCount += Integer.parseInt(p[1]);
                tmaxSum   += Integer.parseInt(p[2]);
                tmaxCount += Integer.parseInt(p[3]);
            }
            String output;
            if (tmaxCount == 0 || tminCount == 0)
                output = key.toString() + ", " + tminSum + ", " + tminCount +
                        ", " + tmaxSum + ", " + tmaxCount;
            else
                output = key.toString() + ", " +
                    String.valueOf((double)tminSum/tminCount) + ", " +
                    String.valueOf((double)tmaxSum/tmaxCount);
            context.write(new Text(output), NullWritable.get());
        }
    }

    public static void main(String[] args) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");
        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        if (otherArgs.length != 2) {
            System.err.println("Usage: InMapperCombiner <in> <out>");
            System.exit(1);
        }

        Job job = Job.getInstance(conf);
        job.setJarByClass(Main.class);
        job.setMapperClass(Map.class);
        job.setReducerClass(Reduce.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);
        FileInputFormat.setInputPaths(job, new Path(otherArgs[0]));
        Path outPath = new Path(otherArgs[1]);
        FileOutputFormat.setOutputPath(job, outPath);
        outPath.getFileSystem(conf).delete(outPath, true);
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
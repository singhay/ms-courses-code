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

public class Main {

    public static class Map extends Mapper<Object, Text, Text, Text>{

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String[] parts = value.toString().split("\\s*,\\s*");
            String id = parts[0];
            String element = parts[2];
            String temp = parts[3];
            if (element.equals("TMAX") || element.equals("TMIN"))
                context.write(new Text(id), new Text(element + "," + temp));
        }
    }


    public static class Combine extends Reducer<Text,Text,Text,Text> {
        String[] parts;
        public void reduce(Text key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            Integer tmaxSum = 0;
            Integer tmaxCount = 0;
            Integer tminSum = 0;
            Integer tminCount = 0;
            Integer temp;
            for (Text val : values) {
                parts = val.toString().split("\\s*,\\s*");
                temp = Integer.parseInt(parts[1]);
                if (parts[0].equals("TMAX")) {
                    tmaxSum += temp;
                    tmaxCount++;
                } else {
                    tminSum += temp;
                    tminCount++;
                }
            }
            String output = String.valueOf(tminSum) + "," +
                            String.valueOf(tminCount) + "," +
                            String.valueOf(tmaxSum) + "," +
                            String.valueOf(tmaxCount);
            context.write(key, new Text(output));
        }
    }


    public static class Reduce extends Reducer<Text,Text,Text,NullWritable> {
        String[] parts;
        public void reduce(Text key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            String mapKey = key.toString();
            Double tmaxSum = 0D;
            Integer tmaxCount = 0;
            Integer tmaxCombineCount = 0;
            Double tminSum = 0D;
            Integer tminCount = 0;
            Integer tminCombineCount = 0;
            for (Text val : values) {
                parts = val.toString().split("\\s*,\\s*");
                tmaxCombineCount = Integer.parseInt(parts[3]);
                tmaxSum += Double.parseDouble(parts[2]) * tmaxCombineCount;
                tmaxCount += tmaxCombineCount;
                tminCombineCount = Integer.parseInt(parts[1]);
                tminSum += Double.parseDouble(parts[0]) * tminCombineCount;
                tminCount += tminCombineCount;
            }
            String output = mapKey + ", " + String.valueOf((double)tminSum/tminCount) + ", " + String.valueOf((double)tmaxSum/tmaxCount);
            context.write(new Text(output), NullWritable.get());
        }
    }

    public static void main(String[] args) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");
        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        if (otherArgs.length != 2) {
            System.err.println("Usage: wordcount <in> <out>");
            System.exit(1);
        }

        Job job = Job.getInstance(conf);
        job.setJarByClass(Main.class);
        job.setMapperClass(Map.class);
        job.setCombinerClass(Combine.class);
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
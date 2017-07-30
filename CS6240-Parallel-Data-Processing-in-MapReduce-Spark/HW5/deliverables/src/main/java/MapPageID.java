/**
 * Created by Ayush Singh on 2/19/17.
 */

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.MultipleOutputs;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

import java.io.IOException;

public class MapPageID {

    public static class Map extends Mapper<Object, Text, Text, Text> {

        private long id;
        private int increment;
        private MultipleOutputs multipleOutputs;

        protected void setup(Context context) throws IOException, InterruptedException {

            Configuration conf = context.getConfiguration();
            id = context.getTaskAttemptID().getTaskID().getId();
            increment = conf.getInt("mapred.map.tasks", 0);
            multipleOutputs = new MultipleOutputs<>(context);

        }

        protected void map(Object key, Text value, Context context) throws IOException, InterruptedException {
            id += increment;
            String[] tokens = value.toString().split("\t");
            if(tokens.length-1 == 0){
                multipleOutputs.write("Dangling", new Text(tokens[0]), id, "Dangling/Dangling");
            }
            multipleOutputs.write("NonDangling", new Text(tokens[0]), id, "NonDangling0/NonDangling");
        }

        protected void cleanup(Context context) throws IOException, InterruptedException {
            multipleOutputs.close();
        }
    }

    public static void main(String[] args) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");
        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        Path inPath = new Path(otherArgs[0]);
        Path outPath = new Path(otherArgs[1]);
        outPath.getFileSystem(conf).delete(outPath, true);

        Job job = Job.getInstance(conf);
        job.setJarByClass(MapPageID.class);
        job.setMapperClass(Map.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        MultipleOutputs.addNamedOutput(job, "Dangling", TextOutputFormat.class,
                Text.class, Text.class);
        MultipleOutputs.addNamedOutput(job, "NonDangling", TextOutputFormat.class,
                Text.class, Text.class);

        FileInputFormat.setInputPaths(job, inPath);
        FileOutputFormat.setOutputPath(job, outPath);
        job.waitForCompletion(true);

    }
}
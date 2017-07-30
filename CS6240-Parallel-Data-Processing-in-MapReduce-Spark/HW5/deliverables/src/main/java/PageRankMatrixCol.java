import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.MultipleInputs;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.util.HashMap;

public class PageRankMatrixCol {

    public static class MatrixMap extends Mapper<Object, Text, Text, Text>{

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String[] tokens = value.toString().split("\t");
            context.write(new Text(tokens[0]), new Text(tokens[1]+"\t"+tokens[2]));
        }
    }

    public static class PageMap extends Mapper<Object, Text, Text, Text>{

        int iterationCount;
        double initialPageRank;

        public void setup(Context context){
            Configuration conf = context.getConfiguration();
            iterationCount  = conf.getInt("iterationCount", 0);
            initialPageRank = conf.getDouble("initialPageRank", 0);
        }

        public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
            String[] tokens = value.toString().split("\t");
            if(iterationCount == 1)
                context.write(new Text(tokens[1]), new Text(String.valueOf(initialPageRank) + "\t" + "initialPageRank"));
            else context.write(new Text(tokens[0]), new Text(tokens[1] + "\t" + "initialPageRank"));
        }

    }

    public static class Reduce extends Reducer<Text,Text,Text,Text> {


        private HashMap<String, Double> prMap;
        int iterationCount;

        protected void setup(Context context) throws IOException, InterruptedException {
            prMap = new HashMap<>();
            iterationCount = context.getConfiguration().getInt("iterationCount", 0);
        }

        public void reduce(Text key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            String[] tokens;
            double currentPageRank = 0D;
            double contribution = 0D;
            for (Text value : values) {
                tokens = value.toString().split("\t");
                if(tokens[1].equals("initialPageRank")) currentPageRank = Double.valueOf(tokens[0]);
                else {
                    contribution = Double.parseDouble(tokens[1]) * currentPageRank;
                    if (prMap.containsKey(tokens[0])) contribution += prMap.get(tokens[0]);
                    prMap.put(tokens[0], contribution);
                }
            }
            prMap.putIfAbsent(key.toString(), 0D);
        }

        public void cleanup(Context context) throws IOException, InterruptedException{
            for (java.util.Map.Entry entry : prMap.entrySet()){
                context.write(new Text(String.valueOf(entry.getKey())), new Text(String.valueOf(entry.getValue())));
            }
        }

    }

    public static class MapSum extends Mapper<Object, Text, Text, Text>{

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String[] tokens = value.toString().split("\t");
            context.write(new Text(tokens[0]), new Text(tokens[1]));
        }
    }

    public static class ReduceSum extends Reducer<Text,Text,Text,Text> {


        private final double alpha = 0.0;
        private static int iterationCount = 0;
        private static long totalLinksCount = 0;
        private static double initialPageRank = 0D;
        private static double danglingNodePageRank = 0D;
        private HashMap<String, Double> prMap;

        protected void setup(Context context) throws IOException, InterruptedException {
            prMap = new HashMap<>();
            Configuration conf = context.getConfiguration();
            iterationCount = Integer.parseInt(conf.get("iterationCount"));
            totalLinksCount = Long.parseLong(conf.get("totalLinksCount"));
            initialPageRank = 1D/totalLinksCount;

            URI[] cacheFiles = context.getCacheFiles();
            Path pageMapFilePath = new Path(cacheFiles[0]);
            FileSystem fs = FileSystem.get(pageMapFilePath.toUri(), conf);
            FileStatus[] status = fs.listStatus(pageMapFilePath);
            String line;
            String[] parts;
            for (int i=0;i<status.length;i++){
                Path path = status[i].getPath();
                if(!path.toString().contains(".") && ! path.toString().contains("_SUCCESS") && !path.toString().contains("crc")){
                    BufferedReader br=new BufferedReader(new InputStreamReader(fs.open(path)));
                    while ((line = br.readLine()) != null){
                        parts = line.split("\t");
                        if(iterationCount == 1) prMap.put(parts[1], initialPageRank);
                        else prMap.put(parts[0], Double.parseDouble(parts[1]));
                    }
                    br.close();
                }
            }

            Path danglingNodePath = new Path(cacheFiles[1]);
            fs = FileSystem.get(danglingNodePath.toUri(), conf);
            status = fs.listStatus(danglingNodePath);
            for (int i=0;i<status.length;i++){
                Path path = status[i].getPath();
                if(!path.toString().contains(".") && ! path.toString().contains("_SUCCESS") && !path.toString().contains("crc")){
                    BufferedReader br=new BufferedReader(new InputStreamReader(fs.open(path)));
                    while ((line = br.readLine()) != null){
                        danglingNodePageRank += prMap.get(line.split("\t")[1]);
                    }
                    br.close();
                }
            }
            danglingNodePageRank /= totalLinksCount;
        }

        public void reduce(Text key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            Double pr = 0D;
            for (Text value : values) {
                pr += Double.parseDouble(value.toString());
            }
            pr = alpha/totalLinksCount + (1-alpha)*(pr + danglingNodePageRank);
            context.write(key, new Text(pr.toString()));
        }

    }

    public static void main(String[] args, Long totalLinksCount) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");

        for (int i = 0; i < 10; i++) {
            Configuration conf = new Configuration();
            conf.set("iterationCount", String.valueOf(i + 1));
            conf.set("totalLinksCount", totalLinksCount.toString());
            conf.setDouble("initialPageRank", 1D/totalLinksCount);
            Job job = Job.getInstance(conf);
            job.setJarByClass(PageRankMatrixCol.class);
            job.setReducerClass(Reduce.class);
            job.setMapOutputKeyClass(Text.class);
            job.setMapOutputValueClass(Text.class);
            job.setOutputKeyClass(Text.class);
            job.setOutputValueClass(Text.class);

            Path inputMatrix  = new Path(args[0]);
            Path output = new Path(args[1] + (i+1));
            Path cache  = new Path(args[1] + i);
            Path cacheD = new Path(args[2]);

            MultipleInputs.addInputPath(job, cache, TextInputFormat.class, PageMap.class);
            MultipleInputs.addInputPath(job, inputMatrix, TextInputFormat.class, MatrixMap.class);

            Path outputPath = new Path(args[1] + "SumInput");
            FileOutputFormat.setOutputPath(job, outputPath);
            outputPath.getFileSystem(conf).delete(outputPath, true);
            job.waitForCompletion(true);

            Job sumJob = Job.getInstance(conf);
            sumJob.setJarByClass(PageRankMatrixCol.class);
            sumJob.setMapperClass(MapSum.class);
            sumJob.setReducerClass(ReduceSum.class);
            sumJob.setMapOutputKeyClass(Text.class);
            sumJob.setMapOutputValueClass(Text.class);
            sumJob.setOutputKeyClass(Text.class);
            sumJob.setOutputValueClass(Text.class);
            sumJob.addCacheFile(cache.toUri());
            sumJob.addCacheFile(cacheD.toUri());
            FileInputFormat.setInputPaths(sumJob, outputPath);
            FileOutputFormat.setOutputPath(sumJob, output);
            output.getFileSystem(conf).delete(output, true);
            sumJob.waitForCompletion(true);
        }
    }
}
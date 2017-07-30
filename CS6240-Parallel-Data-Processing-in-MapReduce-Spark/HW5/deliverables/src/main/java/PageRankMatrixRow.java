import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.util.HashMap;

public class PageRankMatrixRow {

    public static class Map extends Mapper<Object, Text, Text, Text>{

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String[] tokens = value.toString().split("\t");
            context.write(new Text(tokens[0]), new Text(tokens[1]+"\t"+tokens[2]));
        }
    }

    public static class Reduce extends Reducer<Text,Text,Text,Text> {

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
            initialPageRank = 1D / totalLinksCount;

            URI[] cacheFiles = context.getCacheFiles();
            Path pageMapFilePath = new Path(cacheFiles[0]);
            FileSystem fs = FileSystem.get(pageMapFilePath.toUri(), conf);
            FileStatus[] status = fs.listStatus(pageMapFilePath);
            String line;
            String[] parts;
            for (FileStatus stat : status) {
                Path path = stat.getPath();
                if (!path.toString().contains(".") && !path.toString().contains("_SUCCESS") && !path.toString().contains("crc")) {
                    BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(fs.open(path)));
                    while ((line = bufferedReader.readLine()) != null) {
                        parts = line.split("\t");
                        if (iterationCount == 1) prMap.put(parts[1], initialPageRank);
                        else prMap.put(parts[0], Double.parseDouble(parts[1]));
                    }
                    bufferedReader.close();
                }
            }

            Path danglingNodePath = new Path(cacheFiles[1]);
            fs = FileSystem.get(danglingNodePath.toUri(), conf);
            status = fs.listStatus(danglingNodePath);
            for (FileStatus stat : status) {
                Path path = stat.getPath();
                if (!path.toString().contains(".") && !path.toString().contains("_SUCCESS") && !path.toString().contains("crc")) {
                    BufferedReader br = new BufferedReader(new InputStreamReader(fs.open(path)));
                    while ((line = br.readLine()) != null) {
                        parts = line.split("\t");
                        if (!prMap.containsKey(parts[1])) danglingNodePageRank += prMap.get("-111111");
                        else danglingNodePageRank += prMap.get(parts[1]);
                    }
                    br.close();
                }
            }
            danglingNodePageRank /= totalLinksCount;
        }

        public void reduce(Text key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            Double pr = 0D;
            String[] tokens;
            for (Text value : values) {
                tokens = value.toString().split("\t");
                pr += prMap.getOrDefault(tokens[0], prMap.get("-111111")) * Double.parseDouble(tokens[1]);
            }
            pr = alpha/totalLinksCount + (1-alpha)*(pr + danglingNodePageRank);
            context.write(key, new Text(pr.toString()));
        }

        public void cleanup(Context context) throws IOException, InterruptedException{
            context.write(new Text("-111111"), new Text(String.valueOf((alpha/totalLinksCount) + (1-alpha)*danglingNodePageRank)));
        }
    }

    public static void main(String[] args, Long totalLinksCount) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");

        for (int i = 0; i < 10; i++) {
            Configuration conf = new Configuration();
            conf.set("iterationCount", String.valueOf(i+1));
            conf.set("totalLinksCount", totalLinksCount.toString());
            Job job = Job.getInstance(conf);
            job.setJarByClass(PageRankMatrixRow.class);
            job.setMapperClass(Map.class);
            job.setReducerClass(Reduce.class);
            job.setMapOutputKeyClass(Text.class);
            job.setMapOutputValueClass(Text.class);
            job.setOutputKeyClass(Text.class);
            job.setOutputValueClass(Text.class);
            job.addCacheFile(new Path(args[1] + i).toUri());
            job.addCacheFile(new Path(args[2]).toUri());
            FileInputFormat.setInputPaths(job, new Path(args[0]));
            Path outputPath = new Path(args[1] + (i + 1));
            FileOutputFormat.setOutputPath(job, outputPath);
            outputPath.getFileSystem(conf).delete(outputPath, true);
            job.waitForCompletion(true);
        }
    }
}
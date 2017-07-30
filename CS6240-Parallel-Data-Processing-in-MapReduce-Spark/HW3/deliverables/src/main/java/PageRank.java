import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.IOException;
import java.util.Arrays;

public class PageRank {

    enum danglingNode {
        PageRank
    }

    public static class Map extends Mapper<Object, Text, Text, Text>{

        private static int iterationCount = 0;
        private static double initialPageRank = 0D;
        private static double danglingNodePageRank = 0D;

        protected void setup(Context context) throws IOException, InterruptedException {
            Configuration conf = context.getConfiguration();
            iterationCount  = Integer.parseInt(conf.get("iterationCount"));
            danglingNodePageRank = Double.parseDouble(conf.get("danglingNodePageRank"));
            initialPageRank = 1D / Long.parseLong(conf.get("totalLinksCount"));

        }

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String line = value.toString();
            String[] tokens = line.split("\t");
            Double newPageRank;
            Double initPageRank = danglingNodePageRank;
            Integer initPageRankIndex = tokens.length - 1;
            Integer totalAdjLinksCount = tokens.length - 2;
            StringBuilder output_value = new StringBuilder();

            // All elements in a line are guaranteed to be tab separated from parser
            if (tokens[initPageRankIndex].equals("initPageRank"))
                /**
                 * Case 1: PageName OutlinkPageName initPageRank
                 * */
                initPageRank += initialPageRank;
            else
                /**
                 * Case 1: PageName PageRank
                 * Case 2: PageName 0 // which is a dangling node
                 * */
                initPageRank += Double.parseDouble(tokens[initPageRankIndex]);

            if (iterationCount == 10) {
                /** Last iteration only needs the dangling share to be added */
                context.write(new Text(tokens[0]), new Text(initPageRank.toString()));
            } else if (tokens.length > 2) {
                /**
                 * Case 1: Emit all nodes in adjacency list with newPageRank
                 * Case 2: Emit the node itself along with initialPageRank
                 * */
                newPageRank = initPageRank / totalAdjLinksCount;
                for (int index = 1; index < initPageRankIndex; index++) {
                    context.write(new Text(tokens[index]), new Text(newPageRank.toString()));
                    output_value.append(tokens[index]).append("\t");
                }
                context.write(new Text(tokens[0]), new Text(output_value.append(initPageRank).toString()));
            } else {
                /** Make sure all danging nodes goto one reducer to be able to compute the dangling sum avoiding leaks*/
                context.write(new Text("danglingNode"), new Text(tokens[0] + "\t" + initPageRank.toString()));
            }
        }
    }

    public static class Reduce extends Reducer<Text,Text,Text,NullWritable> {

        private static final double ALPHA = 0.15;
        private static int iterationCount = 0;
        private static long totalLinksCount = 0L;
        private static double constantDampingTerm = 0D;

        protected void setup(Context context) throws IOException, InterruptedException {
            Configuration conf = context.getConfiguration();
            iterationCount  = Integer.parseInt(conf.get("iterationCount"));
            totalLinksCount = Long.parseLong(conf.get("totalLinksCount"));
            constantDampingTerm = ALPHA / totalLinksCount;

        }

        public void reduce(Text key, Iterable<Text> values, Context context
        ) throws IOException, InterruptedException {
            String outlinks = "";
            String[] inputValues;
            Double finalPageRank = 0D;
            Double updatedPageRank = 0D;
            Double danglingPageRank = 0D;

            if (iterationCount == 10) {
                for (Text value : values) {
                    context.write(new Text(key + "\t" + value), NullWritable.get());
                }
            } else if (key.toString().equals("danglingNode")) {
                for (Text value : values) {
                    inputValues = value.toString().split("\t");
                    context.write(new Text(inputValues[0] + "\t" + "0"), NullWritable.get());
                    danglingPageRank += Double.parseDouble(inputValues[1]);
                }
                danglingPageRank /= totalLinksCount;
                context.getCounter(danglingNode.PageRank).increment((long)(danglingPageRank*Math.pow(10, 10)));
            } else {
                for (Text value : values) {
                    inputValues = value.toString().split("\t");
                    /**
                     * Input values here could be in two forms as follows:
                     * 1. 0.231241213 in which case we add it to running pageRank Sum
                     * 2. The old adjacency list along with old PageRank which needs to be updated with new one
                     */
                    if (inputValues.length == 1) {
                        updatedPageRank += Double.parseDouble(inputValues[0]);
                    } else {
                        // Extract adjacency list from the value string
                        outlinks = String.join("\t", Arrays.copyOf(inputValues, inputValues.length-1));
                    }
                }
                finalPageRank = constantDampingTerm + ((1 - ALPHA) * updatedPageRank);
                if (!key.toString().equals("") && !outlinks.equals(""))
                    context.write(new Text(key + "\t" + outlinks + "\t" + finalPageRank), NullWritable.get());
            }
        }
    }

    public static String main(String outPath, Long totalLinksCount) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");

        String finalOutPath = "";
        Double danglingNodePageRank = 0D;
        for (int i = 0; i < 10; i++) {
            Configuration conf = new Configuration();
            conf.set("iterationCount", String.valueOf(i+1));
            conf.set("totalLinksCount", totalLinksCount.toString());
            conf.set("danglingNodePageRank", Double.toString(danglingNodePageRank));
            Job job = Job.getInstance(conf);
            job.setJarByClass(PageRank.class);
            job.setMapperClass(Map.class);
            job.setReducerClass(Reduce.class);
            job.setMapOutputKeyClass(Text.class);
            job.setMapOutputValueClass(Text.class);
            job.setOutputKeyClass(Text.class);
            job.setOutputValueClass(NullWritable.class);
            FileInputFormat.setInputPaths(job, new Path(outPath + i));
            Path outputPath = new Path(outPath + (i + 1));
            FileOutputFormat.setOutputPath(job, outputPath);
            outputPath.getFileSystem(conf).delete(outputPath, true);
            job.waitForCompletion(true);
            danglingNodePageRank = (double)job.getCounters().findCounter(danglingNode.PageRank).getValue() / Math.pow(10, 10);
            if (i == 9)
                finalOutPath = outPath + (i+1);
        }
        return finalOutPath;
    }
}
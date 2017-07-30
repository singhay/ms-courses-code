import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.util.HashMap;

public class BuildMatrix {

    public static class Map extends Mapper<Object, Text, Text, Text>{

        private boolean rowMajor;
        private HashMap<String, String> idMap;

        protected void setup(Context context) throws IOException, InterruptedException {
            idMap = new HashMap<>();

            URI[] cacheFiles = context.getCacheFiles();
            Path sourceFilePath = new Path(cacheFiles[0]);
            Configuration conf = context.getConfiguration();
            rowMajor = conf.getBoolean("rowMajor", false);
            FileSystem fs = FileSystem.get(sourceFilePath.toUri(), conf);
            FileStatus[] status = fs.listStatus(sourceFilePath);
            for (int i=0;i<status.length;i++){
                Path path = status[i].getPath();
                if(!path.toString().contains(".") && ! path.toString().contains("_SUCCESS") && !path.toString().contains("crc")){
                    BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(fs.open(path)));
                    String line = null;
                    while((line = bufferedReader.readLine()) != null){
                        String[] parts = line.split("\t");
                        idMap.put(parts[0], parts[1]);
                    }
                    bufferedReader.close();
                }
            }
        }

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String[] tokens = value.toString().split("\t");
            int totalAdjLinksCount = tokens.length-1;
            if (rowMajor) {
                String colPR = idMap.get(tokens[0]) + "\t" + 1D / totalAdjLinksCount;
                for (int i = 1; i <= totalAdjLinksCount; i++) {
                    context.write(new Text(idMap.get(tokens[i])), new Text(colPR));
                }
            } else {
                Double shareCoeff = 1D / totalAdjLinksCount;
                for (int i = 1; i <= totalAdjLinksCount; i++) {
                    context.write(new Text(idMap.get(tokens[0])), new Text(idMap.get(tokens[i]) + "\t" + shareCoeff));
                }

            }
        }
    }

    public static void main(String[] args, boolean rowMajor) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");

        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        Path inPath = new Path(otherArgs[0]);
        Path outPath = new Path(otherArgs[1]);
        outPath.getFileSystem(conf).delete(outPath, true);

        conf.setBoolean("rowMajor", rowMajor);
        Job job = Job.getInstance(conf);
        job.addCacheFile(new Path(otherArgs[2]).toUri());
        job.setJarByClass(BuildMatrix.class);
        job.setMapperClass(Map.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        FileInputFormat.setInputPaths(job, inPath);
        FileOutputFormat.setOutputPath(job, outPath);
        job.waitForCompletion(true);

    }
}
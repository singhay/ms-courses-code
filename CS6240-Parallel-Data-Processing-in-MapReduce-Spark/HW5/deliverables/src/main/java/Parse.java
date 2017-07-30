/**
 * Created by Ayush Singh on 2/19/17.
 */

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
import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import java.io.IOException;
import java.io.StringReader;
import java.net.URLDecoder;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Parse {

    private static Pattern namePattern;
    private static Pattern linkPattern;

    static {
        // Keep only html pages not containing tilde (~).
        namePattern = Pattern.compile("^([^~]+)$");
        // Keep only html filename ending relative paths and not containing tilde (~).
        linkPattern = Pattern.compile("^\\..*/([^~]+)\\.html$");
    }

    /** Hadoop global counter for counting total number of valid nodes along with dangling ones */
    enum totalLinksCount { Valid }

    public static class Map extends Mapper<Object, Text, Text, Text> {

        private XMLReader xmlReader;

        public void setup(Context context){
            // Configure parser
            SAXParserFactory spf = SAXParserFactory.newInstance();
            try {
                spf.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
                SAXParser saxParser = spf.newSAXParser();
                xmlReader = saxParser.getXMLReader();
            } catch (ParserConfigurationException | SAXException e) {
                e.printStackTrace();
            }
        }

        public void map(Object key, Text value, Context context
        ) throws IOException, InterruptedException {
            String line = value.toString();
            List<String> linkPageNames = new LinkedList<>();
            // Each line formatted as (Wiki-page-name:Wiki-page-html).
            Integer delimLoc = line.indexOf(':');
            String pageName = line.substring(0, delimLoc);
            String html = line.substring(delimLoc + 1).replace("&", "&amp;");
            Matcher matcher = namePattern.matcher(pageName);
            Boolean skip = false;
            StringBuilder output = new StringBuilder();
            try {
                // Parser fills linkPageNames with linked page names.
                xmlReader.setContentHandler(new WikiParser(linkPageNames));

                if (!matcher.find()) {
                    // Skip this html file, name contains (~).
                    skip = true;
                }

                // Parse page and fill list of linked pages.
                try {
                    xmlReader.parse(new InputSource(new StringReader(html)));
                } catch (Exception e) {
                    // Discard ill-formatted pages.
                    linkPageNames.clear();
                    skip = true;
                }

            } catch (Exception e) {
                e.printStackTrace();
            }

            /**
             * Skip flag takes care of whether or not to discard the parsed value
             * Below conditional block does two main jobs as follows:
             * 1. Emit all nodes with "maybeDangling" from the list of Page Names for a page
             * 2. Emit the page itself initializing it with "initPageRank"
             */
            if (!skip) {
                output.append(pageName);
                for (String str : linkPageNames) {
                    output.append("\t").append(str);
                    context.write(new Text(str), new Text("maybeDangling"));

                }
                context.write(new Text(pageName), new Text(output.toString()));
            }
        }
    }

    public static class Combine extends Reducer<Text, Text, Text, Text> {

        public void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {

            int maybeDangling = 0;
            int valuesLen = 0;
            for (Text value : values) {
                if (!value.toString().equals("maybeDangling")) context.write(value, new Text("combiner"));
                else maybeDangling++;
                valuesLen++;
            }

            if (maybeDangling == valuesLen)
                context.write(key, new Text("combiner"));

        }
    }

    public static class Reduce extends Reducer<Text, Text, Text, NullWritable> {

        /**
         * Sample Graph: A -> B, C | B -> D | C
         * Following are the three cases that are handled based on sample graph above:
         * 1. A points to B which is a normal node
         * 2. A also points to C which is a dangling node
         * 2. B points to D but D is not present as a node in data i.e. dangling Node
         */
        public void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {

            int maybeDangling = 0;
            int valuesLen = 0;
            for (Text value : values) {
                // if (value.toString().equals("combiner")) context.write(key, NullWritable.get());
                if (!value.toString().equals("maybeDangling")) context.write(value, NullWritable.get());
                else maybeDangling++;
                valuesLen++;
            }
            /**
             When all values received for a key were flagged "maybeDangling"
             it tells us that there was no line present to be parsed for that element
             otherwise there would've been at least one value as "initialPageRank"
             */
            if (maybeDangling == valuesLen)
                context.write(key, NullWritable.get());

            context.getCounter(totalLinksCount.Valid).increment(1);
        }
    }

    /** Parses a Wikipage, finding links inside bodyContent div element. */
    private static class WikiParser extends DefaultHandler {
        /**
         * List of linked pages; filled by parser.
         */
        private List<String> linkPageNames;
        /**
         * Nesting depth inside bodyContent div element.
         */
        private int count = 0;

        public WikiParser(List<String> linkPageNames) {
            super();
            this.linkPageNames = linkPageNames;
        }

        @Override
        public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
            super.startElement(uri, localName, qName, attributes);
            if ("div".equalsIgnoreCase(qName) && "bodyContent".equalsIgnoreCase(attributes.getValue("id")) && count == 0) {
                // Beginning of bodyContent div element.
                count = 1;
            } else if (count > 0 && "a".equalsIgnoreCase(qName)) {
                // Anchor tag inside bodyContent div element.
                count++;
                String link = attributes.getValue("href");
                if (link == null) {
                    return;
                }
                try {
                    // Decode escaped characters in URL.
                    link = URLDecoder.decode(link, "UTF-8");
                } catch (Exception e) {
                    // Wiki-weirdness; use link as is.
                }
                // Keep only html filename ending relative paths and not containing tilde (~).
                Matcher matcher = linkPattern.matcher(link);
                if (matcher.find()) {
                    linkPageNames.add(matcher.group(1));
                }
            } else if (count > 0) {
                // Other element inside bodyContent div.
                count++;
            }
        }

        @Override
        public void endElement(String uri, String localName, String qName) throws SAXException {
            super.endElement(uri, localName, qName);
            if (count > 0) {
                // End of element inside bodyContent div.
                count--;
            }
        }
    }

    public static long parse(String[] args) throws Exception {
        System.setProperty("hadoop.home.dir", "/home/daniel/hadoop");
        Configuration conf = new Configuration();
        String[] otherArgs = new GenericOptionsParser(conf, args).getRemainingArgs();
        if (otherArgs.length != 2) {
            if (!args[0].endsWith(".bz2"))
                System.err.println("Input File does not exist or not bz2 file: " + args[0]);
            else
                System.err.println("Usage: WikiParser <in> <out>");
            System.exit(1);
        }
        Path inPath = new Path(otherArgs[0]);
        Path outPath = new Path(otherArgs[1]);
        outPath.getFileSystem(conf).delete(outPath, true);

        Job job = Job.getInstance(conf);
        job.setJarByClass(WikiParser.class);
        job.setMapperClass(Map.class);
        // job.setCombinerClass(Combine.class);
        job.setReducerClass(Reduce.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(NullWritable.class);

        FileInputFormat.setInputPaths(job, inPath);
        FileOutputFormat.setOutputPath(job, outPath);
        job.waitForCompletion(true);

        return job.getCounters().findCounter(totalLinksCount.Valid).getValue();
    }
}
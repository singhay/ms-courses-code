import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Partitioner;

/**
 * Created by Ayush Singh on 2/9/17.
 */
public class NaturalKeyPartitioner extends Partitioner<CompositeKey, Text> {

    @Override
    public int getPartition(CompositeKey compositeKey, Text value, int numPartitions) {
        return Math.abs(compositeKey.getStationId().hashCode() % numPartitions);
    }
}
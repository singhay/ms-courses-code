import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

/**
 * Created by Ayush Singh on 2/9/17.
 */
public class CompositeKeyComparator extends WritableComparator {

    protected CompositeKeyComparator() {
        super(CompositeKey.class, true);
    }

    @SuppressWarnings("rawtypes")
    @Override
    public int compare(WritableComparable w1, WritableComparable w2) {
        CompositeKey k1 = (CompositeKey) w1;
        CompositeKey k2 = (CompositeKey) w2;

        return k1.compareTo(k2);
    }
}

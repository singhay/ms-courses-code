import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableUtils;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

/**
 * Created by Ayush Singh on 2/8/17.
 */
public class CompositeKey implements WritableComparable<CompositeKey> {

    private String stationId;
    private Integer year;

    public CompositeKey() {}

    public CompositeKey(String stationId, Integer year) {
        this.stationId = stationId;
        this.year = year;
    }

    @Override
    public void write(DataOutput dataOutput) throws IOException {
        WritableUtils.writeString(dataOutput, stationId);
        dataOutput.writeInt(year);
    }

    @Override
    public void readFields(DataInput dataInput) throws IOException {
        stationId = WritableUtils.readString(dataInput);
        year = dataInput.readInt();
    }

    @Override
    public int compareTo(CompositeKey o) {
        int result = stationId.compareTo(o.getStationId());
        if (result == 0) {
            result = year.compareTo(o.getYear());
        }
        return result;
    }

    public String getStationId() {
        return stationId;
    }

    public Integer getYear() {
        return year;
    }

    public void setStationId(String stationId) {
        this.stationId = stationId;
    }

    public void setYear(Integer year) {
        this.year = year;
    }
}

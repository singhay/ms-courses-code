public class Main {

    public static void main(String[] args) throws Exception {
        if (args.length != 4) {
            System.err.println("Usage: PageRank <in> <out> <cache> <rowMajor?>");
            System.exit(1);
        }
        String distCacheDir = args[2];
        boolean rowMajor = Boolean.parseBoolean(args[3]);
        Long totalLinksCount = Parse.parse(new String[]{args[0], args[1]});
        MapPageID.main(new String[]{args[1], distCacheDir});
        BuildMatrix.main(new String[]{args[1], args[1]+"Matrix", distCacheDir+"/NonDangling0"}, rowMajor);
        if (rowMajor)
            PageRankMatrixRow.main(new String[]{args[1]+"Matrix", distCacheDir+"/NonDangling", distCacheDir+"/Dangling"}, totalLinksCount);
        else
            PageRankMatrixCol.main(new String[]{args[1]+"Matrix", distCacheDir+"/NonDangling", distCacheDir+"/Dangling"}, totalLinksCount);
        Sort.main(new String[]{distCacheDir+"/NonDangling10", args[1]+"Sorted", distCacheDir+"/NonDangling0"});
    }
}
public class Main {

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: PageRank <in> <out>");
            System.exit(1);
        }

        Long totalLinksCount = Parse.parse(new String[]{args[0], args[1]+"0"});
        String outPath = PageRank.main(args[1], totalLinksCount);
        Sort.main(new String[]{outPath, args[1]});
    }
}
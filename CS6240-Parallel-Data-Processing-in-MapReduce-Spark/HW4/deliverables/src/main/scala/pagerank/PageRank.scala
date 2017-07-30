package pagerank

import WikiParser.WikiParser
import org.apache.spark.{SparkConf, SparkContext}

object PageRank {

  def main(args: Array[String]) {
    if (args.length < 2) {
      System.err.println("Usage: PageRank <input_file> <output_file>")
      System.exit(1)
    }
    val sc = new SparkContext(new SparkConf().setAppName("PageRank"))
    val parsedInput = sc                                        // SparkContext
      .textFile(args(0))                                        // Local or AWS S3 file(s)
      .map(f => WikiParser.parse(f))                            // Return from WikiParser => PageName\tAdjacentNodes
    var missingGraph = parsedInput
      .map(line => line.split("\t"))                            // Split the output from WikiParser
      .map(f => (f(0), (f.slice(1,f.length), 0D)))              // (PageName, (AdjacentNodes, initialPageRank))
    val unintializedGraph = missingGraph
      .filter(_._2._1.length > 0)                               // Only consider the adjacency list
      .flatMap(f => f._2._1
      .map(m => (m, (new Array[String](0), 0D))))               // PageName X Y, but Y has no line in data
      .union(missingGraph)
      .reduceByKey((v1,v2) => if (v1._1.length > 0) v1 else v2 )
    val broadcastTotalLinksCount = sc.broadcast(unintializedGraph.count()) // Count total number of nodes
    var graph = unintializedGraph
      .map(f => (f._1, (f._2._1, 1D / broadcastTotalLinksCount.value)))
      .persist

    val danglingNodes = graph                                   // Filter dangling nodes i.e zero adjacent nodes
      .filter(_._2._1.length == 0)
      .persist
    val adjacentNodes = graph                                   // Calculates pagerank of individual nodes
      .filter(_._2._1.length > 0)                               // Weed out dangling nodes
      .persist
    for (i <- 1 to 10) {
      val danglingNodePageRankShare = danglingNodes             // Calculate the loss incurred by dangling nodes
        .map(_._2._2)                                           // Only keep pagerank
        .reduce((x,y) => x+y) / broadcastTotalLinksCount.value  // Sum pagerank of all dangling nodes
      val danglingNodesUnique = danglingNodes                   // Gather dangling nodes for next iteration
        .map(f => (f._1, (f._2._1, danglingNodePageRankShare))) // This takes on updates dangling node loss
      val adjacentNodesPageRank = adjacentNodes
        .flatMap(f => f._2._1.map(m => (m, f._2._2 / f._2._1.length))) // (PageName, PageRank); pagerank = oldPR/numAdj
        .reduceByKey(_+_)                                       // For each PageName, sum all its pageranks
        .mapValues(v => 0.15/broadcastTotalLinksCount.value +   // PageRank formula adjusted for dangling node loss
                        (0.85*(v + danglingNodePageRankShare)))
      graph = adjacentNodes                                     // Combine all nodes for next iteration
        .map(f => (f._1, f._2._1))                              // Only consider the adjacency list (PageName, AdjacentNodes)
        .join(adjacentNodesPageRank)                            // (PageName, (AdjacentNodes, updatedPageRank))
        .union(danglingNodesUnique)                             // Combine dangling with normal nodes
    }

    val top = sc.parallelize(graph
      .sortBy(-_._2._2)                                         // Sort by taking pagerank as key in descending order
      .take(100)                                                // Only take the top 100 elements
      .map(f => f._1 + "\t" + f._2._2),1)                       // Custom print format from tuple format i.e. (x,y)
    top.saveAsTextFile(args(1))                     // Save to local filesystem or AWS S3 output dir

    sc.stop()
  }
}
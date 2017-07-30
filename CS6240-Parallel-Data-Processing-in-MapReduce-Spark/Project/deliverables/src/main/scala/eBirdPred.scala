
/**
██████╗███████╗     ██████╗ ██████╗ ██╗  ██╗ ██████╗
██╔════╝██╔════╝    ██╔════╝ ╚════██╗██║  ██║██╔═████╗
██║     ███████╗    ███████╗  █████╔╝███████║██║██╔██║
██║     ╚════██║    ██╔═══██╗██╔═══╝ ╚════██║████╔╝██║
╚██████╗███████║    ╚██████╔╝███████╗     ██║╚██████╔╝
 ╚═════╝╚══════╝     ╚═════╝ ╚══════╝     ╚═╝ ╚═════╝
  eBird Dataset Project
  Goal: Predict bird sightings using eBird Dataset (1.8M x 1653)
  Team: Ayush Singh & Gautam Vashist
  CS 6240 Big Data Processing with MapReduce, Spring 2017
  Prof: Mirek Riedewald
  */

import org.apache.spark.ml.classification.{RandomForestClassificationModel, RandomForestClassifier}
import org.apache.spark.ml.evaluation.MulticlassClassificationEvaluator
import org.apache.spark.sql.{Column, DataFrameNaFunctions, SparkSession}
import org.apache.spark.{SparkConf, SparkContext}
import org.apache.spark.sql.functions._
import org.apache.spark.ml.feature.{IndexToString, StringIndexer, VectorAssembler, VectorIndexer}
import org.apache.spark.sql.types._


object eBirdPred {
  def main(args : Array[String]): Unit = {

    val conf = new SparkConf().setAppName("eBird")
    //val conf = new SparkConf().setAppName("eBird").setMaster("local[*]")
    val sc = new SparkContext(conf)
    val spark = SparkSession.builder().appName("eBird").config("conf", value = true).getOrCreate()

    val bz2df = spark.read.format("csv")
      .option("header", "true")
      .option("mode", "DROPMALFORMED")
      .option("inferschema", "true")
      .csv(args(0))
    val colsToRemove = Seq("COUNTRY", "YEAR", "SAMPLING_EVENT_ID0", "SAMPLING_EVENT_ID953",
      "LOC_ID954", "SAMPLING_EVENT_ID1016", "LOC_ID1017")
    println("LOADING TRAINING FILE")
    val nadf = bz2df.select(bz2df.columns
      .filter(colName => !colsToRemove.contains(colName))
      .filter(!_.startsWith("NLCD"))
      .filter(!_.startsWith("CAUS"))
      .map(colName => new Column(colName)): _*)


    //----------------------------------------------------------------------------------------------------------------------
    //  Handle Missing Values
    //----------------------------------------------------------------------------------------------------------------------

    println("STARTING NA VALUE HANDLING")

    val sdf =  nadf.withColumnRenamed("Agelaius_phoeniceus", "label")
      .withColumn("label", col("label") cast DoubleType)
      .withColumn("GROUP_ID", when(col("GROUP_ID") === "?" || nadf.col("GROUP_ID").isNull , "G0000")
        .otherwise(col("GROUP_ID")))
      .withColumn("PRIMARY_CHECKLIST_FLAG", when(col("PRIMARY_CHECKLIST_FLAG") === "?", -1 )
        .otherwise(col("PRIMARY_CHECKLIST_FLAG")))
      .na.drop(Array("label"))
      .na.replace(nadf.columns, Map("?" -> "-1.0", "X" -> "1.0", "null" -> "-1.0"))
      .withColumn("EFFORT_DISTANCE_KM",when(col("EFFORT_DISTANCE_KM") < 0, col("EFFORT_DISTANCE_KM") * -1)
        .otherwise(col("EFFORT_DISTANCE_KM")))


    //----------------------------------------------------------------------------------------------------------------------
    //  Feature Engineering
    //----------------------------------------------------------------------------------------------------------------------
    /**
      * Use google api to fill in missing county, state_province and add zip_code
      *
      * Use month, day, time fields to fill in NLCD, SNOW, and PREC values
      */
    val df = sdf.withColumn("label", when(col("label") > 1, 1.0).otherwise(0.0))
      .withColumn("COUNT_TYPE_P34", when(sdf.col("count_type") === "P34", 1.0).otherwise(0.0))


    //----------------------------------------------------------------------------------------------------------------------
    //  Data Prep for Random Forest Classifier
    //----------------------------------------------------------------------------------------------------------------------

    println("STARTING DATA PREP")

    val SPindexer = new StringIndexer().setInputCol("STATE_PROVINCE").setOutputCol(s"${"STATE_PROVINCE"}_index").fit(df).transform(df)
    val CTYindexer = new StringIndexer().setInputCol("COUNTY").setOutputCol(s"${"COUNTY"}_index").fit(SPindexer).transform(SPindexer)
    val CTindexer = new StringIndexer().setInputCol("COUNT_TYPE").setOutputCol(s"${"COUNT_TYPE"}_index").fit(CTYindexer).transform(CTYindexer)
    val OBSindexer = new StringIndexer().setInputCol("OBSERVER_ID").setOutputCol(s"${"OBSERVER_ID"}_index").fit(CTindexer).transform(CTindexer)
    val GIDindexed = new StringIndexer().setInputCol("GROUP_ID").setOutputCol(s"${"GROUP_ID"}_index").fit(OBSindexer).transform(OBSindexer)
    val BEindexed = new StringIndexer().setInputCol("BAILEY_ECOREGION").setOutputCol(s"${"BAILEY_ECOREGION"}_index").fit(GIDindexed).transform(GIDindexed)
    val OLEindexed = new StringIndexer().setInputCol("OMERNIK_L3_ECOREGION").setOutputCol(s"${"OMERNIK_L3_ECOREGION"}_index").fit(BEindexed).transform(BEindexed)
    val SBindexed = new StringIndexer().setInputCol("SUBNATIONAL2_CODE").setOutputCol(s"${"SUBNATIONAL2_CODE"}_index").fit(OLEindexed).transform(OLEindexed)
    val indexeddf = new StringIndexer().setInputCol("LOC_ID1").setOutputCol(s"${"LOC_ID1"}_index").fit(SBindexed).transform(SBindexed)

    val colsNotIndexed = Seq("LOC_ID1", "STATE_PROVINCE","COUNTY","COUNT_TYPE","OBSERVER_ID","GROUP_ID", "OMERNIK_L3_ECOREGION", "BAILEY_ECOREGION","SUBNATIONAL2_CODE")
    val indexed = indexeddf.select(indexeddf.columns
      .filter(cname => !colsNotIndexed.contains(cname))
      .map(cname => col(cname).cast(DoubleType)): _*)


    val assembler = new VectorAssembler()
      .setInputCols(indexed.columns.filter(!_.equals("label")))
      .setOutputCol("features")

    val output = assembler.transform(indexed)


    val training = output.select(col("label"), col("features"))

    println("STARTING RFC")
    // Train a RandomForest model.
    val rfc = new RandomForestClassifier()
      .setLabelCol("label")
      .setFeaturesCol("features")
      .setNumTrees(50)
      .setMaxDepth(20)
      .setMaxBins(distinct_col_counts)

    val model = rfc.fit(training)

    //----------------------------------------------------------------------------------------------------------------------
    //  TEST FILE Processing
    //----------------------------------------------------------------------------------------------------------------------
    println("LOADING TEST FILE")
    val tbz2df = spark.read.format("csv")
      .option("header", "true")
      .option("mode", "DROPMALFORMED")
      .option("inferschema", "true")
      .csv(args(1))

    val testColsToRemove = Seq("COUNTRY", "YEAR", "SAMPLING_EVENT_ID953", "LOC_ID954", "SAMPLING_EVENT_ID1016", "LOC_ID1017")
    println("PRE PROCESSING STARTS")

    val tnadf = tbz2df.select(tbz2df.columns
      .filter(colName => !testColsToRemove.contains(colName))
      .filter(!_.startsWith("NLCD"))
      .filter(!_.startsWith("CAUS"))
      .map(colName => new Column(colName)): _*)


    //----------------------------------------------------------------------------------------------------------------------
    //  Handle Missing Values
    //----------------------------------------------------------------------------------------------------------------------

    val tsdf =  tnadf.withColumnRenamed("Agelaius_phoeniceus", "label")
      .withColumn("label", col("label") cast DoubleType)
      .withColumn("PRIMARY_CHECKLIST_FLAG", when(col("PRIMARY_CHECKLIST_FLAG") === "?", -1 )
        .otherwise(col("PRIMARY_CHECKLIST_FLAG")))
     // .na.drop(Array("label"))
      .na.replace(tnadf.columns.filter(!_.equals("label")), Map("?" -> "-1.0", "X" -> "1.0", "null" -> "-1.0"))
      .withColumn("EFFORT_DISTANCE_KM",when(col("EFFORT_DISTANCE_KM") < 0, col("EFFORT_DISTANCE_KM") * -1)
        .otherwise(col("EFFORT_DISTANCE_KM")))
    //    sdf.show


    //----------------------------------------------------------------------------------------------------------------------
    //  Feature Engineering
    //----------------------------------------------------------------------------------------------------------------------
    /**
      * Use google api to fill in missing county, state_province and add zip_code
      * Use month, day, time fields to fill in NLCD, SNOW, and PREC values
      */
    val tdf = tsdf.withColumn("label", when(col("label") > 1, 1.0).otherwise(0))
      .withColumn("COUNT_TYPE_P34", when(tsdf.col("count_type") === "P34", 1.0).otherwise(0.0))
    //    df.show()

    // Since I do not know my max categories possible, I find it out and use it for maxBins parameter in RF
    val distinct_col_counts=df.columns.map(x => df.select(x).distinct().count).max

    //----------------------------------------------------------------------------------------------------------------------
    //  Data Prep for Random Forest Classifier
    //----------------------------------------------------------------------------------------------------------------------

    println("STARTING TEST DATA PREP")

    val tSPindexer = new StringIndexer().setInputCol("STATE_PROVINCE").setOutputCol(s"${"STATE_PROVINCE"}_index").fit(tdf).transform(tdf)
    val tCTYindexer = new StringIndexer().setInputCol("COUNTY").setOutputCol(s"${"COUNTY"}_index").fit(tSPindexer).transform(tSPindexer)
    val tCTindexer = new StringIndexer().setInputCol("COUNT_TYPE").setOutputCol(s"${"COUNT_TYPE"}_index").fit(CTYindexer).transform(tCTYindexer)
    val tOBSindexer = new StringIndexer().setInputCol("OBSERVER_ID").setOutputCol(s"${"OBSERVER_ID"}_index").fit(tCTindexer).transform(tCTindexer)
    val tGIDindexed = new StringIndexer().setInputCol("GROUP_ID").setOutputCol(s"${"GROUP_ID"}_index").fit(tOBSindexer).transform(tOBSindexer)
    val tBEindexed = new StringIndexer().setInputCol("BAILEY_ECOREGION").setOutputCol(s"${"BAILEY_ECOREGION"}_index").fit(tGIDindexed).transform(tGIDindexed)
    val tOLEindexed = new StringIndexer().setInputCol("OMERNIK_L3_ECOREGION").setOutputCol(s"${"OMERNIK_L3_ECOREGION"}_index").fit(tBEindexed).transform(tBEindexed)
    val tSBindexed = new StringIndexer().setInputCol("SUBNATIONAL2_CODE").setOutputCol(s"${"SUBNATIONAL2_CODE"}_index").fit(tOLEindexed).transform(tOLEindexed)
    val tindexeddf = new StringIndexer().setInputCol("LOC_ID1").setOutputCol(s"${"LOC_ID1"}_index").fit(tSBindexed).transform(tSBindexed)




    var tindexed = tindexeddf.select(tindexeddf.columns
      .filter(cname => !colsNotIndexed.contains(cname))
     .map{
      case c if c.equals("SAMPLING_EVENT_ID0") => col(c).cast(StringType)
      case c if !c.equals("SAMPLING_EVENT_ID0") => col(c).cast(DoubleType)
    }: _*)


    val tassembler = new VectorAssembler()
      .setInputCols(tindexed.columns.filter(!_.equals("label")).filter(!_.equals("SAMPLING_EVENT_ID0")))
      .setOutputCol("features")

    val toutput = tassembler.transform(tindexed)
    toutput.show
    val test = toutput.select(col("SAMPLING_EVENT_ID0"), col("label"), col("features"))

    println("STARTING TEST PREDICTION")
    // Make predictions.
    val predictions = model.transform(test)

    // Select example rows to display.
    predictions.select("SAMPLING_EVENT_ID0", "prediction").toJavaRDD.coalesce(1).saveAsTextFile(args(2))

    // Select (prediction, true label) and compute test error
    val evaluator = new MulticlassClassificationEvaluator()
      .setLabelCol("label")
      .setPredictionCol("prediction")
      .setMetricName("accuracy")
    val accuracy = evaluator.evaluate(predictions)

    sc.stop()

  }
}

/** TODO:
  * 2. Have to ignore sample_event_id but still keep for final result
  * 3. X: Present-without-count, if at same location same species is found, then put that count here else ?????????
  * 4. count_type: Stationary (P21), traveling (P22, P34), area (P23, P35), casual (P20), or random (P48). Protocol P34 is a small amount of data contributed from the Rocky Mountain Bird Observatory that we believe is high quality. Protocol P35 data are back-yard area counts made on consecutive days
  * 5. caus_snow: no data available on snow depth from the climate atlas for these months.
  * 6. Locations that fall outside of all polygons are assigned nodata values that are later converted into missing values (represented as ? in the dataset)
  * 7. Some US States have no county, so pick from some API if possible
  *
  */

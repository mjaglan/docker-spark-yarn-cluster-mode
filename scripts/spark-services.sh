#!/bin/bash

echo "HADOOP SERVICES"
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

echo "RUN jps - Java Virtual Machine Process Status Tool"
jps -lm

echo "Get basic filesystem information and statistics."
hdfs dfsadmin -report

echo "SPARK SERVICES"
$SPARK_HOME/sbin/start-all.sh
scala -version

echo "RUN jps - Java Virtual Machine Process Status Tool"
jps -lm

set -e
echo "SPARK TEST"
$SPARK_HOME/bin/spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --deploy-mode cluster \
    --num-executors 1 \
    --driver-memory 512m \
    --executor-memory 512m \
    --executor-cores 1 \
    $SPARK_HOME/examples/jars/spark-examples*.jar 100
set +e


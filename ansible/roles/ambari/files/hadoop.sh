
# Set the current HDP Version
#export HDP_VERSION=`hdp-select status hadoop-client | awk '{print $3}'`

export HADOOP_HOME_WARN_SUPPRESS=1

HDP=/usr/hdp/current
export LD_LIBRARY_PATH=${HDP}/hadoop/lib/native
export HADOOP_HOME=${HDP}/hadoop-client/
export HADOOP_COMMON_HOME=${HDP}/hadoop-client/
export HADOOP_HDFS_HOME=${HDP}/hadoop-hdfs-client/
export HADOOP_MAPRED_HOME=${HDP}/hadoop-mapreduce-client/
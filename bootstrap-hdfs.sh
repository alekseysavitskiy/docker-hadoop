#!/bin/sh
# Bootstraps default HDFS directories read from hdfs-paths file
# (Should be run once).

# expects: HADOOP_HOME

start() {
    echo "Setting up hdfs path: ${1}..."
}

end(){
    echo "Finished setting up hdfs path: ${1}..."
}

create_hdfs_path() #signature path, user, perms, group 
{
    local path="${1}" user="${2:-$HADOOP_HDFS_USER}" perms="${3}" group="${4:-hadoop}"

    start "${path}"
    su -p -c "${HADOOP_HOME}/bin/hdfs dfs -mkdir -p ${path}" $HADOOP_HDFS_USER

    # Set user and group if given
    [ -z "${user}"  ] || 
        su -p -c "${HADOOP_HOME}/bin/hdfs dfs -chown ${user}:${group} ${path}" $HADOOP_HDFS_USER

    # Set perms if given
    [  -z "$perms" ] ||
        su -p -c "${HADOOP_HOME}/bin/hdfs dfs -chmod ${perms} ${path}" $HADOOP_HDFS_USER

    end "${path}"
}

## Check namenode address
#
: ${HADOOP_NAMENODE_ADDRESS:?Must be provided\!}

# Configure hadoop from template (confd)
#
confd -onetime -backend env

su -p -c "${HADOOP_HOME}/bin/hdfs dfs -test -f /.bootstrapped" $HADOOP_HDFS_USER
retVal=$?
if [ $retVal -ne 0 ]; then
    cat ${HADOOP_CONF_DIR}/hdfs-bootstrap-paths | grep -Ev "\s*#" | while read path user perms group; do
       create_hdfs_path $path $user $perms $group
    done
    su -p -c "${HADOOP_HOME}/bin/hdfs dfs -touchz /.bootstrapped" $HADOOP_HDFS_USER
fi
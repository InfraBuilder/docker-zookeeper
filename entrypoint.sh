#!/bin/bash

ZKDIR="/opt/zookeeper"
CFG="$ZKDIR/conf/zoo.cfg"

function zooCfg {
	config="$1=$2"
	grep "^$1" $CFG > /dev/null && sed -i 's;'$1'=.*$;'$config';' $CFG || echo "$config" >> $CFG 
}

function rancherGet {
	curl http://169.254.169.250/latest/$1
}

[ "$DATADIR" = "" ] && DATADIR=/data

mkdir -p $DATADIR
#sed -i 's:dataDir=.*$:dataDir='$DATADIR':g' $CFG
zooCfg dataDir "$DATADIR"

case $1 in
	standalone)
		exec /opt/zookeeper/bin/zkServer.sh start-foreground
		;;
	rancher-cluster)
		ZKMYDID=$(rancherGet self/container/service_index)
		[ "$ZKMYID" = "" ] && echo "Cannot find service index" && exit 1
		echo $ZKMYID > $DATADIR/myid

		NAME=$(rancherGet self/container/name| sed 's/-[0-9]*$/-/')
		echo "my name is $NAME and is $ZKMYID"
		;;

	*)
		exec $@
		;;
esac

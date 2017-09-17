#!/bin/bash

ZKDIR="/opt/zookeeper"
CFG="$ZKDIR/conf/zoo.cfg"

function zooCfg {
	config="$1=$2"
	echo "New config : $config"
	grep "^$1" $CFG > /dev/null \
		&& sed -i 's;'$1'=.*$;'$config';' $CFG \
		|| echo "$config" >> $CFG 
}

function rancherGet {
	curl -s http://169.254.169.250/latest/$1
}

[ "$DATADIR" = "" ] && DATADIR=/data
[ "$ZKNODES" = "" ] && ZKNODES=3
[ "$ZK_INIT_LIMIT" = "" ] && ZK_INIT_LIMIT=5
[ "$ZK_SYNC_LIMIT" = "" ] && ZK_SYNC_LIMIT=3

mkdir -p $DATADIR
zooCfg dataDir "$DATADIR"
zooCfg initLimit $ZK_INIT_LIMIT
zooCfg syncLimit $ZK_SYNC_LIMIT

case $1 in
	standalone)
		exec /opt/zookeeper/bin/zkServer.sh start-foreground
		;;
	rancher-cluster)
		ZKMYID=$(rancherGet self/container/service_index)
		[ "$ZKMYID" = "" ] && echo "Cannot find service index" && exit 1
		echo $ZKMYID > $DATADIR/myid

		NAME=$(rancherGet self/container/name| sed 's/-[0-9]*$/-/')
		echo "my name is $NAME and is $ZKMYID"
		
		for i in $(seq 1 $ZKNODES)
		do
			zooCfg server.$i $NAME$i:2888:3888
		done
		
		exec /opt/zookeeper/bin/zkServer.sh start-foreground
		;;
	cli)
		OPT=""
	
		if [ "$2" != "" ] 
		then
			SERVER="$2"
			PORT="$3"
			[ "$PORT" = "" ] && PORT="2181"
			OPT="-server $SERVER:$PORT"
		fi
		
		exec /opt/zookeeper/bin/zkCli.sh $OPT
		;;
	*)
		exec $@
		;;
esac

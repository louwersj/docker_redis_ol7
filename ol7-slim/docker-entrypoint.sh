#!/bin/bash


# Make sure we get the right argument which are used to start
# the container as intended. We have the following arguments:
#
# -r 
# is for stating the role, correct roles are master, slave
# or sentinel.
#
# -s 
# is used for providing the subnet used for finding the right
# announce ip. This is required when running in the sentinel 
# role. 
#
# -p 
# is used for providing the port used as the announce port. this
# will be needed when running as the sentinel role. 
 
while getopts r:s:p: o
do	case "$o" in
       	r)	SERVERROLE="$OPTARG";;
        s)      SERVERSUBNET="$OPTARG";;
        p)      SERVERPORT="$OPTARG";;
	[?])	echo "help Usage: $0 [-r role] [-s announce subnet] [-p announce port] ..."
		exit 1;;
	esac
done



# based upon the server role we will take the needed actions. 
# the roles that are applicable are master, slave or sentinel.
# When we run the container in a sentinel role we will also
# need the -s and -p arguments to ensure sentinel will be 
# working on the right network. As this can be a internal
# Docker overlay network where the IP will be assigned we will
# not be able to provide the IP as we do not know it when 
# whe initiate the container.
# 
# For the slave role we will need to ensure that we set the
# slave-priority to 0 to ensure the slave can never become
# a master. Redis instances have a configuration parameter 
# called slave-priority. This information is exposed by Redis 
# slave instances in their INFO output, and Sentinel uses it 
# in order to pick a slave among the ones that can be used in 
# order to failover a master:
# - If the slave priority is set to 0, the slave is never 
#   promoted to master.
# - Slaves with a lower priority number are preferred by Sentinel.
#

if [ "$SERVERROLE" = "master" ]; then
   echo "starting the container as a Redis master node"
   redis-server

elif [ "$SERVERROLE" = "slave" ]; then
   echo " starting the container as a Redis slave node"

elif [ "$SERVERROLE" = "sentinel" ]; then
   echo "starting the node as a sentinel node"
   redis-sentinel
else
   echo "STARTING : missing -r for role (master/slave/senitnel). Assuming slave."
   exec redis-server
fi

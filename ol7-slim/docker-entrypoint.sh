#!/bin/bash

# ----------------------------------------------------------------
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
# ----------------------------------------------------------------



# ----------------------------------------------------------------
# Get a number of generic variables needed througout the routine 
# of starting the services

# read the somaxconn setting into a variable so we can use it to
# force it to Redis as a startup variable as tcp-backlog parameter.
# the setting will be given to the Redis start command. Do note,
# the limiting factor is the Docker host and not the container. 
SETSOMAXCONN=`cat /proc/sys/net/core/somaxconn`

# the SETHUGEPAGE is used to influence the setting if hugepages are
# allowed to be used. Currently Redis has an issue with hugepages so
# we set it to never to ensure it will never be used. We have to ensure 
# Transparent Huge Pages (THP) support disabeld in the kernel. THP 
# will create latency and memory usage issues with Redis. If started 
# with this Redis will give a warning at startup. 
SETHUGEPAGE=never

# the SETMEMOVERCOMMIT is used to influence the vm.overcommit_memory.
# When overcommit_memory is set to 0, background save may fail under 
# low memory condition. advised is to set it to 1 
SETMEMOVERCOMMIT=1

# ----------------------------------------------------------------



# ----------------------------------------------------------------
# Take a number of generic actions needed to ensure that 
# Redis (regardless of the role) will perform in a way that
# is acceptable for production like systems.

# ensure huge pages are set correct
 echo $SETHUGEPAGE > /sys/kernel/mm/transparent_hugepage/enabled
 
# ensure memory overcommit is set correct
 sysctl vm.overcommit_memory=$SETMEMOVERCOMMIT
# ----------------------------------------------------------------



# ----------------------------------------------------------------
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
   redis-server --tcp-backlog $SOMAXCONN --slave-priority 10

elif [ "$SERVERROLE" = "slave" ]; then
   echo " starting the container as a Redis slave node"
   redis-server --tcp-backlog $SOMAXCONN --slave-priority 0
   
elif [ "$SERVERROLE" = "sentinel" ]; then
   echo "starting the node as a sentinel node"
   redis-sentinel
else
   echo "STARTING : missing -r for role (master/slave/sentinel). Assuming slave."
   exec redis-server --tcp-backlog $SOMAXCONN
fi
# ----------------------------------------------------------------

#!/bin/bash

# Example script to run the sender
# Usage: ./run_sender.sh [local_port] [remote_ip] [remote_port] [file] [mtu] [window_size]

LOCAL_PORT=${1:-5001}
REMOTE_IP=${2:-127.0.0.1}
REMOTE_PORT=${3:-5000}
FILE=${4:-test_file.txt}
MTU=${5:-1500}
WINDOW_SIZE=${6:-64}

echo "Starting sender on port $LOCAL_PORT"
echo "Remote: $REMOTE_IP:$REMOTE_PORT"
echo "File: $FILE"
echo "MTU: $MTU bytes"
echo "Window size: $WINDOW_SIZE packets"
echo "-------------------------------------------"

java -cp ../bin TCPend -p $LOCAL_PORT -s $REMOTE_IP -a $REMOTE_PORT -f $FILE -m $MTU -c $WINDOW_SIZE

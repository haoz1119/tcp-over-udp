#!/bin/bash

# Example script to run the receiver
# Usage: ./run_receiver.sh [port] [output_file] [mtu] [window_size]

PORT=${1:-5000}
OUTPUT_FILE=${2:-received_file.txt}
MTU=${3:-1500}
WINDOW_SIZE=${4:-64}

echo "Starting receiver on port $PORT"
echo "Output file: $OUTPUT_FILE"
echo "MTU: $MTU bytes"
echo "Window size: $WINDOW_SIZE packets"
echo "-------------------------------------------"

java -cp ../bin TCPend -p $PORT -f $OUTPUT_FILE -m $MTU -c $WINDOW_SIZE

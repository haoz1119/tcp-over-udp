#!/bin/bash

# Demo script showing file transfer between sender and receiver
# This creates a test file, starts receiver in background, then sends the file

echo "=== Reliable Transport Protocol Demo ==="
echo ""

# Create a test file
TEST_FILE="demo_test.txt"
echo "Creating test file: $TEST_FILE"
dd if=/dev/urandom of=$TEST_FILE bs=1024 count=100 2>/dev/null
echo "Test file size: $(wc -c < $TEST_FILE) bytes"
echo ""

# Start receiver in background
echo "Starting receiver..."
java -cp ../bin TCPend -p 5000 -f received_demo.txt -m 1500 -c 64 &
RECEIVER_PID=$!
sleep 1

# Start sender
echo "Starting sender..."
echo ""
java -cp ../bin TCPend -p 5001 -s 127.0.0.1 -a 5000 -f $TEST_FILE -m 1500 -c 64

# Wait for receiver to finish
wait $RECEIVER_PID

echo ""
echo "=== Transfer Complete ==="
echo "Original file size: $(wc -c < $TEST_FILE) bytes"
echo "Received file size: $(wc -c < received_demo.txt) bytes"

# Verify files match
if diff $TEST_FILE received_demo.txt > /dev/null; then
    echo "✓ Files match - transfer successful!"
else
    echo "✗ Files differ - transfer failed!"
fi

# Cleanup
rm $TEST_FILE received_demo.txt

# Quick Start Guide

Get up and running with the Reliable Transport Protocol in 5 minutes.

## Prerequisites

- Java 8 or higher
- Make (optional, but recommended)

## Quick Installation

```bash
# Clone the repository
git clone https://github.com/haozhou1919/reliable-transport-protocol.git
cd reliable-transport-protocol

# Build the project
make build
```

## Run Your First Transfer

### Option 1: Using Make (Easiest)

**Terminal 1 - Start Receiver:**
```bash
make receiver
```

**Terminal 2 - Start Sender:**
```bash
make sender
```

### Option 2: Using Shell Scripts

**Terminal 1 - Start Receiver:**
```bash
cd examples
./run_receiver.sh
```

**Terminal 2 - Start Sender:**
```bash
cd examples
# Create a test file first
echo "Hello, World!" > test_file.txt
./run_sender.sh 5001 127.0.0.1 5000 test_file.txt
```

### Option 3: Run Demo Script

```bash
cd examples
./demo.sh
```

This automatically runs both sender and receiver, transfers a file, and verifies the transfer.

## Manual Usage

### Start Receiver
```bash
java -cp bin TCPend -p 5000 -f output.txt -m 1500 -c 64
```

### Start Sender
```bash
java -cp bin TCPend -p 5001 -s 127.0.0.1 -a 5000 -f input.txt -m 1500 -c 64
```

## Command-Line Arguments

| Flag | Description | Required | Example |
|------|-------------|----------|---------|
| `-p` | Local port number | Yes | `5000` |
| `-s` | Remote IP address | Sender only | `192.168.1.100` |
| `-a` | Remote port number | Sender only | `5000` |
| `-f` | Filename (input for sender, output for receiver) | Yes | `file.txt` |
| `-m` | MTU in bytes | Yes | `1500` |
| `-c` | Window size (packets) | Yes | `64` |

## Example Output

When running, you'll see output like:
```
snd 0.000 S - - - 0 0 0
rcv 0.002 S - A - 0 0 1
snd 0.003 - - A - 1 0 1
snd 0.005 - - A D 1 1024 1
rcv 0.007 - - A - 0 0 1025
...
-------------------------------------------
Amount of Data transferred: 102400
Number of packets sent/received: 150/145
Number of out of sequence packets: 5
Number of packets discarded due to incorrect checksum: 0
Number of packets retransmitted: 3
Number of duplicate ACKs: 9
-------------------------------------------
```

## Understanding the Output

### Packet Log Format
```
<direction> <time> <flags> <seq> <length> <ack>
```

- **direction**: `snd` (sent) or `rcv` (received)
- **time**: Seconds since start
- **flags**: `S` (SYN), `F` (FIN), `A` (ACK), `D` (Data)
- **seq**: Sequence number
- **length**: Data length in bytes
- **ack**: Acknowledgment number

## Testing Over Network

To test between two different machines:

**Machine 1 (Receiver - IP: 192.168.1.100):**
```bash
java -cp bin TCPend -p 5000 -f received_file.txt -m 1500 -c 64
```

**Machine 2 (Sender):**
```bash
java -cp bin TCPend -p 5001 -s 192.168.1.100 -a 5000 -f myfile.txt -m 1500 -c 64
```

## Performance Tuning

### For High-Speed Networks
```bash
# Increase window size and MTU
-m 9000 -c 128
```

### For Lossy Networks
```bash
# Decrease window size for better reliability
-c 32
```

### For Low-Latency Networks
```bash
# Smaller MTU, larger window
-m 576 -c 256
```

## Troubleshooting

### Port Already in Use
```
Error: Address already in use
```
**Solution**: Use a different port number with `-p`

### Connection Timeout
```
Error: max retransmissions reached
```
**Solution**:
- Check firewall settings
- Verify IP address and port
- Check network connectivity

### File Not Found
```
FileNotFoundException
```
**Solution**: Ensure file path is correct and file exists

## Next Steps

- Read [README.md](README.md) for detailed documentation
- Check [docs/PROTOCOL.md](docs/PROTOCOL.md) for protocol specification
- See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for system design

## Clean Up

```bash
# Remove compiled files
make clean

# Remove all generated files
make distclean
```

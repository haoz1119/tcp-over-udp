# Reliable Transport Protocol Implementation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Java](https://img.shields.io/badge/Java-8+-orange.svg)](https://www.java.com)
[![Protocol](https://img.shields.io/badge/Protocol-TCP%20over%20UDP-blue.svg)]()
![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)

A fully-featured TCP-like reliable transport protocol implementation in Java, built from scratch over UDP. This project demonstrates low-level network programming, protocol design, and concurrent systems implementation.

## Overview

This project implements a complete reliable transport layer protocol with features equivalent to TCP, including connection management, flow control, congestion avoidance, and error recovery mechanisms. The implementation handles file transfer between two endpoints with guaranteed delivery and ordering.

## Key Features

### Protocol Mechanisms
- **Three-way handshake** for connection establishment
- **Four-way handshake** for graceful connection termination
- **Sliding window protocol** for flow control
- **Adaptive timeout calculation** using ERTT (Estimated Round-Trip Time) and EDEV (Estimated Deviation)
- **Fast retransmit** on triple duplicate ACK detection
- **Automatic retransmission** on timeout with exponential backoff
- **16-bit checksum** for error detection

### Reliability Features
- Out-of-order packet buffering and reordering
- Duplicate packet detection and elimination
- Packet loss recovery through timeout and retransmission
- Thread-safe concurrent packet processing
- Configurable MTU (Maximum Transmission Unit) and window size

## Architecture

### Core Components

- **TCPHandler**: Abstract base class implementing core TCP functionality including:
  - Connection state management
  - ACK processing with duplicate detection
  - Packet serialization and transmission
  - Statistics collection

- **Sender**: Initiates connections and transmits files
  - Reads file in MTU-sized chunks
  - Manages sliding window flow control
  - Initiates connection close sequence

- **Receiver**: Accepts connections and receives files
  - Priority queue for out-of-order packet management
  - Sequential file writing
  - Connection teardown handling

- **TimerManager**: Manages retransmission timers
  - Adaptive timeout calculation (similar to TCP's Jacobson/Karels algorithm)
  - Priority queue of unacknowledged packets
  - Automatic retransmission on timeout (max 16 attempts)

- **TCPpacket**: Custom packet structure with 24-byte header
  - Sequence and acknowledgment numbers
  - Timestamp for RTT calculation
  - SYN, FIN, ACK flags
  - Checksum validation
  - Variable-length payload

## Usage

### Compilation
```bash
make
```

### Running as Sender
```bash
java TCPend -p <local_port> -s <remote_ip> -a <remote_port> -f <filename> -m <mtu> -c <window_size>
```

### Running as Receiver
```bash
java TCPend -p <local_port> -f <output_filename> -m <mtu> -c <window_size>
```

### Parameters
- `-p`: Local port number
- `-s`: Remote IP address (sender only)
- `-a`: Remote port number (sender only)
- `-f`: Filename (file to send for sender, output file for receiver)
- `-m`: Maximum transmission unit in bytes
- `-c`: Sliding window size (number of packets)

## Example

**Receiver (Host B):**
```bash
java TCPend -p 5000 -f received_file.txt -m 1500 -c 64
```

**Sender (Host A):**
```bash
java TCPend -p 5001 -s 192.168.1.100 -a 5000 -f source_file.txt -m 1500 -c 64
```

## Protocol Specification

### Packet Header Format (24 bytes)
```
0                   1                   2                   3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Sequence Number                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                     Acknowledgment Number                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+                        Timestamp (64-bit)                     +
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                   Data Length + Flags (S/F/A)                 |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|            Reserved           |            Checksum           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Payload (variable length)                  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### Connection States
1. **CLOSED** → SYN sent → **SYN_SENT**
2. **SYN_SENT** → SYN-ACK received → **ESTABLISHED**
3. **ESTABLISHED** → Data transfer
4. **ESTABLISHED** → FIN sent → **FIN_WAIT**
5. **FIN_WAIT** → FIN-ACK received → **TIME_WAIT**
6. **TIME_WAIT** → Timeout (4 × RTO) → **CLOSED**

## Statistics Tracking

The implementation tracks and reports:
- Total data transferred (bytes)
- Packets sent/received
- Out-of-sequence packets received
- Packets discarded due to checksum errors
- Number of retransmissions
- Duplicate ACKs received

## Technical Highlights

- **Concurrency**: Thread-safe implementation using synchronized blocks and proper locking
- **Adaptive algorithms**: Dynamic timeout adjustment based on network conditions
- **Efficient buffering**: Priority queue for O(log n) packet ordering
- **Error handling**: Comprehensive checksum verification and retransmission logic
- **Clean architecture**: Abstract base class with specialized sender/receiver implementations

## Requirements

- Java 8 or higher
- UDP-capable network interface

## Building

```bash
make          # Compile all source files
make clean    # Remove compiled classes
```

## Performance Considerations

- Adaptive timeout prevents unnecessary retransmissions
- Sliding window maximizes throughput
- Fast retransmit reduces latency on packet loss
- Efficient packet buffering minimizes memory overhead

## License

MIT License

---

**Author**: Hao Zhou
**GitHub**: [@haozhou1919](https://github.com/haozhou1919)

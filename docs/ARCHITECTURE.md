# Architecture Documentation

## System Overview

This document describes the architecture of the Reliable Transport Protocol implementation.

## Component Diagram

```
┌─────────────┐                    ┌─────────────┐
│   Sender    │                    │  Receiver   │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │  extends                         │  extends
       ▼                                  ▼
┌──────────────────────────────────────────────────┐
│              TCPHandler (Abstract)                │
│  - Connection management                         │
│  - Packet transmission/reception                 │
│  - ACK processing                                │
│  - Statistics tracking                           │
└────┬──────────────────────────┬─────────────────┘
     │                          │
     │  uses                    │  uses
     ▼                          ▼
┌────────────┐          ┌──────────────┐
│TCPpacket   │          │TimerManager  │
│- serialize │          │- Timeout calc│
│- checksum  │          │- Retransmit  │
└────────────┘          └──────┬───────┘
                               │
                               │  manages
                               ▼
                        ┌──────────────┐
                        │ TimerPacket  │
                        │ (per packet) │
                        └──────────────┘
```

## Class Responsibilities

### TCPHandler (Abstract Base Class)
**Purpose**: Provides common TCP functionality for both sender and receiver

**Key Responsibilities**:
- UDP socket management
- Packet transmission and reception loop
- Connection establishment (3-way handshake)
- Connection termination (4-way handshake)
- ACK processing with duplicate detection
- Statistics collection

**Thread Model**: Runs as separate thread, continuously receiving packets

### Sender
**Purpose**: Initiates connection and transmits file data

**Key Responsibilities**:
- Read file in MTU-sized chunks
- Manage sliding window flow control
- Wait for connection establishment before sending data
- Initiate connection close when transfer complete

**Flow**:
1. Send SYN packet
2. Wait for SYN-ACK
3. Send ACK (connection established)
4. Read and send file data
5. Send FIN when complete
6. Wait for FIN-ACK
7. Enter TIME_WAIT state

### Receiver
**Purpose**: Accept connection and receive file data

**Key Responsibilities**:
- Accept incoming SYN connection
- Buffer out-of-order packets in priority queue
- Write data to file in correct sequence
- Respond to connection close

**Flow**:
1. Receive SYN packet
2. Send SYN-ACK
3. Wait for ACK (connection established)
4. Receive and process data packets
5. Receive FIN
6. Send FIN-ACK
7. Close connection

### TCPpacket
**Purpose**: Packet data structure and serialization

**Header Format** (24 bytes):
```
Bytes 0-3:   Sequence Number (int)
Bytes 4-7:   Acknowledgment Number (int)
Bytes 8-15:  Timestamp (long)
Bytes 16-19: Data Length + Flags (int)
             - Bits 0-2: Flags (SYN, FIN, ACK)
             - Bits 3-31: Data length
Bytes 20-21: Reserved (short)
Bytes 22-23: Checksum (short)
Bytes 24+:   Data (variable)
```

**Key Methods**:
- `serialize()`: Convert packet to byte array
- `deserialize()`: Parse byte array into packet
- `verifyChecksum()`: Validate packet integrity
- `calculateChecksum()`: Compute 16-bit one's complement checksum

### TimerManager
**Purpose**: Manage retransmission timeouts for all packets

**Key Responsibilities**:
- Maintain priority queue of unacknowledged packets
- Calculate adaptive timeout (ERTT, EDEV)
- Schedule retransmissions
- Remove acknowledged packets

**Timeout Algorithm**:
```
First RTT sample:
  ERTT = measured RTT
  EDEV = 0
  TO = 2 × ERTT

Subsequent samples:
  SRTT = measured RTT
  SDEV = |SRTT - ERTT|
  ERTT = (7/8) × ERTT + (1/8) × SRTT
  EDEV = (3/4) × EDEV + (1/4) × SDEV
  TO = ERTT + 4 × EDEV
```

**Sliding Window**:
- Limits number of unacknowledged packets
- Blocks sender when window full
- Releases space when ACKs received

### TimerPacket
**Purpose**: Timer task for individual packet retransmission

**Key Features**:
- Extends `TimerTask` for scheduled execution
- Tracks retransmission count
- Triggers retransmission on timeout
- Maximum 16 retransmissions before giving up

## Connection State Machine

### Sender States
```
CLOSED → [send SYN] → SYN_SENT
SYN_SENT → [recv SYN-ACK, send ACK] → ESTABLISHED
ESTABLISHED → [send data] → ESTABLISHED
ESTABLISHED → [send FIN] → FIN_WAIT
FIN_WAIT → [recv FIN-ACK, send ACK] → TIME_WAIT
TIME_WAIT → [timeout 4×RTO] → CLOSED
```

### Receiver States
```
CLOSED → [recv SYN, send SYN-ACK] → SYN_RECEIVED
SYN_RECEIVED → [recv ACK] → ESTABLISHED
ESTABLISHED → [recv data, send ACK] → ESTABLISHED
ESTABLISHED → [recv FIN, send FIN-ACK] → CLOSE_WAIT
CLOSE_WAIT → [recv final ACK] → CLOSED
```

## Reliability Mechanisms

### 1. Acknowledgments
- Cumulative ACKs (like TCP)
- ACK number indicates next expected sequence number
- Receiver sends ACK for every data packet

### 2. Timeout Retransmission
- Each packet has timer
- Retransmit if no ACK received before timeout
- Adaptive timeout based on RTT measurements

### 3. Fast Retransmit
- Detect 3 duplicate ACKs
- Immediately retransmit suspected lost packet
- Don't wait for timeout

### 4. Checksum Validation
- 16-bit one's complement checksum
- Computed over entire packet (header + data)
- Corrupt packets silently dropped

### 5. Sequence Numbers
- Track packet ordering
- Detect duplicates
- Handle out-of-order delivery

## Flow Control

### Sliding Window Protocol
- Sender maintains window of unacknowledged packets
- Window size configured at startup
- Sender blocks when window full
- ACKs slide window forward

### Buffer Management
- Sender: Priority queue of unacknowledged packets
- Receiver: Priority queue of out-of-order packets
- Thread-safe synchronization

## Thread Safety

### Synchronization Points
1. `sendTCP()`: Synchronized to prevent concurrent sends
2. `getSeqNum()`/`setSeqNum()`: Synchronized accessors
3. `getAckNum()`/`setAckNum()`: Synchronized accessors
4. `packetBuffer`: Synchronized block for queue operations
5. `endThread()`: Synchronized shutdown

### Thread Model
- Main thread: Packet reception loop (TCPHandler.run())
- Timer threads: One per unacknowledged packet
- Application thread: File I/O (Sender/Receiver specific)
- Cleanup thread: TIME_WAIT state (WaitClose)

## Error Handling

### Recoverable Errors
- Packet loss → timeout retransmission
- Packet corruption → checksum failure, silent drop
- Out-of-order delivery → buffering and reordering
- Duplicate packets → sequence number detection

### Fatal Errors
- Max retransmissions exceeded (16) → connection abort
- Socket errors → connection abort
- File I/O errors → connection abort

## Performance Considerations

### Optimization Strategies
1. **Adaptive Timeout**: Prevents unnecessary retransmissions
2. **Fast Retransmit**: Reduces latency on packet loss
3. **Priority Queue**: O(log n) packet insertion/removal
4. **Sliding Window**: Maximizes throughput
5. **Single Thread Reception**: Minimizes context switching

### Scalability Limits
- Single connection per endpoint
- Memory: O(window_size) for packet buffers
- CPU: Linear with packet rate
- Network: Limited by UDP performance

## Future Enhancements

Potential improvements for production use:
1. Congestion control (slow start, congestion avoidance)
2. Selective acknowledgments (SACK)
3. Window scaling
4. Nagle's algorithm for small packets
5. Keep-alive mechanism
6. Multiple simultaneous connections
7. IPv6 support

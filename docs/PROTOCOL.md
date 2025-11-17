# Protocol Specification

## Overview

This document specifies the reliable transport protocol implemented in this project. The protocol provides TCP-like reliability over UDP.

## Packet Format

### Header Structure (24 bytes)

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
|                     Data Length and Flags                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|            Reserved           |            Checksum           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Data (variable length)                     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

### Field Descriptions

#### Sequence Number (32 bits)
- Sequence number of the first byte of data in this packet
- For SYN/FIN packets, this is the initial/final sequence number
- Starts at 0 and increments by data length (or 1 for SYN/FIN)

#### Acknowledgment Number (32 bits)
- If ACK flag set: next sequence number expected by sender
- Cumulative acknowledgment (all bytes before this have been received)
- Zero if ACK flag not set

#### Timestamp (64 bits)
- Nanosecond timestamp when packet was sent
- Used for RTT calculation
- System.nanoTime() on sender

#### Data Length and Flags (32 bits)
- Bits 0-2: Flags (SYN, FIN, ACK)
  - Bit 0: SYN (Synchronize sequence numbers)
  - Bit 1: FIN (Final packet, close connection)
  - Bit 2: ACK (Acknowledgment field is valid)
- Bits 3-31: Data payload length in bytes

#### Reserved (16 bits)
- Set to zero
- Reserved for future use

#### Checksum (16 bits)
- 16-bit one's complement checksum
- Computed over entire packet (header + data)
- Checksum field set to 0 during calculation

#### Data (variable)
- Actual payload data
- Length determined by Data Length field
- Maximum length = MTU - 52 bytes (24 header + 28 UDP/IP overhead)

## Connection Management

### Connection Establishment (3-Way Handshake)

```
Sender                           Receiver
  |                                |
  |  SYN (seq=0)                   |
  |------------------------------->|
  |                                |
  |  SYN-ACK (seq=0, ack=1)        |
  |<-------------------------------|
  |                                |
  |  ACK (seq=1, ack=1)            |
  |------------------------------->|
  |                                |
  |  Connection Established        |
```

**Step 1: SYN**
- Sender sends packet with SYN flag set
- Sequence number = 0
- No data payload

**Step 2: SYN-ACK**
- Receiver responds with SYN and ACK flags set
- Sequence number = 0
- Acknowledgment number = sender's seq + 1 = 1
- No data payload

**Step 3: ACK**
- Sender sends packet with ACK flag set
- Sequence number = 1
- Acknowledgment number = receiver's seq + 1 = 1
- Connection established, data transfer can begin

### Connection Termination (4-Way Handshake)

```
Sender                           Receiver
  |                                |
  |  FIN (seq=N)                   |
  |------------------------------->|
  |                                |
  |  FIN-ACK (seq=M, ack=N+1)      |
  |<-------------------------------|
  |                                |
  |  ACK (seq=N+1, ack=M+1)        |
  |------------------------------->|
  |                                |
  |  TIME_WAIT (4 × RTO)           |
  |                                |
  |  Connection Closed             |
```

**Step 1: FIN**
- Initiator sends FIN packet
- Indicates no more data to send

**Step 2: FIN-ACK**
- Other side sends FIN and ACK
- Acknowledges FIN and requests close

**Step 3: ACK**
- Initiator acknowledges FIN-ACK

**Step 4: TIME_WAIT**
- Initiator waits 4 × RTO before closing
- Ensures all packets cleared from network

## Data Transfer

### Sending Data

1. Sender reads file in chunks (MTU - 52 bytes)
2. Creates packet with data, sequence number
3. Adds to timer queue for retransmission tracking
4. Sends packet via UDP
5. Waits for ACK or timeout
6. Slides window forward when ACKs received

### Receiving Data

1. Receiver gets UDP packet
2. Verifies checksum
3. Checks sequence number:
   - **seq < expected**: Duplicate, discard
   - **seq = expected**: In-order, process immediately
   - **seq > expected**: Out-of-order, buffer in priority queue
4. Sends ACK with next expected sequence number
5. Writes in-order data to file

### Acknowledgments

**ACK Policy**:
- Receiver sends ACK for every data packet received
- ACK number = sequence number + data length
- Cumulative (acknowledges all data before ACK number)

**Duplicate ACKs**:
- Occur when out-of-order packets received
- Same ACK number sent multiple times
- Triggers fast retransmit after 3 duplicates

## Reliability Mechanisms

### Retransmission

**Timeout-based**:
- Each packet has timer = RTO (Retransmission Timeout)
- Timer started when packet sent
- If no ACK before timeout, resend packet
- Maximum 16 retransmissions, then abort

**Fast Retransmit**:
- Triggered by 3 duplicate ACKs
- Immediately resend packet without waiting for timeout
- Reduces latency on packet loss

### Timeout Calculation

**Initial RTO**:
```
RTO = 1 second
```

**First RTT Sample**:
```
ERTT = RTT_sample
EDEV = 0
RTO = 2 × ERTT
```

**Subsequent RTT Samples**:
```
SRTT = RTT_sample
SDEV = |SRTT - ERTT|
ERTT = (7/8) × ERTT + (1/8) × SRTT
EDEV = (3/4) × EDEV + (1/4) × SDEV
RTO = ERTT + 4 × EDEV
```

This is similar to TCP's Jacobson/Karels algorithm.

### Checksum

**Algorithm**: 16-bit one's complement

**Computation**:
1. Divide packet into 16-bit words
2. Sum all words (with wraparound on overflow)
3. Take one's complement of sum
4. Store in checksum field

**Verification**:
1. Compute checksum of received packet (with checksum field = 0)
2. Compare with received checksum value
3. Discard packet if mismatch

### Sequence Numbers

**Purpose**:
- Detect lost packets (gaps in sequence)
- Detect duplicate packets (same sequence twice)
- Reorder out-of-order packets

**Increment Rules**:
- SYN: seq += 1
- FIN: seq += 1
- Data: seq += data_length
- ACK only: seq unchanged

## Flow Control

### Sliding Window

**Window Size**:
- Configured at startup (typically 64 packets)
- Limits number of unacknowledged packets

**Sender Behavior**:
- Send packets while window not full
- Block when window full
- Slide window forward when ACK received

**Receiver Behavior**:
- Accept packets within window
- Buffer out-of-order packets
- Deliver in-order to application

## Error Handling

### Packet Loss
- **Detection**: Timeout or duplicate ACKs
- **Recovery**: Retransmission

### Packet Corruption
- **Detection**: Checksum mismatch
- **Recovery**: Silent drop, timeout triggers retransmission

### Packet Duplication
- **Detection**: Sequence number already received
- **Recovery**: Discard duplicate, send ACK anyway

### Packet Reordering
- **Detection**: Sequence number > expected
- **Recovery**: Buffer in priority queue, deliver when in-order

### Connection Failure
- **Detection**: 16 retransmissions exceeded
- **Recovery**: Abort connection, report error

## Parameters

### Configurable Parameters

| Parameter | Flag | Description | Default |
|-----------|------|-------------|---------|
| Port | -p | Local UDP port | Required |
| Remote IP | -s | Destination IP (sender only) | Required for sender |
| Remote Port | -a | Destination port (sender only) | Required for sender |
| Filename | -f | File to send/receive | Required |
| MTU | -m | Maximum transmission unit | 1500 bytes |
| Window Size | -c | Sliding window size | 64 packets |

### Protocol Constants

| Constant | Value | Description |
|----------|-------|-------------|
| Header Size | 24 bytes | Fixed header length |
| IP/UDP Overhead | 28 bytes | Not in our control |
| Total Overhead | 52 bytes | Header + IP/UDP |
| Initial RTO | 1 second | Before first RTT sample |
| Max Retransmissions | 16 | Before aborting connection |
| TIME_WAIT Duration | 4 × RTO | After FIN-ACK |

## Output Format

### Packet Log
Every sent/received packet is logged:

```
<snd/rcv> <time> <flags> <seq> <length> <ack>
```

**Example**:
```
snd 0.000 S - - - 0 0 0
rcv 0.002 S - A - 0 0 1
snd 0.003 - - A - 1 0 1
snd 0.005 - - A D 1 1024 1
rcv 0.007 - - A - 0 0 1025
```

**Fields**:
- `snd/rcv`: Packet direction
- `time`: Timestamp in seconds since start
- Flags: `S` (SYN), `F` (FIN), `A` (ACK), `D` (Data)
- `seq`: Sequence number
- `length`: Data length
- `ack`: Acknowledgment number

### Statistics
At end of connection:

```
-------------------------------------------
Amount of Data transferred: 102400
Number of packets sent/received: 150/145
Number of out of sequence packets: 5
Number of packets discarded due to incorrect checksum: 0
Number of packets retransmitted: 3
Number of duplicate ACKs: 9
-------------------------------------------
```

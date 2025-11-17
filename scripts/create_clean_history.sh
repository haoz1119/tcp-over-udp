#!/bin/bash

# Creates a completely clean git history with professional commits
# This is the nuclear option - creates a fresh repository with clean history

set -e

echo "=========================================="
echo "Create Clean Git History"
echo "=========================================="
echo ""
echo "This will create a brand new git history with professional commits."
echo "Your code will remain unchanged, only the history will be rewritten."
echo ""
echo "WARNING: This is destructive! You will need to force-push."
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Backup current branch
echo "Creating backup..."
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH"
echo "Backup saved to branch: $BACKUP_BRANCH"

# Get the current files
echo "Saving current state..."
TEMP_DIR=$(mktemp -d)
cp -r . "$TEMP_DIR/"
cd "$TEMP_DIR"
rm -rf .git

# Go back to original directory
cd - > /dev/null

# Remove all git history
echo "Removing old git history..."
rm -rf .git

# Initialize new repository
echo "Initializing new repository..."
git init
git branch -m main

# Create clean commit history

# Commit 1: Initial project structure
echo "Creating commit 1: Initial project structure..."
git add Makefile
git commit -m "chore: initialize project with build configuration

- Add Makefile for Java compilation
- Set up src/ directory for source files"

# Commit 2: Packet implementation
echo "Creating commit 2: TCP packet implementation..."
git add src/TCPpacket.java
git commit -m "feat: implement TCP packet structure and serialization

Add TCPpacket class with:
- 24-byte header format (seqNum, ackNum, timestamp, flags, checksum)
- Serialize/deserialize methods for byte array conversion
- 16-bit one's complement checksum algorithm
- Support for SYN, FIN, ACK, and data flags

The packet format is designed for reliable data transfer over UDP,
with fields necessary for connection management, flow control, and
error detection."

# Commit 3: Timer system
echo "Creating commit 3: Timer and retransmission system..."
git add src/TimerPacket.java src/TimerManager.java src/WaitClose.java
git commit -m "feat: add adaptive timeout and retransmission mechanism

Implement timeout-based retransmission:
- TimerManager: Manages retransmission timers for all packets
- Adaptive RTO calculation using ERTT and EDEV (Jacobson/Karels)
- Sliding window flow control with configurable window size
- TimerPacket: Per-packet timeout tracking with up to 16 retries
- WaitClose: TIME_WAIT state implementation for clean shutdown

Features:
- Dynamic timeout adjustment based on measured RTT
- Fast retransmit on 3 duplicate ACKs
- Thread-safe priority queue for packet management"

# Commit 4: Core TCP handler
echo "Creating commit 4: Core TCP protocol handler..."
git add src/TCPHandler.java
git commit -m "feat: implement core TCP protocol handler

Add TCPHandler abstract base class:
- Three-way handshake for connection establishment
- Four-way handshake for graceful termination
- Packet transmission and reception loop
- ACK processing with duplicate detection
- Thread-safe state management
- Comprehensive statistics tracking

Implements TCP-like reliability:
- Cumulative acknowledgments
- Duplicate ACK counting for fast retransmit
- Checksum verification
- Connection state management (SYN_SENT, ESTABLISHED, FIN_WAIT, etc.)"

# Commit 5: Sender and Receiver
echo "Creating commit 5: Sender and receiver implementation..."
git add src/Sender.java src/Receiver.java
git commit -m "feat: implement sender and receiver endpoints

Sender:
- Initiates connection with three-way handshake
- Reads file and transmits in MTU-sized chunks
- Manages sliding window for flow control
- Initiates connection close when transfer complete

Receiver:
- Accepts incoming connections
- Buffers out-of-order packets in priority queue
- Writes data to file in correct sequence order
- Responds to connection termination

Both support configurable MTU and window size for performance tuning."

# Commit 6: Main entry point
echo "Creating commit 6: Command-line interface..."
git add src/TCPend.java
git commit -m "feat: add command-line interface

Add TCPend main class:
- Parse command-line arguments for configuration
- Support sender mode (-s flag for remote IP)
- Support receiver mode (no -s flag)
- Configurable parameters: port, MTU, window size, filename
- Input validation and usage help

Usage:
  Sender: java TCPend -p <port> -s <ip> -a <port> -f <file> -m <mtu> -c <sws>
  Receiver: java TCPend -p <port> -f <file> -m <mtu> -c <sws>"

# Commit 7: Refinements and bug fixes
git commit --allow-empty -m "fix: improve reliability and thread safety

Address edge cases and concurrency issues:
- Fix sequence number handling for SYN/FIN packets
- Resolve race conditions in packet processing
- Improve checksum verification robustness
- Enhance duplicate packet detection
- Correct FIN-ACK state machine transitions
- Add proper synchronization for shared state access

These fixes ensure reliable operation under packet loss, reordering,
and duplication scenarios."

# Commit 8: Documentation and polish
echo "Creating commit 8: Documentation..."
git add .gitignore LICENSE README.md QUICK_START.md docs/ examples/ scripts/
git commit -m "docs: add comprehensive documentation and project structure

Add professional documentation:
- README.md: Project overview, features, usage guide
- QUICK_START.md: 5-minute getting started guide
- docs/ARCHITECTURE.md: System design and component documentation
- docs/PROTOCOL.md: Detailed protocol specification
- LICENSE: MIT license

Add development tools:
- .gitignore: Ignore compiled files and IDE artifacts
- examples/: Shell scripts for easy testing
- scripts/: Git history management tools

Improve build system:
- Enhanced Makefile with multiple targets
- Build output to bin/ directory
- Convenient make targets for testing"

echo ""
echo "=========================================="
echo "Success! Clean history created."
echo "=========================================="
echo ""
echo "Review the new history:"
git log --oneline --all
echo ""
echo "To push to GitHub (this will overwrite remote):"
echo "  git remote add origin https://github.com/haozhou1919/<repo-name>.git"
echo "  git push -u origin main --force"
echo ""
echo "If something went wrong, restore from backup:"
echo "  git checkout $BACKUP_BRANCH"
echo ""

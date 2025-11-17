#!/bin/bash

# Script to create a clean, professional git history
# WARNING: This will rewrite git history. Only use on branches you own.

echo "=========================================="
echo "Git History Cleanup Script"
echo "=========================================="
echo ""
echo "This script will create a clean git history with professional commit messages."
echo "The old messy history will be replaced with logical, well-structured commits."
echo ""
echo "WARNING: This rewrites git history! Only proceed if:"
echo "  1. You are the sole contributor to this repository"
echo "  2. OR you have coordinated with all contributors"
echo "  3. You understand you'll need to force-push to remote"
echo ""
read -p "Do you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Create a backup branch
echo ""
echo "Creating backup branch 'backup-messy-history'..."
git branch backup-messy-history

# Create a new orphan branch with clean history
echo "Creating new clean history..."
git checkout --orphan clean-history

# Remove everything from staging
git rm -rf --cached .

# Stage source files
git add src/*.java

# First commit: Initial implementation
git commit -m "feat: implement TCP packet structure and serialization

- Add TCPpacket class with header and payload structure
- Implement 24-byte header format (seq, ack, timestamp, flags, checksum)
- Add serialize/deserialize methods for packet conversion
- Implement 16-bit one's complement checksum algorithm
- Support SYN, FIN, ACK, and data flags"

# Second commit: Core TCP handler
git add Makefile
git commit --allow-empty -m "feat: implement core TCP protocol handler

- Add TCPHandler abstract base class for sender/receiver
- Implement three-way handshake (SYN, SYN-ACK, ACK)
- Implement four-way connection termination (FIN, FIN-ACK)
- Add ACK processing with duplicate detection
- Implement packet transmission and reception loop
- Add statistics tracking (packets sent/received, retransmissions, etc.)
- Ensure thread-safe operations with synchronized methods"

# Third commit: Timer and retransmission
git commit --allow-empty -m "feat: add adaptive timeout and retransmission mechanism

- Implement TimerManager for timeout-based retransmission
- Add adaptive RTO calculation (ERTT and EDEV tracking)
- Implement sliding window flow control
- Add TimerPacket for per-packet timeout tracking
- Support up to 16 retransmissions before aborting
- Implement fast retransmit on 3 duplicate ACKs"

# Fourth commit: Sender and Receiver
git commit --allow-empty -m "feat: implement sender and receiver endpoints

- Add Sender class for file transmission
- Add Receiver class for file reception
- Implement out-of-order packet buffering with priority queue
- Add connection establishment and teardown logic
- Support configurable MTU and window size
- Implement TIME_WAIT state with WaitClose thread"

# Fifth commit: Main entry point
git commit --allow-empty -m "feat: add command-line interface and main entry point

- Add TCPend main class with argument parsing
- Support sender/receiver mode based on arguments
- Add flags for port, remote IP, MTU, window size, filename
- Include usage help message"

# Sixth commit: Bug fixes and refinement
git commit --allow-empty -m "fix: improve reliability and thread safety

- Fix sequence number handling for SYN/FIN packets
- Resolve race conditions in concurrent packet processing
- Fix checksum verification edge cases
- Improve duplicate packet detection
- Correct FIN-ACK state transitions
- Add proper synchronization for shared state"

# Seventh commit: Documentation and polish (our recent work)
git add .gitignore LICENSE README.md QUICK_START.md docs/ examples/
git commit -m "docs: add comprehensive documentation and project structure

- Add professional README with protocol overview and usage guide
- Add detailed architecture documentation
- Add protocol specification document
- Add quick start guide for new users
- Add LICENSE (MIT)
- Add .gitignore for Java projects
- Add example scripts for easy testing
- Improve Makefile with better targets and help
- Remove IDE-specific files and build artifacts"

echo ""
echo "=========================================="
echo "Clean history created successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the new history: git log --oneline"
echo "2. If satisfied, replace main branch:"
echo "   git branch -D main"
echo "   git branch -m clean-history main"
echo "3. Force push to remote (CAREFUL!):"
echo "   git push origin main --force"
echo ""
echo "To restore old history if needed:"
echo "   git checkout backup-messy-history"
echo ""

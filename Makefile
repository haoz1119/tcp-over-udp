# Makefile for Reliable Transport Protocol

# Directories
SRC_DIR = src
BIN_DIR = bin

# Java compiler
JC = javac
JFLAGS = -d $(BIN_DIR) -sourcepath $(SRC_DIR)

# Find all Java source files
SOURCES = $(wildcard $(SRC_DIR)/*.java)

# Default target
.PHONY: all
all: build

# Build target
.PHONY: build
build: $(BIN_DIR)
	@echo "Compiling Java sources..."
	$(JC) $(JFLAGS) $(SOURCES)
	@echo "Build complete! Classes are in $(BIN_DIR)/"

# Create bin directory if it doesn't exist
$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# Run receiver (example)
.PHONY: receiver
receiver: build
	@echo "Starting receiver on port 5000..."
	java -cp $(BIN_DIR) TCPend -p 5000 -f received.txt -m 1500 -c 64

# Run sender (example - requires receiver to be running)
.PHONY: sender
sender: build
	@echo "Starting sender..."
	@if [ ! -f test.txt ]; then \
		echo "Creating test file..."; \
		dd if=/dev/urandom of=test.txt bs=1024 count=100 2>/dev/null; \
	fi
	java -cp $(BIN_DIR) TCPend -p 5001 -s 127.0.0.1 -a 5000 -f test.txt -m 1500 -c 64

# Clean compiled files
.PHONY: clean
clean:
	@echo "Cleaning compiled files..."
	rm -rf $(BIN_DIR)
	rm -f test.txt received.txt
	@echo "Clean complete!"

# Clean everything including IDE files
.PHONY: distclean
distclean: clean
	@echo "Deep cleaning..."
	rm -rf .idea
	find . -name "*.class" -delete
	find . -name ".DS_Store" -delete
	@echo "Deep clean complete!"

# Help target
.PHONY: help
help:
	@echo "Reliable Transport Protocol - Makefile Help"
	@echo ""
	@echo "Available targets:"
	@echo "  make build     - Compile all Java source files"
	@echo "  make all       - Same as build (default)"
	@echo "  make receiver  - Build and run receiver example"
	@echo "  make sender    - Build and run sender example"
	@echo "  make clean     - Remove compiled files"
	@echo "  make distclean - Remove all generated files including IDE files"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Manual usage:"
	@echo "  Receiver: java -cp bin TCPend -p <port> -f <file> -m <mtu> -c <window>"
	@echo "  Sender:   java -cp bin TCPend -p <port> -s <ip> -a <port> -f <file> -m <mtu> -c <window>"

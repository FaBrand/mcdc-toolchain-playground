FROM ubuntu:24.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install essential build tools and dependencies
RUN apt-get update && apt-get install -y \
    gcc-14 \
    g++-14 \
    make \
    perl \
    libcapture-tiny-perl \
    libdatetime-perl \
    libjson-xs-perl \
    libdigest-md5-perl \
    python3 \
    git \
    wget \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /mcdc-demo

# Download and extract LLVM toolchain
RUN wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.6/LLVM-21.1.6-Linux-X64.tar.xz && \
    mkdir -p llvm && \
    tar -xf LLVM-21.1.6-Linux-X64.tar.xz --strip-components=1 -C llvm && \
    rm LLVM-21.1.6-Linux-X64.tar.xz

# Clone lcov repository (v2.3.2 with MC/DC support)
RUN git clone --depth 1 --branch v2.3.2 https://github.com/linux-test-project/lcov.git

# Copy source files and Makefile
COPY decision_logic.c test_a.c Makefile ./

# Create build directories
RUN mkdir -p build/llvm build/gcc

# Set default command to run make all
CMD ["make", "all"]

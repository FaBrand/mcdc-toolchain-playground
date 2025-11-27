# MC/DC Coverage Demo

This Docker setup demonstrates MC/DC (Modified Condition/Decision Coverage) generation using both LLVM and GCC toolchains.

## Quick Start

### Build and run with Docker Compose
```bash
docker compose up
```

This will:
- Build the Docker image with LLVM 21.1.6 and latest lcov
- Compile test code with both LLVM and GCC
- Generate coverage reports with MC/DC metrics
- Save results to `./results/` directory

### Build Docker image manually
```bash
docker build --add-host=host.docker.internal:host-gateway . -t mcdc-cov:latest
```

### Run Docker container
```bash
docker run --rm mcdc-cov:latest
```

## Inspecting Results

### Option 1: Using bind mount (docker-compose)
Results are automatically copied to `./results/` directory:
```bash
docker compose up
ls -la results/gcc/
ls -la results/llvm/
```

### Option 2: Using named volume
Inspect the persistent volume:
```bash
docker run --rm -v playground_mcdc-results:/data alpine ls -laR /data
```

Copy files from volume to host:
```bash
docker run --rm -v playground_mcdc-results:/data -v $(pwd):/output alpine cp -r /data /output/results
```

### Option 3: Extract from running container
```bash
docker compose run --rm mcdc-demo sh
# Inside container: explore /mcdc-demo/build/
```

## Generated Files

### LLVM output (`build/llvm/`)
- `test_a.info` - LCOV format coverage with branch info
- `test_a.txt` - Text format coverage report
- `test_a.profdata` - LLVM profiling data
- `*.profraw` - Raw profile data

### GCC output (`build/gcc/`)
- `test_a.info` - LCOV format coverage with MC/DC tags
- `decision_logic.c.gcov` - Human-readable coverage with condition details
- `*.gcda` - GCC coverage data files
- `*.gcno` - GCC notes files

## Make Targets

```bash
make all        # Build and compare both LLVM and GCC coverage
make llvm       # Build with LLVM and generate coverage
make gcc        # Build with GCC and generate coverage
make compare    # Compare coverage results
make clean      # Clean all build artifacts
```

## Requirements

The Dockerfile installs:
- GCC 14
- LLVM 21.1.6
- lcov 2.3.2

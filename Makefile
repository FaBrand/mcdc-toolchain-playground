# ───────────────── project layout (all files in repo root) ───────────────
#   decision_logic.c  test_a.c
# ──────────────────────────────────────────────────────────────────────────

# ─── LLVM toolchain ────────────────────────────────────────────────────────
LLVM_DIR   := ./llvm/bin
LLVM_CC    := $(LLVM_DIR)/clang
LLVM_AR    := $(LLVM_DIR)/llvm-ar
PROFDATA   := $(LLVM_DIR)/llvm-profdata
COV        := $(LLVM_DIR)/llvm-cov

# ─── GCC toolchain ─────────────────────────────────────────────────────────
GCC_VER    := 14                    # e.g. "gcc-14", "gcov-14"
GCC_CC     := gcc-$(GCC_VER)
GCC_AR     := gcc-ar-$(GCC_VER)
GCOV       := gcov-$(GCC_VER)
LCOV       := ./lcov/bin/lcov       # Local LCOV 2.3+ with MC/DC support
GENINFO    := ./lcov/bin/geninfo

# ─── Build directories ─────────────────────────────────────────────────────
BUILD_LLVM := build/llvm
BUILD_GCC  := build/gcc
LIB1_NAME  := libmcdc.a

# ––– coverage / MC‑DC instrumentation flags ––––––––––––––––––––––––––––
LLVM_COV_FLAGS := -O0 -g -fprofile-instr-generate -fcoverage-mapping -fcoverage-mcdc
GCC_COV_FLAGS  := -O0 -g --coverage -fcondition-coverage
CFLAGS_COMMON  := -std=c11 -Wall -Wextra

# Uncomment if you need *fully* static test binaries
# STATIC     := -static

# ––– source file lists –––––––––––––––––––––––––––––––––––––––––––––––––
LIB1_SRC   := decision_logic.c
TEST_SRC   := test_a.c

LLVM_LIB1_OBJ := $(patsubst %.c,$(BUILD_LLVM)/%.o,$(LIB1_SRC))
GCC_LIB1_OBJ  := $(patsubst %.c,$(BUILD_GCC)/%.o,$(LIB1_SRC))
LLVM_TEST_BIN := $(BUILD_LLVM)/test_a
GCC_TEST_BIN  := $(BUILD_GCC)/test_a

# ─── convenience phony targets ─────────────────────────────────────────
.PHONY: all llvm gcc run-llvm run-gcc lcov-llvm lcov-gcc compare clean clean-llvm clean-gcc

# default build → both LLVM and GCC variants with coverage reports
all: llvm gcc compare

# ════════════════════════════ LLVM BUILD ═══════════════════════════════

llvm: lcov-llvm

# ensure the LLVM build directory exists
$(BUILD_LLVM):
	@mkdir -p $@

# compile LLVM objects for the static library
$(BUILD_LLVM)/%.o: %.c | $(BUILD_LLVM)
	$(LLVM_CC) $(CFLAGS_COMMON) $(LLVM_COV_FLAGS) -c $< -o $@

# archive the LLVM static library
$(BUILD_LLVM)/$(LIB1_NAME): $(LLVM_LIB1_OBJ)
	$(LLVM_AR) rcs $@ $^

# build LLVM test_a binary
$(BUILD_LLVM)/test_a: test_a.c $(BUILD_LLVM)/$(LIB1_NAME) | $(BUILD_LLVM)
	$(LLVM_CC) $(CFLAGS_COMMON) $(LLVM_COV_FLAGS) $(STATIC) $< $(BUILD_LLVM)/$(LIB1_NAME) -o $@

# run LLVM test binary
run-llvm: $(LLVM_TEST_BIN)
	@echo "→ $(LLVM_TEST_BIN)"
	@LLVM_PROFILE_FILE=$(LLVM_TEST_BIN).%p.profraw $(LLVM_TEST_BIN)

# generate LLVM LCOV format with MCDC tags
lcov-llvm: run-llvm
	@echo "[LCOV-LLVM] test_a"
	@$(PROFDATA) merge -sparse $(LLVM_TEST_BIN).*.profraw -o $(LLVM_TEST_BIN).profdata
	@$(COV) export -format=lcov -instr-profile=$(LLVM_TEST_BIN).profdata $(LLVM_TEST_BIN) > $(LLVM_TEST_BIN).info
	@echo "  ↳ generated $(LLVM_TEST_BIN).info"
	@$(COV) export -format=text -instr-profile=$(LLVM_TEST_BIN).profdata $(LLVM_TEST_BIN) > $(LLVM_TEST_BIN).txt
	@echo "  ↳ generated $(LLVM_TEST_BIN).txt"

# ═════════════════════════════ GCC BUILD ═══════════════════════════════

gcc: lcov-gcc

# ensure the GCC build directory exists
$(BUILD_GCC):
	@mkdir -p $@

# compile GCC objects for the static library
$(BUILD_GCC)/%.o: %.c | $(BUILD_GCC)
	$(GCC_CC) $(CFLAGS_COMMON) $(GCC_COV_FLAGS) -c $< -o $@

# archive the GCC static library
$(BUILD_GCC)/$(LIB1_NAME): $(GCC_LIB1_OBJ)
	$(GCC_AR) rcs $@ $^

# build GCC test_a binary
$(BUILD_GCC)/test_a: test_a.c $(BUILD_GCC)/$(LIB1_NAME) | $(BUILD_GCC)
	$(GCC_CC) $(CFLAGS_COMMON) $(GCC_COV_FLAGS) $(STATIC) $< $(BUILD_GCC)/$(LIB1_NAME) -o $@

# run GCC test binary
run-gcc: $(GCC_TEST_BIN)
	@echo "→ $(GCC_TEST_BIN)"
	@$(GCC_TEST_BIN)

# generate GCC LCOV format with MCDC tags (using local LCOV 2.3+)
lcov-gcc: run-gcc
	@echo "[LCOV-GCC] test_a (with MC/DC support)"
	@$(LCOV) --capture --directory $(BUILD_GCC) --output-file $(GCC_TEST_BIN).info --gcov-tool $(GCOV) --mcdc-coverage --quiet
	@echo "  ↳ generated $(GCC_TEST_BIN).info"
	@$(GCOV) --conditions --branch-probabilities --branch-counts --object-directory $(BUILD_GCC) $(LIB1_SRC) > /dev/null 2>&1
	@echo "  ↳ generated $(LIB1_SRC).gcov"

# ═════════════════════════════ COMPARISON ══════════════════════════════

# compare the two generated .info files
compare: lcov-llvm lcov-gcc
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "  Coverage Comparison: LLVM vs GCC"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "─── LLVM Coverage ($(LLVM_TEST_BIN).info) ───"
	@grep -E "^(MCF|MCH|BRF|BRH|LF|LH):" $(LLVM_TEST_BIN).info | head -6
	@echo ""
	@echo "─── GCC Coverage ($(GCC_TEST_BIN).info) ───"
	@grep -E "^(MCF|MCH|BRF|BRH|LF|LH):" $(GCC_TEST_BIN).info | head -6 || echo "(No MCDC tags in GCC output)"
	@echo ""
	@echo "─── LLVM MCDC Tags (detailed) ───"
	@grep "^MCDC:" $(LLVM_TEST_BIN).info || echo "(No MCDC tags found)"
	@echo ""
	@echo "─── GCC MCDC Tags (detailed) ───"
	@grep "^MCDC:" $(GCC_TEST_BIN).info || echo "(No MCDC tags found - GCC uses JSON format)"
	@echo ""
	@echo "Files available for inspection:"
	@echo "  LLVM: $(LLVM_TEST_BIN).info"
	@echo "  GCC:  $(GCC_TEST_BIN).info"
	@echo "  GCC:  $(LIB1_SRC).gcov (human-readable with condition coverage)"
	@echo "════════════════════════════════════════════════════════════════"

# ═══════════════════════════ HOUSEKEEPING ══════════════════════════════

clean-llvm:
	rm -rf $(BUILD_LLVM)

clean-gcc:
	rm -rf $(BUILD_GCC)
	rm -f *.gcda *.gcno *.gcov

clean: clean-llvm clean-gcc


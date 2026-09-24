SHELL := /bin/sh

# Plain "make" only builds all implementations.
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Platform-dependent executable suffix
#
# Windows (w64devkit/MSYS2/MinGW): .exe
# Linux/macOS:                     empty
#
# EXEEXT can also be overridden explicitly, for example:
#   make EXEEXT=.exe
# ----------------------------------------------------------------------

ifeq ($(OS),Windows_NT)
EXEEXT ?= .exe
else
EXEEXT ?=
endif

TEST_CORRECTNESS := test_correctness$(EXEEXT)
KAT_PROGRAM      := KAT_KEX$(EXEEXT)
TEST_EFFICIENCY  := test_efficiency$(EXEEXT)

# Order used by "make check".
TEST_PROGRAMS := $(TEST_CORRECTNESS) $(KAT_PROGRAM) $(TEST_EFFICIENCY)

# ----------------------------------------------------------------------
# Directory discovery
# ----------------------------------------------------------------------

KEM_DIRS := $(sort \
	$(wildcard Common/primitives/kem/POLARLAC-*) \
	$(wildcard Common/primitives/kem/ZEN-*) \
	$(wildcard Common/primitives/kem/ZEN_*))

SIG_DIRS := $(sort \
	$(wildcard Common/primitives/sig/BiT-*))

CRETAKE_DIRS := $(sort \
	$(wildcard CreTAKE128/CreTAKE-*) \
	$(wildcard CreTAKE256/CreTAKE-*) \
	$(wildcard CreTAKE512/CreTAKE-*))

# ----------------------------------------------------------------------
# Default build targets
# ----------------------------------------------------------------------

.PHONY: all
all: build
	@echo
	@echo "============================================================"
	@echo "All CreTAKE implementations compiled successfully."
	@echo "No tests were executed."
	@echo
	@echo "Available test commands:"
	@echo "  make correctness"
	@echo "  make kat"
	@echo "  make efficiency"
	@echo "  make check"
	@echo "============================================================"

.PHONY: build
build: protocols

# ----------------------------------------------------------------------
# Display automatically discovered directories and executable names
# ----------------------------------------------------------------------

.PHONY: list
list:
	@echo "Executable suffix: '$(EXEEXT)'"
	@echo
	@echo "KEM directories:"
	@for d in $(KEM_DIRS); do \
		echo "  $$d"; \
	done
	@echo
	@echo "Signature directories:"
	@for d in $(SIG_DIRS); do \
		echo "  $$d"; \
	done
	@echo
	@echo "CreTAKE directories:"
	@for d in $(CRETAKE_DIRS); do \
		echo "  $$d"; \
	done

# ----------------------------------------------------------------------
# Build primitive libraries
# ----------------------------------------------------------------------

.PHONY: kem-libs
kem-libs:
	@set -e; \
	for d in $(KEM_DIRS); do \
		echo; \
		echo "============================================================"; \
		echo "Building KEM library: $$d"; \
		echo "============================================================"; \
		$(MAKE) --no-print-directory -C "$$d" kem-lib; \
	done

.PHONY: sig-libs
sig-libs:
	@set -e; \
	for d in $(SIG_DIRS); do \
		echo; \
		echo "============================================================"; \
		echo "Building signature library: $$d"; \
		echo "============================================================"; \
		$(MAKE) --no-print-directory -C "$$d" lib; \
	done

.PHONY: primitives
primitives: kem-libs sig-libs

# ----------------------------------------------------------------------
# Build all CreTAKE implementations
# ----------------------------------------------------------------------

.PHONY: protocols
protocols: primitives
	@passed=0; \
	failed=0; \
	for d in $(CRETAKE_DIRS); do \
		echo; \
		echo "============================================================"; \
		echo "Building CreTAKE instance: $$d"; \
		echo "============================================================"; \
		if $(MAKE) --no-print-directory -C "$$d" all; then \
			echo "[BUILD PASS] $$d"; \
			passed=$$((passed + 1)); \
		else \
			status=$$?; \
			echo "[BUILD FAIL] $$d (exit code $$status)"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	echo; \
	echo "============================================================"; \
	echo "Build summary"; \
	echo "============================================================"; \
	echo "Passed: $$passed"; \
	echo "Failed: $$failed"; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Run all tests by category
#
# Order:
#   1. all test_correctness programs
#   2. all KAT_KEX programs
#   3. all test_efficiency programs
# ----------------------------------------------------------------------

.PHONY: check
check: build
	@overall_passed=0; \
	overall_failed=0; \
	for test_program in $(TEST_PROGRAMS); do \
		category_passed=0; \
		category_failed=0; \
		echo; \
		echo "################################################################"; \
		case "$$test_program" in \
			test_correctness*) \
				echo "Running all correctness tests"; \
				;; \
			KAT_KEX*) \
				echo "Running all KAT_KEX tests"; \
				;; \
			test_efficiency*) \
				echo "Running all efficiency tests"; \
				;; \
		esac; \
		echo "################################################################"; \
		for d in $(CRETAKE_DIRS); do \
			echo; \
			echo "----------------------------------------------------------------"; \
			echo "Running $$d/$$test_program"; \
			echo "----------------------------------------------------------------"; \
			if [ ! -f "$$d/$$test_program" ]; then \
				echo "[MISSING] $$d/$$test_program"; \
				category_failed=$$((category_failed + 1)); \
				overall_failed=$$((overall_failed + 1)); \
			elif (cd "$$d" && "./$$test_program"); then \
				echo "[PASS] $$d/$$test_program"; \
				category_passed=$$((category_passed + 1)); \
				overall_passed=$$((overall_passed + 1)); \
			else \
				status=$$?; \
				echo "[FAIL] $$d/$$test_program (exit code $$status)"; \
				category_failed=$$((category_failed + 1)); \
				overall_failed=$$((overall_failed + 1)); \
			fi; \
		done; \
		echo; \
		echo "================================================================"; \
		case "$$test_program" in \
			test_correctness*) \
				echo "Correctness test summary"; \
				;; \
			KAT_KEX*) \
				echo "KAT_KEX test summary"; \
				;; \
			test_efficiency*) \
				echo "Efficiency test summary"; \
				;; \
		esac; \
		echo "================================================================"; \
		echo "Passed: $$category_passed"; \
		echo "Failed: $$category_failed"; \
	done; \
	echo; \
	echo "################################################################"; \
	echo "Overall test summary"; \
	echo "################################################################"; \
	echo "Passed: $$overall_passed"; \
	echo "Failed: $$overall_failed"; \
	if [ "$$overall_failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Run all correctness tests
# ----------------------------------------------------------------------

.PHONY: correctness
correctness: build
	@passed=0; \
	failed=0; \
	program="$(TEST_CORRECTNESS)"; \
	echo; \
	echo "################################################################"; \
	echo "Running all correctness tests"; \
	echo "################################################################"; \
	for d in $(CRETAKE_DIRS); do \
		echo; \
		echo "----------------------------------------------------------------"; \
		echo "Running $$d/$$program"; \
		echo "----------------------------------------------------------------"; \
		if [ ! -f "$$d/$$program" ]; then \
			echo "[MISSING] $$d/$$program"; \
			failed=$$((failed + 1)); \
		elif (cd "$$d" && "./$$program"); then \
			echo "[PASS] $$d/$$program"; \
			passed=$$((passed + 1)); \
		else \
			status=$$?; \
			echo "[FAIL] $$d/$$program (exit code $$status)"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	echo; \
	echo "================================================================"; \
	echo "Correctness test summary"; \
	echo "================================================================"; \
	echo "Passed: $$passed"; \
	echo "Failed: $$failed"; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Run all KAT tests
# ----------------------------------------------------------------------

.PHONY: kat
kat: build
	@passed=0; \
	failed=0; \
	program="$(KAT_PROGRAM)"; \
	echo; \
	echo "################################################################"; \
	echo "Running all KAT_KEX tests"; \
	echo "################################################################"; \
	for d in $(CRETAKE_DIRS); do \
		echo; \
		echo "----------------------------------------------------------------"; \
		echo "Running $$d/$$program"; \
		echo "----------------------------------------------------------------"; \
		if [ ! -f "$$d/$$program" ]; then \
			echo "[MISSING] $$d/$$program"; \
			failed=$$((failed + 1)); \
		elif (cd "$$d" && "./$$program"); then \
			echo "[PASS] $$d/$$program"; \
			passed=$$((passed + 1)); \
		else \
			status=$$?; \
			echo "[FAIL] $$d/$$program (exit code $$status)"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	echo; \
	echo "================================================================"; \
	echo "KAT_KEX test summary"; \
	echo "================================================================"; \
	echo "Passed: $$passed"; \
	echo "Failed: $$failed"; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Run all efficiency tests
# ----------------------------------------------------------------------

.PHONY: efficiency
efficiency: build
	@passed=0; \
	failed=0; \
	program="$(TEST_EFFICIENCY)"; \
	echo; \
	echo "################################################################"; \
	echo "Running all efficiency tests"; \
	echo "################################################################"; \
	for d in $(CRETAKE_DIRS); do \
		echo; \
		echo "----------------------------------------------------------------"; \
		echo "Running $$d/$$program"; \
		echo "----------------------------------------------------------------"; \
		if [ ! -f "$$d/$$program" ]; then \
			echo "[MISSING] $$d/$$program"; \
			failed=$$((failed + 1)); \
		elif (cd "$$d" && "./$$program"); then \
			echo "[PASS] $$d/$$program"; \
			passed=$$((passed + 1)); \
		else \
			status=$$?; \
			echo "[FAIL] $$d/$$program (exit code $$status)"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	echo; \
	echo "================================================================"; \
	echo "Efficiency test summary"; \
	echo "================================================================"; \
	echo "Passed: $$passed"; \
	echo "Failed: $$failed"; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Cleaning protocol implementations
# ----------------------------------------------------------------------

.PHONY: clean-protocols
clean-protocols:
	@failed=0; \
	for d in $(CRETAKE_DIRS); do \
		echo "Cleaning protocol: $$d"; \
		if ! $(MAKE) --no-print-directory -C "$$d" clean; then \
			echo "[CLEAN FAIL] $$d"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Cleaning KEM implementations
# ----------------------------------------------------------------------

.PHONY: clean-kems
clean-kems:
	@failed=0; \
	for d in $(KEM_DIRS); do \
		echo "Cleaning KEM: $$d"; \
		if ! $(MAKE) --no-print-directory -C "$$d" distclean; then \
			echo "[CLEAN FAIL] $$d"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Cleaning signature implementations
# ----------------------------------------------------------------------

.PHONY: clean-sigs
clean-sigs:
	@failed=0; \
	for d in $(SIG_DIRS); do \
		echo "Cleaning signature: $$d"; \
		if ! $(MAKE) --no-print-directory -C "$$d" distclean; then \
			echo "[CLEAN FAIL] $$d"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

# ----------------------------------------------------------------------
# Complete cleanup
# ----------------------------------------------------------------------

.PHONY: clean
clean: clean-protocols clean-kems clean-sigs
	@echo
	@echo "Removing residual object, archive, and test executable files..."
	@find Common/primitives CreTAKE128 CreTAKE256 CreTAKE512 \
		-type f \( -name '*.o' -o -name '*.a' \) \
		-exec rm -f {} +
	@find CreTAKE128 CreTAKE256 CreTAKE512 \
		-type f \( \
			-name 'test_correctness' -o \
			-name 'test_correctness.exe' -o \
			-name 'test_efficiency' -o \
			-name 'test_efficiency.exe' -o \
			-name 'KAT_KEX' -o \
			-name 'KAT_KEX.exe' \
		\) \
		-exec rm -f {} +
	@echo "Clean completed."

# ----------------------------------------------------------------------
# Rebuild without running tests
# ----------------------------------------------------------------------

.PHONY: rebuild
rebuild:
	@$(MAKE) clean
	@$(MAKE) all

# ----------------------------------------------------------------------
# Rebuild and run all tests
# ----------------------------------------------------------------------

.PHONY: rebuild-check
rebuild-check:
	@$(MAKE) clean
	@$(MAKE) check


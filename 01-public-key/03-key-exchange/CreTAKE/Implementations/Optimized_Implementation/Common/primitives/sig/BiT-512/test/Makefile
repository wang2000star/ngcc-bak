CC = gcc
CFLAGS ?= -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wvla -Wpointer-arith -O3 -march=native -mtune=native -mavx2 -mfma
CPPFLAGS ?= -I..
SRC_DIR = ..

CORE_SRCS = $(filter-out $(SRC_DIR)/KAT_SIG.c $(SRC_DIR)/PQCgenKAT_sign.c $(SRC_DIR)/rng.c $(SRC_DIR)/ntt.c $(SRC_DIR)/ntt_ref.c, $(wildcard $(SRC_DIR)/*.c))
CORE_SRCS := $(filter-out $(SRC_DIR)/packing.c, $(CORE_SRCS)) $(SRC_DIR)/packing.c
CORE_OBJS = $(CORE_SRCS:.c=.o) $(SRC_DIR)/ntt.o $(SRC_DIR)/intt.o $(SRC_DIR)/pointwise.o $(SRC_DIR)/f1600x4.o

SPEED_HELPERS = cpucycles.c speed_print.c
SPEED_BIN   = test_speed
BENCH_BIN   = test_bench
CORRECT_BIN = test_correctness
DIAG_BIN    = diagnose_ntt

all: test

test: $(CORRECT_BIN)
	./$(CORRECT_BIN)

speed: $(SPEED_BIN)
	./$(SPEED_BIN)

bench: $(BENCH_BIN)
	./$(BENCH_BIN)

reject-rate: $(REJECT_BIN)
	./$(REJECT_BIN)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(SRC_DIR)/f1600x4.o: $(SRC_DIR)/f1600x4.S
	$(CC) -x assembler-with-cpp $(CFLAGS) -c $< -o $@

$(SRC_DIR)/%.o: $(SRC_DIR)/%.S
	$(CC) -x assembler-with-cpp $(CFLAGS) -c $< -o $@

$(CORRECT_BIN): test_correctness.c test_common.h $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) test_correctness.c $(CORE_OBJS) -o $@

$(SPEED_BIN): test_speed.c $(SPEED_HELPERS) $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) test_speed.c $(SPEED_HELPERS) $(CORE_OBJS) -o $@

$(BENCH_BIN): test_bench.c test_common.h $(SPEED_HELPERS) $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) test_bench.c $(SPEED_HELPERS) $(CORE_OBJS) -o $@


diag: $(DIAG_BIN)
	./$(DIAG_BIN)

$(DIAG_BIN): diagnose_ntt.c $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) diagnose_ntt.c $(CORE_OBJS) -o $@


profile: $(PROFILE_BIN)
	./$(PROFILE_BIN)


clean:
	rm -f $(CORRECT_BIN) $(SPEED_BIN) $(BENCH_BIN) $(REJECT_BIN) $(DIAG_BIN) $(PROFILE_BIN)
	rm -f $(CORE_OBJS)

.PHONY: all test speed bench reject-rate diag clean

CC = gcc
CFLAGS ?= -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wvla -Wpointer-arith -O3 -march=native -mtune=native
CPPFLAGS ?= -I..
SRC_DIR = ..

CORE_SRCS = $(wildcard $(SRC_DIR)/*.c)
CORE_SRCS := $(filter-out $(SRC_DIR)/KAT_SIG.c $(SRC_DIR)/PQCgenKAT_sign.c $(SRC_DIR)/rng.c, $(CORE_SRCS))
CORE_SRCS := $(filter-out $(SRC_DIR)/packing.c, $(CORE_SRCS)) $(SRC_DIR)/packing.c
CORE_OBJS = $(CORE_SRCS:.c=.o)

SPEED_HELPERS = cpucycles.c speed_print.c
SPEED_BIN   = test_speed
BENCH_BIN   = test_bench
CORRECT_BIN = test_correctness
HINT_STATS_BIN = hint_stats
REJECT_STATS_BIN = test_reject_stats

all: test

test: $(CORRECT_BIN)
	./$(CORRECT_BIN)

speed: $(SPEED_BIN)
	./$(SPEED_BIN)

bench: $(BENCH_BIN)
	./$(BENCH_BIN)

reject-rate: reject-stats

hint-stats: $(HINT_STATS_BIN)
	./$(HINT_STATS_BIN)

reject-stats: $(REJECT_STATS_BIN)
	./$(REJECT_STATS_BIN) $(ARGS)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(CORRECT_BIN): test_correctness.c test_common.h $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) test_correctness.c $(CORE_OBJS) -o $@

$(SPEED_BIN): test_speed.c $(SPEED_HELPERS) $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) test_speed.c $(SPEED_HELPERS) $(CORE_OBJS) -o $@

$(BENCH_BIN): test_bench.c test_common.h $(SPEED_HELPERS) $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) test_bench.c $(SPEED_HELPERS) $(CORE_OBJS) -o $@


$(HINT_STATS_BIN): hint_stats.c $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) hint_stats.c $(CORE_OBJS) -o $@

$(REJECT_STATS_BIN): test_reject_stats.c $(CORE_OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) -DBIT_LEVEL_NAME='"BiT-256"' test_reject_stats.c $(CORE_OBJS) -o $@

clean:
	rm -f $(CORRECT_BIN) $(SPEED_BIN) $(BENCH_BIN) $(REJECT_BIN) $(HINT_STATS_BIN) $(REJECT_STATS_BIN)
	rm -f $(CORE_OBJS)

.PHONY: all test speed bench reject-rate hint-stats reject-stats clean

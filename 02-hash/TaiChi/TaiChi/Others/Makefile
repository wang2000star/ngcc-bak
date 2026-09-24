CC = gcc
CFLAGS = -std=c99 -Wpedantic -Wall -Wextra -O2

BIN_DIR = bin

OPT_BINS = \
    $(BIN_DIR)/TaiChi-512-op-per \
    $(BIN_DIR)/TaiChi-768-op-per \
    $(BIN_DIR)/TaiChi-1024-op-per \
	$(BIN_DIR)/TaiChi-512-op-res \
    $(BIN_DIR)/TaiChi-768-op-res \
    $(BIN_DIR)/TaiChi-1024-op-res

REF_BINS = \
    $(BIN_DIR)/TaiChi-512 \
    $(BIN_DIR)/TaiChi-768 \
    $(BIN_DIR)/TaiChi-1024

ALL_BINS = $(OPT_BINS) $(REF_BINS)

all: $(BIN_DIR) $(ALL_BINS) chmod_exec

chmod_exec:
	chmod +x run.sh
	chmod +x $(BIN_DIR)/*

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/TaiChi-512-op-per:
	$(CC) $(CFLAGS) \
	Implementations/Optimized_Implementation/TaiChi-512-op-per/*.c \
	-o $@

$(BIN_DIR)/TaiChi-768-op-per:
	$(CC) $(CFLAGS) \
	Implementations/Optimized_Implementation/TaiChi-768-op-per/*.c \
	-o $@

$(BIN_DIR)/TaiChi-1024-op-per:
	$(CC) $(CFLAGS) \
	Implementations/Optimized_Implementation/TaiChi-1024-op-per/*.c \
	-o $@

$(BIN_DIR)/TaiChi-512-op-res:
	$(CC) $(CFLAGS) \
	Implementations/Optimized_Implementation/TaiChi-512-op-res/*.c \
	-o $@

$(BIN_DIR)/TaiChi-768-op-res:
	$(CC) $(CFLAGS) \
	Implementations/Optimized_Implementation/TaiChi-768-op-res/*.c \
	-o $@

$(BIN_DIR)/TaiChi-1024-op-res:
	$(CC) $(CFLAGS) \
	Implementations/Optimized_Implementation/TaiChi-1024-op-res/*.c \
	-o $@

$(BIN_DIR)/TaiChi-512:
	$(CC) $(CFLAGS) \
	Implementations/Reference_Implementation/TaiChi-512/*.c \
	-o $@

$(BIN_DIR)/TaiChi-768:
	$(CC) $(CFLAGS) \
	Implementations/Reference_Implementation/TaiChi-768/*.c \
	-o $@

$(BIN_DIR)/TaiChi-1024:
	$(CC) $(CFLAGS) \
	Implementations/Reference_Implementation/TaiChi-1024/*.c \
	-o $@

clean:
	rm -rf $(BIN_DIR)
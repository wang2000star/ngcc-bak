# ====================================================================
# Garnet 算法 QEMU-ARM 用户态多功能测试版 Makefile
# ====================================================================

# 1. 工具链配置
CC = arm-linux-gnueabihf-gcc
CXX = arm-linux-gnueabihf-g++
QEMU = qemu-arm

# 2. 编译选项
# 开启所有算法变体宏，确保 main_bench.cpp 能跑全量测试
DEFINES = -DENABLE_GARNET_512_W512 -DENABLE_GARNET_512_W640 -DENABLE_GARNET_1024_W1024

CFLAGS = -mthumb -O3 -g $(DEFINES)
CXXFLAGS = -mthumb -O3 -g -static -std=c++11 $(DEFINES)

# 3. 目标文件
TARGET_DEMO = garnet_demo.elf
TARGET_KAT  = garnet_kat.elf
OBJS_COMMON = hash_garnet_universal.o

# 默认构建两个目标
all: $(TARGET_DEMO) $(TARGET_KAT)

# 编译纯 C 算法（供 C++ 链接）
%.o: %.c hash_garnet.h aesT.h
	$(CC) $(CFLAGS) -c $< -o $@

# 目标 1：演示程序 (main.cpp)
$(TARGET_DEMO): main.cpp $(OBJS_COMMON)
	$(CXX) $(CXXFLAGS) $^ -o $@

# --- 运行指令 ---

# 运行基础 Demo
run: $(TARGET_DEMO)
	@echo ">>> Running Demo..."
	$(QEMU) ./$(TARGET_DEMO)

clean:
	rm -f *.o *.elf 
.PHONY: all run gen test clean
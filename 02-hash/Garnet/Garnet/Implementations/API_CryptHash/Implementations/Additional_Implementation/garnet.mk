##############################################################################
# Garnet Crypto Module Makefile Fragment
##############################################################################

# 1. 添加源文件 (路径相对于根目录 Makefile)
C_SOURCES += \
Garnet_Crypto/hash_garnet_universal.c \
Garnet_Crypto/garnet_app_freeRTOS.c

# 2. 添加头文件包含路径
C_INCLUDES += \
-IGarnet_Crypto

# 3. 可选：针对该模块的特定编译定义 (例如开启 512 位版本)
# C_DEFS += -DENABLE_GARNET_512_W1024
LDFLAGS += -u _printf_float
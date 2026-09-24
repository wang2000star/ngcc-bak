CC ?= /usr/bin/cc
CFLAGS += -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wvla -Wpointer-arith -O3 -fomit-frame-pointer

# KATFLAGS 替代了原来的 NISTFLAGS，不需要再链接 -lcrypto (OpenSSL)
KATFLAGS += -Wno-unused-result -O3 -fomit-frame-pointer

# 1. 更新底层源文件：加入了 drng.c 和 auxfunc.c，保留了你包装好的 symmetric-shake.c
SOURCES = sign.c packing.c polyvec.c poly.c ntt.c reduce.c rounding.c \
          symmetric-shake.c drng.c auxfunc.c fips202.c randombytes.c
HEADERS = config.h params.h api.h sign.h packing.h polyvec.h poly.h ntt.h \
          reduce.h rounding.h symmetric.h drng.h auxfunc.h fips202.h randombytes.h

# 2. 官方 KAT 测试代码源文件
KAT_SOURCES = KAT_SIG.c SIG_AlgorithmInstance.c
KAT_HEADERS = SIG_AlgorithmInstance.h

.PHONY: all speed shared clean kat

all: \
  test/test_COMPASS_SIG_128 \
  test/test_COMPASS_SIG_256 \
  test/test_COMPASS_SIG_384 \
  test/test_COMPASS_SIG_512

# 3. 将 nistkat 替换为国密要求的 kat
kat: \
  test/test_kat128 \
  test/test_kat256 \
  test/test_kat384 \
  test/test_kat512

speed: \
  test/test_mul \
  test/test_speed128 \
  test/test_speed256 \
  test/test_speed384 \
  test/test_speed512 \

shared: \
  libpqcrystals_COMPASS_SIG128_ref.so \
  libpqcrystals_COMPASS_SIG256_ref.so \
  libpqcrystals_COMPASS_SIG384_ref.so \
  libpqcrystals_COMPASS_SIG512_ref.so \

# ==========================================
# 动态库编译 (移除了旧的 fips202)
# ==========================================
libpqcrystals_COMPASS_SIG128_ref.so: $(SOURCES) $(HEADERS)
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=128 -o $@ $(SOURCES)

libpqcrystals_COMPASS_SIG256_ref.so: $(SOURCES) $(HEADERS)
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=256 -o $@ $(SOURCES)

libpqcrystals_COMPASS_SIG384_ref.so: $(SOURCES) $(HEADERS)
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=384 -o $@ $(SOURCES)

libpqcrystals_COMPASS_SIG512_ref.so: $(SOURCES) $(HEADERS)
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=512 -o $@ $(SOURCES)

# ==========================================
# 普通正确性测试编译
# ==========================================
test/test_COMPASS_SIG_128: test/test_COMPASS_SIG.c  $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=128 -o $@ $<  $(SOURCES)

test/test_COMPASS_SIG_256: test/test_COMPASS_SIG.c  $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=256 -o $@ $<  $(SOURCES)

test/test_COMPASS_SIG_384: test/test_COMPASS_SIG.c  $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=384 -o $@ $<  $(SOURCES)

test/test_COMPASS_SIG_512: test/test_COMPASS_SIG.c $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=512 -o $@ $<  $(SOURCES)

# ==========================================
# 速度测试编译
# ==========================================
test/test_speed128: test/test_speed.c test/speed_print.c test/speed_print.h \
  test/cpucycles.c test/cpucycles.h  $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=128 \
	  -o $@ $< test/speed_print.c test/cpucycles.c  $(SOURCES)

test/test_speed256: test/test_speed.c test/speed_print.c test/speed_print.h \
  test/cpucycles.c test/cpucycles.h  $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=256 \
	  -o $@ $< test/speed_print.c test/cpucycles.c  $(SOURCES)

test/test_speed384: test/test_speed.c test/speed_print.c test/speed_print.h \
  test/cpucycles.c test/cpucycles.h $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=384 \
	  -o $@ $< test/speed_print.c test/cpucycles.c $(SOURCES)

test/test_speed512: test/test_speed.c test/speed_print.c test/speed_print.h \
  test/cpucycles.c test/cpucycles.h  $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=512 \
	  -o $@ $< test/speed_print.c test/cpucycles.c  $(SOURCES)

test/test_mul: test/test_mul.c  $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS) -UDBENCH -o $@ $<  $(SOURCES)

# ==========================================
# 国密 NGCC KAT 生成测试编译
# ==========================================
test/test_kat128: $(KAT_SOURCES) $(KAT_HEADERS) $(SOURCES) $(HEADERS)
	$(CC) $(KATFLAGS) -DCOMPASS_SIG_MODE=128 -o $@ $(KAT_SOURCES) $(SOURCES)

test/test_kat256: $(KAT_SOURCES) $(KAT_HEADERS) $(SOURCES) $(HEADERS)
	$(CC) $(KATFLAGS) -DCOMPASS_SIG_MODE=256 -o $@ $(KAT_SOURCES) $(SOURCES)

test/test_kat384: $(KAT_SOURCES) $(KAT_HEADERS) $(SOURCES) $(HEADERS)
	$(CC) $(KATFLAGS) -DCOMPASS_SIG_MODE=384 -o $@ $(KAT_SOURCES) $(SOURCES)

test/test_kat512: $(KAT_SOURCES) $(KAT_HEADERS) $(SOURCES) $(HEADERS)
	$(CC) $(KATFLAGS) -DCOMPASS_SIG_MODE=512 -o $@ $(KAT_SOURCES) $(SOURCES)

clean:
	rm -f *~ test/*~ *.gcno *.gcda *.lcov
	rm -f libpqcrystals_COMPASS_SIG128_ref.so
	rm -f libpqcrystals_COMPASS_SIG256_ref.so
	rm -f libpqcrystals_COMPASS_SIG384_ref.so
	rm -f libpqcrystals_COMPASS_SIG512_ref.so
	rm -f test/test_COMPASS_SIG_*
	rm -f test/test_speed*
	rm -f test/test_mul
	rm -f test/test_kat*
	rm -rf output/
CXX := g++
CC := gcc
CXXFLAGS := -O3 -std=c++17 -Wall -Wextra -march=native -mavx2
CFLAGS := -O3 -std=c99 -Wall -Wextra -march=native -mavx2
LDFLAGS :=
LDLIBS := -lcrypto

COMMON_SRCS := P.cpp chime512.cpp
COMMON_OBJS := $(COMMON_SRCS:.cpp=.o)

TEST_SRCS := main.cpp
TEST_OBJS := $(TEST_SRCS:.cpp=.o)

BENCH_SRCS := throughput.cpp sha512.cpp
BENCH_OBJS := $(BENCH_SRCS:.cpp=.o)

GEN_TEST_VECS_SRCS := CryptHash_AlgorithmInstance.c drng.c KAT_CryptHash.c P.cpp sha512.cpp chime512.cpp
GEN_TEST_VECS_OBJS := CryptHash_AlgorithmInstance.o drng.o KAT_CryptHash.o P.o sha512.o chime512.o

TARGETS := test bench gen_test_vecs

.PHONY: all clean

all: $(TARGETS)

test: $(COMMON_OBJS) $(TEST_OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

bench: $(COMMON_OBJS) $(BENCH_OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

gen_test_vecs: $(GEN_TEST_VECS_OBJS) $(GEN_TEST_VECS_SRCS) CryptHash_AlgorithmInstance.h drng.h P.hpp sha_openssl.h sha512.h chime512.hpp
	$(CXX) $(CXXFLAGS) -o $@ $(GEN_TEST_VECS_OBJS) $(LDFLAGS) $(LDLIBS)

%.o: %.cpp P.hpp chime512.hpp chime1024.hpp
	$(CXX) $(CXXFLAGS) -c $< -o $@ $(LDLIBS)

sha512.o: sha512.cpp sha512.h sha_openssl.h
	$(CXX) $(CXXFLAGS) -c $< -o $@ $(LDLIBS)

CryptHash_AlgorithmInstance.o: CryptHash_AlgorithmInstance.c CryptHash_AlgorithmInstance.h chime512.hpp P.hpp
	$(CXX) $(CXXFLAGS) -c $< -o $@ $(LDLIBS)

%.o: %.c CryptHash_AlgorithmInstance.h drng.h
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGETS) *.o
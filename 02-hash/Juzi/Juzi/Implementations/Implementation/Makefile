# Top-level Makefile for JuziHash implementation package.
# Run from the Implementations directory.

.PHONY: all reference optimized clean kat-reference kat-optimized kat-all

REF512 := Reference_Implementation/JuziHash-512
REF1024 := Reference_Implementation/JuziHash-1024
OPT512 := Optimized_Implementation/JuziHash-512
OPT1024 := Optimized_Implementation/JuziHash-1024

all: reference optimized

reference:
	$(MAKE) -C $(REF512) all
	$(MAKE) -C $(REF1024) all

optimized:
	$(MAKE) -C $(OPT512) all
	$(MAKE) -C $(OPT1024) all

# KAT generation may take a long time, especially the large ICCS tests.
kat-reference:
	$(MAKE) -C $(REF512) kat
	$(MAKE) -C $(REF1024) kat

kat-optimized:
	$(MAKE) -C $(OPT512) kat
	$(MAKE) -C $(OPT1024) kat

kat-all: kat-reference kat-optimized

clean:
	$(MAKE) -C $(REF512) clean
	$(MAKE) -C $(REF1024) clean
	$(MAKE) -C $(OPT512) clean
	$(MAKE) -C $(OPT1024) clean

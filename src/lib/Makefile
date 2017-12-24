all: rp-daq-lib.c rp-daq-lib.h
	mkdir -p ../../build/lib/
	gcc -lm -c -O3 -Wall -fpic -ftree-vectorize rp-daq-lib.c -o ../../build/lib/rp-daq-lib.o
	gcc -lm -O3 -shared -o ../../build/lib/librp-daq.so ../../build/lib/rp-daq-lib.o
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./

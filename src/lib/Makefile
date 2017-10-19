all: rp-daq-lib.c rp-daq-lib.h
	mkdir -p ../../build/lib/
	gcc -lm -c -g -Wall -fpic rp-daq-lib.c -o ../../build/lib/rp-daq-lib.o
	gcc -lm -g -shared -o ../../build/lib/librp-daq.so ../../build/lib/rp-daq-lib.o
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./

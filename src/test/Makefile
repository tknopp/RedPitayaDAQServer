all: rp-instrument-configuration.c testSlowIO.c
	mkdir -p ../../build/test/
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./
	gcc -lm rp-instrument-configuration.c ../../build/lib/rp-daq-lib.o -o rp-instrument-configuration
	gcc -lm testSlowIO.c ../../build/lib/rp-daq-lib.o -o testSlowIO

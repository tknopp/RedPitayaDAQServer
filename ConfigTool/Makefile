all: rp-instrument-lib.c rp-instrument-lib.h
	gcc -lm -c -Wall -Werror -fpic rp-instrument-lib.c
	gcc -lm -shared -o rp-instrument-lib.so rp-instrument-lib.o
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./
	gcc -lm rp-instrument-configuration.c rp-instrument-lib.o -o rp-instrument-configuration
	rm *.o

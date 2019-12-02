CFLAGS  = -O3 -std=gnu99
CFLAGS +=
LDFLAGS = /root/apps/RedPitayaDAQServer/build/lib/librp-daq.so
LDLIBS = -lm -lpthread -lscpi

all: test_trigger.c
	mkdir -p ../../build/test/
	gcc $(CFLAGS) test_trigger.c $(LDFLAGS) $(LDLIBS) -o ../../build/test/test_trigger

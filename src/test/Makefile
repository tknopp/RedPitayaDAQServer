CFLAGS  = -O3 -std=gnu99 -g
CFLAGS += -I/opt/redpitaya/include
LDFLAGS = /root/RedPitayaDAQServer/build/lib/librp-daq.so
LDLIBS = -lm -lpthread -lscpi

all: test_trigger.c
	mkdir -p ../../build/server/
	gcc $(CFLAGS) test_trigger.c $(LDFLAGS) $(LDLIBS) -o ../../build/test/test_trigger

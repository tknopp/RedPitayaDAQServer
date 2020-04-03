CFLAGS  = -O3 -std=gnu99
CFLAGS +=
LDFLAGS = /root/apps/RedPitayaDAQServer/build/lib/librp-daq.so
LDLIBS = -lm -lpthread #-lscpi 

all: test_trigger test_wp test_wp_trigger

test_trigger: test_trigger.c
	mkdir -p ../../build/test/
	gcc $(CFLAGS) test_trigger.c $(LDFLAGS) $(LDLIBS) -o ../../build/test/test_trigger

test_wp: test_wp.c
	mkdir -p ../../build/test/
	gcc $(CFLAGS) test_wp.c $(LDFLAGS) $(LDLIBS) -o ../../build/test/test_wp

test_wp_trigger: test_wp_trigger.c
	mkdir -p ../../build/test/
	gcc $(CFLAGS) test_wp_trigger.c $(LDFLAGS) $(LDLIBS) -o ../../build/test/test_wp_trigger

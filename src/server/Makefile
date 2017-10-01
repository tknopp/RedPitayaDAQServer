CFLAGS  = -O3 -std=gnu99
CFLAGS += -I/opt/redpitaya/include
LDFLAGS = -L/root/RedPitayaDAQServer/build/lib
LDLIBS = -lm -lpthread  -lrp-daq

all: daq_server.c
	mkdir -p ../../build/server/
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./
	gcc $(CFLAGS) $(LDLIBS) daq_server.c $(LDFLAGS) -o ../../build/server/daq_server

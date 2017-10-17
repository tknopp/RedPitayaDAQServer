CFLAGS  = -O3 -std=gnu99
CFLAGS += -I/opt/redpitaya/include
LDFLAGS = /root/RedPitayaDAQServer/build/lib/librp-daq.so
LDLIBS = -lm -lpthread -lscpi

all: daq_server.c
	mkdir -p ../../build/server/
	#gcc $(CFLAGS) daq_server.c $(LDFLAGS) $(LDLIBS) -o ../../build/server/daq_server
	gcc $(CFLAGS) daq_server_scpi.c scpi_commands.c $(LDFLAGS) $(LDLIBS) -o ../../build/server/daq_server_scpi

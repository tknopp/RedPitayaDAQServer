CFLAGS  =  -std=gnu99 -O3
CFLAGS += 
LDFLAGS = /root/apps/RedPitayaDAQServer/build/lib/librp-daq.so
LDLIBS = -lm -lpthread -lscpi

all: daq_server.c
	mkdir -p ../../build/server/
	gcc $(CFLAGS) daq_server_scpi.c scpi_commands.c $(LDFLAGS) $(LDLIBS) -o ../../build/server/daq_server_scpi

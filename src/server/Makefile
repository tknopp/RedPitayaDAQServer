CFLAGS  =  -std=gnu99 -O3
CFLAGS += -I../../libs/scpi-parser/libscpi/inc/ 
LDFLAGS = /root/apps/RedPitayaDAQServer/build/lib/librp-daq.so -L../../libs/scpi-parser/libscpi/dist/
LDLIBS = -lm -lpthread -lscpi

all: daq_server_scpi.c
	mkdir -p ../../build/server/
	gcc $(CFLAGS) daq_server_scpi.c scpi_commands.c control.c communication.c $(LDFLAGS) $(LDLIBS) -o ../../build/server/daq_server_scpi

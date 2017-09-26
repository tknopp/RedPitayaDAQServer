CFLAGS  = -O3 -std=gnu99 
CFLAGS += -I/opt/redpitaya/include
LDFLAGS = -L/opt/redpitaya/lib 
LDLIBS = -lm -lpthread -lrp ../../build/lib/rp-daq-lib.so

SRCS=$(wildcard *.c)
OBJS=$(SRCS:.c=)

all: $(OBJS)

%.o: %.c
	$(CC) -c $(CFLAGS)  $< -o $@

clean:
	$(RM) *.o
	$(RM) $(OBJS)

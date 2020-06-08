SRC=pb.c

TARGET=pb.so
CFLAGS=-I/usr/local/include -std=gnu11
LDFLAGS=-L/usr/local/lib

all:$(TARGET)

$(TARGET):$(SRC)
	gcc -O3 -shared -fPIC $(SRC) $(CFLAGS) $(LDFLAGS) -o $@

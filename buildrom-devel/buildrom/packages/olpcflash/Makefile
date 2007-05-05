CC=gcc
CFLAGS_extra= -Wall
LDFLAGS_extra=

olpcflash: olpcflash.c
	$(CC) $(CFLAGS) $(CFLAGS_extra) $(LDFLAGS) $(LDFLAGS_extra) -o $@ olpcflash.c $(LIBS)

clean:
	rm -f olpcflash

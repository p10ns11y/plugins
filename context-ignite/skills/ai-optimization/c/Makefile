CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -O2

.PHONY: all clean

all: context-sage-c

context-sage-c: context_sage.c
	$(CC) $(CFLAGS) -o $@ context_sage.c

clean:
	rm -f context-sage-c

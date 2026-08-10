# eva-tether — secure EVA permission classifier (C11)
# Output: ../bin/eva-tether

CC       ?= cc
CFLAGS   ?= -std=c11 -Wall -Wextra -Werror -Wconversion -Wshadow -O2
CPPFLAGS ?= -I.
LDFLAGS  ?=
PREFIX_BIN ?= ../bin
TARGET   := $(PREFIX_BIN)/eva-tether

.PHONY: all clean install test

all: $(TARGET)

$(TARGET): eva_tether.c main.c eva_tether.h
	@mkdir -p $(PREFIX_BIN)
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ eva_tether.c main.c $(LDFLAGS)

clean:
	rm -f $(TARGET)

install: all

test: all
	@../test/test-eva-tether.sh

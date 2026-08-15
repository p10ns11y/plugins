# mm-kern — PERT / MC / grad leaf math (C11)

CC       ?= cc
CFLAGS   ?= -std=c11 -Wall -Wextra -Werror -Wconversion -Wshadow -O2
CPPFLAGS ?= -I.
LDFLAGS  ?= -lm
PREFIX_BIN ?= ../bin
TARGET   := $(PREFIX_BIN)/mm-kern

.PHONY: all clean test

all: $(TARGET)

$(TARGET): mm_pert.c mm_mc.c mm_grad.c main.c mm_pert.h mm_mc.h mm_grad.h mm_status.h
	@mkdir -p $(PREFIX_BIN)
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ mm_pert.c mm_mc.c mm_grad.c main.c $(LDFLAGS)

clean:
	rm -f $(TARGET)

test: all
	@../test/test-kern.sh

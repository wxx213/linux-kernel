ifeq ($(O), )
O := .
endif
$(shell mkdir -p $(O))

all: kvmsample test.bin

kvmsample: main.c
	gcc main.c -o $(O)/kvmsample -lpthread

test.bin: test.o
	ld -m elf_i386 --oformat binary -N -e _start -Ttext 0x0 -o $(O)/test.bin $(O)/test.o

test.o: test.S
	as --32 test.S -o $(O)/test.o

clean:
	rm  $(O)/test.o $(O)/kvmsample $(O)/test.bin

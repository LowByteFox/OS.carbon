CARBON  ?= carbon
LD      ?= ld
OBJCOPY ?= objcopy
ASM     := nasm

ASMFLAGS := -f elf64
CFLAGS   := -ffreestanding -m64 -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -O2 -Wall -Wextra
LDFLAGS  := -n -T linker.ld

ASM_OBJS := arch/x86_64/boot.o
C_OBJS   := kernel/main.o
OBJS     := $(ASM_OBJS) $(C_OBJS)

ELF_TARGET := kernel.elf
TARGET     := kernel.bin

all: $(TARGET)

arch/x86_64/boot.o: arch/x86_64/boot.s
	$(ASM) $(ASMFLAGS) $< -o $@

kernel/main.o: kernel/main.carbon
	$(CARBON) compile --target=x86_64-elf $< --output=$@ -- $(CFLAGS)

$(ELF_TARGET): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(TARGET): $(ELF_TARGET)
	$(OBJCOPY) -O elf32-i386 $< $@

run: $(TARGET)
	qemu-system-x86_64 -kernel $(TARGET)

clean:
	rm -f $(OBJS) $(ELF_TARGET) $(TARGET)

.PHONY: all run clean

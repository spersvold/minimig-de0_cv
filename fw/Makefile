# MINIMIG-DE1
# ctrl boot firmware
# 2012, rok.krajnc@gmail.com

### paths ###
HEX2MEM_DIR = ../sw/hex2mem/
HEX2MIF_DIR = ../sw/hex2mif/

### OR32 toolchain ###

# make sure or32-elf-gcc is in path, or comment next line and set path
OR32_TOOLCHAIN_PATH=

ifndef OR32_TOOLCHAIN_PATH
OR32_TOOLCHAIN_PATH=/opt/or32-elf-1.0rc1/bin/
endif

ifndef CROSS_COMPILE
CROSS_COMPILE = $(OR32_TOOLCHAIN_PATH)or32-elf-
endif

# programs
AS      = $(CROSS_COMPILE)as
LD      = $(CROSS_COMPILE)ld
CC      = $(CROSS_COMPILE)gcc
AR      = $(CROSS_COMPILE)ar
NM      = $(CROSS_COMPILE)nm
STRIP   = $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
RANLIB  = $(CROSS_COMPILE)ranlib
XXD     = xxd
HEX2MEM = $(HEX2MEM_DIR)hex2mem.py
HEX2MIF = $(HEX2MIF_DIR)hex2mif.py

BINDIR=bin
OBJDIR=obj

# flags
CFLAGS +=   -W -Winline -std=gnu99 -g \
            -Os \
            -fomit-frame-pointer -ffreestanding -static -combine -fwhole-program \
            -fno-strict-aliasing \
            -fno-builtin -nostdlib \
            -Wl,--relax \
            -msoft-mul -msoft-div -DSWAP

XXDFLAGS =-ps -c 4
HEXFLAGS =-w 8 -s 1024 -n

### fw specific ###

# include dirs
CINCLUDES += -I. -I./include

###
### Stage 1
###

STAGE1_ASM_SOURCES=start_stage1.S

STAGE1_KLIBC_SOURCES=klibc/strncmp.c

STAGE1_COMMON_SOURCES=main_stage1.c hardware.c swap.c mmc.c fat.c

STAGE1_SOURCES=$(STAGE1_ASM_SOURCES) $(STAGE1_KLIBC_SOURCES) $(STAGE1_COMMON_SOURCES)

###
### Stage 2
###

STAGE2_ASM_SOURCES=start.S

STAGE2_KLIBC_SOURCES=klibc/memcmp.c klibc/memcpy.c klibc/memset.c klibc/printf.c klibc/sprintf.c klibc/strcat.c klibc/strchr.c klibc/strcpy.c klibc/strlen.c klibc/strncat.c klibc/strncmp.c klibc/strncpy.c klibc/vsnprintf.c

STAGE2_COMMON_SOURCES=hardware.c boot.c config.c fat.c fdd.c fpga.c hdd.c main.c menu.c mmc.c osd.c rafile.c swap.c serial.c

STAGE2_SOURCES=$(STAGE2_ASM_SOURCES) $(STAGE2_KLIBC_SOURCES) $(STAGE2_COMMON_SOURCES)

### build rules ###

STAGE1_TARGET=ctrl_boot
STAGE2_TARGET=de0_boot

# all
.PHONY: all
all: stage1 stage2

.PHONY: stage1
stage1: $(BINDIR) $(BINDIR)/$(STAGE1_TARGET).v $(BINDIR)/$(STAGE1_TARGET).mif $(BINDIR)/$(STAGE1_TARGET).hex

.PHONY: stage2
stage2: $(BINDIR) $(BINDIR)/$(STAGE2_TARGET).bin $(BINDIR)/$(STAGE2_TARGET).hex

# stage1 OR32 object file output
$(BINDIR)/$(STAGE1_TARGET).or32: Makefile rom.ld $(STAGE1_SOURCES)
	@echo Making ROM image ...
	@echo $@
	@$(CC) -Wl,-Map,$(@:.or32=.map) $(CFLAGS) -DSTAGE1 $(CINCLUDES) $(STAGE1_SOURCES) -Trom.ld -o $@
	@$(OBJDUMP) -DSx $@ > $(@:.or32=.dis.S)

# stage2 OR32 object file output
$(BINDIR)/$(STAGE2_TARGET).or32: Makefile ram.ld $(STAGE2_SOURCES)
	@echo Making RAM image ...
	@echo $@
	@$(CC) -Wl,-Map,$(@:.or32=.map) $(CFLAGS) -DSWAP_MACROS $(CINCLUDES) $(STAGE2_SOURCES) -Tram.ld -o $@
	@$(OBJDUMP) -DSx $@ > $(@:.or32=.dis.S)

# bin file
$(BINDIR)/%.bin: $(BINDIR)/%.or32
	@echo $@
	@$(OBJCOPY) -O binary $< $@

$(BINDIR)/%.hex : $(BINDIR)/%.bin
	@echo $@
	@$(XXD) $(XXDFLAGS) $(@:.hex=.bin) > $@

$(BINDIR)/%.v : $(BINDIR)/%.hex
	@echo $@
	@$(HEX2MEM) $(HEXFLAGS) $(@:.v=.hex) $@

$(BINDIR)/%.mif : $(BINDIR)/%.hex
	@echo $@
	@$(HEX2MIF) $(@:.mif=.hex) $@

$(BINDIR):
	@mkdir -p $(BINDIR)

.PHONY: clean
clean:
	@echo clean
	@rm -rf ./bin


###############################################################################
# File: Makefile
# Description: CDFJ+ Template Makefile - staged/portable build
# (C) Copyright 2017 - Chris Walton, Fred Quimby, Darrell Spice Jr
# Additions by Craig Daniels - Gamax Software - 2026
###############################################################################

# -----------------------------------------------------------------------------
# IMPORTANT BUILD IDEA
# -----------------------------------------------------------------------------
# The final ROM needs main/bin/testarm.bin because the DASM source INCBINs it.
# The ARM/C code needs main/defines_dasm.h because it includes DASM-generated
# labels/constants.
#
# So a clean build must be done in stages:
#   1. prep              - build tools if needed, create folders, create dummy ARM bin
#   2. bootstrap_defines - run DASM once using the dummy ARM bin, generate defines_dasm.h
#   3. arm              - compile/link ARM C, produce the real testarm.bin
#   4. final            - run DASM again, now with the real testarm.bin
#
# .NOTPARALLEL prevents make -j from trying to do these stages out of order.
# -----------------------------------------------------------------------------

.NOTPARALLEL:

.DEFAULT_GOAL := default

# Tool names
TOOLCHAIN = arm-none-eabi
CC        = $(TOOLCHAIN)-gcc
AS        = $(TOOLCHAIN)-as
LD        = $(TOOLCHAIN)-ld
OBJCOPY   = $(TOOLCHAIN)-objcopy
SIZE      = $(TOOLCHAIN)-size

DASM	  = dasm    # replace/modify path if DASM is not in your system PATH


REQUIRED_TOOLS = $(DASM) gcc $(CC) $(OBJCOPY) $(SIZE) grep awk

check-tools:
	@for tool in $(REQUIRED_TOOLS); do \
		command -v $$tool >/dev/null 2>&1 || { \
			echo "!!! MISSING TOOL: $$tool !!!"; \
			echo "Install it or make sure it is in PATH."; \
			exit 1; \
		}; \
	done

# TV_MODE: 0 = PAL60, 1 = NTSC
TV_MODE = 1

# Dirs/files
SOURCE = cdfj+_template
BASE   = main
SRC    = $(BASE)/custom
BIN    = $(BASE)/bin
OUTPUT = ./output

EXEEXT =
ifeq ($(OS),Windows_NT)
EXEEXT = .exe
endif

CSTART_EXE = c_start$(EXEEXT)
CSTART_SRC = c_start.c

WAV2RAW_EXE = wav2raw2600$(EXEEXT)
WAV2RAW_SRC = wav2raw2600.c

DASM_TO_C = defines_dasm.h

# C Compiler flags
INCLUDES = -I.
OPTIMIZATION = -Os
CFLAGS = -mcpu=arm7tdmi -march=armv4t -mthumb
CFLAGS += -Wall -ffunction-sections
CFLAGS += $(OPTIMIZATION) $(INCLUDES)
CFLAGS += -Wl,--build-id=none
CFLAGS += -Wno-unused-function

# Search path
VPATH += $(BASE):$(SRC)

# ARM/C output
CUSTOMNAME    = testarm
CUSTOMELF     = $(BIN)/$(CUSTOMNAME).elf
CUSTOMBIN     = $(BIN)/$(CUSTOMNAME).bin
CUSTOMMAP     = $(BIN)/$(CUSTOMNAME).map
CUSTOMLST     = $(BIN)/$(CUSTOMNAME).lst
CUSTOMLINK    = $(SRC)/custom.boot.lds
CUSTOMOBJS    = custom.o main.o ASM_routines.o
CUSTOMTARGETS = $(CUSTOMELF) $(CUSTOMBIN)

.PHONY: default all prep bootstrap_defines arm final testrom testrom_atari testrom_list \
        cstart wavtool tools clean clean-tools clean-all rebuild rebuild-tools distclean check-tools

# Default target
# Runs the staged build in strict order.
default: testrom
all: tools testrom

testrom: check-tools prep bootstrap_defines arm final

# -----------------------------------------------------------------------------
# Stage 1: prep
# -----------------------------------------------------------------------------
# Build c_start if needed, create output folders, run c_start, and create a dummy
# ARM binary so the first DASM pass can satisfy the INCBIN line.
prep: $(CSTART_EXE)
	@echo "== Stage 1: prep =="
	mkdir -p $(BIN) $(OUTPUT)
	./$(CSTART_EXE) ./$(SOURCE).asm $(SRC)/custom.boot.lds || (echo "!!! C_START FAILED !!!" && exit 1)
	@if [ ! -f "$(CUSTOMBIN)" ]; then \
		echo "Creating temporary bootstrap $(CUSTOMBIN)"; \
		printf '\\000' > "$(CUSTOMBIN)"; \
	fi

# -----------------------------------------------------------------------------
# Stage 2: bootstrap_defines
# -----------------------------------------------------------------------------
# Run DASM once using the dummy ARM binary. This is NOT the final build. This
# pass exists only to generate main/defines_dasm.h from DASM output/symbols.
bootstrap_defines: prep
	@echo "== Stage 2: bootstrap_defines =="
	@echo "// Auto-generated from DASM output and symbols" > $(BASE)/$(DASM_TO_C)

	$(DASM) $(SOURCE).asm -DTV_MODE=$(TV_MODE) -f3 -v3 $(INCLUDES) \
		-s$(OUTPUT)/$(SOURCE).sym \
		-l$(OUTPUT)/$(SOURCE).lst \
		-o$(OUTPUT)/$(SOURCE).bin \
		|| (echo "!!! BOOTSTRAP DASM FAILED !!!" && exit 1)

	grep "^#define" $(OUTPUT)/$(SOURCE).lst | awk '!x[$$0]++' >> $(BASE)/$(DASM_TO_C) || true

	@echo "" >> $(BASE)/$(DASM_TO_C)
	@echo "// Auto-generated from DASM symbols" >> $(BASE)/$(DASM_TO_C)

	awk '$$1 ~ /^_/ {printf "#define %-25s 0x%s\n", $$1, $$2}' \
		$(OUTPUT)/$(SOURCE).sym >> $(BASE)/$(DASM_TO_C)

# -----------------------------------------------------------------------------
# Stage 3: arm
# -----------------------------------------------------------------------------
# Build the real ARM binary using the defines generated by the bootstrap pass.
arm: $(BASE)/$(DASM_TO_C)
	@echo "== Stage 3: arm =="
	$(MAKE) $(CUSTOMTARGETS) || (echo "!!! ARM BUILD FAILED !!!" && exit 1)

main.o: $(BASE)/$(DASM_TO_C)
ASM_routines.o: ASM_routines.s
	$(CC) $(CFLAGS) -c $< -o $@

$(CUSTOMELF): $(CUSTOMOBJS) Makefile $(CUSTOMLINK)
	$(CC) $(CFLAGS) -o $(CUSTOMELF) $(CUSTOMOBJS) -T $(CUSTOMLINK) \
		-nostartfiles -Wl,-Map=$(CUSTOMMAP),--gc-sections

$(CUSTOMBIN): $(CUSTOMELF)
	$(OBJCOPY) -O binary -S $(CUSTOMELF) $(CUSTOMBIN) \
		|| (echo "!!! OBJCOPY FAILED !!!" && exit 1)
	@test -f $(CUSTOMBIN) || (echo "!!! MISSING $(CUSTOMBIN) !!!" && exit 1)
	$(SIZE) $(CUSTOMOBJS) $(CUSTOMELF)

# -----------------------------------------------------------------------------
# Stage 4: final
# -----------------------------------------------------------------------------
# Rebuild the final 6502 ROM now that testarm.bin is real.
final: arm
	@echo "== Stage 4: final =="
	$(DASM) $(SOURCE).asm -DTV_MODE=$(TV_MODE) -f3 -v3 $(INCLUDES) \
		-o$(OUTPUT)/$(SOURCE).bin \
		-l$(OUTPUT)/$(SOURCE).lst \
		-s$(OUTPUT)/$(SOURCE).sym \
		|| (echo "!!! DASM FAILED !!!" && exit 1)

# Legacy/manual aliases, if you still want them.
testrom_atari:
	$(DASM) $(SOURCE).asm -DTV_MODE=$(TV_MODE) -f3 -v3 $(INCLUDES) -o$(OUTPUT)/$(SOURCE).bin

testrom_list:
	$(DASM) $(SOURCE).asm -DTV_MODE=$(TV_MODE) -f3 -v3 $(INCLUDES) \
		-o$(OUTPUT)/$(SOURCE).bin \
		-l$(OUTPUT)/$(SOURCE).lst \
		-s$(OUTPUT)/$(SOURCE).sym

flash:
	lpc21isp -bin -wipe -verify -control -controlswap $(OUTPUT)/$(SOURCE).bin /dev/ttyUSB0 38400 10000

# -----------------------------------------------------------------------------
# Tool builds
# -----------------------------------------------------------------------------
$(CSTART_EXE): $(CSTART_SRC)
	@echo ">> Building c_start utility..."
	gcc -Os -o $@ $< || (echo "!!! C_START COMPILE FAILED !!!" && exit 1)
	- strip $@

cstart: $(CSTART_EXE)

$(WAV2RAW_EXE): $(WAV2RAW_SRC)
	@echo ">> Building wav2raw2600 utility..."
	gcc -Os -o $@ $< || (echo "!!! WAV2RAW2600 COMPILE FAILED !!!" && exit 1)
	- strip $@

wavtool: $(WAV2RAW_EXE)

tools: cstart wavtool

# -----------------------------------------------------------------------------
# Clean targets
# -----------------------------------------------------------------------------
clean:
	rm -f *.o *.i $(CUSTOMTARGETS) $(BIN)/*.* $(OUTPUT)/*.* $(BASE)/$(DASM_TO_C)

# Keeps tools, removes all generated project files.
distclean: clean
	rm -f *.map *.elf *.lst

clean-tools:
	rm -f $(CSTART_EXE) $(WAV2RAW_EXE)

clean-all: clean-tools clean

rebuild: clean
	$(MAKE)

rebuild-tools: clean-tools tools

###############################################################################
# File: Makefile
# Description: CDFJ+ Template Makefile - staged/portable build
# (C) Copyright 2017 - Chris Walton, Fred Quimby, Darrell Spice Jr
# Additions by Craig Daniels - Gamax Software - 2026
###############################################################################

###############################################################################
# IMPORTANT BUILD IDEA
###############################################################################
# The final ROM needs main/bin/testarm.bin because the DASM source INCBINs it.
# The ARM/C code needs main/defines_dasm.h because it includes DASM-generated
# labels/constants.
#
# So a clean build must be done in stages:
#   1. prep					- build tools if needed, create folders, create dummy ARM bin
#   2. bootstrap_defines	- run DASM once using the dummy ARM bin, generate defines_dasm.h
#   3. arm					- compile/link ARM C, produce the real testarm.bin
#   4. final				- run DASM again, now with the real testarm.bin
#
###############################################################################
# BUILD OPTIONS / COMMON TARGETS
###############################################################################
#
# Basic build:
#   make
#   make rom
#
# Emulator launch:
#   make run              # uses EMULATOR ?= stella
#   make stella
#   make gopher
#   make run EMULATOR=gopher
#
# Helper tools:
#   make cstart           # builds tools/c_start
#   make wavtool          # builds tools/wav2raw2600
#   make tools            # builds both
#   make all              # builds tools, then ROM
#
# Manual / legacy DASM-only targets:
#   make testrom_atari
#   make testrom_list
#
# Cleaning / rebuilding:
#   make clean            # removes generated ROM/build/output files
#   make clean-tools      # removes compiled helper tools
#   make clean-all        # clean + clean-tools
#   make distclean        # clean + loose root map/elf/lst files
#   make rebuild          # clean, then build
#   make rebuild-tools    # rebuild helper tools only
#
# Notes:
#   - .NOTPARALLEL is required for the staged build.
#   - main/defines_dasm.h is auto-generated. Do not hand-edit it.
#   - Update TOOLCHAIN, DASM, HOST_CC, STELLA, and GOPHER as needed per system.
#
###############################################################################

###############################################################################
# User/system-specific paths -- where are things located on your system?

# Tools
TOOLCHAIN	= arm-none-eabi
DASM		= dasm
HOST_CC		= gcc

# Emulators
STELLA		= C:/Program Files/Stella/Stella.exe
GOPHER 		= gopher2600

# Note: on MacOS Intel build of Gopher will likely be suffixed with _amd64
###############################################################################

# Default Emulator stella/gopher
EMULATOR ?= gopher

# NTSC|PAL|PAL60|SECAM
TV_TYPE = NTSC

# Default Stella console/video options
STELLA_TV	= $(TV_TYPE)
STELLA_ARGS	=  -format $(STELLA_TV) -rc atarivox

# Default Gopher console/video options
GOPHER_TV	= $(TV_TYPE)
GOPHER_ARGS	= -tv $(GOPHER_TV) -right savekey

.NOTPARALLEL:

.DEFAULT_GOAL := default

# Tool name additions
CC			= $(TOOLCHAIN)-gcc
AS			= $(TOOLCHAIN)-as
LD			= $(TOOLCHAIN)-ld
OBJCOPY		= $(TOOLCHAIN)-objcopy
SIZE		= $(TOOLCHAIN)-size
TOOLS		= tools


REQUIRED_TOOLS = $(DASM) $(CC) $(OBJCOPY) $(SIZE) grep awk
REQUIRED_HOST_TOOLS = $(HOST_CC)

check-tools:
	@for tool in $(REQUIRED_TOOLS); do \
		command -v $$tool >/dev/null 2>&1 || { \
			echo "!!! MISSING TOOL: $$tool !!!"; \
			echo "Install it or make sure it is in PATH."; \
			exit 1; \
		}; \
	done

check-host-tools:
	@for tool in $(REQUIRED_HOST_TOOLS); do \
		command -v $$tool >/dev/null 2>&1 || { \
			echo "!!! MISSING HOST TOOL: $$tool !!!"; \
			echo "Install it or make sure it is in PATH."; \
			exit 1; \
		}; \
	done

# Dirs/files
SOURCE = cdfj+_template
BASE   = main
SRC    = $(BASE)/custom
BIN    = $(BASE)/bin
OUTPUT = ./output
BUILD  = ./build

EXEEXT =
ifeq ($(OS),Windows_NT)
EXEEXT = .exe
endif

CSTART_EXE = $(TOOLS)/c_start$(EXEEXT)
CSTART_SRC = $(TOOLS)/c_start.c

WAV2RAW_EXE = $(TOOLS)/wav2raw2600$(EXEEXT)
WAV2RAW_SRC = $(TOOLS)/wav2raw2600.c

DASM_TO_C = defines_dasm.h

# C Compiler flags
INCLUDES = -I. -I$(BASE)/samples
OPTIMIZATION = -Os
CFLAGS = -mcpu=arm7tdmi -march=armv4t -mthumb
CFLAGS += -Wall -ffunction-sections
CFLAGS += $(OPTIMIZATION) $(INCLUDES)
CFLAGS += -Wl,--build-id=none
CFLAGS += -Wno-unused-function

# Search path
VPATH += $(BASE):$(SRC)

# ARM/C output
CUSTOMNAME    = armcode
CUSTOMELF     = $(BUILD)/$(CUSTOMNAME).elf
CUSTOMBIN     = $(BIN)/$(CUSTOMNAME).bin
CUSTOMMAP     = $(BUILD)/$(CUSTOMNAME).map
CUSTOMLST     = $(BUILD)/$(CUSTOMNAME).lst
CUSTOMLINK    = $(SRC)/custom.boot.lds
SRCS = \
	ASM_routines.s \
	$(SRC)/custom.S \
	$(BASE)/main.c \
	$(BASE)/defines_cdfjplus.c \
	$(BASE)/samples.c \
	$(BASE)/state_00.c \
	$(BASE)/state_01.c \
	$(BASE)/state_02.c 


CUSTOMOBJS = $(addprefix $(BUILD)/,$(notdir $(SRCS:.c=.o)))
CUSTOMOBJS := $(CUSTOMOBJS:.s=.o)
CUSTOMOBJS := $(CUSTOMOBJS:.S=.o)
CUSTOMTARGETS = $(CUSTOMELF) $(CUSTOMBIN)

ROM_HISTORY = _ROMs
ROM_TARGET := $(shell date +"$(SOURCE)_%Y%m%d@%H_%M_%S")

.PHONY: default all prep bootstrap_defines arm final rom testrom_atari testrom_list \
        cstart wavtool tools clean clean-tools clean-all rebuild rebuild-tools distclean check-tools \
        run stella gopher

# Legacy compatibility alias
testrom: rom

# Default target
# Runs the staged build in strict order.
default: rom
all: tools
	$(MAKE) rom

rom: check-tools
	$(MAKE) prep
	$(MAKE) bootstrap_defines
	$(MAKE) arm
	$(MAKE) final

# -----------------------------------------------------------------------------
# Stage 1: prep
# -----------------------------------------------------------------------------
# Build c_start if needed, create output folders, run c_start, and create a dummy
# ARM binary so the first DASM pass can satisfy the INCBIN line.
prep: $(CSTART_EXE)
	@echo "== Stage 1: prep =="
	mkdir -p $(BIN) $(OUTPUT) $(BUILD)
	$(CSTART_EXE) ./$(SOURCE).asm $(SRC)/custom.boot.lds || (echo "!!! C_START FAILED !!!" && exit 1)
	@if [ ! -f "$(CUSTOMBIN)" ]; then \
		echo "Creating temporary bootstrap $(CUSTOMBIN)"; \
		printf '\\000' > "$(CUSTOMBIN)"; \
	fi

# -----------------------------------------------------------------------------
# Stage 2: bootstrap_defines
# -----------------------------------------------------------------------------
# Run DASM once using the dummy ARM binary. This is NOT the final build. This
# pass exists only to generate main/defines_dasm.h from DASM output/symbols.
bootstrap_defines: 
	@echo "== Stage 2: bootstrap_defines =="
	@echo "// Auto-generated from DASM output and symbols" > $(BASE)/$(DASM_TO_C)

	$(DASM) $(SOURCE).asm -f3 -v3 $(INCLUDES) \
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
arm:
	@echo "== Stage 3: arm =="
	rm -f $(CUSTOMBIN)
	$(MAKE) $(CUSTOMTARGETS) || (echo "!!! ARM BUILD FAILED !!!" && exit 1)

$(BUILD)/main.o: $(BASE)/$(DASM_TO_C)
$(BUILD)/defines_cdfjplus.o: $(BASE)/$(DASM_TO_C)

$(BUILD)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: %.S
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
final:
	@echo "== Stage 4: final =="
	$(DASM) $(SOURCE).asm -f3 -v3 $(INCLUDES) \
		-o$(OUTPUT)/$(SOURCE).bin \
		-l$(OUTPUT)/$(SOURCE).lst \
		-s$(OUTPUT)/$(SOURCE).sym \
		|| (echo "!!! DASM FAILED !!!" && exit 1)

# Uncomment these two lines to archive a time-stamped ROM
#	mkdir -p $(ROM_HISTORY)
#	cp $(OUTPUT)/$(SOURCE).bin $(ROM_HISTORY)/$(ROM_TARGET).bin

# Legacy/manual aliases, if you still want them.
testrom_atari:
	$(DASM) $(SOURCE).asm -f3 -v3 $(INCLUDES) -o$(OUTPUT)/$(SOURCE).bin

testrom_list:
	$(DASM) $(SOURCE).asm -f3 -v3 $(INCLUDES) \
		-o$(OUTPUT)/$(SOURCE).bin \
		-l$(OUTPUT)/$(SOURCE).lst \
		-s$(OUTPUT)/$(SOURCE).sym

flash:
	lpc21isp -bin -wipe -verify -control -controlswap $(OUTPUT)/$(SOURCE).bin /dev/ttyUSB0 38400 10000

# -----------------------------------------------------------------------------
# Emulator launch targets
# -----------------------------------------------------------------------------

run: $(EMULATOR)

stella: rom
	@if [ ! -f "$(STELLA)" ]; then \
		echo "!!! STELLA NOT FOUND !!!"; \
		echo "Set STELLA to the correct path in the Makefile."; \
		exit 1; \
	fi
	"$(STELLA)" $(STELLA_ARGS) "$(OUTPUT)/$(SOURCE).bin"

gopher: rom
	@if ! command -v "$(GOPHER)" >/dev/null 2>&1; then \
		echo "!!! GOPHER2600 NOT FOUND !!!"; \
		echo "Install Gopher2600 or set GOPHER to the correct path."; \
		exit 1; \
	fi
	$(GOPHER) $(GOPHER_ARGS) "$(OUTPUT)/$(SOURCE).bin"

# -----------------------------------------------------------------------------
# Tool builds
# -----------------------------------------------------------------------------
$(CSTART_EXE): $(CSTART_SRC) check-host-tools
	@echo ">> Building c_start utility..."
	$(HOST_CC) -Os -o $@ $< || (echo "!!! C_START COMPILE FAILED !!!" && exit 1)
	- strip $@

cstart: $(CSTART_EXE)

$(WAV2RAW_EXE): $(WAV2RAW_SRC) check-host-tools
	@echo ">> Building wav2raw2600 utility..."
	$(HOST_CC) -Os -o $@ $< || (echo "!!! WAV2RAW2600 COMPILE FAILED !!!" && exit 1)
	- strip $@

wavtool: $(WAV2RAW_EXE)

tools: cstart
	$(MAKE) wavtool

# -----------------------------------------------------------------------------
# Clean targets
# -----------------------------------------------------------------------------
clean:
	rm -rf $(BUILD) $(OUTPUT)
	rm -f $(CUSTOMBIN) $(BASE)/$(DASM_TO_C)

# Keeps tools, removes all generated project files.
distclean: clean
	rm -f *.map *.elf *.lst

clean-tools:
	rm -f $(CSTART_EXE) $(WAV2RAW_EXE)

clean-all: clean-tools clean

rebuild: clean
	$(MAKE)

rebuild-tools: clean-tools tools

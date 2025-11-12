GAME_DISC_1_NAME := SLPS-01840

ROM_DIR      := rom
CONFIG_DIR   := configs
IMAGE_DIR    := $(ROM_DIR)/images
BUILD_DIR    := build
OUT_DIR      := $(BUILD_DIR)/out
TOOLS_DIR    := tools
LINKER_DIR   := linkers
ASM_DIR      := asm
C_DIR        := src
EXPECTED_DIR := expected

# Tools

CROSS   := mips-linux-gnu
AS      := $(CROSS)-as
LD      := $(CROSS)-ld
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump
CPP     := $(CROSS)-cpp
CC      := $(TOOLS_DIR)/gcc-2.8.1-psx/cc1
OBJDIFF := $(OBJDIFF_DIR)/objdiff

PYTHON          := python3
SPLAT           := $(PYTHON) -m splat split
MASPSX          := $(PYTHON) $(TOOLS_DIR)/maspsx/maspsx.py
DUMPSXISO       := $(TOOLS_DIR)/psxiso/dumpsxiso
GET_YAML_TARGET := $(PYTHON) $(TOOLS_DIR)/get_yaml_target.py

# Flags
OPT_FLAGS           := -O2
ENDIAN              := -EL
INCLUDE_FLAGS       := -Iinclude -I $(BUILD_DIR) -Iinclude/psyq
DEFINE_FLAGS        := -D_LANGUAGE_C -DUSE_INCLUDE_ASM
CPP_FLAGS           := $(INCLUDE_FLAGS) $(DEFINE_FLAGS) -P -MMD -MP -undef -Wall -lang-c -nostdinc
LD_FLAGS            := $(ENDIAN) $(OPT_FLAGS) -nostdlib --no-check-sections
OBJCOPY_FLAGS       := -O binary
OBJDUMP_FLAGS       := --disassemble-all --reloc --disassemble-zeroes -Mreg-names=32
SPLAT_FLAGS         := --disassemble-all --make-full-disasm-for-code
DUMPSXISO_FLAGS     := -x $(ROM_DIR) -s $(ROM_DIR)/layout.xml $(IMAGE_DIR)/$(GAME_DISC_1_NAME).bin

TARGET_PREBUILD  := main

# Adjusts compiler and assembler flags based on source file location.
# - Files under main executable paths use -G8; overlay files use -G0.
# - Enables `--expand-div` for certain `libsd` sources which require it (others can't build with it).
# - Adds overlay-specific compiler flags based on files directory (currently only per-map defines).
define FlagsSwitch
	$(if $(findstring /main/,$(1)), $(eval DL_FLAGS = -G8), $(eval DL_FLAGS = -G0))
	$(eval AS_FLAGS = $(ENDIAN) $(INCLUDE_FLAGS) $(OPT_FLAGS) $(DL_FLAGS) -march=r3000 -mtune=r3000 -no-pad-sections)
	$(eval CC_FLAGS = $(OPT_FLAGS) $(DL_FLAGS) -mips1 -mcpu=3000 -w -funsigned-char -fpeephole -ffunction-cse -fpcc-struct-return -fcommon -fverbose-asm -msoft-float -mgas -fgnu-linker -quiet)
	
	$(if $(or $(findstring smf_mid,$(1)), $(findstring smf_io,$(1)),), \
		$(eval MASPSX_FLAGS = --gnu-as-path=/usr/bin/mips-linux-gnu-as --aspsx-version=2.77 --run-assembler --expand-div $(AS_FLAGS)), \
		$(eval MASPSX_FLAGS = --gnu-as-path=/usr/bin/mips-linux-gnu-as --aspsx-version=2.77 --run-assembler $(AS_FLAGS)))

	$(eval _rel_path := $(patsubst build/src/maps/%,%,$(patsubst build/asm/maps/%,%,$(1))))
	$(eval _map_name := $(shell echo $(word 1, $(subst /, ,$(_rel_path))) | tr a-z A-Z))
	$(if $(and $(findstring MAP,$(_map_name)),$(findstring _S,$(_map_name))), \
		$(eval OVL_FLAGS := -D$(_map_name)), \
		$(eval OVL_FLAGS :=))
endef

# Utils

# Function to find matching .bin files for a target name.
find_bin_files = $(shell find $(ASM_DIR)/$(strip $1) -type f -path "*.bin" 2> /dev/null)

# Function to find matching .s files for a target name.
find_s_files = $(shell find $(ASM_DIR)/$(strip $1) -type f -path "*.s" -not -path "asm/*matchings*" 2> /dev/null)

# Function to find matching .c files for a target name.
find_c_files = $(shell find $(C_DIR)/$(strip $1) -type f -path "*.c" 2> /dev/null)

# Function to generate matching .o files for target name in build directory.
gen_o_files = $(addprefix $(BUILD_DIR)/, \
							$(patsubst %.s, %.s.o, $(call find_s_files, $1)) \
							$(patsubst %.c, %.c.o, $(call find_c_files, $1)) \
							$(patsubst %.bin, %.bin.o, $(call find_bin_files, $1)))

# Function to get path to .yaml file for given target.
get_yaml_path = $(addsuffix .yaml,$(addprefix $(CONFIG_DIR)/,$1))

# Function to get target output path for given target.
get_target_out = $(addprefix $(OUT_DIR)/,$(shell $(GET_YAML_TARGET) $(call get_yaml_path,$1)))

define make_elf_target
$2: $2.elf
	$(OBJCOPY) $(OBJCOPY_FLAGS) $$< $$@
ifneq (,$(filter $1,$(TARGET_POSTBUILD)))
	-$(POSTBUILD) $1
endif

$2.elf: $(call gen_o_files, $1)
	@mkdir -p $(dir $2)
	$(LD) $(LD_FLAGS) \
		-Map $2.map \
		-T $(LINKER_DIR)/$1.ld \
		-T $(LINKER_DIR)/$(filter-out ./,$(dir $1))undefined_syms_auto.$(notdir $1).txt \
		-T $(LINKER_DIR)/$(filter-out ./,$(dir $1))undefined_funcs_auto.$(notdir $1).txt \
		-o $$@
endef

TARGET_MAIN := main
TARGET_IN  := $(TARGET_MAIN)
TARGET_OUT := $(foreach target,$(TARGET_IN),$(call get_target_out,$(target)))

CONFIG_FILES := $(foreach target,$(TARGET_IN),$(call get_yaml_path,$(target)))
LD_FILES     := $(addsuffix .ld,$(addprefix $(LINKER_DIR)/,$(TARGET_IN)))

# Recursively include any .d dependency files from previous builds.
# Allowing Make to rebuild targets when any included headers/sources change.
-include $(shell [ -d $(BUILD_DIR) ] && find $(BUILD_DIR) -name '*.d' || true)

# Rules

default: all

all: build

build: $(TARGET_OUT)

extract:
	$(DUMPSXISO) $(DUMPSXISO_FLAGS)

generate: $(LD_FILES)

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(PERMUTER_DIR)

reset: clean
	rm -rf $(ASM_DIR)
	rm -rf $(LINKER_DIR)
	rm -rf $(EXPECTED_DIR)

check: build
	@sha256sum --ignore-missing --check checksum.sha

$(foreach target,$(TARGET_IN),$(eval $(call make_elf_target,$(target),$(call get_target_out,$(target)))))

$(BUILD_DIR)/%.i: %.c
	@mkdir -p $(dir $@)
	$(call FlagsSwitch, $@)
ifeq ($(MAKE_COMPILE_LOG),1)
	@echo "$(CPP) -P -MMD -MP -MT $@ -MF $@.d $(CPP_FLAGS) $(OVL_FLAGS) -o $@ $<" >> compile.log
endif
	$(CPP) -P -MMD -MP -MT $@ -MF $@.d $(CPP_FLAGS) $(OVL_FLAGS) -o $@ $<

$(BUILD_DIR)/%.sjis.i: $(BUILD_DIR)/%.i
	iconv -f UTF-8 -t SHIFT-JIS $< -o $@

$(BUILD_DIR)/%.c.s: $(BUILD_DIR)/%.sjis.i
	@mkdir -p $(dir $@)
	$(call FlagsSwitch, $@)
	$(CC) $(CC_FLAGS) -o $@ $<

$(BUILD_DIR)/%.c.o: $(BUILD_DIR)/%.c.s
	@mkdir -p $(dir $@)
	$(call FlagsSwitch, $@)
	-$(MASPSX) $(MASPSX_FLAGS) -o $@ $<
	-$(OBJDUMP) $(OBJDUMP_FLAGS) $@ > $(@:.o=.dump.s)

$(BUILD_DIR)/%.s.o: %.s
	@mkdir -p $(dir $@)
	$(call FlagsSwitch, $@)
	$(AS) $(AS_FLAGS) -o $@ $<

$(LINKER_DIR)/%.ld: $(CONFIG_DIR)/%.yaml
	@mkdir -p $(dir $@)
	$(SPLAT) $(SPLAT_FLAGS) $<

	
### Settings
.SECONDARY:
.PHONY: all clean default
SHELL = /bin/bash -e -o pipefail

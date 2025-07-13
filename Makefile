DEVICE = 85k
PIN_DEF = ulx3s_v20.lpf
BUILD_DIR = build

CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy

PROG = display
PROG_OUT = $(BUILD_DIR)/$(PROG).out
PROG_BIN = $(BUILD_DIR)/$(PROG).bin
PROG_HEX = $(BUILD_DIR)/$(PROG).hex
FAKE_ROM = $(BUILD_DIR)/rom.hex

C_SOURCES = lib/start.S $(wildcard lib/*.c)
C_DEFINES = -DULX3S
C_FLAGS = $(C_DEFINES) -O2 -Wall -nostartfiles -Wl,-Tlib/linker_script.ld,-Map=$(BUILD_DIR)/output.map
VERILOG_SOURCES = $(wildcard hdl/*.v)
ROMS = $(wildcard rom/*.hex)

all: $(BUILD_DIR)/toplevel.bit

program: $(BUILD_DIR)/toplevel.bit
	fujprog $^

ftp: $(BUILD_DIR)/toplevel.bit
	ftp -u ftp://ulx3s/fpga $^

tty:
	fujprog -t -b 9600

sim:
	verilator -Wno-fatal --trace --exe --build --cc -j 0 -y hdl -y lib sim_main.cpp hdl/top.v
	$(MAKE) -j -C obj_dir -f Vtop.mk
	obj_dir/Vtop

clean:
	rm -rf $(BUILD_DIR)

$(FAKE_ROM): | $(BUILD_DIR)
	ecpbram -w 32 -d 16384 -g $@

$(PROG_OUT): examples/$(PROG).c $(C_SOURCES) lib/linker_script.ld | $(BUILD_DIR)
	$(CC) $(C_FLAGS) -o $@ $(C_SOURCES) $<

$(PROG_BIN): $(PROG_OUT)
	$(OBJCOPY) -O binary $< $@

$(PROG_HEX): $(PROG_OUT)
	$(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

$(BUILD_DIR)/%.json: $(VERILOG_SOURCES) $(ROMS) $(FAKE_ROM) | $(BUILD_DIR)
	yosys -p "synth_ecp5 -abc9 -top top -json $@" $(VERILOG_SOURCES)

$(BUILD_DIR)/%.config: $(PIN_DEF) $(BUILD_DIR)/%.json
	 nextpnr-ecp5 --$(DEVICE) --package CABGA381 --freq 25 --textcfg $@ --json $(filter-out $<,$^) --lpf $<

$(BUILD_DIR)/%.bit: $(BUILD_DIR)/%.config $(PROG_HEX)
	ecpbram -f $(FAKE_ROM) -t $(PROG_HEX) -i $< -o $(BUILD_DIR)/temp.config
	ecppack $(BUILD_DIR)/temp.config $@ --compress

$(BUILD_DIR):
	mkdir $@

.SECONDARY: $(BUILD_DIR)/toplevel.config $(BUILD_DIR)/toplevel.json
.PHONY: all clean ftp program sim tty

DEVICE = 85k
PIN_DEF = ulx3s_v20.lpf
BUILDDIR = build

CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy

CFLAGS = -DULX3S -O2 -Wall -nostartfiles -Wl,-Tlib/linker_script.ld,-Map=$(BUILDDIR)/output.map

PROG = display
PROG_OUT = $(BUILDDIR)/$(PROG).out
PROG_BIN = $(BUILDDIR)/$(PROG).bin
PROG_HEX = $(BUILDDIR)/$(PROG).hex
FAKE_ROM = $(BUILDDIR)/rom.hex

C_SRC = lib/start.S $(wildcard lib/*.c)
VERILOG_SRC = $(wildcard hdl/*.v)
ROMS = $(wildcard rom/*.hex)

all: $(BUILDDIR)/toplevel.bit

program: $(BUILDDIR)/toplevel.bit
	fujprog $^

ftp: $(BUILDDIR)/toplevel.bit
	ftp -u ftp://ulx3s/fpga $^

tty:
	fujprog -t -b 9600

sim:
	verilator -Wno-fatal --trace --exe --build --cc -j 0 -y hdl -y lib sim_main.cpp hdl/top.v
	$(MAKE) -j -C obj_dir -f Vtop.mk
	obj_dir/Vtop

clean:
	rm -rf $(BUILDDIR)

$(FAKE_ROM):
	mkdir -p $(BUILDDIR)
	ecpbram -w 32 -d 16384 -g $@

$(PROG_OUT): examples/$(PROG).c $(C_SRC) lib/linker_script.ld
	mkdir -p $(BUILDDIR)
	$(CC) $(CFLAGS) -o $@ $(C_SRC) $<

$(PROG_BIN): $(PROG_OUT)
	$(OBJCOPY) -O binary $< $@

$(PROG_HEX): $(PROG_OUT)
	$(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

$(BUILDDIR)/%.json: $(VERILOG_SRC) $(ROMS) $(FAKE_ROM)
	yosys -p "synth_ecp5 -abc9 -top top -json $@" $(VERILOG_SRC)

$(BUILDDIR)/%.config: $(PIN_DEF) $(BUILDDIR)/%.json
	 nextpnr-ecp5 --$(DEVICE) --package CABGA381 --freq 25 --textcfg $@ --json $(filter-out $<,$^) --lpf $<

$(BUILDDIR)/%.bit: $(BUILDDIR)/%.config $(PROG_HEX)
	ecpbram -f $(FAKE_ROM) -t $(PROG_HEX) -i $< -o $(BUILDDIR)/temp.config
	ecppack $(BUILDDIR)/temp.config $@ --compress

.SECONDARY: $(BUILDDIR)/toplevel.config $(BUILDDIR)/toplevel.json
.PHONY: all clean ftp program sim tty

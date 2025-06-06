# riscv-ulx3s

## Prerequisites

```sh
sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip python3-tomli libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev libslirp-dev
```

## Getting Started

Build and install RISC-V toolchain:

```sh
gh repo clone riscv-collab/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv32i --with-arch=rv32i
make -j$(nproc)
```

Build project and program the FPGA:

```sh
make program
```

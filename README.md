# riscv-ulx3s

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

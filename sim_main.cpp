#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Vtop.h"

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  Vtop *dut = new Vtop{contextp};
  contextp->traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");
  contextp->commandArgs(argc, argv);

  vluint64_t time = 0;

  dut->clk_25mhz = 0;
  dut->btn = 0b111111;

  int i = 0;

  while (time < 1000000) {

    if (dut->clk_25mhz)
      i++;

    dut->eval();
    m_trace->dump(time);
    dut->clk_25mhz = !dut->clk_25mhz;
    time++;
  }

  dut->final();
  m_trace->close();

  contextp->statsPrintSummary();

  delete dut;
  delete contextp;

  return 0;
}

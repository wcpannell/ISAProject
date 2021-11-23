// TIMER Peribus peripheral

`default_nettype none

module Timer(
  input var logic addr,
  input var logic [15:0] write_data,
  input var logic write_en,
  input var logic read_en,
  input var logic clock,
  input var logic reset_n,
  input var logic chipselect,
  output var logic [15:0] read_data,
  output var logic irq
);

// Memory Map of Peripheral
// 0: [16:0] Timer Count
// 1: [16:0] Timer Period
// 2: [16:0] Control Register: {13'h0 IRQ enable, Reload, Run}
// 3: [16:0] Status Register: {14'h0, IRQ, Running}

endmodule

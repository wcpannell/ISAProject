`default_nettype none

module test_timer(input var logic CLOCK_50);

logic [1:0] addr;
logic [15:0] write_data;
logic write_en;
logic read_en;
logic reset_n;
logic chipselect;
logic [15:0] read_data;
logic irq;

Timer timer(
  addr,
  write_data,
  write_en,
  read_en,
  CLOCK_50,
  reset_n,
  chipselect,
  read_data,
  irq
);

// Memory Map of Peripheral
// 0: [16:0] Timer Count
// 1: [16:0] Timer Period
// 2: [16:0] Control Register: {Prescale[7:0], 5'h0, IRQ enable, Reload, Run}
// 3: [16:0] Status Register: {14'h0, IRQ, Running}

initial begin
  addr = 0;
  write_data = 0;
  write_en = 0;
  read_en = 0;
  reset_n = 0;
  chipselect = 0;

  #25 addr = 2'd1;
  reset_n = 1'b1;

  #25 write_data = 16'h0055;
  write_en = 1'b1;
  chipselect = 1'b1;

  #25 write_en = 1'b0;
  read_en = 1'b1;

  // ensure did not start

  #225 addr = 2'd2;
  write_data = 16'h0101;
  write_en = 1'b1;

  #25 write_en = 1'b0;

end
endmodule

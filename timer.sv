// TIMER Peribus peripheral
//
// Note: Prescale divider value is (value + 1)
// e.g. prescale - 1 = 0 => 1, time = period / 1
// prescale - 1 = 1 => 2, time = period / 2

`default_nettype none

module Timer(
  input var logic [1:0] addr,
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
// 2: [16:0] Control Register: {Prescale[7:0], 5'h0, IRQ enable, Reload, Run}
// 3: [16:0] Status Register: {14'h0, IRQ, 0}

localparam CTRL_RUN_OFFSET = 0;
localparam CTRL_RELOAD_OFFSET = 1;
localparam CTRL_IRQ_OFFSET = 2;
localparam CTRL_PRE_OFFSET = 8;
localparam CTRL_PRE_BITS = 8;

localparam STAT_RUN_OFFSET = 0;
localparam STAT_IRQ_OFFSET = 1;

logic [15:0] count;
logic [15:0] period;
logic [15:0] control;
logic [15:0] status;
logic [7:0] pre_count;
logic count_flag;
logic prescale_output;
logic timer_init;

assign irq = (control[CTRL_IRQ_OFFSET] && status[STAT_IRQ_OFFSET]) ? 1'b1: 1'b0;

// Reads
always_ff @(posedge clock or negedge reset_n) begin
  if (~reset_n) read_data <= 16'h0;  // Clear on reset
  else if (chipselect && read_en) begin
    case (addr)
      2'd0: read_data <= count;
      2'd1: read_data <= period;
      2'd2: read_data <= control;
      default: read_data <= status;  // addr == 3
    endcase
  end
end

// Count Register
always_ff @(posedge clock or negedge reset_n) begin
  // reset
  if (~reset_n) begin
    count <= 16'h0;
    count_flag <= 1'b0;
  end

  // Bus Write
  else if (chipselect && write_en && (addr == 0)) begin
    count <= write_data;
    count_flag <= 1'b0;
  end

  // Counter running
  else if (control[CTRL_RUN_OFFSET]) begin
    // Overflow
    if (count == 16'd0) begin
      if (timer_init) count <= period;
      else begin
        count_flag <= 1'b1;

        // if auto reload, load new count minus one (or not, if prescaled).
        // Wait until IRQ is set (or was already set) before reloading
        count <= (control[CTRL_RELOAD_OFFSET] && status[STAT_IRQ_OFFSET]) ? period - prescale_output : 16'd0;
      end
    end
    // Decrement
    else begin
      count_flag <= 1'b0;
      count <= count - prescale_output;
    end
  end
  else count_flag <= 1'b0;
end

// Prescale Counter
// Counts down, set prescale_output on zero
always_ff @(posedge clock or negedge reset_n) begin
  if (~reset_n) begin
    pre_count <= 0;
    prescale_output <= 1'b0;
  end
  // If running
  else if (control[CTRL_RUN_OFFSET]) begin
    if (pre_count == 8'd0) begin  // only load the prescaler while running to keep count correct
      // reload prescale
      pre_count <= control[(CTRL_PRE_BITS + CTRL_PRE_OFFSET - 1) : CTRL_PRE_OFFSET];
      prescale_output <= 1'b1;  // indicate ready to decrement
    end
    else begin // normal prescaling
      pre_count <= pre_count - 'd1;
      prescale_output <= 1'b0;
    end
  end
end

// Period Register
always_ff @(posedge clock or negedge reset_n) begin
  // reset
  if (~reset_n) period <= 16'd0;
  else if (chipselect && write_en && (addr == 1)) period <= write_data;
end

// Control Register
always_ff @(posedge clock or negedge reset_n) begin
  // reset
  if (~reset_n) begin
    control <= 16'd0;
    timer_init <= 1'b0;
  end

  // Peribus Write
  else if (chipselect && write_en && (addr == 2)) begin
    // if first start
    if (~control[CTRL_RUN_OFFSET] && write_data[CTRL_RUN_OFFSET]) timer_init <= 1'b1;
    control <= write_data;
  end

  else begin
    // Flip Run bit when complete. On first start, wait until timer_init is
    // cleared before calling it complete.
    if (~control[CTRL_RELOAD_OFFSET] && (count == 16'd0)) control[CTRL_RUN_OFFSET] <= timer_init;

    // Flip off init bit if counter loaded
    if (count != 16'd0) timer_init <= 1'b0;
  end
end

// Status Register
// Per Modelsim, Counter reset MUST wait until IRQ flag is asserted before
// resetting. Race condition causes flag to be missed.
always_ff @(posedge clock or negedge reset_n) begin
  // reset
  if (~reset_n) status <= 16'd0;
  else if (chipselect && write_en && (addr == 3)) status <= write_data;
  else begin
    if (count_flag) status[STAT_IRQ_OFFSET] <= 1'b1;
  end
end


endmodule

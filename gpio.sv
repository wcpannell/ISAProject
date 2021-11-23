// GPIO Peribus peripheral

`default_nettype none

module Gpio(
  input var logic [1:0] addr,
  input var logic [15:0] write_data,
  input var logic write_en,
  input var logic read_en,
  input var logic clock,
  input var logic reset_n,
  input var logic chipselect,
  output var logic [15:0] read_data,
  output var logic irq,
  inout tri [15:0] bidir_port  // GPIO ports
);

// Memory Map of Peripheral
// 0: [16:0] Port State  (1 is high, 0 is low)
// 1: [16:0] Port Direction (1 is output, 0 is input)
// 2: [16:0] IRQ-on-change Enable (1 is enabled, 0 is disabled)
// 3: [16:0] IRQ Flags (1 is IRQ, 0 is cleared)

logic [15:0] port_input;
logic [15:0] port_output;
logic [15:0] port_write;
logic [15:0] port_dir;
logic [15:0] port_edges;
logic [15:0] irq_en;
logic [15:0] irq_flags;

assign irq = |(irq_flags & irq_en);

// Split bidir_port into in/out and make tristate (read is Hi-Z)
assign bidir_port[0] = (port_dir[0]) ? port_output[0] : 1'bZ;
assign bidir_port[1] = (port_dir[1]) ? port_output[1] : 1'bZ;
assign bidir_port[2] = (port_dir[2]) ? port_output[2] : 1'bZ;
assign bidir_port[3] = (port_dir[3]) ? port_output[3] : 1'bZ;
assign bidir_port[4] = (port_dir[4]) ? port_output[4] : 1'bZ;
assign bidir_port[5] = (port_dir[5]) ? port_output[5] : 1'bZ;
assign bidir_port[6] = (port_dir[6]) ? port_output[6] : 1'bZ;
assign bidir_port[7] = (port_dir[7]) ? port_output[7] : 1'bZ;
assign bidir_port[8] = (port_dir[8]) ? port_output[8] : 1'bZ;
assign bidir_port[9] = (port_dir[9]) ? port_output[9] : 1'bZ;
assign bidir_port[10] = (port_dir[10]) ? port_output[10] : 1'bZ;
assign bidir_port[11] = (port_dir[11]) ? port_output[11] : 1'bZ;
assign bidir_port[12] = (port_dir[12]) ? port_output[12] : 1'bZ;
assign bidir_port[13] = (port_dir[13]) ? port_output[13] : 1'bZ;
assign bidir_port[14] = (port_dir[14]) ? port_output[14] : 1'bZ;
assign bidir_port[15] = (port_dir[15]) ? port_output[15] : 1'bZ;

// Reads
always_ff @(posedge clock or negedge reset_n) begin
  if (~reset_n) read_data <= 16'h0;  // Clear on reset
  else if (chipselect && read_en) begin
    case (addr)
      2'd0: read_data <= port_input;
      2'd1: read_data <= port_dir;
      2'd2: read_data <= irq_en;
      default: read_data <= irq_flags;  // addr == 3
    endcase
  end
end

// Write Port State
always_ff @(posedge clock or negedge reset_n) begin
  if (~reset_n) port_output <= 16'h0;  // clear on reset
  else if (chipselect && write_en && (addr == 0)) port_output <= write_data;
end

// Write Port Direction
always_ff @(posedge clock or negedge reset_n) begin
  if (~reset_n) port_dir <= 16'h0;  // Clear on reset
  else if (chipselect && write_en && (addr == 1)) port_dir <= write_data;
end

// Write IRQ Enable
always_ff @(posedge clock or negedge reset_n) begin
  if (~reset_n) irq_en <= 16'h0;  // Clear on reset
  else if (chipselect && write_en && (addr == 2)) irq_en <= write_data;
end

// Write IRQ Flags
//
// Note, writing only clears the flags
always_ff @(posedge clock or negedge reset_n) begin
  if (~reset_n) irq_flags <= 16'h0;  // Clear on reset
  else begin
    if (chipselect && write_en && (addr == 3)) irq_flags <= write_data | port_edges;  // ignore clear if simultaneously set
    else irq_flags <= irq_flags | port_edges;  // Update irq_flags with new edges
  end
end


// port differences arent' working?
always_comb begin
  if (~reset_n) begin
    // Reset
    port_edges = 16'h0;
    port_input = bidir_port;
  end else begin
    port_edges = port_input ^ bidir_port;  // Grab differences between last port state and current
    port_input = bidir_port;  // update port_input
  end
end

endmodule

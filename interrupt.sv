// Interrupt Controller
//
// This module supersedes the PC_SAVE and Interrupt Controller blocks from the
// original design.

`default_nettype none

module Interrupt #(
  parameter INTERRUPT_VECTOR = 11'h4,
  parameter RESET_VECTOR = 11'h0,
  parameter PC_SAVE = 2'h3
) (
  input var logic irq,
  input var logic instr_clock,
  input var logic reset_n,
  input var logic [1:0] pc_mux_control,
  input var logic [10:0] pc_next,
  output var logic [10:0] pc_out,
  output var logic [10:0] pc_save
);

logic coerce_pc;
logic interrupt_active;

assign pc_out = (coerce_pc) ? INTERRUPT_VECTOR : pc_next;

always_ff @(posedge instr_clock or posedge irq) begin
  // if interrupted and not already coerced
  if (irq) begin
    if (~interrupt_active) begin
      coerce_pc <= 1'b1;
      pc_save <= pc_next;
    end
    else coerce_pc <= 1'b0;
  end
  // clear on every posedge
  else if (instr_clock) coerce_pc <= 1'b0;
end

// Toggle to make ISR entry a oneshot, re-arms on rfi
always_latch begin
  if (~reset_n) interrupt_active = 1'b0;  // initialize on reset
  if (coerce_pc) interrupt_active = 1'b1;  // trigger on this edge
  else if (pc_mux_control == PC_SAVE) interrupt_active = 1'b0;  // reset & rearm on this "edge"
end
endmodule

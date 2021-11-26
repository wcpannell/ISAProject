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
logic [10:0] new_pc;

assign pc_out = (coerce_pc) ? INTERRUPT_VECTOR : pc_next;

always_ff @(posedge instr_clock or posedge irq) begin
  // if interrupted and not already coerced
  if (irq && ~interrupt_active) begin
    coerce_pc <= 1'b1;
    pc_save <= pc_next;
  end
  // clear on every posedge
  else if (instr_clock) coerce_pc <= 1'b0;
end

// Toggle to make ISR entry a oneshot, re-arms on rfi
always_comb begin
  if (~reset_n) interrupt_active = 1'b0;  // initialize on reset
  if (coerce_pc) interrupt_active = 1'b1;  // trigger on this edge
  else if (pc_mux_control == PC_SAVE) interrupt_active = 1'b0;  // reset & rearm on this "edge"
end


// // Interrupt one-shot
// // Also sets interrupt active flag
// always_ff @(posedge instr_clock or negedge reset_n) begin
//   if (~reset_n) begin
//     coerce_pc <= 1'b0;
//     interrupt_active <= 1'b0;
//     pc_save <= RESET_VECTOR;  // Reset if using rfi outside of interrupt
//   end
//   // Interrupt Requested
//   else if (irq) begin
//     // Not already in ISR, go there
//     if (~interrupt_active) begin
//       pc_save <= pc_next;
//       new_pc <= INTERRUPT_VECTOR;
//       interrupt_active <= 1'b1;  // Not active yet, next cycle
//       coerce_pc <= 1'b1;
//     end
//     // In ISR? unlock the PC
//     else  begin
//       interrupt_active <= 1'b1;
//       coerce_pc <= 1'b0;
//     end
//   end
//   // rfi instruction
//   else if (pc_mux == PC_SAVE) begin
//       interrupt_active <= 1'b0;  // set inactive
//     // Leaving interrupt service routine
//     if (interrupt_active) begin
//       new_pc <= pc_save;
//       coerce_pc <= 1'b1;
//     end
//     else begin
//       new_pc <= RESET_VECTOR;
//       coerce_pc <= 1'b1;
//     end
//   end
//   else coerce_pc <= 1'b0;
// end
endmodule

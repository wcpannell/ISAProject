// This module normally passes the input value 'in' straight through, but on
// reset it shorts the value to 0, the reset_vector, so the MCU's first
// instruction will be the reset_vector as intended.

`default_nettype none

module Program_Counter(
  input var logic [10:0] in, output var logic [10:0] out, input var logic clock, input var logic reset_bar);

logic hold, clear_hold;

always_ff @(negedge clock or negedge reset_bar)
begin
  if (~reset_bar) begin
    // Reinitialize on reset
    out <= 11'h0;
    hold <= 1'b1;
  end else begin
    // wait one clock cycle before serving in
    if (hold) begin
      out <= 11'h0;
      hold <= 1'b0;
    end else begin
      out <= in;
      hold <= 1'b0;
    end
  end
end
endmodule

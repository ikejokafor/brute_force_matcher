`timescale 1ns / 1ns
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//        
// Engineer:    
//
// Create Date:    
// Design Name:    
// Module Name:    
// Project Name:  
// Target Devices:  
// Tool versions:
// Description:    
//
// Dependencies:
//   
//    
//
// Revision:
//
//
//
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module SRL_bit  #(
  parameter C_CLOCK_CYCLES = 1
) (
  clk,
  ce,
  rst,
  data_in,
  data_out
);
  // -----------------------------------------------------------------------
  // Inputs/Outputs/Inouts
  // -----------------------------------------------------------------------
  input  clk;
  input  ce;
  input  rst;
  input  data_in;
  output data_out;   
  
  
  // -----------------------------------------------------------------------
  // Regs/Wires/Integers
  // -----------------------------------------------------------------------
  reg [C_CLOCK_CYCLES - 1:0] shift_reg;
  
  always @(posedge clk) begin
    if(rst) begin
      shift_reg  <= {C_CLOCK_CYCLES{1'b0}};
    end else if(ce) begin
      shift_reg   <= {shift_reg[C_CLOCK_CYCLES - 2:0], data_in};
    end
  end
  
  assign data_out = shift_reg[C_CLOCK_CYCLES-  1];

endmodule                  

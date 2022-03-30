`timescale 1ns / 1ns
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:      
//        
// Engineer:  
//
// Create Date:    
// Design Name:    
// Module Name:    
// Project Name:  
// Target Devices:  
// Tool versions:
// Description:   DSP module which takes its two inputs, subtracts them, squares them, and then 
//                --> if it is not last DSP, passes the result on to next DSP, or 
//                --> if it is the last DSP, it will accumulate values from previous DSP's.
//
// Dependencies:
//   
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
module brute_force_matcher_preSubSquareAccum_DSP  #(
    parameter C_DSP_INPUT_WIDTH  = 16,  // Size of inputs
    parameter C_INPUT_DELAY      = 1,
    parameter C_IS_ACCUM         = 0,
    parameter C_DSP_OUTPUT_WIDTH = 48
) (
    clk        ,
    rst        ,
    first_desc ,
    a          ,
    d          ,
    pcin       ,
    pout       ,
    accum
); 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    
    
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs /Outputs
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    input                                      clk;
    input                                      rst;
    input                                      first_desc;
    input   signed [C_DSP_INPUT_WIDTH - 1:0]   a;
    input   signed [C_DSP_INPUT_WIDTH - 1:0]   d;
    input          [C_DSP_OUTPUT_WIDTH - 1:0]  pcin;
    input                                      accum;
    output  reg    [C_DSP_OUTPUT_WIDTH - 1:0]  pout;
  
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Wire / Regs / Integers
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    reg signed [C_DSP_INPUT_WIDTH  - 1:0]   diff_reg;
    reg signed [2 * C_DSP_INPUT_WIDTH :0]   m_reg;
    wire       [2 * C_DSP_INPUT_WIDTH :0]   m_reg_u;

    reg        [C_DSP_INPUT_WIDTH - 1:0]    a_delay_reg [C_INPUT_DELAY -1:0];
    reg        [C_DSP_INPUT_WIDTH - 1:0]    d_delay_reg [C_INPUT_DELAY -1:0];
    integer                                 idx;

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    generate
        if(C_IS_ACCUM) begin
            if(`SIMD == 8) begin
                always@(posedge clk) begin
                    if(rst) begin
                        pout <= 0;
                    end else begin
                        if(accum) begin
                            pout <= m_reg_u + pcin + pout;
                        end else if(!accum && first_desc) begin
                            pout <= m_reg_u + pcin;
                        end
                    end
                end
            end else if(`SIMD == 64) begin
                always@(posedge clk) begin
                    if(rst) begin
                        pout <= 0;
                    end else begin
                        if(accum) begin
                            pout <= m_reg_u + pcin;
                        end 
                    end
                end
            end
        end else begin
            always@(posedge clk) begin
                if(rst) begin
                        pout <= 0;
                    end else begin
                        pout <= m_reg_u + pcin;
                    end
                end
            end
    endgenerate 

    // BEGIN DSP Logic ------------------------------------------------------------------------------------------------------------------------------
    assign m_reg_u = m_reg;
    
    always@(posedge clk)begin
        a_delay_reg[0] <= a;
        d_delay_reg[0] <= d;
        for(idx = 1; idx < C_INPUT_DELAY; idx = idx + 1) begin
            a_delay_reg[idx] <= a_delay_reg[idx - 1];
            d_delay_reg[idx] <= d_delay_reg[idx - 1];
        end
    end
    
    always @(posedge clk) begin 
        if(rst) begin
            diff_reg <= 0;
            m_reg    <= 0;
        end  else begin
            diff_reg <= a_delay_reg[C_INPUT_DELAY - 1] - d_delay_reg[C_INPUT_DELAY - 1];          
            m_reg    <= diff_reg * diff_reg;    
        end
    end
  
 
  // END DSP Logic --------------------------------------------------------------------------------------------------------------------------------

endmodule 

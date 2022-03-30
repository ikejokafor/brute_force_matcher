`timescale 1ps / 1ps
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
// Description:   Converts distance to floating point
//
// Dependencies:  brute_force_matcher_fixed_to_flt.v
//   
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_format_conv 
(
    clk,
    rst,
    s_axis_tvalid,
    s_axis_tdata,
    m_axis_result_tdata,
    m_axis_result_tvalid
);
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    `include "soc_it_defs.vh"


    //----------------------------------------------------------------------------------------------------------------------------------------------
    // LocalParams
    //----------------------------------------------------------------------------------------------------------------------------------------------
    localparam  C_LATENCY_OF_FLT_FIXED = 4'h6;

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    //----------------------------------------------------------------------------------------------------------------------------------------------- 
    input                          clk;
    input                          rst;
    input                          s_axis_tvalid;
    input [`MATCH_TABLE_WIDTH-1:0] s_axis_tdata;
    output[`MATCH_TABLE_WIDTH-1:0] m_axis_result_tdata;
    output                         m_axis_result_tvalid;


    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    reg  [`MATCH_TABLE_CTROL_BITS-1:0] bypass_reg [C_LATENCY_OF_FLT_FIXED:0];
    wire [1:0]                         m_axis_result_tvalid_i;
    wire [3:0]                         s_axis_tready_i;
    wire                               s_axis_tready_bp; 
    integer i;
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations
    //-----------------------------------------------------------------------------------------------------------------------------------------------   
    //---------------------------------------------------
    // Designed assuming the latency of Fixed->float conv
    // is 6 clock cycles
    // SCORE-FIELD_WIDTH is 26 (1 bit for sign) (Conservative)
    //---------------------------------------------------
    brute_force_matcher_fixed_to_flt 
    word1 (
        .aclk                  (clk),
        .s_axis_a_tvalid       (s_axis_tvalid),
        .s_axis_a_tdata        (s_axis_tdata[`MATCH_TABLE_2ND_SCORE_FIELD]),
        .m_axis_result_tvalid  (m_axis_result_tvalid_i[1]),  
        .m_axis_result_tdata   (m_axis_result_tdata[`MATCH_TABLE_2ND_SCORE_FIELD])
    );
    
    
    brute_force_matcher_fixed_to_flt 
    word0 (
        .aclk                  (clk),
        .s_axis_a_tvalid       (s_axis_tvalid),
        .s_axis_a_tdata        (s_axis_tdata[`MATCH_TABLE_1ST_SCORE_FIELD]),
        .m_axis_result_tvalid  (m_axis_result_tvalid_i[0]),
        .m_axis_result_tdata   (m_axis_result_tdata[`MATCH_TABLE_1ST_SCORE_FIELD])
    );
    
  
    // BEGIN Format Conversion logic ----------------------------------------------------------------------------------------------------------------
    assign m_axis_result_tvalid = &m_axis_result_tvalid_i;
    assign {    m_axis_result_tdata[`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_FIELD],
                m_axis_result_tdata[`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_FIELD],
                m_axis_result_tdata[`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_FIELD],
                m_axis_result_tdata[`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_FIELD] 
            }   = bypass_reg[C_LATENCY_OF_FLT_FIXED];

    always @(posedge clk) begin
        if(rst) begin
            for (i=1; i <= C_LATENCY_OF_FLT_FIXED; i = i+1) begin
                bypass_reg[i]    <= 'd0;
            end
        end else begin
            for (i=1; i <= C_LATENCY_OF_FLT_FIXED; i = i+1) begin
                bypass_reg[i] <= bypass_reg[i-1];
            end
            bypass_reg[0]    <= {
                                    s_axis_tdata[`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_FIELD], 
                                    s_axis_tdata[`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_FIELD], 
                                    s_axis_tdata[`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_FIELD], 
                                    s_axis_tdata[`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_FIELD]
                                };
        end
    end
    // END Format Conversion logic ----------------------------------------------------------------------------------------------------------------

endmodule


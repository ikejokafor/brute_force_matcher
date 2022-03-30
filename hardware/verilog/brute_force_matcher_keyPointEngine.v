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
// Description:          Instaniates DSP cascade
//
// Dependencies:        brute_force_matcher_preSubSquareAccum_DSP.v
//   
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_keyPointEngine (
  clk                         ,
  rst                         ,
  first_desc                  ,

  i_descriptor_primary_data   ,
  i_descriptor_secondary_data ,
  keyPointDistance            ,

  accum
);  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
 
 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    localparam C_BUFFER_DATA_WIDTH = `DESCRIPTOR_ELEMENT_WIDTH * `SIMD;
    localparam C_I_DSP_OUT_WIDTH   = `DSP_OUTPUT_WIDTH * `SIMD;
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs/Outputs/Inouts
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                               clk;
    input                               rst;
    input                               first_desc;

    input   [C_BUFFER_DATA_WIDTH - 1:0] i_descriptor_primary_data;
    input   [C_BUFFER_DATA_WIDTH - 1:0] i_descriptor_secondary_data;
    output  [  `DSP_OUTPUT_WIDTH - 1:0] keyPointDistance;

    input                               accum;
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires/Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------  
    wire  [C_I_DSP_OUT_WIDTH - 1 : 0]   i_dsp_out_w;

    wire  [C_BUFFER_DATA_WIDTH - 1:0]   i_descriptor_primary_data_pipeline_w;
    wire  [C_BUFFER_DATA_WIDTH - 1:0]   i_descriptor_secondary_data_pipeline_w;

    wire  [              `SIMD - 1:0]   i_clear_accumReg_w;
    wire  [              `SIMD - 1:0]   i_accum;

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations / Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    genvar i;
    generate
        for(i = 0; i < `SIMD; i = i + 1) begin  
            if(i == 0) begin        
                brute_force_matcher_preSubSquareAccum_DSP  #(
                    .C_DSP_INPUT_WIDTH  ( `DESCRIPTOR_ELEMENT_WIDTH  ),
                    .C_INPUT_DELAY      ( i + 1   ),
                    .C_IS_ACCUM         ( 0       ),
                    .C_DSP_OUTPUT_WIDTH ( `DSP_OUTPUT_WIDTH )
                ) 
                i0_brute_force_matcher_preSubSquareAccum_DSP (
                    .clk        ( clk        ),
                    .rst        ( rst        ),
                    .first_desc ( 1'b0       ),
                    .a          ( i_descriptor_primary_data   [( i * `DESCRIPTOR_ELEMENT_WIDTH) +: `DESCRIPTOR_ELEMENT_WIDTH]    ),
                    .d          ( i_descriptor_secondary_data [( i * `DESCRIPTOR_ELEMENT_WIDTH) +: `DESCRIPTOR_ELEMENT_WIDTH]    ),
                    .pcin       ( {(`DSP_OUTPUT_WIDTH){1'b0}} ),
                    .pout       ( i_dsp_out_w [( i * ( `DSP_OUTPUT_WIDTH)) +: ( `DSP_OUTPUT_WIDTH)]),
                    .accum      ( i_accum[i]   )
                );
            end else if(i == (`SIMD - 1)) begin
                brute_force_matcher_preSubSquareAccum_DSP  #(
                    .C_DSP_INPUT_WIDTH  ( `DESCRIPTOR_ELEMENT_WIDTH  ),
                    .C_INPUT_DELAY      ( i + 1    ),
                    .C_IS_ACCUM         ( 1        ),
                    .C_DSP_OUTPUT_WIDTH ( `DSP_OUTPUT_WIDTH )
                ) 
                i0_brute_force_matcher_preSubSquareAccum_DSP (
                    .clk        ( clk         ),
                    .rst        ( rst         ),
                    .first_desc ( first_desc  ),
                    .a          ( i_descriptor_primary_data   [( i * `DESCRIPTOR_ELEMENT_WIDTH)   +: `DESCRIPTOR_ELEMENT_WIDTH]  ),
                    .d          ( i_descriptor_secondary_data [( i * `DESCRIPTOR_ELEMENT_WIDTH)   +: `DESCRIPTOR_ELEMENT_WIDTH]  ),
                    .pcin       ( i_dsp_out_w  [(( i - 1) * ( `DSP_OUTPUT_WIDTH)) +: ( `DSP_OUTPUT_WIDTH)]  ),
                    .pout       ( i_dsp_out_w  [      ( i * ( `DSP_OUTPUT_WIDTH)) +: ( `DSP_OUTPUT_WIDTH)]  ),
                    .accum      ( i_accum[i]  )
                );    
            end else begin
                brute_force_matcher_preSubSquareAccum_DSP  #(
                    .C_DSP_INPUT_WIDTH  ( `DESCRIPTOR_ELEMENT_WIDTH ),
                    .C_INPUT_DELAY      ( i + 1 ),
                    .C_IS_ACCUM         ( 0     ),
                    .C_DSP_OUTPUT_WIDTH ( `DSP_OUTPUT_WIDTH )
                ) 
                i0_brute_force_matcher_preSubSquareAccum_DSP(
                    .clk        ( clk     ),
                    .rst        ( rst     ),
                    .first_desc ( 1'b0    ),
                    .a          ( i_descriptor_primary_data   [( i * `DESCRIPTOR_ELEMENT_WIDTH) +: `DESCRIPTOR_ELEMENT_WIDTH]  ),
                    .d          ( i_descriptor_secondary_data [( i * `DESCRIPTOR_ELEMENT_WIDTH) +: `DESCRIPTOR_ELEMENT_WIDTH]  ),
                    .pcin       ( i_dsp_out_w   [( ( i - 1) * ( `DSP_OUTPUT_WIDTH)) +: ( `DSP_OUTPUT_WIDTH)]  ),
                    .pout       ( i_dsp_out_w   [       ( i * ( `DSP_OUTPUT_WIDTH)) +: ( `DSP_OUTPUT_WIDTH)]  ),
                    .accum      ( i_accum[i] )
                );
            end
            if(i == (`SIMD - 1)) begin
                assign i_accum[i]  = accum;  
            end else begin
                assign i_accum[i]  = 0;
            end    
        end 
    endgenerate
  
    // BEGIN Keypoint engine logic ------------------------------------------------------------------------------------------------------------------
    assign keyPointDistance                                                         = i_dsp_out_w[((`SIMD - 1) * (`DSP_OUTPUT_WIDTH)) +: (`DSP_OUTPUT_WIDTH)];
    assign i_descriptor_primary_data_pipeline_w  [0 +: `DESCRIPTOR_ELEMENT_WIDTH]   = i_descriptor_primary_data  [0 +: `DESCRIPTOR_ELEMENT_WIDTH];
    assign i_descriptor_secondary_data_pipeline_w[0 +: `DESCRIPTOR_ELEMENT_WIDTH]   = i_descriptor_secondary_data[0 +: `DESCRIPTOR_ELEMENT_WIDTH];
    // END keypoint engine logic --------------------------------------------------------------------------------------------------------------------

endmodule 

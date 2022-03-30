`timescale 1ns / 1ns
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    
// Engineer: Ikenna Okafor  
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
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_engine #(
    parameter C_SEC_DESCRIPTOR_TABLE_DEPTH  = 1,
    parameter C_SEC_DESC_FIFO_DEPTH         = 32
) (
    compute_clk,
    interface_clk,
    rst,
    force_rst,
    
    primary_descriptor_buffer_read_info,
    primary_descriptor_buffer_read_data,
    primary_descriptor_buffer_read_valid,
    primary_descriptor_buffer_read_init,
    primary_descriptor_buffer_empty,
    
    secondary_descriptor_buffer_space_available,
    secondary_descriptor_buffer_depleted,
    secondary_descriptor_buffer_load_init,
    secondary_descriptor_buffer_load_data,
    secondary_descriptor_buffer_load_valid,
    secondary_descriptor_buffer_load_info,
    secondary_descriptor_buffer_load_count,
    sec_desc_engine_desc_valid,
    all_sec_desc_engine_desc_valid,

    match_table_ready,
    match_info_valid,
    match_info,
    
    advance,
    sec_buffer_wren
);
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    `include "soc_it_defs.vh"

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------------------------------------------------------------------------    
    localparam C_BUFFER_DATA_WIDTH                  = `SIMD * `DESCRIPTOR_ELEMENT_WIDTH;
    localparam C_NUM_DESC_ELEM_DIV_SIMD_MINUS_TWO   = (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD) - 16'd2;
  
  
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    input                                   compute_clk;
    input                                   interface_clk;
    input                                   rst;
    input                                   force_rst;
    
    input  [`DESCRIPTOR_INFO_WIDTH - 1:0]   primary_descriptor_buffer_read_info;
    input  [   C_BUFFER_DATA_WIDTH - 1:0]   primary_descriptor_buffer_read_data;
    input                                   primary_descriptor_buffer_read_valid;
    output                                  primary_descriptor_buffer_read_init;
    input                                   primary_descriptor_buffer_empty;
    
    output                                  secondary_descriptor_buffer_space_available;
    output                                  secondary_descriptor_buffer_depleted;
    input                                   secondary_descriptor_buffer_load_init;
    input  [   C_BUFFER_DATA_WIDTH - 1:0]   secondary_descriptor_buffer_load_data;
    input                                   secondary_descriptor_buffer_load_valid;
    input  [`DESCRIPTOR_INFO_WIDTH - 1:0]   secondary_descriptor_buffer_load_info;
    input  [                        15:0]   secondary_descriptor_buffer_load_count;
    output                                  sec_desc_engine_desc_valid;
    input                                   all_sec_desc_engine_desc_valid;
    
    input                                   match_table_ready;
    output                                  match_info_valid;
    output [    `MATCH_INFO_WIDTH - 1:0]    match_info;
    
    output                                  advance;
    output                                  sec_buffer_wren;
  
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------   
    wire  [   C_BUFFER_DATA_WIDTH - 1:0]    secondary_descriptor_buffer_read_data;
    wire                                    secondary_descriptor_buffer_read_valid;
    wire                                    secondary_descriptor_buffer_desc_valid;
    wire  [`DESCRIPTOR_INFO_WIDTH - 1:0]    secondary_descriptor_buffer_read_info;
    wire                                    secondary_descriptor_buffer_empty;

    reg                                     all_sec_desc_engine_desc_valid_r;
    wire                                    advance;
    wire                                    secondary_descriptor_buffer_keypoint_advance;
    wire  [  `DESCRIPTOR_INFO_KEYPOINT_FIRST_WIDTH - 1:0]          primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_FIRST_FLAG;
    wire  [   `DESCRIPTOR_INFO_KEYPOINT_LAST_WIDTH - 1:0]          primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG;    
    wire  [ `DESCRIPTOR_INFO_DESCRIPTOR_LAST_WIDTH - 1:0]          primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_LAST_FLAG;
    wire  [`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_WIDTH - 1:0]          primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD;
    
  

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations / Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------    
    brute_force_matcher_secondary_descriptor_buffer #(
        .C_SEC_DESCRIPTOR_TABLE_DEPTH            (C_SEC_DESCRIPTOR_TABLE_DEPTH  ),
        .C_SEC_DESC_FIFO_DEPTH                   (C_SEC_DESC_FIFO_DEPTH         )                                    
    ) 
    i0_brute_force_matcher_secondary_descriptor_buffer (
        .rst                                        ( rst                                                                                  ),
        .force_rst                                  ( force_rst                                                                            ),

        .queue_write_clk                            ( interface_clk                                                                        ),
        .queue_depleted                             ( secondary_descriptor_buffer_depleted                                                 ),
        .queue_space_available                      ( secondary_descriptor_buffer_space_available                                          ),
        .queue_wren                                 ( secondary_descriptor_buffer_load_valid                                               ),
        .queue_datain                               ( {secondary_descriptor_buffer_load_data, secondary_descriptor_buffer_load_info }      ),
        .secondary_descriptor_buffer_load_init      ( secondary_descriptor_buffer_load_init                                                ),
        .buffer_empty                               ( secondary_descriptor_buffer_empty                                                    ),

        .queue_read_clk                             ( compute_clk                                                                          ),
        .buffer_control_descriptor_valid            ( secondary_descriptor_buffer_desc_valid                                               ),
        .descriptor_advance                         ( advance                                                                              ),
        .keypoint_advance                           ( secondary_descriptor_buffer_keypoint_advance                                         ),
        .descriptor_dataout                         ( {secondary_descriptor_buffer_read_data, secondary_descriptor_buffer_read_info}       ),
        .descriptor_dataout_valid                   ( secondary_descriptor_buffer_read_valid                                               ),
        .dispatch_unit_total_keypoint_load_count    ( secondary_descriptor_buffer_load_count                                               ),
        .sec_buffer_wren                            ( sec_buffer_wren                                                                      )
    ); 


    brute_force_matcher_descriptor_compute_pipeline
    i0_brute_force_matcher_descriptor_compute_pipeline (  
        .rst                                ( rst                                               ),

        .descripor_clk                      ( compute_clk                                       ),
        .descriptor_valid                   ( all_sec_desc_engine_desc_valid_r                  ),

        .descriptor_primary_data            ( primary_descriptor_buffer_read_data               ),
        .descriptor_primary_info            ( primary_descriptor_buffer_read_info               ),
        .descriptor_primary_data_valid      ( primary_descriptor_buffer_read_valid              ),
        .descriptor_primary_empty           ( primary_descriptor_buffer_empty                   ),

        .descriptor_secondary_data          ( secondary_descriptor_buffer_read_data             ),
        .descriptor_secondary_info          ( secondary_descriptor_buffer_read_info             ),
        .descriptor_secondary_data_valid    ( secondary_descriptor_buffer_read_valid            ),
        .descriptor_secondary_empty         ( secondary_descriptor_buffer_empty                 ),

        .match_table_ready                  ( match_table_ready                                 ),
        .match_info_valid                   ( match_info_valid                                  ),
        .match_info                         ( match_info                                        )
    );
  
    
    // BEGIN Cluser Descriptor Engine logic ---------------------------------------------------------------------------------------------------------
    assign primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_FIRST_FLAG = primary_descriptor_buffer_read_info[`DESCRIPTOR_INFO_KEYPOINT_FIRST_FLAG];
    assign primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG = primary_descriptor_buffer_read_info[`DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG];
    assign primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_LAST_FLAG = primary_descriptor_buffer_read_info[`DESCRIPTOR_INFO_DESCRIPTOR_LAST_FLAG];
    assign primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD = primary_descriptor_buffer_read_info[`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD];
    
    assign sec_desc_engine_desc_valid                   = secondary_descriptor_buffer_desc_valid;
    
    assign advance                                      =   (primary_descriptor_buffer_empty) ? 0 : 
                                                            (`SIMD == 64) ? 
                                                            (all_sec_desc_engine_desc_valid && secondary_descriptor_buffer_desc_valid && match_table_ready) : 
                                                            (!primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_FIRST_FLAG || (primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_FIRST_FLAG 
                                                            && all_sec_desc_engine_desc_valid && secondary_descriptor_buffer_desc_valid && match_table_ready)); 

    assign primary_descriptor_buffer_read_init          = (primary_descriptor_buffer_empty) ? 0 : 
                                                          (`SIMD == 64) ? (primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG) :
                                                          (primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG && primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_LAST_FLAG);
                                                            
    assign secondary_descriptor_buffer_keypoint_advance =   (primary_descriptor_buffer_empty || secondary_descriptor_buffer_empty) ? 0 : 
                                                            (`SIMD == 64) ? (advance && (primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG)) :
                                                            advance && primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG 
                                                            && primary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD == C_NUM_DESC_ELEM_DIV_SIMD_MINUS_TWO;
  
    // Added by sxv49. To fix the bug in accum_w (not asserting for the last
    // time at the last desc pair) inside compute_pipeline. 
    always@(posedge compute_clk) begin
        if(rst) begin
            all_sec_desc_engine_desc_valid_r <= 1'b0;
        end else begin
            all_sec_desc_engine_desc_valid_r <= all_sec_desc_engine_desc_valid;
        end
    end 
    // END Cluster Descriptor Engine logic ----------------------------------------------------------------------------------------------------------
  
endmodule


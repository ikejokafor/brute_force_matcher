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
// Description:   Tertiary top level module for DSP cascade. Instaniates DSP cascade module. Instaniates
//                delay logic which controls when valid data is present from the DSP cascade and when 
//                valid match data is available. Also contains delay logic to coordinate the last
//                accumulator DSP should accumulate inputs or overwrite with new inputs if a new
//                pair of keypoints is being processed.
//
// Dependencies:  SRL_bit.v
//                SRL_bus.v
//                brute_force_matcher_keyPointEngine.v
//                brute_force_matcher_squareRoot.v
//   
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_descriptor_compute_pipeline (
    rst                                ,

    descripor_clk                      ,
    descriptor_valid                   ,

    descriptor_primary_data            ,
    descriptor_primary_info            ,
    descriptor_primary_data_valid      ,
    descriptor_primary_empty           ,

    descriptor_secondary_data          ,
    descriptor_secondary_info          ,
    descriptor_secondary_data_valid    ,
    descriptor_secondary_empty         ,

    match_table_ready                  ,
    match_info_valid                   ,
    match_info                         
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
    localparam C_NUM_CYCLES_DSP_CASCADE    = (`DSP_LATENCY  + (`SIMD - 1)) + ((`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD) - 1);

    // localparam C_NUM_CYCLES_FIRST_VALID_MATCH   = (`DSP_LATENCY + (`SIMD - 1)) + (`NUM_ELEMENTS_PER_DESCRIPTOR/`SIMD - 1) + `SQRT_LATENCY;
    //                      // initial latency                // num iterations for all desc value
    //                      // numDSP - 1 bc numDsp - 1            // - 1 because first value latency
    //                      // cycle delays on last dsp            // is computed in first term  

    localparam C_NUM_CYCLES_MATCH          = (`DSP_LATENCY + (`SIMD - 1)) + (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD - 1) + `SQRT_LATENCY;

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                                               rst;
    input                                               descripor_clk;
    input                                               descriptor_valid;

    input       [` DESCRIPTOR_SIMD_ELEMENT_WIDTH - 1:0] descriptor_primary_data;
    input       [` DESCRIPTOR_INFO_WIDTH - 1:0]         descriptor_primary_info;
    input                                               descriptor_primary_data_valid;
    input                                               descriptor_primary_empty;

    input       [` DESCRIPTOR_SIMD_ELEMENT_WIDTH - 1:0] descriptor_secondary_data;
    input       [` DESCRIPTOR_INFO_WIDTH - 1:0]         descriptor_secondary_info;
    input                                               descriptor_secondary_data_valid;
    input                                               descriptor_secondary_empty;

    input                                               match_table_ready;
    output                                              match_info_valid;
    output reg  [` MATCH_INFO_WIDTH - 1:0]              match_info;
 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    wire                                              descriptor_secondary_empty_w;
    wire                                              descriptor_primary_empty_w;
    wire [ `DSP_OUTPUT_WIDTH - 1:0]                   keyPointEngine_keyPointDistance;
    wire [ `SQRT_OUTPUT_WIDTH - 1:0]                  root_keyPointEngine_keyPointDistance;
    wire                                              accum_w;
    wire                                              accum;
    wire                                              squareRoot_dout_valid;
    wire [ `MATCH_INFO_QUERY_KEYPOINT_ID_WIDTH - 1:0] descriptor_primary_info_keypoint_id;
    wire [ `MATCH_INFO_MODEL_KEYPOINT_ID_WIDTH - 1:0] descriptor_secondary_info_keypoint_id;
    wire [ `MATCH_INFO_CELL_ID_WIDTH - 1:0]           descriptor_secondary_info_cell_id;
    wire                                              dsp_cascade_dout_valid;
    wire                                              dsp_cascade_dout_valid_w;
    wire                                              first_desc;
    wire                                              first_desc_w;


    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations 
    //-----------------------------------------------------------------------------------------------------------------------------------------------  
    SRL_bit #(
        .C_CLOCK_CYCLES((`DSP_LATENCY - 1) + (`SIMD - 1))  
    )
    i0_SRL_bit (
        .clk      ( descripor_clk ),
        .ce       ( 1'b1          ),
        .rst      ( rst           ),
        .data_in  ( accum_w       ),
        .data_out ( accum         )
    );

    
    SRL_bit #(
        .C_CLOCK_CYCLES(`DSP_LATENCY  + (`SIMD - 1))
    )
    i1_SRL_bit (
        .clk      ( descripor_clk            ),
        .ce       ( 1'b1                     ),
        .rst      ( rst                      ),
        .data_in  ( dsp_cascade_dout_valid_w ),
        .data_out ( dsp_cascade_dout_valid   )
    );

    
    SRL_bit #(
        .C_CLOCK_CYCLES((`DSP_LATENCY - 1) + (`SIMD - 1))
    )
    i3_SRL_bit (
        .clk      ( descripor_clk ),
        .ce       ( 1'b1          ),
        .rst      ( rst           ),
        .data_in  ( first_desc_w  ),
        .data_out ( first_desc    )
    );

    
    SRL_bus #(
        .C_DATA_WIDTH       (`MATCH_INFO_QUERY_KEYPOINT_ID_WIDTH    ),
        .C_CLOCK_CYCLES     (C_NUM_CYCLES_MATCH                     )
    )
    i0_SRL_bus (
        .clk      ( descripor_clk                                                 ),
        .ce       ( 1'b1                                                          ),
        .rst      ( rst                                                           ),
        .data_in  ( descriptor_secondary_info[`DESCRIPTOR_INFO_KEYPOINT_ID_FIELD] ),
        .data_out ( descriptor_secondary_info_keypoint_id                         )
    );

    
    SRL_bus #(
        .C_DATA_WIDTH       (`MATCH_INFO_MODEL_KEYPOINT_ID_WIDTH  ),
        .C_CLOCK_CYCLES     (C_NUM_CYCLES_MATCH                   )
    )
    i1_SRL_bus (
        .clk      ( descripor_clk                                               ),
        .ce       ( 1'b1                                                        ),
        .rst      ( rst                                                         ),
        .data_in  ( descriptor_primary_info[`DESCRIPTOR_INFO_KEYPOINT_ID_FIELD] ),
        .data_out ( descriptor_primary_info_keypoint_id                         )
    );
  
  
    SRL_bus #(
        .C_DATA_WIDTH       (`MATCH_INFO_CELL_ID_WIDTH  ),
        .C_CLOCK_CYCLES     (C_NUM_CYCLES_MATCH         )
    )
    i2_SRL_bus (
        .clk      ( descripor_clk                                             ),
        .ce       ( 1'b1                                                      ),
        .rst      ( rst                                                       ),
        .data_in  ( descriptor_secondary_info[`DESCRIPTOR_INFO_CELL_ID_FIELD] ),
        .data_out ( descriptor_secondary_info_cell_id                         )
    );

    
    brute_force_matcher_keyPointEngine
    i0_brute_force_matcher_keyPointEngine (
        .clk                         ( descripor_clk                   ),
        .rst                         ( rst                             ),

        .first_desc                  ( first_desc                      ),
        .i_descriptor_primary_data   ( descriptor_primary_data         ),
        .i_descriptor_secondary_data ( descriptor_secondary_data       ),
        .keyPointDistance            ( keyPointEngine_keyPointDistance ),

        .accum                       ( accum                           )
    );  
 
 
    // NOTE: Although the input and output widths are parameterized, 
    // the config of the sqrt IP takes 48 bit input and gives 25 bit output
    brute_force_matcher_squareRoot
    i0_brute_force_matcher_squareRoot (
        .aclk                    ( descripor_clk                                ),
        .s_axis_cartesian_tvalid ( dsp_cascade_dout_valid                       ),
        .s_axis_cartesian_tdata  ( keyPointEngine_keyPointDistance              ),
        .m_axis_dout_tvalid      ( squareRoot_dout_valid                        ),
        .m_axis_dout_tdata       ( root_keyPointEngine_keyPointDistance         )
    );

    
    SRL_bit #(
        .C_CLOCK_CYCLES(C_NUM_CYCLES_MATCH)
    )
    i4_SRL_bit (
        .clk      ( descripor_clk               ),
        .ce       ( 1'b1                        ),
        .rst      ( rst                         ),
        .data_in  ( descriptor_primary_empty    ),
        .data_out ( descriptor_primary_empty_w  )
    );
    
    SRL_bit #(
        .C_CLOCK_CYCLES(C_NUM_CYCLES_MATCH)
    )
    i5_SRL_bit (
        .clk      ( descripor_clk                   ),
        .ce       ( 1'b1                            ),
        .rst      ( rst                             ),
        .data_in  ( descriptor_secondary_empty      ),
        .data_out ( descriptor_secondary_empty_w    )
    );
 
    // BEGIN Keypoint Engine Logic ------------------------------------------------------------------------------------------------------------------
    assign match_info_valid         =  squareRoot_dout_valid;

    assign dsp_cascade_dout_valid_w =   (descriptor_secondary_empty) ? 0 : 
                                        (`SIMD == 64) ? (descriptor_primary_data_valid && descriptor_secondary_data_valid) :
                                        descriptor_secondary_info[`DESCRIPTOR_INFO_DESCRIPTOR_LAST_FLAG] 
                                            && descriptor_primary_data_valid && descriptor_secondary_data_valid;
                                        
    assign first_desc_w             =   (descriptor_primary_empty) ? 0 : 
                                        (`SIMD == 64) ? descriptor_primary_data_valid : 
                                            (descriptor_primary_info[`DESCRIPTOR_INFO_DESCRIPTOR_FIRST_FLAG] && descriptor_primary_data_valid);
                                    
    assign accum_w                  =   (descriptor_primary_empty) ? 0 : 
                                        (`SIMD == 64) ? (/*match_table_ready &&*/ descriptor_primary_data_valid && descriptor_secondary_data_valid && descriptor_valid) :
                                            (match_table_ready && !descriptor_primary_info[`DESCRIPTOR_INFO_DESCRIPTOR_FIRST_FLAG] && 
                                            descriptor_primary_data_valid && descriptor_secondary_data_valid && descriptor_valid);
    
    always@(*) begin
        match_info[`MATCH_INFO_QUERY_KEYPOINT_ID_FIELD] = (descriptor_primary_empty_w)   ? 0 : descriptor_primary_info_keypoint_id;
        match_info[`MATCH_INFO_MODEL_KEYPOINT_ID_FIELD] = (descriptor_secondary_empty_w) ? 0 : descriptor_secondary_info_keypoint_id;
        match_info[`MATCH_INFO_SCORE_FIELD]             = root_keyPointEngine_keyPointDistance;
        match_info[`MATCH_INFO_CELL_ID_FIELD]           = (descriptor_secondary_empty_w) ? 0 : descriptor_secondary_info_cell_id;
    end
    // END Keypoint Engine Logic --------------------------------------------------------------------------------------------------------------------
 
`ifdef SIMULATION
    // integer                                           f_solution;
    // integer                                           f_sq_solution;
    // initial begin
    //     f_solution    = $fopen("hw_dsp_out_sqrt_in.txt","w");
    //     f_sq_solution = $fopen("hw_sqrt_out.txt","w");
    // 
    //     //$fwrite(f_solution," keyPointEngine_keyPointDistance \n");
    // end
    // 
    // always@(posedge descripor_clk) begin
    //     if(dsp_cascade_dout_valid)
    //         $fwrite(f_solution, "%x.000000\n", keyPointEngine_keyPointDistance);
    //     if(squareRoot_dout_valid)
    //         $fwrite(f_sq_solution, "%d.000000 \n", root_keyPointEngine_keyPointDistance[23:0]);
    // end
    integer numMatches;
    always@(posedge descripor_clk) begin
        if(rst) begin
            numMatches <= 0;
        end else if(match_info_valid) begin
            numMatches <= numMatches + 1;
        end
    end
`endif
 
endmodule


/*
module brute_force_matcher_descriptor_compute_pipeline (
    rst                                ,

    descripor_clk                      ,
    descriptor_valid                   ,

    descriptor_primary_data            ,
    descriptor_primary_info            ,
    descriptor_primary_data_valid      ,
    descriptor_primary_empty           ,

    descriptor_secondary_data          ,
    descriptor_secondary_info          ,
    descriptor_secondary_data_valid    ,
    descriptor_secondary_empty         ,

    match_table_ready                  ,
    match_info_valid                   ,
    match_info               
);
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    `include "soc_it_defs.vh"

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                                               rst;
    input                                               descripor_clk;
    input                                               descriptor_valid;

    input       [` DESCRIPTOR_SIMD_ELEMENT_WIDTH - 1:0] descriptor_primary_data;
    input       [` DESCRIPTOR_INFO_WIDTH - 1:0]         descriptor_primary_info;
    input                                               descriptor_primary_data_valid;
    input                                               descriptor_primary_empty;

    input       [` DESCRIPTOR_SIMD_ELEMENT_WIDTH - 1:0] descriptor_secondary_data;
    input       [` DESCRIPTOR_INFO_WIDTH - 1:0]         descriptor_secondary_info;
    input                                               descriptor_secondary_data_valid;
    input                                               descriptor_secondary_empty;

    input                                               match_table_ready;
    output                                              match_info_valid;
    output reg  [` MATCH_INFO_WIDTH - 1:0]              match_info;
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local Variables
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    int numMatches;
    reg match_info_valid_r;
   
    assign match_info_valid = match_info_valid_r;
   
    always@(posedge descripor_clk) begin
        match_info              <= 0;
        match_info_valid_r      <= 0;
        if(i0_brute_force_matcher_controller.init_keypoint_engine || 
            (i0_brute_force_matcher.genblk1[0].i0_brute_force_matcher_match_table.model_kp_count == i0_brute_force_matcher.genblk1[0].i0_brute_force_matcher_match_table.controller_num_model_kp)
        ) begin
            numMatches <= 0;
        end
        if(descriptor_primary_data_valid && descriptor_secondary_data_valid && descriptor_valid) begin
            match_info_valid_r      <= 1;
            numMatches              <= numMatches + 1;
        end
    end

 
endmodule
*/